import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/component.dart';
import '../models/settings.dart';
import 'api_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

export 'api_client.dart' show ApiClient, InventoryMeta;

enum StorageMode { local, remote }
enum SortMode { none, name, quantity, drawer, specialTag }

// Nuova classe per gestire i filtri a range e testuali
class SpecialFilter {
  final String exact;
  final String min;
  final String max;

  SpecialFilter({this.exact = '', this.min = '', this.max = ''});
  bool get isEmpty => exact.isEmpty && min.isEmpty && max.isEmpty;
}

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
      notifyListeners();

      final ok = await _api!.ping();
      if (!ok) throw Exception('Server non raggiungibile');
      _serverConnected = true;

      // 1. Fetch Remote Data
      final remoteDb = await _api!.getFullDb();
      final remoteComponents = (remoteDb['components'] as List).map((e) => Component.fromJson(e)).toList();
      final remoteSettings = AppSettings.fromJson(remoteDb['settings']);
      final remoteTs = DateTime.tryParse(remoteDb['lastUpdated'] ?? '');

      // 2. Fetch Local Data
      final prefs = await SharedPreferences.getInstance();
      final localTs = DateTime.tryParse(prefs.getString(_localTimestampKey) ?? '');
      
      if (checkConflict && localTs != null && remoteTs != null) {
        // CASE A: Server is strictly newer -> Auto-update local
        if (remoteTs.isAfter(localTs)) {
          _components = remoteComponents;
          _settings = remoteSettings;
          await _mirrorToLocal(_components, _settings); // Update local file and timestamp
        } 
        // CASE B: Local is newer -> Ask user
        else if (localTs.isAfter(remoteTs)) {
          final localComponents = (jsonDecode(prefs.getString(_componentsKey)!) as List)
              .map((e) => Component.fromJson(e)).toList();
          final localSettings = AppSettings.fromJson(jsonDecode(prefs.getString(_settingsKey)!));

          _pendingConflict = SyncConflict(
            localComponents: localComponents,
            localSettings: localSettings,
            remoteComponents: remoteComponents,
            remoteSettings: remoteSettings,
            localTimestamp: localTs,
            remoteTimestamp: remoteTs,
          );
          // Show server data in background but wait for resolution
          _components = remoteComponents; 
          _settings = remoteSettings;
        }
      } else {
        // Default: overwrite (first load or no local data)
        _components = remoteComponents;
        _settings = remoteSettings;
        await _mirrorToLocal(_components, _settings);
      }
    } catch (e) {
      _serverConnected = false;
      _lastError = e.toString();
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
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Inventario componenti'));
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
    Map<String, SpecialFilter> specialTagFilters,
    [String? sortSpecialTag, int? cabinetFilter, bool unassignedPosition = false] 
  ) {
    var results = _components.toList();
    
    if (unassignedPosition) {
      results = results.where((c) => c.drawer.isEmpty).toList();
    }

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
    
    specialTagFilters.forEach((tagName, filter) {
      final tagDef = _settings.specialTags.where((t) => t.name == tagName).firstOrNull;
      final isStr = tagDef?.isString ?? false;

      results = results.where((c) {
        final valStr = c.specialTagValues[tagName];
        if (valStr == null) return false;
        
        if (isStr) {
          // Ricerca esatta testuale o inclusione (case insensitive)
          if (filter.exact.isNotEmpty) {
            return valStr.toLowerCase().contains(filter.exact.toLowerCase());
          }
          return true;
        } else {
          // Logica per range numerico o valore matematico esatto
          final parsedVal = parseSpecialValue(valStr);
          if (parsedVal == null) return false;

          if (filter.exact.isNotEmpty) {
            final parsedExact = parseSpecialValue(filter.exact);
            if (parsedExact != null && parsedVal != parsedExact) return false;
          }
          if (filter.min.isNotEmpty) {
            final parsedMin = parseSpecialValue(filter.min);
            if (parsedMin != null && parsedVal < parsedMin) return false;
          }
          if (filter.max.isNotEmpty) {
            final parsedMax = parseSpecialValue(filter.max);
            if (parsedMax != null && parsedVal > parsedMax) return false;
          }
          return true;
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
          // Se sono vuoti (non assegnati), vanno in fondo
          if (a.drawer.isEmpty && b.drawer.isEmpty) return a.name.compareTo(b.name);
          if (a.drawer.isEmpty) return 1;
          if (b.drawer.isEmpty) return -1;

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
              return valStrA.compareTo(valStrB);
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

  // ── Backups ──────────────────────────────────────────────────────────────────
  Future<List<String>> getBackups() async {
    if (_mode != StorageMode.remote || !_serverConnected) return [];
    try {
      return await _api!.getBackups();
    } catch (e) { 
      print('ERRORE BACKUP: $e'); 
      _lastError = e.toString(); 
      return []; 
    }
  }

  Future<bool> restoreBackup(String filename) async {
    if (_mode != StorageMode.remote || !_serverConnected) return false;
    try {
      await _api!.restoreBackup(filename);
      await refreshFromServer(); 
      return true;
    } catch (e) { 
      _lastError = e.toString(); 
      return false; 
    }
  }

  // ── Update APK ───────────────────────────────────────────────────────────────
  Future<void> checkForUpdates() async {
    if (_mode != StorageMode.remote || !_serverConnected) return;
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final res = await http.get(Uri.parse('$_serverUrl/api/update/version'))
          .timeout(const Duration(seconds: 5));
      
      if (res.statusCode == 200) {
        final serverVersion = jsonDecode(res.body)['version'];
        
        if (serverVersion != currentVersion) {
          final apkRes = await http.get(Uri.parse('$_serverUrl/api/update/download'));
          
          final dir = await getExternalStorageDirectory(); 
          final file = File('${dir!.path}/update.apk');
          await file.writeAsBytes(apkRes.bodyBytes);
          
          await OpenFilex.open(file.path);
        }
      }
    } catch (e) {
      print("Errore aggiornamento: $e");
    }
  }

  Future<void> createBackup() async {
    if (_mode != StorageMode.remote || !_serverConnected) return;
    try {
      await _api!.createBackup();
    } catch (e) {
      print("Errore creazione backup: $e");
    }
  }
}