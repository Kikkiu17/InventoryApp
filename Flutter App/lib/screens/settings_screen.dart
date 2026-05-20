import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../services/data_service.dart';
import '../services/api_client.dart';
import 'inventory_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _numCabinets;
  late int _rows;
  late int _cols;
  late List<String> _tags;
  late Map<String, dynamic> _tagTree;
  late List<SpecialTag> _specialTags;
  int _selectedCabinetPreview = 1;
  late Map<String, int> _drawerDividers;
  
  final _newTagCtrl         = TextEditingController();
  final _newSpecialNameCtrl = TextEditingController();
  final _newSpecialUnitCtrl = TextEditingController();
  final _serverUrlCtrl      = TextEditingController();
  
  final _cabsCtrl = TextEditingController();
  final _rowsCtrl = TextEditingController();
  final _colsCtrl = TextEditingController();
  final _manualDrawerCtrl = TextEditingController();
  
  bool _testingServer = false;
  bool? _serverOk;
  bool _newSpecialIsString = false;
  
  final Set<String> _expandedPaths = {};
  AppSettings? _lastSettingsRef; 

  @override
  void initState() {
    super.initState();
    _numCabinets = 1;
    _rows = 4;
    _cols = 6;
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
    _serverUrlCtrl.dispose();
    _cabsCtrl.dispose();
    _rowsCtrl.dispose();
    _colsCtrl.dispose();
    _manualDrawerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ds = context.read<DataService>();
    await ds.updateSettings(AppSettings(
      numCabinets: _numCabinets,
      drawerRows: _rows,
      drawerColumns: _cols,
      availableTags: _tags,
      tagTree: _tagTree,
      specialTags: _specialTags,
      drawerDividers: _drawerDividers,
    ));
    _lastSettingsRef = ds.settings; 
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impostazioni salvate')));
    }
  }

  String _getExcelColumn(int index) {
    String name = '';
    while (index >= 0) {
      name = String.fromCharCode(65 + (index % 26)) + name;
      index = (index ~/ 26) - 1;
    }
    return name;
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

  Future<void> _configureDrawerSeparators(String label) async {
    final key = '${_selectedCabinetPreview.clamp(1, _numCabinets)}_$label';
    final currentZones = _drawerDividers[key] ?? 1;
    int dialogZones = currentZones >= 2 ? currentZones : 2;
    bool isDivided = currentZones >= 2;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, dialogState) => AlertDialog(
          title: Text('Configura separatori per $label (Cassettiera ${_selectedCabinetPreview.clamp(1, _numCabinets)})'),
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
      setState(() {
        if (result['isDivided'] == true) {
          _drawerDividers[key] = result['zones'] as int;
        } else {
          _drawerDividers.remove(key);
        }
      });
    }
  }

  void _configureManualDrawer() {
    final input = _manualDrawerCtrl.text.trim().toUpperCase();
    if (input.isEmpty) return;
    
    if (!_validateDrawerCoordinate(input, _rows, _cols)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordinate cassetto non valide per le dimensioni attuali della cassettiera'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    FocusScope.of(context).unfocus();
    _configureDrawerSeparators(input);
  }

  @override
  Widget build(BuildContext context) {
    final ds    = context.watch<DataService>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    
    if (_lastSettingsRef != ds.settings) {
      _lastSettingsRef = ds.settings;
      final s = ds.settings;
      _numCabinets = s.numCabinets;
      _rows        = s.drawerRows;
      _cols        = s.drawerColumns;
      _tags        = List.from(s.availableTags);
      _tagTree     = _deepCopyTree(s.tagTree);
      _specialTags = s.specialTags.map((t) => SpecialTag(name: t.name, unit: t.unit, isString: t.isString)).toList();
      _drawerDividers = Map.from(s.drawerDividers);
      
      _cabsCtrl.text = _numCabinets.toString();
      _rowsCtrl.text = _rows.toString();
      _colsCtrl.text = _cols.toString();
      _serverUrlCtrl.text = ds.serverUrl;
      _expandedPaths.clear();
    }

    final sortedTags = List<String>.from(_tags)..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        actions: [TextButton(onPressed: _save, child: const Text('Salva'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _SectionHeader(title: 'Server remoto', icon: Icons.cloud_outlined),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Usa server remoto', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    ds.isRemote ? ds.serverConnected ? '✅ Connesso' : '❌ Non connesso' : 'Archiviazione locale',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ]),
                Switch(
                  value: ds.isRemote,
                  onChanged: (v) async {
                    await ds.setStorageMode(v ? StorageMode.remote : StorageMode.local);
                    if (mounted && v && !ds.serverConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ds.lastError ?? 'Errore connessione'), backgroundColor: cs.error));
                    }
                  },
                ),
              ]),
              const Divider(height: 24),
              if (ds.isRemote && ds.serverConnected && ds.currentInventory != null)
                InkWell(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const InventoryListScreen())),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Icon(Icons.inventory_2_outlined, size: 18, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Inventario attivo',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                          Text(ds.currentInventory!.name,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600,
                                             color: cs.primary)),
                        ],
                      )),
                      Icon(Icons.chevron_right, color: cs.primary, size: 18),
                    ]),
                  ),
                ),
              if (ds.isRemote && ds.serverConnected && ds.currentInventory != null)
                const Divider(height: 16),
              Text('Indirizzo server', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _serverUrlCtrl,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(), hintText: 'http://192.168.1.2:8080', isDense: true,
                      suffixIcon: _serverOk == null ? null : Icon(_serverOk! ? Icons.check_circle : Icons.error_outline, color: _serverOk! ? Colors.green : cs.error),
                    ),
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => _applyServer(),
                  ),
                ),
                const SizedBox(width: 8),
                _testingServer
                    ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2))
                    : FilledButton.tonal(onPressed: _testServer, child: const Text('Test')),
              ]),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _applyServer, icon: const Icon(Icons.save_outlined), label: const Text('Salva indirizzo server'))),
              if (ds.isRemote) ...[
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(
                  onPressed: () async {
                    await ds.refreshFromServer();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ds.serverConnected ? 'Dati aggiornati' : ds.lastError ?? 'Errore'), backgroundColor: ds.serverConnected ? null : cs.error));
                    }
                  },
                  icon: const Icon(Icons.sync), label: const Text('Sincronizza ora'),
                )),
              ],
            ]),
          )),
          const SizedBox(height: 24),

          _SectionHeader(title: 'Aspetto', icon: Icons.palette_outlined),
          Card(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tema dell\'app', style: theme.textTheme.bodyLarge),
                DropdownButton<ThemeMode>(
                  value: ds.themeMode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Row(
                        children: [
                          Icon(Icons.brightness_auto, size: 18),
                          SizedBox(width: 8),
                          Text('Sistema'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Row(
                        children: [
                          Icon(Icons.light_mode, size: 18),
                          SizedBox(width: 8),
                          Text('Chiaro'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Row(
                        children: [
                          Icon(Icons.dark_mode, size: 18),
                          SizedBox(width: 8),
                          Text('Scuro'),
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
          )),
          const SizedBox(height: 24),

          _SectionHeader(title: 'Configurazione cassetti', icon: Icons.grid_view),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cassettiere: $_numCabinets · Colonne: A–${_getExcelColumn(_cols > 0 ? _cols - 1 : 0)} · Righe: 1–$_rows · Totale: ${_rows * _cols} cassetti x cassettiera', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cabsCtrl,
                      decoration: const InputDecoration(labelText: 'Cassettiere', border: OutlineInputBorder(), isDense: true),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final val = int.tryParse(v);
                        if (val != null && val > 0) setState(() => _numCabinets = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _colsCtrl,
                      decoration: const InputDecoration(labelText: 'Colonne', border: OutlineInputBorder(), isDense: true),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final val = int.tryParse(v);
                        if (val != null && val > 0) setState(() => _cols = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _rowsCtrl,
                      decoration: const InputDecoration(labelText: 'Righe', border: OutlineInputBorder(), isDense: true),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final val = int.tryParse(v);
                        if (val != null && val > 0) setState(() => _rows = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_numCabinets > 1) ...[
                Row(
                  children: [
                    const Text('Cassettiera da visualizzare/modificare: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _selectedCabinetPreview.clamp(1, _numCabinets),
                      items: List.generate(_numCabinets, (i) => i + 1)
                          .map((cab) => DropdownMenuItem(
                                value: cab,
                                child: Text('Cassettiera $cab'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCabinetPreview = val);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              _DrawerGrid(
                rows: _rows,
                cols: _cols,
                getColName: _getExcelColumn,
                selectedCabinet: _selectedCabinetPreview.clamp(1, _numCabinets),
                drawerDividers: _drawerDividers,
                onDrawerClick: (label, currentZones) {
                  _configureDrawerSeparators(label);
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Configura cassetto per coordinate (per cassetti non visibili nell\'anteprima)',
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
                      decoration: const InputDecoration(
                        labelText: 'Codice cassetto',
                        hintText: 'Es: A20 o K4',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _configureManualDrawer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _configureManualDrawer,
                    child: const Text('Configura'),
                  ),
                ],
              ),
            ]),
          )),
          const SizedBox(height: 24),

          _SectionHeader(title: 'Albero dei Tag', icon: Icons.account_tree_outlined),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Crea categorie e sottocategorie digitando nel campo apposito e premendo invio.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
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

          _SectionHeader(title: 'Tag Generici (Sfusi)', icon: Icons.label_outline),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _newTagCtrl,
                    decoration: const InputDecoration(labelText: 'Nuovo tag generico', border: OutlineInputBorder(), isDense: true),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: _addTag, icon: const Icon(Icons.add), label: const Text('Aggiungi')),
              ]),
              const SizedBox(height: 16),
              if (_tags.isEmpty)
                Text('Nessun tag generico.', style: TextStyle(color: cs.onSurfaceVariant))
              else
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: sortedTags.map((tag) => Chip(
                    label: Text(tag), onDeleted: () => _confirmDeleteTag(tag), deleteIcon: const Icon(Icons.close, size: 16),
                  )).toList(),
                ),
            ]),
          )),
          const SizedBox(height: 24),

          _SectionHeader(title: 'Proprietà con valore', icon: Icons.tune),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Definisci proprietà numeriche o stringhe. Trascina per riordinarle.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextField(controller: _newSpecialNameCtrl, decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder(), isDense: true), onSubmitted: (_) => _addSpecialTag())),
                const SizedBox(width: 8),
                // AUMENTATA LA LARGHEZZA A 90 PIXEL
                SizedBox(width: 90, child: TextField(controller: _newSpecialUnitCtrl, decoration: const InputDecoration(labelText: 'Unità', border: OutlineInputBorder(), isDense: true), onSubmitted: (_) => _addSpecialTag())),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Testo'),
                  selected: _newSpecialIsString,
                  onSelected: (v) => setState(() => _newSpecialIsString = v),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _addSpecialTag, icon: const Icon(Icons.add), tooltip: 'Aggiungi'),
              ]),
              const SizedBox(height: 16),
              if (_specialTags.isEmpty)
                Text('Nessuna proprietà configurata.', style: TextStyle(color: cs.onSurfaceVariant))
              else
                ReorderableListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), buildDefaultDragHandles: false,
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
                      key: ValueKey(st.name), contentPadding: EdgeInsets.zero,
                      leading: Icon(st.isString ? Icons.text_fields : Icons.numbers, color: cs.primary),
                      title: Text(st.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text((st.unit.isNotEmpty ? 'Unità: ${st.unit}' : 'Nessuna unità') + (st.isString ? ' • Testo' : ' • Valore')),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: Icon(Icons.delete_outline, color: cs.error), onPressed: () => _confirmDeleteSpecialTag(st.name)),
                        ReorderableDragStartListener(index: i, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Icon(Icons.drag_handle))),
                      ]),
                    );
                  },
                ),
            ]),
          )),
          const SizedBox(height: 24),

          _SectionHeader(title: 'Dati', icon: Icons.storage_outlined),
          Card(child: Column(children: [
            ListTile(leading: Icon(Icons.upload_file, color: cs.primary), title: const Text('Esporta dati'), onTap: () async => await ds.exportData()),
            const Divider(height: 1),
            ListTile(leading: Icon(Icons.download_outlined, color: cs.primary), title: const Text('Importa dati'), onTap: () => _importData(ds)),
            // --- NUOVO BOTTONE PER I BACKUP REMOTI ---
            if (ds.isRemote && ds.serverConnected) ...[
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.restore, color: cs.primary), 
                title: const Text('Ripristina backup remoto'), 
                onTap: () => _showRestoreDialog(context, ds),
              ),
            ],
          ])),
        ],
      ),
    );
  }

  Widget _buildTreeLevel(Map<String, dynamic> node, List<String> path) {
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
                  if (exp) _expandedPaths.add(currentPathKey);
                  else _expandedPaths.remove(currentPathKey);
                });
              },
              title: Text(k, style: const TextStyle(fontWeight: FontWeight.bold)),
              dense: true,
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error), 
                tooltip: 'Elimina', 
                onPressed: () => _confirmDeleteNode(currentPath)
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Container(
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
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
            right: 16.0
          ),
          child: TextField(
            key: ValueKey('${pathKey}_${keys.length}'),
            decoration: InputDecoration(
              hintText: path.isEmpty ? 'Aggiungi principale...' : 'Aggiungi in ${path.last}...',
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
    final res = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Elimina Tag'),
        content: Text('Vuoi eliminare "${path.last}" e tutti i suoi sottotag?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Elimina')),
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
    setState(() { _testingServer = true; _serverOk = null; });
    final ok = await ApiClient(_serverUrlCtrl.text.trim()).ping();
    setState(() { _testingServer = false; _serverOk = ok; });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Raggiungibile! ✅' : 'Errore ❌')));
  }

  Future<void> _applyServer() async {
    final url = _serverUrlCtrl.text.trim();
    if (url.isEmpty) return;
    final ok = await context.read<DataService>().setServerUrl(url);
    setState(() => _serverOk = ok);
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
      _specialTags.add(SpecialTag(name: name, unit: _newSpecialUnitCtrl.text.trim(), isString: _newSpecialIsString));
      _newSpecialIsString = false;
    });
    _newSpecialNameCtrl.clear();
    _newSpecialUnitCtrl.clear();
  }

  Future<void> _confirmDeleteTag(String tag) async {
    final confirm = await showDialog<bool>(
      context: context, builder: (ctx) => AlertDialog(
        title: const Text('Rimuovi tag'), content: Text('Rimuovere "$tag"?'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rimuovi'))],
      ),
    );
    if (confirm == true) setState(() => _tags.remove(tag));
  }

  Future<void> _confirmDeleteSpecialTag(String name) async {
    final confirm = await showDialog<bool>(
      context: context, builder: (ctx) => AlertDialog(
        title: const Text('Rimuovi proprietà'), content: Text('Rimuovere "$name"?'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rimuovi'))],
      ),
    );
    if (confirm == true) setState(() => _specialTags.removeWhere((t) => t.name == name));
  }

  Future<void> _importData(DataService ds) async {
    final confirm = await showDialog<bool>(
      context: context, builder: (ctx) => AlertDialog(
        title: const Text('Importa dati'), content: const Text('Sovrascrivere tutti i dati?'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importa'))],
      ),
    );
    if (confirm != true) return;
    final ok = await ds.importData();
    if (ok) {
      _lastSettingsRef = ds.settings; 
      setState(() {
        _numCabinets = ds.settings.numCabinets;
        _rows        = ds.settings.drawerRows;
        _cols        = ds.settings.drawerColumns;
        _tags        = List.from(ds.settings.availableTags);
        _tagTree     = _deepCopyTree(ds.settings.tagTree);
        _specialTags = ds.settings.specialTags.map((t) => SpecialTag(name: t.name, unit: t.unit, isString: t.isString)).toList();
        _drawerDividers = Map.from(ds.settings.drawerDividers);
        _cabsCtrl.text = _numCabinets.toString();
        _rowsCtrl.text = _rows.toString();
        _colsCtrl.text = _cols.toString();
      });
    }
  }

  Future<void> _showRestoreDialog(BuildContext context, DataService ds) async {
    final backups = await ds.getBackups();
    if (!context.mounted) return;
    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun backup trovato')));
      return;
    }
    
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ripristina backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: backups.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(_formatBackupName(backups[i])), 
              leading: const Icon(Icons.history),
              onTap: () => Navigator.pop(ctx, backups[i]),
            )
          )
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla'))],
      )
    );

    if (choice != null && context.mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Conferma ripristino'),
          content: const Text('Sovrascrivere i dati attuali? (Verrà creato un backup di sicurezza automatico prima di procedere).'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ripristina'))
          ]
        )
      );
      
      if (confirm == true) {
        final ok = await ds.restoreBackup(choice);
        if (ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup ripristinato con successo')));
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
          return '${d.substring(6,8)}/${d.substring(4,6)}/${d.substring(0,4)} alle ${t.substring(0,2)}:${t.substring(2,4)}:${t.substring(4,6)}';
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
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _DrawerGrid extends StatelessWidget {
  final int rows, cols;
  final String Function(int) getColName;
  final int selectedCabinet;
  final Map<String, int> drawerDividers;
  final void Function(String label, int currentZones) onDrawerClick;

  const _DrawerGrid({
    required this.rows,
    required this.cols,
    required this.getColName,
    required this.selectedCabinet,
    required this.drawerDividers,
    required this.onDrawerClick,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Anteprima (clicca su un cassetto per dividere in zone/separatori)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int r = 0; r < rows.clamp(0, 6); r++)
                Row(
                  children: [
                    for (int c = 0; c < cols.clamp(0, 8); c++) () {
                      final label = '${getColName(c)}${r + 1}';
                      final key = '${selectedCabinet}_$label';
                      final zones = drawerDividers[key] ?? 1;
                      return InkWell(
                        onTap: () => onDrawerClick(label, zones),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 44,
                          height: 32,
                          margin: const EdgeInsets.all(3),
                          child: zones < 2
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                                  ? const BorderRadius.vertical(top: Radius.circular(4))
                                                  : i == zones - 1
                                                      ? const BorderRadius.vertical(bottom: Radius.circular(4))
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
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: cs.primaryContainer.withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: cs.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    }(),
                    if (cols > 8)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text('…', style: TextStyle(color: cs.onSurfaceVariant)),
                      ),
                  ],
                ),
              if (rows > 6)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('… e altre ${rows - 6} righe',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}