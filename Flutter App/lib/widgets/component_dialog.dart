import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../models/settings.dart';
import '../services/data_service.dart';

const double _opacityPrimary = 0.4;
const double _opacityNeutral = 0.6;
const double _opacityGreen = 0.2;
const double _opacityTertiary = 0.4;

class ComponentDialog extends StatefulWidget {
  final Component? existing;
  final AppSettings settings;
  final bool isDuplicate;

  const ComponentDialog({super.key, this.existing, required this.settings, this.isDuplicate = false});

  @override
  State<ComponentDialog> createState() => _ComponentDialogState();
}

class _ComponentDialogState extends State<ComponentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _colCtrl;
  late TextEditingController _rowCtrl;

  int _selectedCabinet = 1;
  
  List<String> _selectedTags = [];
  List<String> _treePath = [];
  bool _showLooseTags = false;

  Map<String, TextEditingController> _specialTagCtrls = {};
  
  List<Attachment> _attachments = [];
  bool _isSaving = false;
  int? _selectedZone;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _qtyCtrl  = TextEditingController(text: (e?.quantity ?? 0).toString());
    _colCtrl  = TextEditingController();
    _rowCtrl  = TextEditingController();

    _selectedCabinet = e?.cabinet ?? 1;
    _selectedZone = e?.drawerZone;

    final d = e?.drawer ?? '';
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

    final settings = Provider.of<DataService>(context, listen: false).settings;
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
      _specialTagCtrls[st.name] = TextEditingController(
        text: e?.specialTagValues[st.name] ?? '', 
      );
    }
    
    _attachments = List.from(e?.attachments ?? []);
    
    _colCtrl.addListener(_onDrawerCoordinatesChanged);
    _rowCtrl.addListener(_onDrawerCoordinatesChanged);
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

  void _removeNodeAndDescendants(String node, dynamic subtree, List<String> list) {
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

    final isEdit  = widget.existing != null && !widget.isDuplicate;
    final cs      = Theme.of(context).colorScheme;

    Map<String, dynamic> currentTreeLevel = settings.tagTree;
    for (String step in _treePath) {
      currentTreeLevel = currentTreeLevel[step] ?? <String, dynamic>{};
    }
    final sortedCurrentLevel = currentTreeLevel.keys.toList()..sort();
    final sortedLoose  = List<String>.from(settings.availableTags)..sort();

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(isEdit ? 'Modifica componente' : (widget.isDuplicate ? 'Duplica componente' : 'Nuovo componente'))),
          if (isEdit)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              tooltip: 'Elimina componente',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Elimina componente'),
                    content: const Text('Vuoi davvero eliminare questo componente?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
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
                if (confirm == true) {
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
                validator: (v) => v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
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
                  fillColor: cs.surfaceContainerHighest.withOpacity(_opacityNeutral),
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Quantità', border: const OutlineInputBorder(), filled: true,
                      fillColor: Colors.green.withOpacity(_opacityGreen), 
                    ),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (int.tryParse(v) == null || int.parse(v) < 0) return 'Non valido';
                      return null;
                    },
                  ),
                ),
                if (settings.numCabinets > 1) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedCabinet > settings.numCabinets ? 1 : _selectedCabinet,
                      decoration: InputDecoration(
                        labelText: 'Cassettiera', border: const OutlineInputBorder(), filled: true,
                        fillColor: Colors.green.withOpacity(_opacityGreen),
                      ),
                      items: List.generate(settings.numCabinets, (i) => i + 1)
                          .map((c) => DropdownMenuItem(value: c, child: Text('N° $c'))).toList(),
                      onChanged: (v) => setState(() => _selectedCabinet = v ?? 1),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _colCtrl,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Colonna', hintText: 'Es: A', border: const OutlineInputBorder(), filled: true,
                      fillColor: Colors.green.withOpacity(_opacityGreen),
                    ),
                    validator: (v) {
                      if ((v?.isEmpty ?? true) && _rowCtrl.text.trim().isNotEmpty) return 'Manca colonna';
                      if ((v?.isNotEmpty ?? false) && _rowCtrl.text.trim().isEmpty) return 'Manca riga';
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
                      labelText: 'Riga', hintText: 'Es: 3', border: const OutlineInputBorder(), filled: true,
                      fillColor: Colors.green.withOpacity(_opacityGreen),
                    ),
                    validator: (v) {
                      if ((v?.isEmpty ?? true) && _colCtrl.text.trim().isNotEmpty) return 'Manca riga';
                      if ((v?.isNotEmpty ?? false) && _colCtrl.text.trim().isEmpty) return 'Manca colonna';
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
              ]),
              () {
                final col = _colCtrl.text.trim().toUpperCase();
                final row = _rowCtrl.text.trim();
                if (col.isEmpty || row.isEmpty) return const SizedBox.shrink();
                
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
                        onPressed: () => _configureDrawerSeparators(drawer),
                      ),
                    ),
                    if (zones >= 2) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedZone == null || _selectedZone! < 1 || _selectedZone! > zones ? 1 : _selectedZone,
                        decoration: InputDecoration(
                          labelText: 'Zona del cassetto (Separatore)',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.green.withOpacity(_opacityGreen),
                        ),
                        items: List.generate(zones, (i) => i + 1)
                            .map((z) => DropdownMenuItem(
                                  value: z,
                                  child: Text(getZoneLabel(z, zones)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedZone = v ?? 1),
                      ),
                    ],
                  ],
                );
              }(),
              const SizedBox(height: 16),

              if (_selectedTags.isNotEmpty) ...[
                Text('Tag selezionati', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 10,
                  children: _selectedTags.map((tag) => InputChip(
                    label: Text(tag, style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: cs.primaryContainer,
                    onDeleted: () => setState(() {
                      final subtree = _findSubtree(tag, settings.tagTree);
                      _removeNodeAndDescendants(tag, subtree ?? {}, _selectedTags);
                      final idx = _treePath.indexOf(tag);
                      if (idx != -1) _treePath = _treePath.sublist(0, idx);
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 4),
              ],

              if (settings.tagTree.isNotEmpty) ...[
                Text('Naviga nell\'albero dei tag', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4, runSpacing: 4,
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
                          onPressed: () => setState(() => _treePath = _treePath.sublist(0, i + 1)),
                        ),
                      ]
                    ]
                  ),
                ),
                const SizedBox(height: 12),
                
                if (sortedCurrentLevel.isEmpty)
                  Text('Nessun sottotag disponibile.', style: TextStyle(fontStyle: FontStyle.italic, color: cs.onSurfaceVariant))
                else
                  Wrap(
                    spacing: 8, runSpacing: 12,
                    children: sortedCurrentLevel.map((t) {
                      final isSelected = _selectedTags.contains(t);
                      return ChoiceChip(
                        label: Text(t),
                        selected: isSelected,
                        selectedColor: cs.primaryContainer,
                        onSelected: (sel) {
                          if (!sel) return; 
                          setState(() {
                            final siblings = sortedCurrentLevel.where((k) => k != t);
                            for (final s in siblings) {
                              if (_selectedTags.contains(s)) {
                                _removeNodeAndDescendants(s, currentTreeLevel[s], _selectedTags);
                              }
                            }
                            
                            if (!_selectedTags.contains(t)) _selectedTags.add(t);
                                                        if (_treePath.isEmpty) {
                              if (_nameCtrl.text.isEmpty || settings.tagTree.keys.contains(_nameCtrl.text)) {
                                _nameCtrl.text = t;
                              }
                            } else if (_nameCtrl.text.isEmpty) {
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
                  icon: Icon(_showLooseTags ? Icons.expand_less : Icons.expand_more),
                  label: const Text('Mostra tag generici (sfusi)'),
                  onPressed: () => setState(() => _showLooseTags = !_showLooseTags),
                ),
                if (_showLooseTags) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 12,
                    children: sortedLoose.map((tag) {
                      final selected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: selected,
                        selectedColor: cs.primaryContainer,
                        backgroundColor: cs.surfaceContainerHighest,
                        onSelected: (v) => setState(() => v ? _selectedTags.add(tag) : _selectedTags.remove(tag)),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              if (settings.specialTags.isNotEmpty) ...[
                Text('Proprietà', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                ...settings.specialTags.map((st) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        controller: _specialTagCtrls[st.name],
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: st.unit.isNotEmpty ? '${st.name} (${st.unit})' : st.name,
                          border: const OutlineInputBorder(), 
                          hintText: st.isString ? 'Testo libero' : 'Lascia vuoto o usa K, V, M... (es. 1K2)',
                          filled: true, fillColor: cs.tertiaryContainer.withOpacity(_opacityTertiary),
                        ),
                        keyboardType: TextInputType.text,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (!st.isString && parseSpecialValue(v) == null) return 'Formato numerico non valido';
                          return null;
                        },
                      ),
                    )),
              ],

              const SizedBox(height: 16),
              Text('Allegati', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              if (_attachments.isNotEmpty)
                Column(
                  children: _attachments.map((a) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(a.isLink ? Icons.link : Icons.insert_drive_file),
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
                              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome (es. Datasheet)')),
                              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL (https://...)')),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aggiungi')),
                          ],
                        ),
                      );
                      if (res == true && urlCtrl.text.isNotEmpty) {
                        setState(() {
                          _attachments.add(Attachment(name: nameCtrl.text.isEmpty ? 'Link' : nameCtrl.text, path: urlCtrl.text, isLink: true));
                        });
                      }
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Nuovo File'),
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun file esistente')));
                        }
                        return;
                      }
                      
                      final selected = await showDialog<Attachment>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Scegli file esistente'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: existingFiles.length,
                              itemBuilder: (_, i) {
                                final a = existingFiles[i];
                                return ListTile(
                                  leading: const Icon(Icons.insert_drive_file),
                                  title: Text(a.name),
                                  onTap: () => Navigator.pop(ctx, a),
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
                          ],
                        ),
                      );

                      if (selected != null) {
                        setState(() {
                          _attachments.add(Attachment(name: selected.name, path: selected.path, isLink: false));
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        FilledButton(onPressed: _isSaving ? null : _submit, child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Salva' : 'Aggiungi')),
      ],
    );
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
          title: Text('Configura separatori per $label (Cassettiera $_selectedCabinet)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Dividi cassetto in zone'),
                subtitle: const Text('Suddivide in profondità (vicina, in mezzo, lontana)'),
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
                      onPressed: dialogZones > 2 ? () => dialogState(() => dialogZones--) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$dialogZones zone', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: dialogZones < 10 ? () => dialogState(() => dialogZones++) : null,
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
        numCabinets: currentSettings.numCabinets,
        drawerRows: currentSettings.drawerRows,
        drawerColumns: currentSettings.drawerColumns,
        availableTags: currentSettings.availableTags,
        tagTree: currentSettings.tagTree,
        specialTags: currentSettings.specialTags,
        drawerDividers: newDividers,
      );
      
      await ds.updateSettings(updatedSettings);
      
      setState(() {
        final maxZones = newDividers[key] ?? 1;
        if (_selectedZone == null || _selectedZone! < 1 || _selectedZone! > maxZones) {
          _selectedZone = maxZones >= 2 ? 1 : null;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final qty    = int.tryParse(_qtyCtrl.text) ?? 0;
    
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

    final specialValues = <String, String>{};
    for (final st in settings.specialTags) {
      final text = _specialTagCtrls[st.name]?.text.trim() ?? '';
      if (text.isNotEmpty) {
        specialValues[st.name] = text; 
      }
    }

    final isEdit = widget.existing != null && !widget.isDuplicate;
    
    setState(() => _isSaving = true);
    
    final ds = Provider.of<DataService>(context, listen: false);
    List<Attachment> finalAttachments = [];
    for (var a in _attachments) {
      if (a.isLink || (!a.path.startsWith('/'))) {
        finalAttachments.add(a); 
      } else if (a.path.startsWith('/')) { // local path picked
        final newName = await ds.uploadAttachment(a.path, a.name);
        if (newName != null) {
          finalAttachments.add(Attachment(name: a.name, path: newName, isLink: false));
        } else {
          // Fallback if error, keep as is
          finalAttachments.add(a);
        }
      } else {
        finalAttachments.add(a);
      }
    }

    final result = Component(
      id: isEdit ? widget.existing?.id : null,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      quantity: qty,
      cabinet: _selectedCabinet,
      drawer: drawer,
      tags: _selectedTags,
      specialTagValues: specialValues,
      attachments: finalAttachments,
      drawerZone: finalZone,
    );
    Navigator.pop(context, result);
  }
}