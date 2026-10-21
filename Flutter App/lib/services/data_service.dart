import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/component.dart';
import '../models/settings.dart';
import '../models/search_result.dart';
import '../l10n/app_localizations.dart';
import 'api_client.dart';
import 'package:uuid/uuid.dart';

export 'api_client.dart' show ApiClient, InventoryMeta;

enum StorageMode { local, remote }

class AppHttpOverrides extends HttpOverrides {
  final bool trustSelfSigned;
  AppHttpOverrides({required this.trustSelfSigned});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    if (trustSelfSigned) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }
    return client;
  }
}

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

bool matchesQuery(Component c, String query, AppSettings settings) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return true;
  final rawTerms = trimmed.split(' ').where((s) => s.isNotEmpty).toList();

  return rawTerms.every((rawTerm) {
    final parsedTerm = parseSpecialValue(rawTerm);
    final term = rawTerm.toLowerCase();

    return c.name.toLowerCase().contains(term) ||
        c.drawer.toLowerCase().contains(term) ||
        c.cabinet.toString().contains(term) ||
        c.description.toLowerCase().contains(term) ||
        c.tags.any((t) => t.toLowerCase().contains(term)) ||
        c.specialTagValues.entries.any((entry) {
          final tagDef = settings.specialTags
              .where((t) => t.name == entry.key)
              .firstOrNull;
          final isStr = tagDef?.isString ?? false;

          if (isStr) {
            return entry.value.toLowerCase().contains(term);
          } else {
            final parsedVal = parseSpecialValue(entry.value);

            double? parsedTermWithUnitStripped;
            bool termMatchesUnit = false;
            if (tagDef != null && tagDef.unit.isNotEmpty) {
              final unitLower = tagDef.unit.toLowerCase();
              if (term.endsWith(unitLower)) {
                final stripped =
                    term.substring(0, term.length - unitLower.length).trim();
                parsedTermWithUnitStripped = parseSpecialValue(stripped);
              }
              if (unitLower.contains(term)) {
                termMatchesUnit = true;
              }
            }

            return entry.value.toLowerCase().contains(term) ||
                (parsedTerm != null && parsedVal == parsedTerm) ||
                (parsedTermWithUnitStripped != null &&
                    parsedVal == parsedTermWithUnitStripped) ||
                termMatchesUnit;
          }
        });
  });
}

class DataService extends ChangeNotifier {
  static const _serverUrlKey = 'serverUrl';
  static const _trustSelfSignedKey = 'trustSelfSigned';
  static const _storageModeKey = 'storageMode';
  static const _inventoryIdKey = 'currentInventoryId';
  static const _themeModeKey = 'themeMode';
  static const _languageKey = 'app_language';

  List<Component> _components = [];
  List<Component> _bufferComponents = [];
  AppSettings _settings = AppSettings();
  List<InventoryMeta> _inventories = [];

  StorageMode _mode = StorageMode.local;
  String _serverUrl = 'http://192.168.1.2:8080';
  bool _trustSelfSigned = true;
  String _currentInventoryId = 'default';
  String? _globalSearchQuery;
  ApiClient? _api;

  DataService() {
    _applyHttpOverrides();
  }

  ThemeMode _themeMode = ThemeMode.system;
  String _languageCode = 'en';
  String? _savedLanguageCode;
  String? _localAppDocDir;

  bool _serverConnected = false;
  bool _syncing = false;
  String? _lastError;
  SyncConflict? _pendingConflict;

  String get _componentsKey => 'components_$_currentInventoryId';
  String get _settingsKey => 'settings_$_currentInventoryId';
  String get _localTimestampKey => 'localTimestamp_$_currentInventoryId';
  String get _bufferComponentsKey => 'components__buffer_';

  List<Component> get components => _components;
  List<Component> get bufferComponents => _bufferComponents;
  AppSettings get settings => _settings;
  List<InventoryMeta> get inventories => _inventories;
  String get currentInventoryId => _currentInventoryId;
  InventoryMeta? get currentInventory {
    if (_mode == StorageMode.local) {
      return InventoryMeta(id: 'default', name: AppLocalizations.current.localInventory);
    }
    return _inventories.where((i) => i.id == _currentInventoryId).firstOrNull;
  }

  StorageMode get mode => _mode;
  String get serverUrl => _serverUrl;
  bool get trustSelfSigned => _trustSelfSigned;
  bool get serverConnected => _serverConnected;
  bool get syncing => _syncing;
  String? get lastError => _lastError;
  bool get isRemote => _mode == StorageMode.remote;
  SyncConflict? get pendingConflict => _pendingConflict;
  String? get globalSearchQuery => _globalSearchQuery;
  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  String? get savedLanguageCode => _savedLanguageCode;
  Locale get locale => Locale(_languageCode);

  void setGlobalSearchQuery(String? query) {
    _globalSearchQuery = query;
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
    notifyListeners();
  }

  Future<void> updateLanguage(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null || code == 'system') {
      _savedLanguageCode = null;
      await prefs.remove(_languageKey);
      _languageCode = _detectSystemLanguage();
    } else if (AppLocalizations.supportedLanguageCodes.contains(code.toLowerCase())) {
      _savedLanguageCode = code.toLowerCase();
      _languageCode = code.toLowerCase();
      await prefs.setString(_languageKey, _languageCode);
    }
    AppLocalizations.current = AppLocalizations.fromLocale(Locale(_languageCode));
    notifyListeners();
  }

  static String _detectSystemLanguage() {
    try {
      final sysLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final sysLang = sysLocale.languageCode.toLowerCase();
      if (AppLocalizations.supportedLanguageCodes.contains(sysLang)) {
        return sysLang;
      }
    } catch (_) {}
    return 'en';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final docDir = await getApplicationDocumentsDirectory();
      _localAppDocDir = docDir.path;
    } catch (_) {}

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

    _serverUrl = prefs.getString(_serverUrlKey) ?? 'http://192.168.1.2:8080';
    _trustSelfSigned = prefs.getBool(_trustSelfSignedKey) ?? true;
    _applyHttpOverrides();
    _currentInventoryId = prefs.getString(_inventoryIdKey) ?? 'default';
    final modeStr = prefs.getString(_storageModeKey) ?? 'local';
    _mode = modeStr == 'remote' ? StorageMode.remote : StorageMode.local;

    final themeStr = prefs.getString(_themeModeKey) ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeStr,
      orElse: () => ThemeMode.system,
    );

    _savedLanguageCode = prefs.getString(_languageKey);
    if (_savedLanguageCode != null &&
        AppLocalizations.supportedLanguageCodes
            .contains(_savedLanguageCode!.toLowerCase())) {
      _languageCode = _savedLanguageCode!.toLowerCase();
    } else {
      _languageCode = _detectSystemLanguage();
    }
    AppLocalizations.current =
        AppLocalizations.fromLocale(Locale(_languageCode));

    if (_mode == StorageMode.remote) {
      _api = ApiClient(
        _serverUrl,
        inventoryId: _currentInventoryId,
        allowSelfSigned: _trustSelfSigned,
      );
      await _loadFromServer(checkConflict: true);
      await _loadBufferFromServer();
    } else {
      await _loadFromLocal(prefs);
      await _loadBufferFromLocal(prefs);
    }
    notifyListeners();
  }

  Future<void> _loadFromLocal(SharedPreferences prefs) async {
    final sj = prefs.getString(_settingsKey);
    _settings =
        sj != null ? AppSettings.fromJson(jsonDecode(sj)) : AppSettings();
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

      // Fetch inventory list so the Inventari tab is populated immediately
      _inventories = await _api!.listInventories();

      // 1. Fetch Remote Data
      final remoteDb = await _api!.getFullDb();
      final remoteComponents = (remoteDb['components'] as List)
          .map((e) => Component.fromJson(e))
          .toList();
      final remoteSettings = AppSettings.fromJson(remoteDb['settings']);
      final remoteTs = DateTime.tryParse(remoteDb['lastUpdated'] ?? '');

      // 2. Fetch Local Data
      final prefs = await SharedPreferences.getInstance();
      final localTs =
          DateTime.tryParse(prefs.getString(_localTimestampKey) ?? '');

      if (checkConflict && localTs != null && remoteTs != null) {
        // CASE A: Server is strictly newer -> Auto-update local
        if (remoteTs.isAfter(localTs)) {
          _components = remoteComponents;
          _settings = remoteSettings;
          // Use remoteTs so next launch sees equal timestamps → no false conflict
          await _mirrorToLocal(_components, _settings, timestamp: remoteTs);
        }
        // CASE B: Local is newer -> Ask user
        else if (localTs.isAfter(remoteTs)) {
          final localComponents =
              (jsonDecode(prefs.getString(_componentsKey)!) as List)
                  .map((e) => Component.fromJson(e))
                  .toList();
          final localSettings =
              AppSettings.fromJson(jsonDecode(prefs.getString(_settingsKey)!));

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
        // Use remoteTs (if available) so next launch sees equal timestamps
        await _mirrorToLocal(_components, _settings, timestamp: remoteTs);
      }
    } catch (e) {
      _serverConnected = false;
      _lastError = e.toString();
      // Server unreachable — load the last locally cached data so the app
      // isn't empty. On the next successful sync it will be overwritten.
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
      _settings = c.localSettings;
      try {
        await _api!.uploadFullDb({
          'components': _components.map((x) => x.toJson()).toList(),
          'settings': _settings.toJson(),
        });
        // Use the timestamp the server assigned after the upload
        final ts = DateTime.tryParse(_api!.lastUpdated ?? '');
        await _mirrorToLocal(_components, _settings, timestamp: ts);
      } catch (e) {
        _lastError = e.toString();
      }
    } else {
      _components = c.remoteComponents;
      _settings = c.remoteSettings;
      // Use the remote timestamp we already fetched — no need to hit the server again
      await _mirrorToLocal(_components, _settings,
          timestamp: c.remoteTimestamp);
    }
    notifyListeners();
  }

  Future<void> _mirrorToLocal(List<Component> comps, AppSettings s,
      {DateTime? timestamp}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _componentsKey, jsonEncode(comps.map((c) => c.toJson()).toList()));
    await prefs.setString(_settingsKey, jsonEncode(s.toJson()));
    // Use provided timestamp (e.g. server's lastUpdated) so comparisons stay stable
    await prefs.setString(
        _localTimestampKey, (timestamp ?? DateTime.now()).toIso8601String());
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_componentsKey,
        jsonEncode(_components.map((c) => c.toJson()).toList()));
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

  Future<InventoryMeta> createInventory(String name,
      {String description = ''}) async {
    final meta = await _api!.createInventory(name, description: description);
    _inventories = await _api!.listInventories();
    notifyListeners();
    return meta;
  }

  Future<void> renameCurrentInventory(String name,
      {String description = ''}) async {
    await _api!
        .renameInventory(_currentInventoryId, name, description: description);
    _inventories = await _api!.listInventories();
    notifyListeners();
  }

  Future<void> renameInventory(String id, String name,
      {String description = ''}) async {
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
      _settings = AppSettings();
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

  void _applyHttpOverrides() {
    HttpOverrides.global = AppHttpOverrides(trustSelfSigned: _trustSelfSigned);
  }

  Future<void> setTrustSelfSigned(bool value) async {
    _trustSelfSigned = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trustSelfSignedKey, value);
    _applyHttpOverrides();
    if (_mode == StorageMode.remote) {
      _api?.close();
      _api = ApiClient(
        _serverUrl,
        inventoryId: _currentInventoryId,
        allowSelfSigned: _trustSelfSigned,
      );
    }
    notifyListeners();
  }

  Future<bool> setServerUrl(String url) async {
    String normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    _serverUrl = normalized;
    _api?.close();
    _api = ApiClient(
      _serverUrl,
      inventoryId: _currentInventoryId,
      allowSelfSigned: _trustSelfSigned,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, normalized);
    final ok = await _api!.ping();
    _serverConnected = ok;
    _lastError = ok ? null : 'Impossibile connettersi a $_serverUrl';
    notifyListeners();
    return ok;
  }

  Future<void> setStorageMode(StorageMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageModeKey, mode == StorageMode.remote ? 'remote' : 'local');
    if (mode == StorageMode.remote) {
      _api?.close();
      _api = ApiClient(
        _serverUrl,
        inventoryId: _currentInventoryId,
        allowSelfSigned: _trustSelfSigned,
      );
      await _loadFromServer(checkConflict: true);
      await _loadBufferFromServer();
    } else {
      _serverConnected = false;
      _inventories = [];
      await _loadFromLocal(prefs);
      await _loadBufferFromLocal(prefs);
    }
    notifyListeners();
  }

  Future<void> refreshFromServer() async {
    if (_mode != StorageMode.remote) return;
    await _loadFromServer(checkConflict: false);
    await _loadBufferFromServer();
    notifyListeners();
  }

  Future<void> addComponent(Component c) async {
    if (_mode == StorageMode.remote && _serverConnected) {
      try {
        final created = await _api!.createComponent(c);
        _components.add(created);
        final ts = DateTime.tryParse(_api!.lastUpdated ?? '');
        await _mirrorToLocal(_components, _settings, timestamp: ts);
      } catch (e) {
        _lastError = e.toString();
        rethrow;
      }
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
        final ts = DateTime.tryParse(_api!.lastUpdated ?? '');
        await _mirrorToLocal(_components, _settings, timestamp: ts);
      } catch (e) {
        _lastError = e.toString();
        rethrow;
      }
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
        _components.removeWhere((e) => e.id == id);
        final ts = DateTime.tryParse(_api!.lastUpdated ?? '');
        await _mirrorToLocal(_components, _settings, timestamp: ts);
      } catch (e) {
        _lastError = e.toString();
        rethrow;
      }
    } else {
      _components.removeWhere((e) => e.id == id);
      await _saveLocal();
    }
    notifyListeners();
  }

  Future<void> moveComponent(
      String componentId, String targetInventoryId) async {
    if (_mode == StorageMode.remote && _serverConnected) {
      try {
        await _api!.moveComponent(componentId, targetInventoryId);
        _components.removeWhere((e) => e.id == componentId);
        final ts = DateTime.tryParse(_api!.lastUpdated ?? '');
        await _mirrorToLocal(_components, _settings, timestamp: ts);

        // Invalidate target inventory local mirror
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('components_$targetInventoryId');
        await prefs.remove('localTimestamp_$targetInventoryId');
      } catch (e) {
        _lastError = e.toString();
        rethrow;
      }
    } else {
      throw Exception(
          'Lo spostamento è supportato solo in modalità remota con server connesso');
    }
    notifyListeners();
  }

  Future<void> updateQuantity(String id, int delta) async {
    if (_mode == StorageMode.remote && _serverConnected) {
      try {
        final updated = await _api!.patchQuantity(id, delta);
        final idx = _components.indexWhere((e) => e.id == updated.id);
        if (idx != -1) _components[idx] = updated;
        final ts = DateTime.tryParse(_api!.lastUpdated ?? '');
        await _mirrorToLocal(_components, _settings, timestamp: ts);
        notifyListeners();
        return;
      } catch (e) {
        _lastError = e.toString();
      }
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
        final ts = DateTime.tryParse(_api!.lastUpdated ?? '');
        await _mirrorToLocal(_components, _settings, timestamp: ts);
      } catch (e) {
        _lastError = e.toString();
      }
    } else {
      await _saveLocal();
    }
    notifyListeners();
  }

  List<String> getBags() {
    final bags = {
      ..._settings.bufferBags,
      ..._components.map((c) => c.bagName).whereType<String>()
    }.toList();
    bags.sort();
    return bags;
  }

  List<Component> getComponentsInBag(String bagName) {
    return _components.where((c) => c.bagName == bagName).toList();
  }

  Future<void> createBag(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    if (!_settings.bufferBags.contains(trimmedName)) {
      _settings.bufferBags.add(trimmedName);
      await updateSettings(_settings);
    }
  }

  Future<void> renameBag(String oldName, String newName) async {
    final trimmedNew = newName.trim();
    if (trimmedNew.isEmpty || trimmedNew == oldName) return;

    final idx = _settings.bufferBags.indexOf(oldName);
    if (idx != -1) {
      _settings.bufferBags[idx] = trimmedNew;
    } else if (!_settings.bufferBags.contains(trimmedNew)) {
      _settings.bufferBags.add(trimmedNew);
    }

    for (var c in _components) {
      if (c.bagName == oldName) {
        c.bagName = trimmedNew;
      }
    }

    if (_mode == StorageMode.remote && _serverConnected) {
      try {
        await _api!.uploadFullDb({
          'components': _components.map((x) => x.toJson()).toList(),
          'settings': _settings.toJson(),
        });
        final ts = DateTime.tryParse(_api!.lastUpdated ?? '');
        await _mirrorToLocal(_components, _settings, timestamp: ts);
      } catch (e) {
        _lastError = e.toString();
      }
    } else {
      await _saveLocal();
    }
    notifyListeners();
  }

  Future<void> deleteBag(String name, {bool deleteComponents = true}) async {
    _settings.bufferBags.remove(name);

    if (deleteComponents) {
      _components.removeWhere((c) => c.bagName == name);
    } else {
      for (var c in _components) {
        if (c.bagName == name) {
          c.bagName = null;
        }
      }
    }

    if (_mode == StorageMode.remote && _serverConnected) {
      try {
        await _api!.uploadFullDb({
          'components': _components.map((x) => x.toJson()).toList(),
          'settings': _settings.toJson(),
        });
        final ts = DateTime.tryParse(_api!.lastUpdated ?? '');
        await _mirrorToLocal(_components, _settings, timestamp: ts);
      } catch (e) {
        _lastError = e.toString();
      }
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
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/inventario_componenti.json');
    await file.writeAsString(data);
    await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: AppLocalizations.current.appName));
  }

  Future<bool> importData() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return false;
    try {
      final data =
          jsonDecode(await File(result.files.single.path!).readAsString())
              as Map<String, dynamic>;
      if (data.containsKey('components')) {
        _components = (data['components'] as List)
            .map((e) => Component.fromJson(e))
            .toList();
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
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  List<Component> search(String query, List<String> selectedTags, SortMode sort,
      Map<String, SpecialFilter> specialTagFilters,
      [String? sortSpecialTag,
      int? cabinetFilter,
      bool unassignedPosition = false,
      bool sortAscending = true]) {
    var results = _components.where((c) => c.bagName == null).toList();

    if (unassignedPosition) {
      results = results.where((c) => c.drawer.isEmpty).toList();
    }

    if (cabinetFilter != null) {
      results = results.where((c) => c.cabinet == cabinetFilter).toList();
    }

    if (query.isNotEmpty) {
      results =
          results.where((c) => matchesQuery(c, query, _settings)).toList();
    }

    if (selectedTags.isNotEmpty) {
      results = results
          .where((c) => selectedTags.every((t) => c.tags.contains(t)))
          .toList();
    }

    specialTagFilters.forEach((tagName, filter) {
      final tagDef =
          _settings.specialTags.where((t) => t.name == tagName).firstOrNull;
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
          if (a.drawer.isEmpty && b.drawer.isEmpty)
            return a.name.compareTo(b.name);
          if (a.drawer.isEmpty) return 1;
          if (b.drawer.isEmpty) return -1;

          final cab = a.cabinet.compareTo(b.cabinet);
          if (cab != 0) return cab;

          final drawerComp = a.drawer.compareTo(b.drawer);
          if (drawerComp != 0) return drawerComp;

          final zoneA = a.drawerZone ?? 1;
          final zoneB = b.drawerZone ?? 1;
          final zoneComp = zoneA.compareTo(zoneB);
          if (zoneComp != 0) return zoneComp;

          return a.name.compareTo(b.name);
        });
        break;
      case SortMode.specialTag:
        if (sortSpecialTag != null) {
          results.sort((a, b) {
            final valStrA = a.specialTagValues[sortSpecialTag];
            final valStrB = b.specialTagValues[sortSpecialTag];
            if (valStrA == null && valStrB == null)
              return a.name.compareTo(b.name);
            if (valStrA == null) return 1;
            if (valStrB == null) return -1;

            final tagDef = _settings.specialTags
                .where((t) => t.name == sortSpecialTag)
                .firstOrNull;
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
      case SortMode.none:
        break;
    }
    if (!sortAscending) {
      results = results.reversed.toList();
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

  Future<void> createBackup() async {
    if (_mode != StorageMode.remote || !_serverConnected) return;
    try {
      await _api!.createBackup();
    } catch (e) {
      print("Errore creazione backup: $e");
    }
  }

  // ── Attachments ──────────────────────────────────────────────────────────────
  Future<String?> uploadAttachment(String filePath, String filename) async {
    if (_mode == StorageMode.remote && _serverConnected) {
      try {
        return await _api!.uploadAttachment(filePath, filename);
      } catch (e) {
        _lastError = e.toString();
        notifyListeners();
        return null;
      }
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final attachDir =
            Directory('${dir.path}/attachments/$_currentInventoryId');
        if (!await attachDir.exists()) {
          await attachDir.create(recursive: true);
        }
        final safeName = '${const Uuid().v4()}_$filename';
        final newPath = '${attachDir.path}/$safeName';
        await File(filePath).copy(newPath);
        return safeName;
      } catch (e) {
        _lastError = e.toString();
        notifyListeners();
        return null;
      }
    }
  }

  Future<void> deleteAttachment(String filename) async {
    if (_mode == StorageMode.remote && _serverConnected) {
      try {
        await _api!.deleteAttachment(filename);
      } catch (e) {
        _lastError = e.toString();
        notifyListeners();
      }
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/attachments/$_currentInventoryId/$filename';
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        _lastError = e.toString();
        notifyListeners();
      }
    }
  }

  Future<String> getLocalAttachmentPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/attachments/$_currentInventoryId/$filename';
  }

  String getLocalAttachmentPathSync(String filename) {
    if (_localAppDocDir == null) return '';
    return '$_localAppDocDir/attachments/$_currentInventoryId/$filename';
  }

  String getAttachmentUrl(String filename) {
    if (_api != null) {
      return _api!.getAttachmentUrl(filename);
    }
    return '';
  }

  // ── Ricerca Globale ────────────────────────────────────────────────────────
  Future<List<GlobalSearchResult>> globalSearch(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    List<GlobalSearchResult> matches = [];

    // 1. Search in Inventories (Remote or Local)
    if (_mode == StorageMode.remote && _serverConnected && _api != null) {
      try {
        final results = await _api!.searchAll(q);
        matches = results
            .map((e) => GlobalSearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Remote search failed, falling back or error: $e');
      }
    } else {
      // Local search
      final prefs = await SharedPreferences.getInstance();
      for (var inv in _inventories) {
        final cj = prefs.getString('components_${inv.id}');
        if (cj == null) continue;

        final sj = prefs.getString('settings_${inv.id}');
        final settings =
            sj != null ? AppSettings.fromJson(jsonDecode(sj)) : AppSettings();

        final comps =
            (jsonDecode(cj) as List).map((e) => Component.fromJson(e)).toList();
        for (var c in comps) {
          if (matchesQuery(c, query, settings)) {
            matches.add(GlobalSearchResult(
              inventoryId: inv.id,
              inventoryName: inv.name,
              component: c,
              specialTags: settings.specialTags,
            ));
          }
        }
      }
    }

    // 2. Search in Buffer Components
    for (var c in _bufferComponents) {
      if (matchesQuery(c, query, _settings)) {
        matches.add(GlobalSearchResult(
          inventoryId: '_buffer_',
          inventoryName: 'Buffer',
          component: c,
          specialTags: _settings.specialTags,
        ));
      }
    }

    return matches;
  }

  List<SpecialTag>? getSpecialTagsForInventory(String invId) {
    if (invId == '_buffer_' || invId == _currentInventoryId) {
      return _settings.specialTags;
    }
    return null;
  }

  Map<String, String> getAllInventoryNames() {
    final names = <String, String>{};
    names['_buffer_'] = AppLocalizations.current.tabBuffer;

    if (_mode == StorageMode.remote) {
      for (final inv in _inventories) {
        names[inv.id] = inv.name;
      }
      if (!names.containsKey(_currentInventoryId)) {
        final current = currentInventory;
        names[_currentInventoryId] = current?.name ?? _currentInventoryId;
      }
    } else {
      names['default'] = AppLocalizations.current.localInventory;
      for (final inv in _inventories) {
        names[inv.id] = inv.name;
      }
    }
    return names;
  }

  Future<Map<String, List<Component>>> getAllInventoriesComponents() async {
    final result = <String, List<Component>>{};
    final prefs = await SharedPreferences.getInstance();

    if (_mode == StorageMode.remote && _serverConnected && _api != null) {
      // Current inventory
      result[_currentInventoryId] = List<Component>.from(_components);
      // Buffer
      result['_buffer_'] = List<Component>.from(_bufferComponents);

      // Other inventories
      for (final inv in _inventories) {
        if (inv.id == _currentInventoryId) continue;
        try {
          final comps = await _api!.withInventory(inv.id).getComponents();
          result[inv.id] = comps;
          await prefs.setString('components_${inv.id}',
              jsonEncode(comps.map((c) => c.toJson()).toList()));
        } catch (_) {
          final cachedStr = prefs.getString('components_${inv.id}');
          if (cachedStr != null) {
            try {
              result[inv.id] = (jsonDecode(cachedStr) as List)
                  .map((e) => Component.fromJson(e))
                  .toList();
            } catch (_) {}
          }
        }
      }
    } else {
      // Local mode
      result['default'] = List<Component>.from(_components);
      result['_buffer_'] = List<Component>.from(_bufferComponents);
      for (final inv in _inventories) {
        if (inv.id == 'default') continue;
        final cachedStr = prefs.getString('components_${inv.id}');
        if (cachedStr != null) {
          try {
            result[inv.id] = (jsonDecode(cachedStr) as List)
                .map((e) => Component.fromJson(e))
                .toList();
          } catch (_) {}
        }
      }
    }

    return result;
  }

  // ── Shared Buffer Operations ───────────────────────────────────────────────
  Future<void> _loadBufferFromLocal(SharedPreferences prefs) async {
    final cj = prefs.getString(_bufferComponentsKey);
    _bufferComponents = cj != null
        ? (jsonDecode(cj) as List).map((e) => Component.fromJson(e)).toList()
        : [];
  }

  Future<void> _saveBufferLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bufferComponentsKey,
        jsonEncode(_bufferComponents.map((c) => c.toJson()).toList()));
  }

  Future<void> _loadBufferFromServer() async {
    if (_mode != StorageMode.remote || !_serverConnected || _api == null)
      return;
    try {
      final bufferApi = _api!.withInventory('_buffer_');
      final remoteDb = await bufferApi.getFullDb();
      _bufferComponents = (remoteDb['components'] as List)
          .map((e) => Component.fromJson(e))
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_bufferComponentsKey,
          jsonEncode(_bufferComponents.map((c) => c.toJson()).toList()));
    } catch (e) {
      debugPrint('Error loading buffer from server: $e');
      final prefs = await SharedPreferences.getInstance();
      await _loadBufferFromLocal(prefs);
    }
  }

  Future<void> _saveBufferServer() async {
    if (_mode != StorageMode.remote || !_serverConnected || _api == null)
      return;
    try {
      final bufferApi = _api!.withInventory('_buffer_');
      await bufferApi.uploadFullDb({
        'components': _bufferComponents.map((x) => x.toJson()).toList(),
        'settings': AppSettings().toJson(),
      });
    } catch (e) {
      debugPrint('Error saving buffer to server: $e');
      _lastError = e.toString();
    }
  }

  Future<void> addBufferComponent(Component c) async {
    _bufferComponents.add(c);
    if (_mode == StorageMode.remote && _serverConnected) {
      await _saveBufferServer();
    }
    await _saveBufferLocal();
    notifyListeners();
  }

  Future<void> updateBufferComponent(Component c) async {
    final idx = _bufferComponents.indexWhere((e) => e.id == c.id);
    if (idx != -1) {
      _bufferComponents[idx] = c;
      if (_mode == StorageMode.remote && _serverConnected) {
        await _saveBufferServer();
      }
      await _saveBufferLocal();
      notifyListeners();
    }
  }

  Future<void> deleteBufferComponent(String id) async {
    _bufferComponents.removeWhere((e) => e.id == id);
    if (_mode == StorageMode.remote && _serverConnected) {
      await _saveBufferServer();
    }
    await _saveBufferLocal();
    notifyListeners();
  }

  Future<void> updateBufferQuantity(String id, int delta) async {
    final idx = _bufferComponents.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _bufferComponents[idx] = _bufferComponents[idx].copyWith(
        quantity: (_bufferComponents[idx].quantity + delta).clamp(0, 99999),
      );
      if (_mode == StorageMode.remote && _serverConnected) {
        await _saveBufferServer();
      }
      await _saveBufferLocal();
      notifyListeners();
    }
  }

  Future<void> placeComponent(Component c, String targetInventoryId,
      int cabinet, String drawer, int? zone) async {
    _bufferComponents.removeWhere((e) => e.id == c.id);
    if (_mode == StorageMode.remote && _serverConnected) {
      await _saveBufferServer();
    }
    await _saveBufferLocal();

    final placedComponent = c.copyWith(
      cabinet: cabinet,
      drawer: drawer,
      drawerZone: zone,
      clearBagName: true,
      clearTargetInventoryId: true,
    );

    if (targetInventoryId == _currentInventoryId) {
      await addComponent(placedComponent);
    } else {
      if (_mode == StorageMode.remote && _serverConnected) {
        try {
          final targetApi = _api!.withInventory(targetInventoryId);
          await targetApi.createComponent(placedComponent);
        } catch (e) {
          _lastError = e.toString();
          await _placeLocalOnly(placedComponent, targetInventoryId);
        }
      } else {
        await _placeLocalOnly(placedComponent, targetInventoryId);
      }
    }
    notifyListeners();
  }

  Future<void> _placeLocalOnly(Component c, String targetInventoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final targetKey = 'components_$targetInventoryId';
    final cj = prefs.getString(targetKey);
    final List<Component> targetComps = cj != null
        ? (jsonDecode(cj) as List).map((e) => Component.fromJson(e)).toList()
        : [];
    targetComps.add(c);
    await prefs.setString(
        targetKey, jsonEncode(targetComps.map((x) => x.toJson()).toList()));
    await prefs.setString(
        'localTimestamp_$targetInventoryId', DateTime.now().toIso8601String());
  }

  Future<AppSettings> getSettingsForInventory(String inventoryId) async {
    if (_mode == StorageMode.remote && _serverConnected && _api != null) {
      try {
        final targetApi = _api!.withInventory(inventoryId);
        return await targetApi.getSettings();
      } catch (e) {
        debugPrint('Error getting settings for inventory $inventoryId: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final sj = prefs.getString('settings_$inventoryId');
    return sj != null ? AppSettings.fromJson(jsonDecode(sj)) : AppSettings();
  }
}
