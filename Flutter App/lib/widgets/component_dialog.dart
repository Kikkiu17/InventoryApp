import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/component.dart';
import '../models/settings.dart';
import '../services/data_service.dart';
import 'image_viewer.dart';
import 'drawer_picker_dialog.dart';

const double _opacityPrimary = 0.4;
const double _opacityNeutral = 0.6;
const double _opacityGreen = 0.2;
const double _opacityTertiary = 0.4;

class ComponentDialog extends StatefulWidget {
  final Component? existing;
  final AppSettings settings;
  final bool isDuplicate;
  final String? bagName;
  final bool isBuffer;
  final int? prefilledCabinet;
  final String? prefilledDrawer;
  final int? prefilledDrawerZone;
  final Map<String, dynamic>? draft;

  const ComponentDialog({
    super.key,
    this.existing,
    required this.settings,
    this.isDuplicate = false,
    this.bagName,
    this.isBuffer = false,
    this.prefilledCabinet,
    this.prefilledDrawer,
    this.prefilledDrawerZone,
    this.draft,
  });

  @override
  State<ComponentDialog> createState() => _ComponentDialogState();
}

class _ComponentDialogState extends State<ComponentDialog> {
  bool get _isInBag =>
      widget.isBuffer ||
      widget.bagName != null ||
      (widget.existing?.bagName != null && !widget.isDuplicate);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _colCtrl;
  late TextEditingController _rowCtrl;
  late TextEditingController _noteCtrl;

  String? _selectedTargetInventoryId;
  AppSettings? _targetSettings;
  bool _isLoadingSettings = false;

  int _selectedCabinet = 1;

  List<String> _selectedTags = [];
  List<String> _treePath = [];
  bool _showLooseTags = false;

  Map<String, TextEditingController> _specialTagCtrls = {};

  List<Attachment> _attachments = [];
  List<String> _images = [];
  bool _isSaving = false;
  int? _selectedZone;
  String _positionInputMode = 'text';

  @override
  void initState() {
    super.initState();
    final dMap = widget.draft;
    final e = widget.existing;

    if (dMap != null) {
      _nameCtrl = TextEditingController(text: dMap['name'] ?? '');
      _descCtrl = TextEditingController(text: dMap['description'] ?? '');
      _qtyCtrl = TextEditingController(text: dMap['quantity'] ?? '0');
      _colCtrl = TextEditingController(text: dMap['col'] ?? '');
      _rowCtrl = TextEditingController(text: dMap['row'] ?? '');
      _noteCtrl = TextEditingController(text: dMap['note'] ?? '');
      _selectedCabinet = dMap['selectedCabinet'] ?? 1;
      _selectedZone = dMap['selectedZone'];
      _selectedTags = List<String>.from(dMap['selectedTags'] ?? []);
      _images = List<String>.from(dMap['images'] ?? []);

      final atts = dMap['attachments'] as List<dynamic>? ?? [];
      _attachments = atts
          .map((a) => Attachment(
                name: a['name'] ?? '',
                path: a['path'] ?? '',
                isLink: a['isLink'] ?? false,
              ))
          .toList();
    } else {
      _nameCtrl = TextEditingController(text: e?.name ?? '');
      _descCtrl = TextEditingController(text: e?.description ?? '');
      _qtyCtrl = TextEditingController(text: (e?.quantity ?? 0).toString());
      _colCtrl = TextEditingController();
      _rowCtrl = TextEditingController();
      _noteCtrl = TextEditingController(text: e?.note ?? '');

      _selectedCabinet = e?.cabinet ?? widget.prefilledCabinet ?? 1;
      _selectedZone = e?.drawerZone ?? widget.prefilledDrawerZone;

      final d = e?.drawer ?? widget.prefilledDrawer ?? '';
      if (d.isNotEmpty) {
        final match = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(d);
        if (match != null) {
          _colCtrl.text = match.group(1) ?? '';
          _rowCtrl.text = match.group(2) ?? '';
        } else {
          _colCtrl.text = d;
        }
      }
      _selectedTags = List.from(e?.tags ?? []);
      _attachments = List.from(e?.attachments ?? []);
      _images = List.from(e?.images ?? []);
    }

    final ds = Provider.of<DataService>(context, listen: false);

    if (widget.isBuffer) {
      _selectedTargetInventoryId = dMap != null
          ? dMap['selectedTargetInventoryId']
          : e?.targetInventoryId;
      if (_selectedTargetInventoryId != null) {
        _isLoadingSettings = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final tSettings =
              await ds.getSettingsForInventory(_selectedTargetInventoryId!);
          if (mounted) {
            setState(() {
              _targetSettings = tSettings;
              _isLoadingSettings = false;

              _specialTagCtrls.clear();
              for (final st in tSettings.specialTags) {
                final Map? specialVals =
                    dMap != null ? dMap['specialTagValues'] as Map? : null;
                final val = specialVals != null
                    ? specialVals[st.name]
                    : e?.specialTagValues[st.name];
                _specialTagCtrls[st.name] = TextEditingController(
                  text: val ?? '',
                );
              }

              _treePath.clear();
              Map<String, dynamic> currentTree = tSettings.tagTree;
              while (true) {
                bool found = false;
                for (final key in currentTree.keys) {
                  if (_selectedTags.contains(key)) {
                    _treePath.add(key);
                    currentTree = currentTree[key] as Map<String, dynamic>;
                    found = true;
                    break;
                  }
                }
                if (!found) break;
              }
            });
          }
        });
      }
    } else {
      final settings = ds.settings;
      Map<String, dynamic> currentTree = settings.tagTree;
      while (true) {
        bool found = false;
        for (final key in currentTree.keys) {
          if (_selectedTags.contains(key)) {
            _treePath.add(key);
            currentTree = currentTree[key] as Map<String, dynamic>;
            found = true;
            break;
          }
        }
        if (!found) break;
      }

      for (final st in settings.specialTags) {
        final Map? specialVals =
            dMap != null ? dMap['specialTagValues'] as Map? : null;
        final val = specialVals != null
            ? specialVals[st.name]
            : e?.specialTagValues[st.name];
        _specialTagCtrls[st.name] = TextEditingController(
          text: val ?? '',
        );
      }
    }

    _colCtrl.addListener(_onDrawerCoordinatesChanged);
    _rowCtrl.addListener(_onDrawerCoordinatesChanged);
  }

  Future<void> _onTargetInventoryChanged(String? newId) async {
    if (newId == _selectedTargetInventoryId) return;

    setState(() {
      _selectedTargetInventoryId = newId;
      _targetSettings = null;
      _selectedTags.clear();
      _treePath.clear();
      for (final c in _specialTagCtrls.values) {
        c.dispose();
      }
      _specialTagCtrls.clear();
    });

    if (newId == null) return;

    setState(() => _isLoadingSettings = true);
    final ds = Provider.of<DataService>(context, listen: false);
    final tSettings = await ds.getSettingsForInventory(newId);

    if (mounted && _selectedTargetInventoryId == newId) {
      setState(() {
        _targetSettings = tSettings;
        _isLoadingSettings = false;
        for (final st in tSettings.specialTags) {
          _specialTagCtrls[st.name] = TextEditingController();
        }
      });
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = {
      'name': _nameCtrl.text,
      'description': _descCtrl.text,
      'quantity': _qtyCtrl.text,
      'selectedCabinet': _selectedCabinet,
      'col': _colCtrl.text,
      'row': _rowCtrl.text,
      'selectedZone': _selectedZone,
      'selectedTags': _selectedTags,
      'specialTagValues': {
        for (final entry in _specialTagCtrls.entries)
          entry.key: entry.value.text
      },
      'attachments': _attachments
          .map((a) => {
                'name': a.name,
                'path': a.path,
                'isLink': a.isLink,
              })
          .toList(),
      'images': _images,
      'isDuplicate': widget.isDuplicate,
      'isBuffer': widget.isBuffer,
      'existingId': widget.existing?.id,
      'bagName': widget.bagName,
      'prefilledCabinet': widget.prefilledCabinet,
      'prefilledDrawer': widget.prefilledDrawer,
      'prefilledDrawerZone': widget.prefilledDrawerZone,
      'note': _noteCtrl.text,
    };
    await prefs.setString('pending_component_draft', jsonEncode(draft));
  }

  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_component_draft');
  }

  void _onDrawerCoordinatesChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _colCtrl.removeListener(_onDrawerCoordinatesChanged);
    _rowCtrl.removeListener(_onDrawerCoordinatesChanged);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _colCtrl.dispose();
    _rowCtrl.dispose();
    _noteCtrl.dispose();
    for (final c in _specialTagCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  dynamic _findSubtree(String tag, Map<String, dynamic> current) {
    if (current.containsKey(tag)) return current[tag];
    for (final v in current.values) {
      if (v is Map<String, dynamic>) {
        final res = _findSubtree(tag, v);
        if (res != null) return res;
      }
    }
    return null;
  }

  void _removeNodeAndDescendants(
      String node, dynamic subtree, List<String> list) {
    list.remove(node);
    if (subtree is Map<String, dynamic>) {
      for (final k in subtree.keys) {
        _removeNodeAndDescendants(k, subtree[k], list);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = Provider.of<DataService>(context);
    final settings = ds.settings;

    final isEdit = widget.existing != null && !widget.isDuplicate;
    final cs = Theme.of(context).colorScheme;

    final AppSettings? activeSettingsForTags =
        widget.isBuffer ? _targetSettings : settings;

    Map<String, dynamic> currentTreeLevel =
        activeSettingsForTags?.tagTree ?? {};
    for (String step in _treePath) {
      currentTreeLevel = currentTreeLevel[step] ?? <String, dynamic>{};
    }
    final sortedCurrentLevel = currentTreeLevel.keys.toList()..sort();
    final sortedLoose =
        List<String>.from(activeSettingsForTags?.availableTags ?? [])..sort();

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(isEdit
                  ? 'Modifica componente'
                  : (widget.isDuplicate
                      ? 'Duplica componente'
                      : 'Nuovo componente'))),
          if (isEdit)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              tooltip: 'Elimina componente',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Elimina componente'),
                    content:
                        const Text('Vuoi davvero eliminare questo componente?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annulla')),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(ctx).colorScheme.error,
                            foregroundColor: Theme.of(ctx).colorScheme.onError),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Elimina'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  Navigator.pop(context, 'DELETE');
                }
              },
            ),
        ],
      ),
      scrollable: true,
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Nome *',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: cs.primaryContainer.withOpacity(_opacityPrimary),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Descrizione',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor:
                      cs.surfaceContainerHighest.withOpacity(_opacityNeutral),
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              if (widget.isBuffer) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nota (promemoria)',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor:
                        cs.surfaceContainerHighest.withOpacity(_opacityNeutral),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                () {
                  final List<InventoryMeta> availableInventories = ds.isRemote
                      ? ds.inventories
                      : [
                          InventoryMeta(
                              id: 'default', name: 'Inventario Locale')
                        ];
                  return DropdownButtonFormField<String?>(
                    value: _selectedTargetInventoryId,
                    decoration: InputDecoration(
                      labelText: 'Inventario di destinazione',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor:
                          cs.primaryContainer.withOpacity(_opacityPrimary),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Nessuno (Da selezionare)'),
                      ),
                      ...availableInventories
                          .map((inv) => DropdownMenuItem<String?>(
                                value: inv.id,
                                child: Text(inv.name),
                              )),
                    ],
                    onChanged: (v) => _onTargetInventoryChanged(v),
                  );
                }(),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Quantità',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.green.withOpacity(_opacityGreen),
                    ),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (int.tryParse(v) == null || int.parse(v) < 0)
                        return 'Non valido';
                      return null;
                    },
                  ),
                ),
                if (!_isInBag && settings.containers.length > 1) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: settings.containers
                              .any((c) => c.id == _selectedCabinet)
                          ? _selectedCabinet
                          : (settings.containers.isNotEmpty
                              ? settings.containers.first.id
                              : 1),
                      decoration: InputDecoration(
                        labelText: 'Cassettiera',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.green.withOpacity(_opacityGreen),
                      ),
                      items: settings.containers
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                    c.name.isNotEmpty ? c.name : 'N° ${c.id}'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCabinet = v ?? 1),
                    ),
                  ),
                ],
              ]),
              if (!_isInBag) ...[
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: cs.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Posizione',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'text',
                                  label: Text('Tastiera'),
                                  icon: Icon(Icons.keyboard_outlined, size: 16),
                                ),
                                ButtonSegment(
                                  value: 'map',
                                  label: Text('Mappa'),
                                  icon: Icon(Icons.grid_view, size: 16),
                                ),
                              ],
                              selected: {_positionInputMode},
                              onSelectionChanged: (val) {
                                setState(() => _positionInputMode = val.first);
                              },
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_positionInputMode == 'text') ...[
                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: _colCtrl,
                                textInputAction: TextInputAction.next,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: 'Colonna',
                                  hintText: 'Es: A',
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor:
                                      Colors.green.withOpacity(_opacityGreen),
                                ),
                                validator: (v) {
                                  if ((v?.isEmpty ?? true) &&
                                      _rowCtrl.text.trim().isNotEmpty)
                                    return 'Manca colonna';
                                  if ((v?.isNotEmpty ?? false) &&
                                      _rowCtrl.text.trim().isEmpty)
                                    return 'Manca riga';
                                  if (v != null && v.trim().isNotEmpty) {
                                    final col =
                                        _colCtrl.text.trim().toUpperCase();
                                    final row = _rowCtrl.text.trim();
                                    if (col.isNotEmpty && row.isNotEmpty) {
                                      final label = '$col$row';
                                      final container = settings.containers
                                          .firstWhere(
                                              (c) => c.id == _selectedCabinet,
                                              orElse: () =>
                                                  settings.containers.first);
                                      if (container.disabledDrawers
                                          .contains(label)) {
                                        return 'Cassetto disattivato';
                                      }
                                      if (!container.isDrawerValid(label)) {
                                        return 'Max: ${container.columnLabels.last}${container.rows}';
                                      }
                                    }
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _rowCtrl,
                                textInputAction: TextInputAction.done,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Riga',
                                  hintText: 'Es: 3',
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor:
                                      Colors.green.withOpacity(_opacityGreen),
                                ),
                                validator: (v) {
                                  if ((v?.isEmpty ?? true) &&
                                      _colCtrl.text.trim().isNotEmpty)
                                    return 'Manca riga';
                                  if ((v?.isNotEmpty ?? false) &&
                                      _colCtrl.text.trim().isEmpty)
                                    return 'Manca colonna';
                                  if (v != null && v.trim().isNotEmpty) {
                                    final col =
                                        _colCtrl.text.trim().toUpperCase();
                                    final row = _rowCtrl.text.trim();
                                    if (col.isNotEmpty && row.isNotEmpty) {
                                      final label = '$col$row';
                                      final container = settings.containers
                                          .firstWhere(
                                              (c) => c.id == _selectedCabinet,
                                              orElse: () =>
                                                  settings.containers.first);
                                      if (container.disabledDrawers
                                          .contains(label)) {
                                        return 'Cassetto disattivato';
                                      }
                                      if (!container.isDrawerValid(label)) {
                                        return 'Max: ${container.columnLabels.last}${container.rows}';
                                      }
                                    }
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.map_outlined),
                              tooltip: 'Seleziona da mappa',
                              onPressed: () async {
                                final res = await DrawerPickerDialog.show(
                                  context,
                                  settings: settings,
                                  dataService: ds,
                                  initialCabinetId: _selectedCabinet,
                                  initialCol: _colCtrl.text,
                                  initialRow: _rowCtrl.text,
                                  initialZone: _selectedZone,
                                );
                                if (res != null && mounted) {
                                  setState(() {
                                    _selectedCabinet = res['cabinetId'] as int;
                                    _colCtrl.text = res['col'] as String;
                                    _rowCtrl.text = res['row'] as String;
                                    _selectedZone = res['zone'] as int?;
                                  });
                                }
                              },
                            ),
                          ]),
                        ] else ...[
                          DrawerGridPicker(
                            settings: settings,
                            dataService: ds,
                            selectedCabinetId: _selectedCabinet,
                            selectedCol: _colCtrl.text,
                            selectedRow: _rowCtrl.text,
                            selectedZone: _selectedZone,
                            showCabinetSelector: false,
                            onCabinetChanged: (newCab) {
                              setState(() => _selectedCabinet = newCab);
                            },
                            onDrawerSelected: (cId, cStr, rStr, zIdx) {
                              setState(() {
                                _selectedCabinet = cId;
                                _colCtrl.text = cStr;
                                _rowCtrl.text = rStr;
                                _selectedZone = zIdx;
                              });
                            },
                          ),
                        ],
                        () {
                          final col = _colCtrl.text.trim().toUpperCase();
                          final row = _rowCtrl.text.trim();
                          if (col.isEmpty || row.isEmpty)
                            return const SizedBox.shrink();

                          final drawer = '$col$row';
                          final key = '${_selectedCabinet}_$drawer';
                          final zones = settings.drawerDividers[key] ?? 1;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.tune, size: 16),
                                  label: Text(zones >= 2
                                      ? 'Modifica separatori ($zones zone)'
                                      : 'Configura separatori (cassetto normale)'),
                                  onPressed: () =>
                                      _configureDrawerSeparators(drawer),
                                ),
                              ),
                              if (zones >= 2) ...[
                                const SizedBox(height: 12),
                                DropdownButtonFormField<int>(
                                  value: _selectedZone == null ||
                                          _selectedZone! < 1 ||
                                          _selectedZone! > zones
                                      ? 1
                                      : _selectedZone,
                                  decoration: InputDecoration(
                                    labelText: 'Zona del cassetto (Separatore)',
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor:
                                        Colors.green.withOpacity(_opacityGreen),
                                  ),
                                  items: List.generate(zones, (i) => i + 1)
                                      .map((z) => DropdownMenuItem(
                                            value: z,
                                            child: Text(getZoneLabel(z, zones)),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedZone = v ?? 1),
                                ),
                              ],
                            ],
                          );
                        }(),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_isLoadingSettings) ...[
                const SizedBox(height: 16),
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Caricamento tag...'),
                    ],
                  ),
                ),
              ] else if (activeSettingsForTags == null) ...[
                const SizedBox(height: 16),
                Card(
                  color: cs.surfaceContainerHighest.withOpacity(0.5),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Seleziona un inventario di destinazione per impostare tag e proprietà.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                if (_selectedTags.isNotEmpty) ...[
                  Text('Tag selezionati',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 10,
                    children: _selectedTags
                        .map((tag) => InputChip(
                              label: Text(tag,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              backgroundColor: cs.primaryContainer,
                              onDeleted: () => setState(() {
                                final subtree = _findSubtree(
                                    tag, activeSettingsForTags.tagTree);
                                _removeNodeAndDescendants(
                                    tag, subtree ?? {}, _selectedTags);
                                final idx = _treePath.indexOf(tag);
                                if (idx != -1)
                                  _treePath = _treePath.sublist(0, idx);
                              }),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 4),
                ],
                if (activeSettingsForTags.tagTree.isNotEmpty) ...[
                  Text('Naviga nell\'albero dei tag',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6)),
                    child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          ActionChip(
                            label: const Text('Inizio'),
                            avatar: const Icon(Icons.home, size: 16),
                            onPressed: () => setState(() => _treePath.clear()),
                          ),
                          for (int i = 0; i < _treePath.length; i++) ...[
                            const Icon(Icons.chevron_right, size: 16),
                            ActionChip(
                              label: Text(_treePath[i]),
                              onPressed: () => setState(() =>
                                  _treePath = _treePath.sublist(0, i + 1)),
                            ),
                          ]
                        ]),
                  ),
                  const SizedBox(height: 12),
                  if (sortedCurrentLevel.isEmpty)
                    Text('Nessun sottotag disponibile.',
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: cs.onSurfaceVariant))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: sortedCurrentLevel.map((t) {
                        final isSelected = _selectedTags.contains(t);
                        return ChoiceChip(
                          label: Text(t),
                          selected: isSelected,
                          selectedColor: cs.primaryContainer,
                          onSelected: (sel) {
                            if (!sel) return;
                            setState(() {
                              final siblings =
                                  sortedCurrentLevel.where((k) => k != t);
                              for (final s in siblings) {
                                if (_selectedTags.contains(s)) {
                                  _removeNodeAndDescendants(
                                      s, currentTreeLevel[s], _selectedTags);
                                }
                              }

                              if (!_selectedTags.contains(t))
                                _selectedTags.add(t);
                              if (_nameCtrl.text.isEmpty ||
                                  activeSettingsForTags.tagTree.keys
                                      .contains(_nameCtrl.text)) {
                                _nameCtrl.text = t;
                              }

                              _treePath.add(t);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                ],
                if (sortedLoose.isNotEmpty) ...[
                  TextButton.icon(
                    icon: Icon(
                        _showLooseTags ? Icons.expand_less : Icons.expand_more),
                    label: const Text('Mostra tag generici (sfusi)'),
                    onPressed: () =>
                        setState(() => _showLooseTags = !_showLooseTags),
                  ),
                  if (_showLooseTags) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: sortedLoose.map((tag) {
                        final selected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: selected,
                          selectedColor: cs.primaryContainer,
                          backgroundColor: cs.surfaceContainerHighest,
                          onSelected: (v) => setState(() => v
                              ? _selectedTags.add(tag)
                              : _selectedTags.remove(tag)),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                if (activeSettingsForTags.specialTags.isNotEmpty) ...[
                  Text('Proprietà',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  ...activeSettingsForTags.specialTags.map((st) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextFormField(
                          controller: _specialTagCtrls[st.name],
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: st.unit.isNotEmpty
                                ? '${st.name} (${st.unit})'
                                : st.name,
                            border: const OutlineInputBorder(),
                            hintText: st.isString
                                ? 'Testo libero'
                                : 'Lascia vuoto o usa K, V, M... (es. 1K2)',
                            filled: true,
                            fillColor: cs.tertiaryContainer
                                .withOpacity(_opacityTertiary),
                          ),
                          keyboardType: TextInputType.text,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            if (!st.isString && parseSpecialValue(v) == null)
                              return 'Formato numerico non valido';
                            return null;
                          },
                        ),
                      )),
                ],
              ],
              const SizedBox(height: 16),
              Text('Allegati', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              if (_attachments.isNotEmpty)
                Column(
                  children: _attachments.map((a) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          Icon(a.isLink ? Icons.link : Icons.insert_drive_file),
                      title: Text(a.name),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: cs.error),
                        onPressed: () {
                          setState(() {
                            _attachments.remove(a);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text('Link'),
                    onPressed: () async {
                      final urlCtrl = TextEditingController();
                      final nameCtrl = TextEditingController();
                      final res = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Aggiungi Link'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                  controller: nameCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Nome (es. Datasheet)')),
                              TextField(
                                  controller: urlCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'URL (https://...)')),
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Annulla')),
                            FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Aggiungi')),
                          ],
                        ),
                      );
                      if (res == true && urlCtrl.text.isNotEmpty) {
                        setState(() {
                          _attachments.add(Attachment(
                              name: nameCtrl.text.isEmpty
                                  ? 'Link'
                                  : nameCtrl.text,
                              path: urlCtrl.text,
                              isLink: true));
                        });
                      }
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Carica File'),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null && result.files.single.path != null) {
                        setState(() {
                          _attachments.add(Attachment(
                            name: result.files.single.name,
                            path: result.files.single.path!,
                            isLink: false,
                          ));
                        });
                      }
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('File Esistente'),
                    onPressed: () async {
                      final ds = context.read<DataService>();
                      final existingFiles = ds.components
                          .expand((c) => c.attachments)
                          .where((a) => !a.isLink)
                          .fold<Map<String, Attachment>>({}, (map, a) {
                            map[a.path] = a;
                            return map;
                          })
                          .values
                          .toList();

                      if (existingFiles.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Nessun file esistente')));
                        }
                        return;
                      }

                      final selected = await showDialog<Attachment>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Scegli file esistente'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: existingFiles.map((a) {
                                  return ListTile(
                                    leading:
                                        const Icon(Icons.insert_drive_file),
                                    title: Text(a.name),
                                    onTap: () => Navigator.pop(ctx, a),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Annulla')),
                          ],
                        ),
                      );

                      if (selected != null) {
                        setState(() {
                          _attachments.add(Attachment(
                              name: selected.name,
                              path: selected.path,
                              isLink: false));
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Immagini', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              if (_images.isNotEmpty) ...[
                SizedBox(
                  height: 90,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _images.asMap().entries.map((entry) {
                        final index = entry.key;
                        final path = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FullscreenImageViewer(
                                        images: _images,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: _buildImageWidget(context, path),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _images.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              if (index == 0)
                                Positioned(
                                  bottom: 2,
                                  left: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Icona',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextButton.icon(
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  await _saveDraft();
                  final source = await showModalBottomSheet<ImageSource>(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Scatta Foto Ora'),
                            onTap: () => Navigator.pop(ctx, ImageSource.camera),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Seleziona dalla Galleria'),
                            onTap: () =>
                                Navigator.pop(ctx, ImageSource.gallery),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (source == null) return;
                  final picker = ImagePicker();

                  if (source == ImageSource.camera) {
                    final photo = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                      maxWidth: 1920,
                      maxHeight: 1920,
                    );
                    if (photo != null) {
                      setState(() {
                        _images.add(photo.path);
                      });
                    }
                  } else {
                    final photos = await picker.pickMultiImage(
                      imageQuality: 80,
                      maxWidth: 1920,
                      maxHeight: 1920,
                    );
                    if (photos.isNotEmpty) {
                      setState(() {
                        _images.addAll(photos.map((p) => p.path));
                      });
                    }
                  }
                },
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Aggiungi Foto'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await clearDraft();
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Annulla'),
        ),
        FilledButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isEdit ? 'Salva' : 'Aggiungi')),
      ],
    );
  }

  Widget _buildImageWidget(BuildContext context, String imagePath) {
    final ds = Provider.of<DataService>(context, listen: false);
    if (imagePath.startsWith('/')) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image),
      );
    } else if (imagePath.startsWith('http://') ||
        imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image),
      );
    } else {
      if (ds.mode == StorageMode.remote && ds.serverConnected) {
        return Image.network(
          ds.getAttachmentUrl(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image),
        );
      } else {
        final localPath = ds.getLocalAttachmentPathSync(imagePath);
        return Image.file(
          File(localPath),
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image),
        );
      }
    }
  }

  Future<void> _configureDrawerSeparators(String label) async {
    final ds = Provider.of<DataService>(context, listen: false);
    final currentSettings = ds.settings;

    final key = '${_selectedCabinet}_$label';
    final currentZones = currentSettings.drawerDividers[key] ?? 1;
    int dialogZones = currentZones >= 2 ? currentZones : 2;
    bool isDivided = currentZones >= 2;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, dialogState) => AlertDialog(
          title: Text(
              'Configura separatori per $label (Cassettiera $_selectedCabinet)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Dividi cassetto in zone'),
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
                      child: Text('$dialogZones zone',
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'isDivided': isDivided,
                'zones': dialogZones,
              }),
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final newDividers = Map<String, int>.from(currentSettings.drawerDividers);
      if (result['isDivided'] == true) {
        newDividers[key] = result['zones'] as int;
      } else {
        newDividers.remove(key);
      }

      final updatedSettings = AppSettings(
        containers: currentSettings.containers,
        availableTags: currentSettings.availableTags,
        tagTree: currentSettings.tagTree,
        specialTags: currentSettings.specialTags,
        drawerDividers: newDividers,
      );

      await ds.updateSettings(updatedSettings);

      setState(() {
        final maxZones = newDividers[key] ?? 1;
        if (_selectedZone == null ||
            _selectedZone! < 1 ||
            _selectedZone! > maxZones) {
          _selectedZone = maxZones >= 2 ? 1 : null;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;

    final settings = Provider.of<DataService>(context, listen: false).settings;

    // Se entrambi i campi colonna e riga sono vuoti, restituisce stringa vuota (Posizione non assegnata)
    final col = _colCtrl.text.trim().toUpperCase();
    final row = _rowCtrl.text.trim();
    final drawer = col.isEmpty && row.isEmpty ? '' : '$col$row';

    int? finalZone;
    if (drawer.isNotEmpty) {
      final key = '${_selectedCabinet}_$drawer';
      final zones = settings.drawerDividers[key] ?? 1;
      if (zones >= 2) {
        finalZone = _selectedZone ?? 1;
      }
    }

    final activeSettings = widget.isBuffer ? _targetSettings : settings;
    final specialValues = <String, String>{};
    if (activeSettings != null) {
      for (final st in activeSettings.specialTags) {
        final text = _specialTagCtrls[st.name]?.text.trim() ?? '';
        if (text.isNotEmpty) {
          specialValues[st.name] = text;
        }
      }
    }

    final isEdit = widget.existing != null && !widget.isDuplicate;

    setState(() => _isSaving = true);
    await clearDraft();

    final ds = Provider.of<DataService>(context, listen: false);
    List<Attachment> finalAttachments = [];
    for (var a in _attachments) {
      if (a.isLink || (!a.path.startsWith('/'))) {
        finalAttachments.add(a);
      } else if (a.path.startsWith('/')) {
        // local path picked
        final newName = await ds.uploadAttachment(a.path, a.name);
        if (newName != null) {
          finalAttachments
              .add(Attachment(name: a.name, path: newName, isLink: false));
        } else {
          // Fallback if error, keep as is
          finalAttachments.add(a);
        }
      } else {
        finalAttachments.add(a);
      }
    }

    List<String> finalImages = [];
    for (var path in _images) {
      if (!path.startsWith('/')) {
        finalImages.add(path);
      } else {
        final filename = path.split('/').last;
        final newName = await ds.uploadAttachment(path, filename);
        if (newName != null) {
          finalImages.add(newName);
        } else {
          finalImages.add(path);
        }
      }
    }

    final result = Component(
      id: isEdit ? widget.existing?.id : null,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      quantity: qty,
      cabinet: _isInBag ? 1 : _selectedCabinet,
      drawer: _isInBag ? '' : drawer,
      tags: _selectedTags,
      specialTagValues: specialValues,
      attachments: finalAttachments,
      drawerZone: _isInBag ? null : finalZone,
      bagName: _isInBag ? (widget.bagName ?? widget.existing?.bagName) : null,
      note: _noteCtrl.text.trim(),
      targetInventoryId: widget.isBuffer ? _selectedTargetInventoryId : null,
      images: finalImages,
    );
    if (context.mounted) {
      Navigator.pop(context, result);
    }
  }
}
