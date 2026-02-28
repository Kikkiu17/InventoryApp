import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/component.dart';
import '../models/settings.dart';
import 'api_client.dart';

export 'api_client.dart' show ApiClient, InventoryMeta;

enum StorageMode { local, remote }
enum SortMode { none, name, quantity, drawer, specialTag }

class SyncConflict {
  final List<Component> localComponents;
  final AppSettings localSettings;
  final List<Component> remoteComponents;
  final AppSettings remoteSettings;
  final DateTime? localTimestamp;
  final DateTime? remoteTimestamp;

  SyncConflict({
    required this.localComponents,
    required this.localSettings,
    required this.remoteComponents,
    required this.remoteSettings,
    this.localTimestamp,
    this.remoteTimestamp,
  });
}

class DataService extends ChangeNotifier {
  static const _serverUrlKey      = 'serverUrl';
  static const _storageModeKey    = 'storageMode';
  static const _inventoryIdKey    = 'currentInventoryId';

  List<Component> _components = [];
  AppSettings _settings = AppSettings();
  List<InventoryMeta> _inventories = [];

  StorageMode _mode = StorageMode.local;
  String _serverUrl = 'http://192.168.1.2:8080';
  String _currentInventoryId = 'default';
  ApiClient? _api;

  bool _serverConnected = false;
  bool _syncing = false;
  String? _lastError;
  SyncConflict? _pendingConflict;

  String get _componentsKey     => 'components_$_currentInventoryId';
  String get _settingsKey       => 'settings_$_currentInventoryId';
  String get _localTimestampKey => 'localTimestamp_$_currentInventoryId';

  List<Component> get components => _components;
  AppSettings get settings => _settings;
  List<InventoryMeta> get inventories => _inventories;
  String get currentInventoryId => _currentInventoryId;
  InventoryMeta? get currentInventory =>
      _inventories.where((i) => i.id == _currentInventoryId).firstOrNull;
  StorageMode get mode => _mode;
  String get serverUrl => _serverUrl;
  bool get serverConnected => _serverConnected;
  bool get syncing => _syncing;
  String? get lastError => _lastError;
  bool get isRemote => _mode == StorageMode.remote;
  SyncConflict? get pendingConflict => _pendingConflict;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('components') && prefs.containsKey('settings')) {
      final oldC = prefs.getString('components');
      final oldS = prefs.getString('settings');
      final oldT = prefs.getString('localTimestamp');
      if (oldC != null) await prefs.setString('components_default', oldC);
      if (oldS != null) await prefs.setString('settings_default', oldS);
      if (oldT != null) await prefs.setString('localTimestamp_default', oldT);
      await prefs.remove('components');
      await prefs.remove('settings');
      await prefs.remove('localTimestamp');
    }

    _serverUrl          = prefs.getString(_serverUrlKey) ?? 'http://192.168.1.2:8080';
    _currentInventoryId = prefs.getString(_inventoryIdKey) ?? 'default';
    final modeStr = prefs.getString(_storageModeKey) ?? 'local';
    _mode = modeStr == 'remote' ? StorageMode.remote : StorageMode.local;

    if (_mode == StorageMode.remote) {
      _api = ApiClient(_serverUrl, inventoryId: _currentInventoryId);
      await _loadFromServer(checkConflict: true);
    } else {
      await _loadFromLocal(prefs);
    }
    notifyListeners();
  }

  Future<void> _loadFromLocal(SharedPreferences prefs) async {
    final sj = prefs.getString(_settingsKey);
    _settings = sj != null ? AppSettings.fromJson(jsonDecode(sj)) : AppSettings();
    final cj = prefs.getString(_componentsKey);
    _components = cj != null
        ? (jsonDecode(cj) as List).map((e) => Component.fromJson(e)).toList()
        : [];
  }

  Future<void> _loadFromServer({bool checkConflict = false}) async {
    try {
      _syncing = true;
      _lastError = null;
      notifyListeners();

      final ok = await _api!.ping();
      if (!ok) throw Exception('Server non raggiungibile');
      _serverConnected = true;

      _inventories = await _api!.listInventories();

      if (_inventories.isNotEmpty &&
          !_inventories.any((i) => i.id == _currentInventoryId)) {
        await _switchInventoryId(_inventories.first.id);
      }

      if (_inventories.isEmpty) {
        final created = await _api!.createInventory('Inventario principale');
        _inventories = [created];
        await _switchInventoryId(created.id);
      }

      final remoteComponents = await _api!.getComponents();
      final remoteSettings   = await _api!.getSettings();

      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_componentsKey);

      if (checkConflict && localJson != null) {
        final localComponents = (jsonDecode(localJson) as List)
            .map((e) => Component.fromJson(e)).toList();
        final lsj = prefs.getString(_settingsKey);
        final localSettings = lsj != null
            ? AppSettings.fromJson(jsonDecode(lsj)) : AppSettings();

        final localIds  = localComponents.map((c) => c.id).toSet();
        final remoteIds = remoteComponents.map((c) => c.id).toSet();
        final differ = localIds.length != remoteIds.length ||
            localIds.difference(remoteIds).isNotEmpty;

        if (differ && localComponents.isNotEmpty) {
          _pendingConflict = SyncConflict(
            localComponents: localComponents,
            localSettings: localSettings,
            remoteComponents: remoteComponents,
            remoteSettings: remoteSettings,
            localTimestamp: DateTime.tryParse(
                prefs.getString(_localTimestampKey) ?? ''),
          );
          _components = remoteComponents;
          _settings   = remoteSettings;
          notifyListeners();
          return;
        }
      }

      _components = remoteComponents;
      _settings   = remoteSettings;
      await _mirrorToLocal(_components, _settings);
    } catch (e) {
      _serverConnected = false;
      _lastError = e.toString();
      final prefs = await SharedPreferences.getInstance();
      await _loadFromLocal(prefs);
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> resolveConflict(bool useLocal) async {
    final c = _pendingConflict;
    if (c == null) return;
    _pendingConflict = null;
    if (useLocal) {
      _components = c.localComponents;
      _settings   = c.localSettings;
      try {
        await _api!.uploadFullDb({
          'components': _components.map((x) => x.toJson()).toList(),
          'settings':   _settings.toJson(),
        });
      } catch (e) { _lastError = e.toString(); }
    } else {
      _components = c.remoteComponents;
      _settings   = c.remoteSettings;
      await _mirrorToLocal(_components, _settings);
    }
    notifyListeners();
  }

  Future<void> _mirrorToLocal(List<Component> comps, AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_componentsKey, jsonEncode(comps.map((c) => c.toJson()).toList()));
    await prefs.setString(_settingsKey, jsonEncode(s.toJson()));
    await prefs.setString(_localTimestampKey, DateTime.now().toIso8601String());
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_componentsKey, jsonEncode(_components.map((c) => c.toJson()).toList()));
    await prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
    await prefs.setString(_localTimestampKey, DateTime.now().toIso8601String());
  }

  Future<void> _switchInventoryId(String id) async {
    _currentInventoryId = id;
    _api = _api!.withInventory(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_inventoryIdKey, id);
  }

  Future<void> switchInventory(String id) async {
    if (id == _currentInventoryId && _components.isNotEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_componentsKey);
    await prefs.remove(_settingsKey);
    await prefs.remove(_localTimestampKey);

    _components = [];
    _settings = AppSettings();

    await _switchInventoryId(id);
    await _loadFromServer(checkConflict: false);
  }

  Future<InventoryMeta> createInventory(String name, {String description = ''}) async {
    final meta = await _api!.createInventory(name, description: description);
    _inventories = await _api!.listInventories();
    notifyListeners();
    return meta;
  }

  Future<void> renameCurrentInventory(String name, {String description = ''}) async {
    await _api!.renameInventory(_currentInventoryId, name, description: description);
    _inventories = await _api!.listInventories();
    notifyListeners();
  }

  Future<void> renameInventory(String id, String name, {String description = ''}) async {
    await _api!.renameInventory(id, name, description: description);
    _inventories = await _api!.listInventories();
    notifyListeners();
  }

  Future<void> deleteInventory(String id) async {
    await _api!.deleteInventory(id);
    _inventories = await _api!.listInventories();
    if (id == _currentInventoryId && _inventories.isNotEmpty) {
      await switchInventory(_inventories.first.id);
    } else if (_inventories.isEmpty) {
      _components = [];
      _settings   = AppSettings();
      notifyListeners();
    }
  }

  Future<void> refreshInventoryList() async {
    if (!_serverConnected) return;
    try {
      _inventories = await _api!.listInventories();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> setServerUrl(String url) async {
    _serverUrl = url;
    _api = ApiClient(url, inventoryId: _currentInventoryId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);
    final ok = await _api!.ping();
    _serverConnected = ok;
    _lastError = ok ? null : 'Impossibile connettersi a $url';
    notifyListeners();
    return ok;
  }

  Future<void> setStorageMode(StorageMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageModeKey, mode == StorageMode.remote ? 'remote' : 'local');
    if (mode == StorageMode.remote) {
      _api = ApiClient(_serverUrl, inventoryId: _currentInventoryId);
      await _loadFromServer(checkConflict: true);
    } else {
      _serverConnected = false;
      _inventories = [];
      await _loadFromLocal(prefs);
    }
    notifyListeners();
  }

  Future<void> refreshFromServer() async {
    if (_mode != StorageMode.remote) return;
    await _loadFromServer(checkConflict: false);
    notifyListeners();
  }

  Future<void> addComponent(Component c) async {
    if (_mode == StorageMode.remote && _serverConnected) {
      try {
        final created = await _api!.createComponent(c);
        _components.add(created);
        await _mirrorToLocal(_components, _settings);
      } catch (e) { _lastError = e.toString(); rethrow; }
    } else {
      _components.add(c);
      await _saveLocal();
    }
    notifyListeners();
  }

  Future<void> updateComponent(Component c) async {
    if (_mode == StorageMode.remote && _serverConnected) {
      try {
        final updated = await _api!.updateComponent(c);
        final idx = _components.indexWhere((e) => e.id == updated.id);
        if (idx != -1) _components[idx] = updated;
        await _mirrorToLocal(_components, _settings);
      } catch (e) { _lastError = e.toString(); rethrow; }
    } else {
      final idx = _components.indexWhere((e) => e.id == c.id);
      if (idx != -1) _components[idx] = c;
      await _saveLocal();
    }
    notifyListeners();
  }

  Future<void> deleteComponent(String id) async {
    if (_mode == StorageMode.remote && _serverConnected) {
      try {
        await _api!.deleteComponent(id);
      } catch (e) { _lastError = e.toString(); rethrow; }
    }
    _components.removeWhere((e) => e.id == id);
    await _saveLocal();
    notifyListeners();
  }

  Future<void> updateQuantity(String id, int delta) async {
    if (_mode == StorageMode.remote && _serverConnected) {
      try {
        final updated = await _api!.patchQuantity(id, delta);
        final idx = _components.indexWhere((e) => e.id == updated.id);
        if (idx != -1) _components[idx] = updated;
        await _mirrorToLocal(_components, _settings);
        notifyListeners();
        return;
      } catch (e) { _lastError = e.toString(); }
    }
    final idx = _components.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _components[idx] = _components[idx].copyWith(
          quantity: (_components[idx].quantity + delta).clamp(0, 99999));
      await _saveLocal();
    }
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings s) async {
    _settings = s;
    if (_mode == StorageMode.remote && _serverConnected) {
      try {
        await _api!.updateSettings(s);
        await _mirrorToLocal(_components, _settings);
      } catch (e) { _lastError = e.toString(); }
    } else {
      await _saveLocal();
    }
    notifyListeners();
  }

  Future<void> exportData() async {
    final data = jsonEncode({
      'components': _components.map((c) => c.toJson()).toList(),
      'settings': _settings.toJson(),
      'exportedAt': DateTime.now().toIso8601String(),
    });
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/inventario_componenti.json');
    await file.writeAsString(data);
    await Share.shareXFiles([XFile(file.path)], text: 'Inventario componenti');
  }

  Future<bool> importData() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return false;
    try {
      final data = jsonDecode(
          await File(result.files.single.path!).readAsString()) as Map<String, dynamic>;
      if (data.containsKey('components')) {
        _components = (data['components'] as List)
            .map((e) => Component.fromJson(e)).toList();
      }
      if (data.containsKey('settings')) {
        _settings = AppSettings.fromJson(data['settings']);
      }
      if (_mode == StorageMode.remote && _serverConnected) {
        await _api!.uploadFullDb(data);
      }
      await _saveLocal();
      notifyListeners();
      return true;
    } catch (e) { _lastError = e.toString(); return false; }
  }

  List<Component> search(
    String query,
    List<String> selectedTags,
    SortMode sort,
    Map<String, String> specialTagFilters,
    [String? sortSpecialTag, int? cabinetFilter] 
  ) {
    var results = _components.toList();
    
    if (cabinetFilter != null) {
      results = results.where((c) => c.cabinet == cabinetFilter).toList();
    }
    
    if (query.isNotEmpty) {
      final rawTerms = query.split(' ').where((s) => s.isNotEmpty).toList();
      
      results = results.where((c) => rawTerms.every((rawTerm) {
        final parsedTerm = parseSpecialValue(rawTerm);
        final term = rawTerm.toLowerCase();
        
        return c.name.toLowerCase().contains(term) ||
          c.drawer.toLowerCase().contains(term) ||
          c.cabinet.toString().contains(term) ||
          c.description.toLowerCase().contains(term) ||
          c.tags.any((t) => t.toLowerCase().contains(term)) ||
          c.specialTagValues.entries.any((entry) {
              final tagDef = _settings.specialTags.where((t) => t.name == entry.key).firstOrNull;
              final isStr = tagDef?.isString ?? false;
              
              if (isStr) {
                return entry.value.toLowerCase().contains(term);
              } else {
                final parsedVal = parseSpecialValue(entry.value);
                return entry.value.toLowerCase().contains(term) || 
                       (parsedTerm != null && parsedVal == parsedTerm);
              }
          });
      })).toList();
    }
    
    if (selectedTags.isNotEmpty) {
      results = results
          .where((c) => selectedTags.every((t) => c.tags.contains(t))).toList();
    }
    
    specialTagFilters.forEach((tagName, filterText) {
      final tagDef = _settings.specialTags.where((t) => t.name == tagName).firstOrNull;
      final isStr = tagDef?.isString ?? false;

      final parsedFilter = isStr ? null : parseSpecialValue(filterText);
      final term = filterText.toLowerCase();
      
      results = results.where((c) {
        final valStr = c.specialTagValues[tagName];
        if (valStr == null) return false;
        
        if (isStr) {
          return valStr.toLowerCase().contains(term);
        } else {
          final parsedVal = parseSpecialValue(valStr);
          if (parsedFilter != null && parsedVal == parsedFilter) return true;
          return valStr.toLowerCase().contains(term);
        }
      }).toList();
    });
    
    switch (sort) {
      case SortMode.name:     
        results.sort((a, b) => a.name.compareTo(b.name)); 
        break;
      case SortMode.quantity: 
        results.sort((a, b) => b.quantity.compareTo(a.quantity)); 
        break;
      case SortMode.drawer:   
        results.sort((a, b) {
          final cab = a.cabinet.compareTo(b.cabinet);
          if (cab != 0) return cab;
          return a.drawer.compareTo(b.drawer);
        }); 
        break;
      case SortMode.specialTag:
        if (sortSpecialTag != null) {
          results.sort((a, b) {
            final valStrA = a.specialTagValues[sortSpecialTag];
            final valStrB = b.specialTagValues[sortSpecialTag];
            if (valStrA == null && valStrB == null) return a.name.compareTo(b.name);
            if (valStrA == null) return 1;
            if (valStrB == null) return -1;
            
            final tagDef = _settings.specialTags.where((t) => t.name == sortSpecialTag).firstOrNull;
            if (tagDef?.isString == true) {
              return valStrA.compareTo(valStrB); // Fallback nel caso in cui un tag stringa finisca qua
            }
            
            final numA = parseSpecialValue(valStrA);
            final numB = parseSpecialValue(valStrB);
            
            if (numA != null && numB != null) {
              return numA.compareTo(numB);
            }
            return valStrA.compareTo(valStrB);
          });
        }
        break;
      case SortMode.none: break;
    }
    return results;
  }
}