import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/component.dart';
import '../models/settings.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Metadati di un inventario sul server
class InventoryMeta {
  final String id;
  String name;
  String description;
  final String createdAt;

  InventoryMeta({
    required this.id,
    required this.name,
    this.description = '',
    this.createdAt = '',
  });

  factory InventoryMeta.fromJson(Map<String, dynamic> j) => InventoryMeta(
        id:          j['id']          as String,
        name:        j['name']        as String? ?? j['id'],
        description: j['description'] as String? ?? '',
        createdAt:   j['createdAt']   as String? ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'description': description};
}

class ApiClient {
  final String baseUrl;       // es: "http://192.168.1.2:8080"
  final String inventoryId;   // ID inventario attivo

  // Set after every write; callers use this to store the exact server
  // timestamp locally, preventing false sync-conflict dialogs on relaunch.
  String? lastUpdated;

  ApiClient(this.baseUrl, {this.inventoryId = 'default'});

  /// Crea un clone con un inventario diverso
  ApiClient withInventory(String id) => ApiClient(baseUrl, inventoryId: id);

  static const _timeout = Duration(seconds: 8);

  Uri _root(String path) => Uri.parse('$baseUrl$path');
  Uri _inv(String path)  => Uri.parse('$baseUrl/api/inventories/$inventoryId$path');

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<void> _check(http.Response res) async {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = 'Errore ${res.statusCode}';
      try { msg = (jsonDecode(res.body)['error'] as String?) ?? msg; } catch (_) {}
      throw ApiException(res.statusCode, msg);
    }
    // Capture the server timestamp echoed back from every write endpoint.
    lastUpdated = res.headers['x-last-updated'];
  }

  // ── Ping ────────────────────────────────────────────────────────────────────
  Future<bool> ping() async {
    try {
      final res = await http.get(_root('/api/status')).timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  // ── Inventari ────────────────────────────────────────────────────────────────
  Future<List<InventoryMeta>> listInventories() async {
    final res = await http.get(_root('/api/inventories')).timeout(_timeout);
    await _check(res);
    return (jsonDecode(res.body) as List)
        .map((e) => InventoryMeta.fromJson(e)).toList();
  }

  Future<InventoryMeta> createInventory(String name, {String description = ''}) async {
    final res = await http.post(
      _root('/api/inventories'),
      headers: _headers,
      body: jsonEncode({'name': name, 'description': description}),
    ).timeout(_timeout);
    await _check(res);
    return InventoryMeta.fromJson(jsonDecode(res.body));
  }

  Future<InventoryMeta> renameInventory(String id, String name, {String description = ''}) async {
    final res = await http.put(
      _root('/api/inventories/$id'),
      headers: _headers,
      body: jsonEncode({'name': name, 'description': description}),
    ).timeout(_timeout);
    await _check(res);
    return InventoryMeta.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteInventory(String id) async {
    final res = await http.delete(_root('/api/inventories/$id')).timeout(_timeout);
    await _check(res);
  }

  // ── Components ───────────────────────────────────────────────────────────────
  Future<List<Component>> getComponents() async {
    final res = await http.get(_inv('/components')).timeout(_timeout);
    await _check(res);
    return (jsonDecode(res.body) as List).map((e) => Component.fromJson(e)).toList();
  }

  Future<Component> createComponent(Component c) async {
    final res = await http.post(_inv('/components'),
        headers: _headers, body: jsonEncode(c.toJson())).timeout(_timeout);
    await _check(res);
    return Component.fromJson(jsonDecode(res.body));
  }

  Future<Component> updateComponent(Component c) async {
    final res = await http.put(_inv('/components/${c.id}'),
        headers: _headers, body: jsonEncode(c.toJson())).timeout(_timeout);
    await _check(res);
    return Component.fromJson(jsonDecode(res.body));
  }

  Future<Component> patchQuantity(String id, int delta) async {
    final res = await http.patch(_inv('/components/$id/quantity'),
        headers: _headers, body: jsonEncode({'delta': delta})).timeout(_timeout);
    await _check(res);
    return Component.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteComponent(String id) async {
    final res = await http.delete(_inv('/components/$id')).timeout(_timeout);
    await _check(res);
  }

  // ── Settings ─────────────────────────────────────────────────────────────────
  Future<AppSettings> getSettings() async {
    final res = await http.get(_inv('/settings')).timeout(_timeout);
    await _check(res);
    return AppSettings.fromJson(jsonDecode(res.body));
  }

  Future<AppSettings> updateSettings(AppSettings s) async {
    final res = await http.put(_inv('/settings'),
        headers: _headers, body: jsonEncode(s.toJson())).timeout(_timeout);
    await _check(res);
    return AppSettings.fromJson(jsonDecode(res.body));
  }

  // ── Full DB ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getFullDb() async {
    final res = await http.get(_inv('/db')).timeout(_timeout);
    await _check(res);
    return jsonDecode(res.body);
  }

  Future<void> uploadFullDb(Map<String, dynamic> db) async {
    final res = await http.post(_inv('/db'),
        headers: _headers, body: jsonEncode(db)).timeout(_timeout);
    await _check(res);
  }

  // ── Backups ──────────────────────────────────────────────────────────────────
  Future<List<String>> getBackups() async {
    final res = await http.get(_inv('/backups')).timeout(_timeout);
    await _check(res);
    return List<String>.from(jsonDecode(res.body));
  }

  Future<void> restoreBackup(String filename) async {
    final res = await http.post(_inv('/backups/$filename/restore'), headers: _headers).timeout(_timeout);
    await _check(res);
  }

  Future<void> createBackup() async {
    final res = await http.post(_inv('/backup'), headers: _headers).timeout(_timeout);
    await _check(res);
  }
}