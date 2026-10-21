import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/settings.dart';
import '../services/data_service.dart';
import '../services/update_service.dart';
import '../services/inventory_changes_service.dart';
import '../l10n/app_localizations.dart';
import 'inventory_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<ContainerConfig> _containers;
  late List<String> _tags;
  late Map<String, dynamic> _tagTree;
  late List<SpecialTag> _specialTags;
  int _selectedCabinetPreview = 1;
  late Map<String, int> _drawerDividers;
  final Set<String> _selectedPreviewDrawers = {};

  final _newTagCtrl = TextEditingController();
  final _newSpecialNameCtrl = TextEditingController();
  final _newSpecialUnitCtrl = TextEditingController();
  final _newSpecialShortIdCtrl = TextEditingController();
  final _serverUrlCtrl = TextEditingController();

  final _manualDrawerCtrl = TextEditingController();

  bool _testingServer = false;
  bool? _serverOk;
  bool _newSpecialIsString = false;

  final Set<String> _expandedPaths = {};
  AppSettings? _lastSettingsRef;

  @override
  void initState() {
    super.initState();
    _containers = [];
    _tags = [];
    _tagTree = {};
    _specialTags = [];
    _drawerDividers = {};
  }

  Map<String, dynamic> _deepCopyTree(Map<String, dynamic> source) {
    final result = <String, dynamic>{};
    source.forEach((k, v) {
      result[k] = _deepCopyTree(v as Map<String, dynamic>);
    });
    return result;
  }

  @override
  void dispose() {
    _newTagCtrl.dispose();
    _newSpecialNameCtrl.dispose();
    _newSpecialUnitCtrl.dispose();
    _newSpecialShortIdCtrl.dispose();
    _serverUrlCtrl.dispose();
    _manualDrawerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ds = context.read<DataService>();
    await ds.updateSettings(AppSettings(
      containers: _containers,
      availableTags: _tags,
      tagTree: _tagTree,
      specialTags: _specialTags,
      drawerDividers: _drawerDividers,
    ));
    _lastSettingsRef = ds.settings;

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.settingsSaved)));
    }
  }

  int _excelColumnToIndex(String colStr) {
    int index = 0;
    for (int i = 0; i < colStr.length; i++) {
      index = index * 26 + (colStr.codeUnitAt(i) - 65 + 1);
    }
    return index - 1;
  }

  bool _validateDrawerCoordinate(String input, int maxRows, int maxCols) {
    final clean = input.trim().toUpperCase();
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(clean);
    if (match == null) return false;

    final colStr = match.group(1)!;
    final rowVal = int.tryParse(match.group(2)!) ?? 0;

    if (rowVal < 1 || rowVal > maxRows) return false;

    final colIdx = _excelColumnToIndex(colStr);
    if (colIdx < 0 || colIdx >= maxCols) return false;

    return true;
  }

  Future<void> _showAddContainerDialog() async {
    final l10n = context.l10n;
    final nextId = _containers.isEmpty ? 1 : _containers.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
    final nameCtrl = TextEditingController(
        text: '${l10n.cabinetContainer} $nextId');
    final rowsCtrl = TextEditingController(text: '5');
    final colsCtrl = TextEditingController(text: '13');
    final formKey = GlobalKey<FormState>();
    bool invertRows = false;
    bool invertColumns = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, dialogState) => AlertDialog(
          title: Text(l10n.newContainer),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration:
                        InputDecoration(labelText: l10n.containerName),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.compNameError : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: rowsCtrl,
                          decoration: InputDecoration(labelText: l10n.rows),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final val = int.tryParse(v ?? '');
                            if (val == null || val <= 0)
                              return l10n.error;
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: colsCtrl,
                          decoration:
                              InputDecoration(labelText: l10n.columns),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final val = int.tryParse(v ?? '');
                            if (val == null || val <= 0)
                              return l10n.error;
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: Text(l10n.invertRows),
                    subtitle: const Text(
                        'Ordine numerico dal basso verso l\'alto (es. N...1)'),
                    value: invertRows,
                    onChanged: (val) =>
                        dialogState(() => invertRows = val ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(l10n.invertColumns),
                    subtitle: const Text(
                        'Ordine alfabetico da destra a sinistra (es. Z...A)'),
                    value: invertColumns,
                    onChanged: (val) =>
                        dialogState(() => invertColumns = val ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancelButton)),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: Text(l10n.addTag),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        final nextId = _containers.isEmpty
            ? 1
            : _containers.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
        _containers.add(ContainerConfig(
          id: nextId,
          name: nameCtrl.text.trim(),
          rows: int.parse(rowsCtrl.text),
          columns: int.parse(colsCtrl.text),
          disabledDrawers: [],
          invertRows: invertRows,
          invertColumns: invertColumns,
        ));
        _selectedCabinetPreview = nextId;
      });
    }
  }

  Future<void> _showEditContainerDialog(ContainerConfig container) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController(text: container.name);
    final rowsCtrl = TextEditingController(text: container.rows.toString());
    final colsCtrl = TextEditingController(text: container.columns.toString());
    final formKey = GlobalKey<FormState>();
    bool invertRows = container.invertRows;
    bool invertColumns = container.invertColumns;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, dialogState) => AlertDialog(
          title: Text('${l10n.editAction} ${l10n.cabinetContainer} N° ${container.id}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration:
                        InputDecoration(labelText: l10n.containerName),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.compNameError : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: rowsCtrl,
                          decoration: InputDecoration(labelText: l10n.rows),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final val = int.tryParse(v ?? '');
                            if (val == null || val <= 0)
                              return l10n.error;
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: colsCtrl,
                          decoration:
                              InputDecoration(labelText: l10n.columns),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final val = int.tryParse(v ?? '');
                            if (val == null || val <= 0)
                              return l10n.error;
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: Text(l10n.invertRows),
                    subtitle: const Text(
                        'Ordine numerico dal basso verso l\'alto (es. N...1)'),
                    value: invertRows,
                    onChanged: (val) =>
                        dialogState(() => invertRows = val ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: Text(l10n.invertColumns),
                    subtitle: const Text(
                        'Ordine alfabetico da destra a sinistra (es. Z...A)'),
                    value: invertColumns,
                    onChanged: (val) =>
                        dialogState(() => invertColumns = val ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancelButton)),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        container.name = nameCtrl.text.trim();
        container.rows = int.parse(rowsCtrl.text);
        container.columns = int.parse(colsCtrl.text);
        container.invertRows = invertRows;
        container.invertColumns = invertColumns;

        final updatedDisabled = <String>[];
        for (final d in container.disabledDrawers) {
          final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(d);
          if (match != null) {
            final colStr = match.group(1)!;
            final rowVal = int.tryParse(match.group(2)!) ?? 0;
            int colIdx = 0;
            for (int i = 0; i < colStr.length; i++) {
              colIdx = colIdx * 26 + (colStr.codeUnitAt(i) - 65 + 1);
            }
            colIdx -= 1;
            if (rowVal >= 1 &&
                rowVal <= container.rows &&
                colIdx >= 0 &&
                colIdx < container.columns) {
              updatedDisabled.add(d);
            }
          }
        }
        container.disabledDrawers = updatedDisabled;
      });
    }
  }

  Future<void> _confirmDeleteContainer(ContainerConfig container) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteContainer),
        content: Text(
            '${l10n.deleteContainer} "${container.name.isNotEmpty ? container.name : '${l10n.cabinetContainer} ${container.id}'}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelButton)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _containers.removeWhere((c) => c.id == container.id);
        if (_selectedCabinetPreview == container.id) {
          _selectedCabinetPreview =
              _containers.isNotEmpty ? _containers.first.id : 1;
        }
      });
    }
  }

  Future<void> _showBulkActionDialog() async {
    final l10n = context.l10n;
    if (_selectedPreviewDrawers.isEmpty) return;

    final count = _selectedPreviewDrawers.length;
    final containerIndex =
        _containers.indexWhere((c) => c.id == _selectedCabinetPreview);
    if (containerIndex == -1) return;
    final container = _containers[containerIndex];

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.bulkDrawerAction(count)),
        content: Text(l10n.bulkDrawerActionDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'enable'),
            child: Text(l10n.enableAll),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'disable'),
            child: Text(l10n.disableAll),
          ),
          if (count > 1)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'merge'),
              child: Text(l10n.mergeDrawers),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'unmerge'),
            child: Text(l10n.splitDrawers),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'zones'),
            child: Text(l10n.setZones),
          ),
        ],
      ),
    );

    if (action == null || action == 'cancel') {
      setState(() {
        _selectedPreviewDrawers.clear();
      });
      return;
    }

    if (action == 'enable') {
      setState(() {
        for (final label in _selectedPreviewDrawers) {
          container.disabledDrawers.remove(label);
        }
        _selectedPreviewDrawers.clear();
      });
    } else if (action == 'disable') {
      setState(() {
        for (final label in _selectedPreviewDrawers) {
          if (!container.disabledDrawers.contains(label)) {
            container.disabledDrawers.add(label);
          }
        }
        _selectedPreviewDrawers.clear();
      });
    } else if (action == 'merge') {
      setState(() {
        final selectedList = _selectedPreviewDrawers.toList();
        for (final m in List.from(container.mergedDrawers)) {
          m.removeWhere((label) => selectedList.contains(label));
        }
        container.mergedDrawers.removeWhere((m) => m.length < 2);
        container.mergedDrawers.add(selectedList);
        _selectedPreviewDrawers.clear();
      });
    } else if (action == 'unmerge') {
      setState(() {
        final selectedList = _selectedPreviewDrawers.toList();
        for (final m in List.from(container.mergedDrawers)) {
          m.removeWhere((label) => selectedList.contains(label));
        }
        container.mergedDrawers.removeWhere((m) => m.length < 2);
        _selectedPreviewDrawers.clear();
      });
    } else if (action == 'zones') {
      int selectedZones = 2;
      if (!mounted) return;
      final zonesResult = await showDialog<int>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx2, dialogState) => AlertDialog(
            title: Text('${l10n.setZones} ($count)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    l10n.bulkDrawerActionDesc),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedZones,
                  decoration: InputDecoration(
                    labelText: l10n.zoneLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: List.generate(11, (i) => i + 2) // 2 to 12
                      .map((z) => DropdownMenuItem(
                            value: z,
                            child: Text(l10n.zonesCount(z)),
                          ))
                      .toList(),
                  onChanged: (v) => dialogState(() => selectedZones = v ?? 2),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancelButton),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 1),
                child: Text(l10n.noDividers),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, selectedZones),
                child: Text(l10n.apply),
              ),
            ],
          ),
        ),
      );

      if (zonesResult != null) {
        setState(() {
          for (final label in _selectedPreviewDrawers) {
            final key = '${container.id}_$label';
            if (zonesResult == 1) {
              _drawerDividers.remove(key);
            } else {
              _drawerDividers[key] = zonesResult;
            }
          }
          _selectedPreviewDrawers.clear();
        });
      } else {
        setState(() {
          _selectedPreviewDrawers.clear();
        });
      }
    }
  }

  Future<void> _configureDrawer(String label) async {
    final l10n = context.l10n;
    final containerIndex =
        _containers.indexWhere((c) => c.id == _selectedCabinetPreview);
    if (containerIndex == -1) return;

    final container = _containers[containerIndex];
    final key = '${container.id}_$label';
    final currentZones = _drawerDividers[key] ?? 1;
    bool isCurrentlyDisabled = container.disabledDrawers.contains(label);

    bool dialogIsActive = !isCurrentlyDisabled;
    int dialogZones = currentZones >= 2 ? currentZones : 2;
    bool isDivided = currentZones >= 2;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, dialogState) => AlertDialog(
          title: Text(
              '${l10n.drawerLabel} $label (${container.name.isNotEmpty ? container.name : '${l10n.cabinetContainer} ${container.id}'})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(l10n.enabled),
                subtitle: Text(
                    l10n.drawerDisabled),
                value: dialogIsActive,
                onChanged: (val) => dialogState(() {
                  dialogIsActive = val;
                }),
                contentPadding: EdgeInsets.zero,
              ),
              if (dialogIsActive) ...[
                const Divider(),
                SwitchListTile(
                  title: Text(l10n.divideIntoZones),
                  subtitle: const Text(
                      'Suddivide in profondità (vicina, in mezzo, lontana)'),
                  value: isDivided,
                  onChanged: (val) => dialogState(() => isDivided = val),
                  contentPadding: EdgeInsets.zero,
                ),
                if (isDivided) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: dialogZones > 2
                            ? () => dialogState(() => dialogZones--)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(l10n.zonesCount(dialogZones),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: dialogZones < 10
                            ? () => dialogState(() => dialogZones++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'isActive': dialogIsActive,
                'isDivided': isDivided,
                'zones': dialogZones,
              }),
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (result['isActive'] == false) {
          if (!container.disabledDrawers.contains(label)) {
            container.disabledDrawers.add(label);
          }
          _drawerDividers.remove(key);
        } else {
          container.disabledDrawers.remove(label);
          if (result['isDivided'] == true) {
            _drawerDividers[key] = result['zones'] as int;
          } else {
            _drawerDividers.remove(key);
          }
        }
      });
    }
  }

  void _configureManualDrawer() {
    final l10n = context.l10n;
    final input = _manualDrawerCtrl.text.trim().toUpperCase();
    if (input.isEmpty) return;

    final container = _containers.firstWhere(
        (c) => c.id == _selectedCabinetPreview,
        orElse: () => _containers.first);
    if (!_validateDrawerCoordinate(input, container.rows, container.columns)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              l10n.invalidDrawerCoords),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    _configureDrawer(input);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_lastSettingsRef != ds.settings) {
      _lastSettingsRef = ds.settings;
      final s = ds.settings;

      _containers = s.containers
          .map((c) => ContainerConfig(
                id: c.id,
                name: c.name,
                rows: c.rows,
                columns: c.columns,
                disabledDrawers: List<String>.from(c.disabledDrawers),
                invertRows: c.invertRows,
                invertColumns: c.invertColumns,
                mergedDrawers: c.mergedDrawers
                    .map((list) => List<String>.from(list))
                    .toList(),
              ))
          .toList();

      _tags = List.from(s.availableTags);
      _tagTree = _deepCopyTree(s.tagTree);
      _specialTags = s.specialTags.map((t) => t.clone()).toList();
      _drawerDividers = Map.from(s.drawerDividers);

      _serverUrlCtrl.text = ds.serverUrl;
      _expandedPaths.clear();
    }

    final sortedTags = List<String>.from(_tags)..sort();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        actions: [TextButton(onPressed: _save, child: Text(l10n.saveSettings))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: l10n.sectionRemoteServer, icon: Icons.cloud_outlined),
          Card(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.useRemoteServer,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      ds.isRemote
                          ? ds.serverConnected
                              ? l10n.serverConnectedStatus
                              : l10n.serverDisconnectedStatus
                          : l10n.localStorageStatus,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ]),
                ),
                Switch(
                  value: ds.isRemote,
                  onChanged: (v) async {
                    await ds.setStorageMode(
                        v ? StorageMode.remote : StorageMode.local);
                    if (mounted && v && !ds.serverConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ds.lastError ?? l10n.connectionFailed),
                          backgroundColor: cs.error));
                    }
                  },
                ),
              ]),
              const Divider(height: 24),
              if (ds.isRemote &&
                  ds.serverConnected &&
                  ds.currentInventory != null)
                InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const InventoryListScreen())),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 18, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.activeInventory,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                          Text(ds.currentInventory!.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary)),
                        ],
                      )),
                      Icon(Icons.chevron_right, color: cs.primary, size: 18),
                    ]),
                  ),
                ),
              if (ds.isRemote &&
                  ds.serverConnected &&
                  ds.currentInventory != null)
                const Divider(height: 16),
              Text(l10n.serverUrl,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _serverUrlCtrl,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'https://192.168.1.2:8443',
                      isDense: true,
                      suffixIcon: _serverOk == null
                          ? null
                          : Icon(
                              _serverOk!
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: _serverOk! ? Colors.green : cs.error),
                    ),
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => _applyServer(),
                  ),
                ),
                const SizedBox(width: 8),
                _testingServer
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : FilledButton.tonal(
                        onPressed: _testServer, child: Text(l10n.check)),
              ]),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.trustSelfSignedCertificates),
                subtitle: Text(
                  l10n.trustSelfSignedCertificatesDesc,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                value: ds.trustSelfSigned,
                onChanged: (val) async {
                  await ds.setTrustSelfSigned(val);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                      onPressed: _applyServer,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l10n.save))),
              if (ds.isRemote) ...[
                const SizedBox(height: 8),
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ds.refreshFromServer();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ds.serverConnected
                                  ? l10n.syncSuccess
                                  : ds.lastError ?? l10n.error),
                              backgroundColor:
                                  ds.serverConnected ? null : cs.error));
                        }
                      },
                      icon: const Icon(Icons.sync),
                      label: Text(l10n.syncNow),
                    )),
              ],
            ]),
          )),
          const SizedBox(height: 24),
          _SectionHeader(title: l10n.sectionAppearance, icon: Icons.palette_outlined),
          Card(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(l10n.themeMode, style: theme.textTheme.bodyLarge),
                    ),
                    DropdownButton<ThemeMode>(
                      value: ds.themeMode,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Row(
                            children: [
                              const Icon(Icons.brightness_auto, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.themeSystem),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Row(
                            children: [
                              const Icon(Icons.light_mode, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.themeLight),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Row(
                            children: [
                              const Icon(Icons.dark_mode, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.themeDark),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ds.updateThemeMode(val);
                        }
                      },
                    ),
                  ],
                ),
                const Divider(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 460;
                    final languageDropdown = DropdownButton<String>(
                      value: ds.savedLanguageCode ?? 'system',
                      underline: const SizedBox.shrink(),
                      isExpanded: isNarrow,
                      items: [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text(l10n.languageSystem),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(l10n.langEn),
                        ),
                        DropdownMenuItem(
                          value: 'it',
                          child: Text(l10n.langIt),
                        ),
                        DropdownMenuItem(
                          value: 'es',
                          child: Text(l10n.langEs),
                        ),
                        DropdownMenuItem(
                          value: 'fr',
                          child: Text(l10n.langFr),
                        ),
                        DropdownMenuItem(
                          value: 'de',
                          child: Text(l10n.langDe),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ds.updateLanguage(val);
                        }
                      },
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.language, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(l10n.languageLabel,
                                    style: theme.textTheme.bodyLarge),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          languageDropdown,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.language, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(l10n.languageLabel,
                                    style: theme.textTheme.bodyLarge),
                              ),
                            ],
                          ),
                        ),
                        languageDropdown,
                      ],
                    );
                  },
                ),
              ],
            ),
          )),
          const SizedBox(height: 24),
          _SectionHeader(
              title: l10n.sectionContainers,
              icon: Icons.grid_view),
          Card(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  l10n.containersDesc,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              ..._containers.map((container) {
                return Card(
                  color: cs.surfaceContainerLow,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      child: Text('${container.id}'),
                    ),
                    title: Text(
                      container.name.isNotEmpty
                          ? container.name
                          : '${l10n.cabinetContainer} ${container.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${container.rows} ${l10n.rows.toLowerCase()} x ${container.columns} ${l10n.columns.toLowerCase()} · ${container.rows * container.columns - container.disabledDrawers.length} (${container.disabledDrawers.length})',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: l10n.editAction,
                          onPressed: () => _showEditContainerDialog(container),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: cs.error,
                          tooltip: l10n.deleteContainer,
                          onPressed: _containers.length > 1
                              ? () => _confirmDeleteContainer(container)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAddContainerDialog,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newContainer),
                ),
              ),
              const Divider(height: 32),
              if (_containers.isNotEmpty) ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 460;
                    final previewDropdown = DropdownButton<int>(
                      value: _containers
                              .any((c) => c.id == _selectedCabinetPreview)
                          ? _selectedCabinetPreview
                          : _containers.first.id,
                      underline: const SizedBox.shrink(),
                      isExpanded: isNarrow,
                      items: _containers.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name.isNotEmpty
                              ? c.name
                              : '${l10n.cabinetContainer} ${c.id}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCabinetPreview = val);
                        }
                      },
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.previewAndShape,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: previewDropdown,
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.previewAndShape,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        previewDropdown,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _DrawerGrid(
                  container: _containers.firstWhere(
                      (c) => c.id == _selectedCabinetPreview,
                      orElse: () => _containers.first),
                  drawerDividers: _drawerDividers,
                  selectedDrawers: _selectedPreviewDrawers,
                  onDrawerClick: (label) {
                    _configureDrawer(label);
                  },
                  onSelectStart: (label) {
                    setState(() {
                      _selectedPreviewDrawers.add(label);
                    });
                  },
                  onSelectUpdate: (label) {
                    setState(() {
                      _selectedPreviewDrawers.add(label);
                    });
                  },
                  onSelectEnd: () {
                    _showBulkActionDialog();
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  l10n.manualDrawerConfigTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualDrawerCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.manualDrawerCode,
                          hintText: l10n.manualDrawerHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _configureManualDrawer(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _configureManualDrawer,
                      child: Text(l10n.configureButton),
                    ),
                  ],
                ),
              ],
            ]),
          )),
          const SizedBox(height: 24),
          _SectionHeader(
              title: l10n.sectionTagTree, icon: Icons.account_tree_outlined),
          Card(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  l10n.tagTreeDesc,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildTreeLevel(_tagTree, []),
              ),
            ]),
          )),
          const SizedBox(height: 24),
          _SectionHeader(
              title: l10n.sectionGenericTags, icon: Icons.label_outline),
          Card(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _newTagCtrl,
                    decoration: InputDecoration(
                        labelText: l10n.newGenericTag,
                        border: const OutlineInputBorder(),
                        isDense: true),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addTag)),
              ]),
              const SizedBox(height: 16),
              if (_tags.isEmpty)
                Text(l10n.noGenericTags,
                    style: TextStyle(color: cs.onSurfaceVariant))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sortedTags
                      .map((tag) => Chip(
                            label: Text(tag),
                            onDeleted: () => _confirmDeleteTag(tag),
                            deleteIcon: const Icon(Icons.close, size: 16),
                          ))
                      .toList(),
                ),
            ]),
          )),
          const SizedBox(height: 24),
          _SectionHeader(title: l10n.sectionProperties, icon: Icons.tune),
          Card(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  l10n.propertiesDesc,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;

                Widget buildUnitField({bool expanded = false}) {
                  final field = TextField(
                    controller: _newSpecialUnitCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.propUnit,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addSpecialTag(),
                  );
                  return expanded
                      ? Expanded(flex: 3, child: field)
                      : SizedBox(width: 80, child: field);
                }

                Widget buildShortIdField({bool expanded = false}) {
                  final field = TextField(
                    controller: _newSpecialShortIdCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.propSigla,
                      hintText: l10n.propSiglaHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addSpecialTag(),
                  );
                  return expanded
                      ? Expanded(flex: 2, child: field)
                      : SizedBox(width: 70, child: field);
                }

                Widget buildTextChip() {
                  return FilterChip(
                    label: Text(l10n.propText),
                    selected: _newSpecialIsString,
                    onSelected: (v) => setState(() => _newSpecialIsString = v),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }

                Widget buildAddButton() {
                  return IconButton.filled(
                    onPressed: _addSpecialTag,
                    icon: const Icon(Icons.add),
                    tooltip: l10n.addProp,
                    visualDensity: VisualDensity.compact,
                  );
                }

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _newSpecialNameCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.propName,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addSpecialTag(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          buildUnitField(expanded: true),
                          const SizedBox(width: 8),
                          buildShortIdField(expanded: true),
                          const SizedBox(width: 8),
                          buildTextChip(),
                          const SizedBox(width: 8),
                          buildAddButton(),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newSpecialNameCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.propName,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addSpecialTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    buildUnitField(),
                    const SizedBox(width: 8),
                    buildShortIdField(),
                    const SizedBox(width: 8),
                    buildTextChip(),
                    const SizedBox(width: 8),
                    buildAddButton(),
                  ],
                );
              }),
              const SizedBox(height: 16),
              if (_specialTags.isEmpty)
                Text(l10n.noPropsConfigured,
                    style: TextStyle(color: cs.onSurfaceVariant))
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _specialTags.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _specialTags.removeAt(oldIndex);
                      _specialTags.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (ctx, i) {
                    final st = _specialTags[i];
                    return ListTile(
                      key: ValueKey(st.name),
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                          st.isString ? Icons.text_fields : Icons.numbers,
                          color: cs.primary),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(st.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (st.shortId.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                st.shortId,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text((st.unit.isNotEmpty
                              ? '${l10n.propUnit}: ${st.unit}'
                              : l10n.notAssigned) +
                          (st.isString ? ' • ${l10n.propText}' : '') +
                          (st.shortId.isNotEmpty ? ' • ${l10n.propSigla}: ${st.shortId}' : '')),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: l10n.editAction,
                            onPressed: () => _editSpecialTag(st)),
                        IconButton(
                            icon: Icon(Icons.delete_outline, color: cs.error),
                            tooltip: l10n.deleteButton,
                            onPressed: () => _confirmDeleteSpecialTag(st.name)),
                        ReorderableDragStartListener(
                            index: i,
                            child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Icon(Icons.drag_handle))),
                      ]),
                    );
                  },
                ),
            ]),
          )),
          const SizedBox(height: 24),
          _SectionHeader(title: l10n.sectionData, icon: Icons.storage_outlined),
          Card(
              child: Column(children: [
            ListTile(
                leading: Icon(Icons.upload_file, color: cs.primary),
                title: Text(l10n.exportJson),
                onTap: () async => await ds.exportData()),
            const Divider(height: 1),
            ListTile(
                leading: Icon(Icons.download_outlined, color: cs.primary),
                title: Text(l10n.importJson),
                onTap: () => _importData(ds)),
            // --- NUOVO BOTTONE PER I BACKUP REMOTI ---
            if (ds.isRemote && ds.serverConnected) ...[
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.restore, color: cs.primary),
                title: Text(l10n.restoreRemoteBackup),
                onTap: () => _showRestoreDialog(context, ds),
              ),
            ],
          ])),
          const SizedBox(height: 24),
          _SectionHeader(
              title: l10n.sectionAbout, icon: Icons.info_outline),
          Card(
              child: Column(children: [
            ListTile(
              leading: Icon(Icons.system_update_alt, color: cs.primary),
              title: Text(l10n.checkUpdates),
              subtitle:
                  Text(l10n.checkUpdatesSubtitle),
              onTap: () => UpdateService.checkAndPromptUpdate(context,
                  showNoUpdateFeedback: true),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.open_in_browser, color: cs.primary),
              title: Text(l10n.openGitHub),
              subtitle: const Text('https://github.com/Kikkiu17/InventoryApp'),
              onTap: () async {
                final uri = Uri.parse(UpdateService.releasesHtmlUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.published_with_changes, color: cs.primary),
              title: Text(l10n.whatsNewViewRecentChanges),
              subtitle: Text(l10n.whatsNewSubtitle),
              onTap: () =>
                  InventoryChangesService.showRecentChanges(context, ds),
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary:
                  Icon(Icons.notifications_active_outlined, color: cs.primary),
              title: Text(l10n.whatsNewSettingTitle),
              subtitle: Text(l10n.whatsNewSettingSubtitle),
              value: !InventoryChangesService.isPopupDisabled,
              onChanged: (val) async {
                await InventoryChangesService.setDontShowPopup(!val);
                setState(() {});
              },
            ),
          ])),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTreeLevel(Map<String, dynamic> node, List<String> path) {
    final l10n = context.l10n;
    final keys = node.keys.toList()..sort();
    final pathKey = path.join('|');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...keys.map((k) {
          final currentPath = [...path, k];
          final currentPathKey = currentPath.join('|');
          final children = node[k] as Map<String, dynamic>;

          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _expandedPaths.contains(currentPathKey),
              onExpansionChanged: (exp) {
                setState(() {
                  if (exp)
                    _expandedPaths.add(currentPathKey);
                  else
                    _expandedPaths.remove(currentPathKey);
                });
              },
              title:
                  Text(k, style: const TextStyle(fontWeight: FontWeight.bold)),
              dense: true,
              trailing: IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error),
                  tooltip: l10n.deleteAction,
                  onPressed: () => _confirmDeleteNode(currentPath)),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border(
                            left: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant))),
                    child: _buildTreeLevel(children, currentPath),
                  ),
                )
              ],
            ),
          );
        }),
        Padding(
          padding: EdgeInsets.only(
              left: path.isEmpty ? 16.0 : 16.0,
              top: 4.0,
              bottom: 12.0,
              right: 16.0),
          child: TextField(
            key: ValueKey('${pathKey}_${keys.length}'),
            decoration: InputDecoration(
              hintText: path.isEmpty
                  ? l10n.addMainTag
                  : l10n.addSubTag(path.last),
              isDense: true,
              border: const UnderlineInputBorder(),
              suffixIcon: const Icon(Icons.keyboard_return, size: 16),
            ),
            onSubmitted: (val) {
              final v = val.trim();
              if (v.isNotEmpty) {
                setState(() {
                  Map<String, dynamic> current = _tagTree;
                  for (String p in path) {
                    current = current[p];
                  }
                  if (!current.containsKey(v)) {
                    current[v] = <String, dynamic>{};
                  }
                  final newPathKey = [...path, v].join('|');
                  _expandedPaths.add(newPathKey);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteNode(List<String> path) async {
    final l10n = context.l10n;
    final res = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.deleteButton),
        content: Text(l10n.deleteTagConfirm(path.last)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l10n.cancelButton)),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l10n.deleteButton)),
        ],
      ),
    );

    if (res == true) {
      setState(() {
        if (path.length == 1) {
          _tagTree.remove(path.last);
        } else {
          Map<String, dynamic> current = _tagTree;
          for (int i = 0; i < path.length - 1; i++) {
            current = current[path[i]];
          }
          current.remove(path.last);
        }
      });
    }
  }

  Future<void> _testServer() async {
    final l10n = context.l10n;
    final ds = context.read<DataService>();
    setState(() {
      _testingServer = true;
      _serverOk = null;
    });
    final client = ApiClient(
      _serverUrlCtrl.text.trim(),
      allowSelfSigned: ds.trustSelfSigned,
    );
    final ok = await client.ping();
    client.close();
    setState(() {
      _testingServer = false;
      _serverOk = ok;
    });
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? '${l10n.connectionSuccess} ✅' : '${l10n.connectionFailed} ❌')));
  }

  Future<void> _applyServer() async {
    final url = _serverUrlCtrl.text.trim();
    if (url.isEmpty) return;
    final ds = context.read<DataService>();
    final ok = await ds.setServerUrl(url);
    setState(() {
      _serverOk = ok;
      _serverUrlCtrl.text = ds.serverUrl;
    });
  }

  void _addTag() {
    final tag = _newTagCtrl.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() => _tags.add(tag));
    _newTagCtrl.clear();
  }

  void _addSpecialTag() {
    final name = _newSpecialNameCtrl.text.trim();
    if (name.isEmpty || _specialTags.any((t) => t.name == name)) return;
    setState(() {
      _specialTags.add(SpecialTag(
          name: name,
          unit: _newSpecialUnitCtrl.text.trim(),
          isString: _newSpecialIsString,
          shortId: _newSpecialShortIdCtrl.text.trim()));
      _newSpecialIsString = false;
    });
    _newSpecialNameCtrl.clear();
    _newSpecialUnitCtrl.clear();
    _newSpecialShortIdCtrl.clear();
  }

  Future<void> _editSpecialTag(SpecialTag st) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController(text: st.name);
    final unitCtrl = TextEditingController(text: st.unit);
    final shortIdCtrl = TextEditingController(text: st.shortId);
    bool isString = st.isString;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.editPropTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.propName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: unitCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.propUnit,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: shortIdCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.propSigla,
                          hintText: l10n.propSiglaHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.propTextFree),
                      selected: isString,
                      onSelected: (v) => setDialogState(() => isString = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () {
                final newName = nameCtrl.text.trim();
                if (newName.isEmpty) return;
                if (newName != st.name &&
                    _specialTags.any((t) => t.name == newName)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Esiste già una proprietà con questo nome')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );

    if (updated == true) {
      setState(() {
        st.name = nameCtrl.text.trim();
        st.unit = unitCtrl.text.trim();
        st.shortId = shortIdCtrl.text.trim();
        st.isString = isString;
      });
    }
  }

  Future<void> _confirmDeleteTag(String tag) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteButton),
        content: Text(l10n.deleteTagConfirm(tag)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelButton)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.deleteButton))
        ],
      ),
    );
    if (confirm == true) setState(() => _tags.remove(tag));
  }

  Future<void> _confirmDeleteSpecialTag(String name) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteButton),
        content: Text(l10n.deletePropConfirm(name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelButton)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.deleteButton))
        ],
      ),
    );
    if (confirm == true)
      setState(() => _specialTags.removeWhere((t) => t.name == name));
  }

  Future<void> _importData(DataService ds) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importJson),
        content: Text(l10n.confirmRestoreMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelButton)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.importJson))
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await ds.importData();
    if (ok) {
      _lastSettingsRef = ds.settings;
      setState(() {
        _containers = ds.settings.containers
            .map((c) => ContainerConfig(
                  id: c.id,
                  name: c.name,
                  rows: c.rows,
                  columns: c.columns,
                  disabledDrawers: List<String>.from(c.disabledDrawers),
                  invertRows: c.invertRows,
                  invertColumns: c.invertColumns,
                  mergedDrawers: c.mergedDrawers
                      .map((list) => List<String>.from(list))
                      .toList(),
                ))
            .toList();
        _tags = List.from(ds.settings.availableTags);
        _tagTree = _deepCopyTree(ds.settings.tagTree);
        _specialTags =
            ds.settings.specialTags.map((t) => t.clone()).toList();
        _drawerDividers = Map.from(ds.settings.drawerDividers);
      });
    }
  }

  Future<void> _showRestoreDialog(BuildContext context, DataService ds) async {
    final l10n = context.l10n;
    final backups = await ds.getBackups();
    if (!context.mounted) return;
    if (backups.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.noBackupsFound)));
      return;
    }

    final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(l10n.restoreBackupTitle),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: backups
                        .map((backup) => ListTile(
                              title: Text(_formatBackupName(backup)),
                              leading: const Icon(Icons.history),
                              onTap: () => Navigator.pop(ctx, backup),
                            ))
                        .toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.cancelButton))
              ],
            ));

    if (choice != null && context.mounted) {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: Text(l10n.confirmRestoreTitle),
                  content: Text(
                      l10n.confirmRestoreMsg),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancelButton)),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.restoreBackupTitle))
                  ]));

      if (confirm == true) {
        final ok = await ds.restoreBackup(choice);
        if (ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.restoreSuccess)));
        }
      }
    }
  }

  String _formatBackupName(String filename) {
    try {
      final parts = filename.replaceAll('.json', '').split('_');
      if (parts.length >= 3) {
        final d = parts[parts.length - 2]; // YYYYMMDD
        final t = parts[parts.length - 1]; // HHMMSS
        if (d.length == 8 && t.length == 6) {
          return '${d.substring(6, 8)}/${d.substring(4, 6)}/${d.substring(0, 4)} alle ${t.substring(0, 2)}:${t.substring(2, 4)}:${t.substring(4, 6)}';
        }
      }
    } catch (_) {}
    return filename; // Fallback se il nome non corrisponde al formato
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

class _DrawerGrid extends StatelessWidget {
  final ContainerConfig container;
  final Map<String, int> drawerDividers;
  final void Function(String label) onDrawerClick;
  final Set<String> selectedDrawers;
  final void Function(String label) onSelectStart;
  final void Function(String label) onSelectUpdate;
  final VoidCallback onSelectEnd;

  const _DrawerGrid({
    required this.container,
    required this.drawerDividers,
    required this.onDrawerClick,
    required this.selectedDrawers,
    required this.onSelectStart,
    required this.onSelectUpdate,
    required this.onSelectEnd,
  });

  Map<String, int> _parseLabelCoords(String label) {
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(label);
    if (match == null) return {'col': 0, 'row': 0};
    final colStr = match.group(1)!;
    final rowVal = int.tryParse(match.group(2)!) ?? 1;

    int colIdx = 0;
    for (int i = 0; i < colStr.length; i++) {
      colIdx = colIdx * 26 + (colStr.codeUnitAt(i) - 65 + 1);
    }
    colIdx -= 1;
    return {'col': colIdx, 'row': rowVal - 1};
  }

  String? _getLabelFromOffset(Offset offset) {
    final x = offset.dx - 8;
    final y = offset.dy - 8;

    final colIdx = (x / 54).floor().clamp(0, container.columns - 1);
    final rowIdx = (y / 38).floor().clamp(0, container.rows - 1);

    final displayRow =
        container.invertRows ? (container.rows - 1 - rowIdx) : rowIdx;
    final displayCol =
        container.invertColumns ? (container.columns - 1 - colIdx) : colIdx;

    if (displayCol >= 0 &&
        displayCol < container.columnLabels.length &&
        displayRow >= 0 &&
        displayRow < container.rows) {
      return '${container.columnLabels[displayCol]}${displayRow + 1}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final rows = container.rows;
    final cols = container.columns;

    // Create merge lookup
    final Map<String, List<String>> mergeGroups = {};
    for (final group in container.mergedDrawers) {
      for (final label in group) {
        mergeGroups[label] = group;
      }
    }

    final List<Widget> positionedCells = [];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final label = '${container.columnLabels[c]}${r + 1}';
        final group = mergeGroups[label];

        int minCol = c;
        int minRow = r;
        int minDCol = container.invertColumns ? (cols - 1 - c) : c;
        int maxDCol = minDCol;
        int minDRow = container.invertRows ? (rows - 1 - r) : r;
        int maxDRow = minDRow;

        if (group != null) {
          // Parse all coordinates in the group
          final coordsList = group.map((lbl) {
            final coords = _parseLabelCoords(lbl);
            final col = coords['col']!;
            final row = coords['row']!;
            final dCol = container.invertColumns ? (cols - 1 - col) : col;
            final dRow = container.invertRows ? (rows - 1 - row) : row;
            return {
              'col': col,
              'row': row,
              'dCol': dCol,
              'dRow': dRow,
            };
          }).toList();

          minCol =
              coordsList.map((e) => e['col']!).reduce((a, b) => a < b ? a : b);
          minRow =
              coordsList.map((e) => e['row']!).reduce((a, b) => a < b ? a : b);

          minDCol =
              coordsList.map((e) => e['dCol']!).reduce((a, b) => a < b ? a : b);
          maxDCol =
              coordsList.map((e) => e['dCol']!).reduce((a, b) => a > b ? a : b);
          minDRow =
              coordsList.map((e) => e['dRow']!).reduce((a, b) => a < b ? a : b);
          maxDRow =
              coordsList.map((e) => e['dRow']!).reduce((a, b) => a > b ? a : b);

          // Skip if this is not the top-left cell of the group in logical coordinates
          if (c != minCol || r != minRow) {
            continue;
          }
        }

        final cellLabel = group != null ? group.join('+') : label;
        final key =
            '${container.id}_$label'; // Dividers are saved by primary label
        final zones = drawerDividers[key] ?? 1;
        final isDisabled = container.disabledDrawers.contains(label);
        final isSelected = selectedDrawers.contains(label) ||
            (group != null && group.any((l) => selectedDrawers.contains(l)));

        Widget cellWidget = isDisabled
            ? Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  cellLabel,
                  style: TextStyle(
                    fontSize: group != null ? 8 : 9,
                    color: cs.onSurfaceVariant.withOpacity(0.3),
                    decoration: TextDecoration.lineThrough,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : (zones < 2
                ? Container(
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cellLabel,
                      style: TextStyle(
                        fontSize: group != null ? 8 : 10,
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        children: List.generate(
                          zones,
                          (i) => Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: i == 0
                                    ? const BorderRadius.vertical(
                                        top: Radius.circular(4))
                                    : i == zones - 1
                                        ? const BorderRadius.vertical(
                                            bottom: Radius.circular(4))
                                        : null,
                                border: i < zones - 1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: cs.primary.withOpacity(0.4),
                                          width: 1,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            cellLabel,
                            style: TextStyle(
                              fontSize: group != null ? 8 : 9,
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ));

        if (isSelected) {
          cellWidget = Stack(
            children: [
              cellWidget,
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.primary, width: 2.5),
                    borderRadius: BorderRadius.circular(4),
                    color: cs.primary.withOpacity(0.15),
                  ),
                ),
              ),
            ],
          );
        }

        final double left = minDCol * 54.0 + 3.0;
        final double top = minDRow * 38.0 + 3.0;
        final double width = (maxDCol - minDCol + 1) * 54.0 - 6.0;
        final double height = (maxDRow - minDRow + 1) * 38.0 - 6.0;

        positionedCells.add(Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: InkWell(
            onTap: () => onDrawerClick(label),
            borderRadius: BorderRadius.circular(4),
            child: cellWidget,
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            l10n.drawerGridHint,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          height: (rows * 38 + 16)
              .toDouble()
              .clamp(100.0, 320.0), // Limite altezza a 320px scrollabile
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPressStart: (details) {
                  final label = _getLabelFromOffset(details.localPosition);
                  if (label != null) {
                    final group = mergeGroups[label];
                    if (group != null) {
                      for (final lbl in group) {
                        onSelectStart(lbl);
                      }
                    } else {
                      onSelectStart(label);
                    }
                  }
                },
                onLongPressMoveUpdate: (details) {
                  final label = _getLabelFromOffset(details.localPosition);
                  if (label != null) {
                    final group = mergeGroups[label];
                    if (group != null) {
                      for (final lbl in group) {
                        onSelectUpdate(lbl);
                      }
                    } else {
                      onSelectUpdate(label);
                    }
                  }
                },
                onLongPressEnd: (details) {
                  onSelectEnd();
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: cols * 54.0,
                    height: rows * 38.0,
                    child: Stack(
                      children: positionedCells,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
