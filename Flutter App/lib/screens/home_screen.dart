import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

import '../models/component.dart';
import '../models/settings.dart';
import '../services/data_service.dart';
import '../widgets/component_tile.dart';
import '../widgets/component_dialog.dart';
import '../widgets/component_view_dialog.dart';
import 'inventory_list_screen.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isShowingConflict = false;
  final _searchCtrl = TextEditingController();
  String _query = '';
  List<String> _selectedTags = [];
  SortMode _sortMode = SortMode.name;
  String? _sortSpecialTag; 
  Map<String, SpecialFilter> _specialFilters = {};
  int? _cabinetFilter; 
  bool _unassignedPosition = false;
  
  String _lastInventoryId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ds = context.read<DataService>();
      ds.checkForUpdates();
      // Retry loading from server in case the initial load() in main() failed
      // (e.g. network not ready on cold start). Safe: uses checkConflict:false
      // so it never triggers the conflict dialog.
      ds.refreshFromServer();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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

  String _formatValueWithUnit(String value, String unit) {
    if (unit.isEmpty) return value;
    final v = value.trim();
    final regEnd = RegExp(r'^([0-9]+(?:\.[0-9]+)?)([a-zA-Zµ])$');
    final match = regEnd.firstMatch(v);
    if (match != null) {
      return '${match.group(1)}${match.group(2)}$unit';
    }
    return '$v$unit';
  }

  // Creazione ed esportazione del file PDF
  Future<void> _exportToPdf(List<Component> items, AppSettings settings) async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttf),
    );


    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text("Inventario Componenti", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Nome', 'Posizione', 'Qtà', 'Dettagli'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            // Aggiunto per evitare l'a capo sulle colonne strette
            columnWidths: const {
              0: pw.FlexColumnWidth(1.6),  // Nome (circa 2/3 di 2.5)
              1: pw.FixedColumnWidth(70),  // Posizione
              2: pw.FixedColumnWidth(40),  // Qtà
              3: pw.FlexColumnWidth(4.9),  // Dettagli (allargata)
            },
            data: items.map((c) {
              final pos = c.drawer.isEmpty ? 'Non ass.' : (settings.numCabinets > 1 ? '${c.cabinet}-${c.drawer}' : c.drawer);
              final props = c.specialTagValues.entries.map((e) {
                final st = settings.specialTags.where((s) => s.name == e.key).firstOrNull;
                return '${e.key}: ${_formatValueWithUnit(e.value, st?.unit ?? '')}';
              }).join(', ');
              final details = [if (c.description.isNotEmpty) c.description, if (c.tags.isNotEmpty) c.tags.join(', '), if (props.isNotEmpty) props].join('\n');
              
              return [c.name, pos, c.quantity.toString(), details];
            }).toList(),
          ),
        ],
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/inventario_export.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore esportazione PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();

    if (_lastInventoryId != ds.currentInventoryId) {
      _lastInventoryId = ds.currentInventoryId;
      _query = '';
      _searchCtrl.clear();
      _selectedTags.clear();
      _specialFilters.clear();
      _cabinetFilter = null;
      _unassignedPosition = false;
      _sortMode = SortMode.name;
      _sortSpecialTag = null;
    }

    if (ds.globalSearchQuery != null) {
      _query = ds.globalSearchQuery!;
      _searchCtrl.text = ds.globalSearchQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ds.setGlobalSearchQuery(null);
      });
    }

    if (ds.pendingConflict != null && !_isShowingConflict) {
      _isShowingConflict = true; // Blocca ulteriori popup
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await _showConflictDialog(ds);
          // Sblocca quando il popup viene chiuso
          if (mounted) setState(() => _isShowingConflict = false);
        }
      });
    }

    final results = ds.search(_query, _selectedTags, _sortMode, _specialFilters, _sortSpecialTag, _cabinetFilter, _unassignedPosition);
    final hasFilter = _query.isNotEmpty || _selectedTags.isNotEmpty || _specialFilters.isNotEmpty || _cabinetFilter != null || _unassignedPosition;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<DataService>(
          builder: (_, ds, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Inventario Componenti'),
              if (ds.isRemote && ds.currentInventory != null)
                Text(
                  ds.currentInventory!.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Esporta lista in PDF',
            onPressed: () => _exportToPdf(results, ds.settings),
          ),
          if (ds.isRemote)
            ds.syncing
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    icon: const Icon(Icons.sync),
                    tooltip: 'Sincronizza',
                    onPressed: () => ds.refreshFromServer(),
                  ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordina',
            onSelected: (val) {
              setState(() {
                if (val.startsWith('sp_')) {
                  _sortMode = SortMode.specialTag;
                  _sortSpecialTag = val.substring(3);
                } else {
                  _sortSpecialTag = null;
                  if (val == 'name') _sortMode = SortMode.name;
                  else if (val == 'quantity') _sortMode = SortMode.quantity;
                  else if (val == 'drawer') _sortMode = SortMode.drawer;
                }
              });
            },
            itemBuilder: (_) => [
              _sortItem('name', 'Per nome', Icons.sort_by_alpha, _sortMode == SortMode.name),
              _sortItem('quantity', 'Per quantità', Icons.format_list_numbered, _sortMode == SortMode.quantity),
              _sortItem('drawer', 'Per cassetto', Icons.inbox, _sortMode == SortMode.drawer),
              if (ds.settings.specialTags.any((st) => !st.isString)) const PopupMenuDivider(),
              ...ds.settings.specialTags.where((st) => !st.isString).map((st) => 
                _sortItem('sp_${st.name}', 'Per ${st.name}', Icons.tune, _sortMode == SortMode.specialTag && _sortSpecialTag == st.name)
              ),
            ],
          ),
        ],
      ),
      body: Column(children: [
        if (ds.isRemote)
          _ServerBanner(
            connected: ds.serverConnected,
            url: ds.serverUrl,
            error: ds.lastError,
            inventoryName: ds.currentInventory?.name,
            inventoryCount: ds.inventories.length,
            onSwitchTap: () {
              DefaultTabController.of(context).animateTo(1);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const InventoryListScreen()));
            },
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(children: [
            Expanded(
              child: SearchBar(
                controller: _searchCtrl,
                hintText: 'Cerca per nome, cassetto…',
                leading: const Icon(Icons.search),
                trailing: _query.isNotEmpty
                    ? [
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      ]
                    : null,
                onChanged: (v) => setState(() => _query = v),
                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
              ),
            ),
            const SizedBox(width: 8),
            if (hasFilter && _query.isEmpty) ...[
              IconButton.filledTonal(
                icon: const Icon(Icons.filter_alt_off),
                color: Theme.of(context).colorScheme.error,
                tooltip: 'Azzera filtri',
                onPressed: () => setState(() {
                  _selectedTags.clear();
                  _specialFilters.clear();
                  _cabinetFilter = null;
                  _unassignedPosition = false;
                }),
              ),
              const SizedBox(width: 8),
            ],
            _FilterButton(
              settings: ds.settings,
              selectedTags: _selectedTags,
              specialFilters: _specialFilters,
              selectedCabinet: _cabinetFilter,
              unassignedPos: _unassignedPosition,
              onChanged: (tags, filters, cab, unassigned) => setState(() {
                _selectedTags   = tags;
                _specialFilters = filters;
                _cabinetFilter  = cab;
                _unassignedPosition = unassigned;
              }),
            ),
          ]),
        ),

        if (_selectedTags.isNotEmpty || _specialFilters.isNotEmpty || _cabinetFilter != null || _unassignedPosition)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                if (_unassignedPosition)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      avatar: const Icon(Icons.location_off_outlined, size: 16),
                      label: const Text('Senza posizione', style: TextStyle(fontWeight: FontWeight.bold)),
                      onDeleted: () => setState(() => _unassignedPosition = false),
                    ),
                  ),
                if (_cabinetFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      avatar: const Icon(Icons.kitchen_outlined, size: 16),
                      label: Text('N° $_cabinetFilter'),
                      onDeleted: () => setState(() => _cabinetFilter = null),
                    ),
                  ),
                ..._selectedTags.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        label: Text(t),
                        onDeleted: () => setState(() {
                          final subtree = _findSubtree(t, ds.settings.tagTree);
                          _removeNodeAndDescendants(t, subtree ?? {}, _selectedTags);
                        }),
                      ),
                    )),
                ..._specialFilters.entries.map((e) {
                  final f = e.value;
                  final st = ds.settings.specialTags.where((s) => s.name == e.key).firstOrNull;
                  final unit = st?.unit ?? '';
                  String labelText = '${e.key}: ';
                  
                  if (f.exact.isNotEmpty) {
                    labelText += _formatValueWithUnit(f.exact, unit);
                  } else if (f.min.isNotEmpty && f.max.isNotEmpty) {
                    labelText += '${_formatValueWithUnit(f.min, unit)} - ${_formatValueWithUnit(f.max, unit)}';
                  } else if (f.min.isNotEmpty) {
                    labelText += '>= ${_formatValueWithUnit(f.min, unit)}';
                  } else if (f.max.isNotEmpty) {
                    labelText += '<= ${_formatValueWithUnit(f.max, unit)}';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text(labelText),
                      onDeleted: () => setState(() => _specialFilters.remove(e.key)),
                    ),
                  );
                }),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Row(children: [
            Text(
              hasFilter
                  ? '${results.length} risultati'
                  : '${results.length} componenti · ${_sortLabel()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ]),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    const Text('Nessun componente trovato'),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: results.length,
                  itemBuilder: (ctx, i) {
                    final comp = results[i];
                    return ComponentTile(
                      component: comp,
                      settings: ds.settings,
                      onTapTile: () => _viewComponent(ctx, comp),
                      onEdit: () => _editComponent(ctx, comp),
                      onDuplicate: () => _duplicateComponent(ctx, comp),
                      onIncrement: () => ds.updateQuantity(comp.id, 1),
                      onDecrement: () => ds.updateQuantity(comp.id, -1),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addComponent(context),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
    );
  }

  Future<void> _showConflictDialog(DataService ds) async {
    final conflict = ds.pendingConflict;
    if (conflict == null) return;

    String formatTs(DateTime? dt) => dt != null 
        ? "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}" 
        : "Sconosciuta";

    final choice = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Conflitto di sincronizzazione'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hai modificato i dati offline, ma il server ha una versione precedente.'),
            const SizedBox(height: 16),
            _ConflictOption(
              icon: Icons.phone_android,
              title: 'Versione Locale (Più recente)',
              subtitle: 'Ultima modifica: ${formatTs(conflict.localTimestamp)}',
            ),
            const SizedBox(height: 8),
            _ConflictOption(
              icon: Icons.cloud,
              title: 'Versione Server',
              subtitle: 'Ultima modifica: ${formatTs(conflict.remoteTimestamp)}',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Usa Server')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usa Locali (Aggiorna Server)')),
        ],
      ),
    );

    if (choice != null) await ds.resolveConflict(choice);
  }

  PopupMenuItem<String> _sortItem(String value, String label, IconData icon, bool isSelected) =>
      PopupMenuItem(
        value: value, 
        child: Row(children: [
          Icon(icon, size: 20), 
          const SizedBox(width: 8), 
          Text(label), 
          if (isSelected) ...[const Spacer(), const Icon(Icons.check, size: 18)]
        ])
      );

  String _sortLabel() {
    if (_sortMode == SortMode.specialTag && _sortSpecialTag != null) {
      return 'Per $_sortSpecialTag';
    }
    return switch (_sortMode) { 
      SortMode.name => 'Per nome', 
      SortMode.quantity => 'Per quantità', 
      SortMode.drawer => 'Per cassetto', 
      _ => '' 
    };
  }

  Future<void> _addComponent(BuildContext context) async {
    final ds = context.read<DataService>();
    final result = await showDialog<Component>(context: context, builder: (_) => ComponentDialog(settings: ds.settings));
    if (result != null) {
      try { await ds.addComponent(result); } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  Future<void> _viewComponent(BuildContext context, Component comp) async {
    final ds = context.read<DataService>();
    await showDialog(
      context: context,
      builder: (ctx) => ComponentViewDialog(
        component: comp,
        settings: ds.settings,
        onEdit: () {
          _editComponent(context, comp);
        },
      ),
    );
  }

  Future<void> _editComponent(BuildContext context, Component comp) async {
    final ds = context.read<DataService>();
    final result = await showDialog<dynamic>(context: context, builder: (_) => ComponentDialog(existing: comp, settings: ds.settings));
    
    if (result is Component) {
      try { 
        await ds.updateComponent(result); 
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    } else if (result == 'DELETE') {
      try { 
        await ds.deleteComponent(comp.id); 
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  Future<void> _duplicateComponent(BuildContext context, Component comp) async {
    final ds = context.read<DataService>();
    final result = await showDialog<dynamic>(context: context, builder: (_) => ComponentDialog(existing: comp, settings: ds.settings, isDuplicate: true));
    
    if (result is Component) {
      try { 
        await ds.addComponent(result); 
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }
}

class _ConflictOption extends StatelessWidget {
  final IconData icon; final String title; final String subtitle;
  const _ConflictOption({required this.icon, required this.title, required this.subtitle});
  @override Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [Icon(icon, color: cs.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))]))]),
    );
  }
}

class _ServerBanner extends StatelessWidget {
  final bool connected;
  final String url;
  final String? error;
  final String? inventoryName;
  final int inventoryCount;
  final VoidCallback? onSwitchTap;

  const _ServerBanner({
    required this.connected,
    required this.url,
    this.error,
    this.inventoryName,
    this.inventoryCount = 1,
    this.onSwitchTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isConnected = connected;

    return GestureDetector(
      onTap: (isConnected && inventoryCount > 1) ? onSwitchTap : null,
      child: Container(
        color: isConnected
            ? Colors.green.withOpacity(0.1)
            : cs.errorContainer.withOpacity(0.6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(children: [
          Icon(
            isConnected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            size: 14,
            color: isConnected ? Colors.green[700] : cs.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isConnected
                      ? (inventoryName != null
                          ? '📦 $inventoryName'
                          : 'Server: \$url')
                      : error != null
                          ? 'Offline · usando dati locali'
                          : 'Server non raggiungibile',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isConnected
                          ? Colors.green[800]
                          : cs.onErrorContainer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isConnected)
                  Text(url,
                      style: TextStyle(
                          fontSize: 10,
                          color: isConnected
                              ? Colors.green[700]!.withOpacity(0.8)
                              : cs.onErrorContainer.withOpacity(0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (isConnected && inventoryCount > 1)
            TextButton.icon(
              onPressed: onSwitchTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: Colors.green[800],
              ),
              icon: const Icon(Icons.swap_horiz, size: 14),
              label: const Text('Cambia', style: TextStyle(fontSize: 11)),
            ),
        ]),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final AppSettings settings;
  final List<String> selectedTags;
  final Map<String, SpecialFilter> specialFilters;
  final int? selectedCabinet;
  final bool unassignedPos;
  final void Function(List<String>, Map<String, SpecialFilter>, int?, bool) onChanged;

  const _FilterButton({
    required this.settings, 
    required this.selectedTags, 
    required this.specialFilters, 
    required this.selectedCabinet,
    required this.unassignedPos,
    required this.onChanged,
  });

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
    final active = selectedTags.isNotEmpty || specialFilters.isNotEmpty || selectedCabinet != null || unassignedPos;
    final cs     = Theme.of(context).colorScheme;
    final count  = selectedTags.length + specialFilters.length + (selectedCabinet != null ? 1 : 0) + (unassignedPos ? 1 : 0);

    return Badge(
      isLabelVisible: active, label: Text('$count'),
      child: IconButton.filled(
        icon: const Icon(Icons.filter_list), tooltip: 'Filtri',
        style: active ? null : IconButton.styleFrom(backgroundColor: cs.surfaceContainerHighest, foregroundColor: cs.onSurface),
        onPressed: () => _showFilterSheet(context),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    List<String> tempTags = List.from(selectedTags);
    int? tempCabinet = selectedCabinet;
    bool tempUnassigned = unassignedPos;
    
    // Configurazione controller per i range
    Map<String, Map<String, TextEditingController>> tempCtrls = {};
    for (final st in settings.specialTags) {
      final f = specialFilters[st.name];
      tempCtrls[st.name] = {
        'exact': TextEditingController(text: f?.exact ?? ''),
        'min': TextEditingController(text: f?.min ?? ''),
        'max': TextEditingController(text: f?.max ?? ''),
      };
    }

    List<String> treePath = [];
    Map<String, dynamic> currentSearch = settings.tagTree;
    while (true) {
      bool found = false;
      for (final key in currentSearch.keys) {
        if (tempTags.contains(key)) {
          treePath.add(key);
          currentSearch = currentSearch[key] as Map<String, dynamic>;
          found = true;
          break;
        }
      }
      if (!found) break;
    }

    bool showLooseTags = false;

    void applyFilters() {
      final activeFilters = <String, SpecialFilter>{};
      tempCtrls.forEach((k, v) { 
        final exact = v['exact']!.text.trim();
        final min = v['min']!.text.trim();
        final max = v['max']!.text.trim();
        if (exact.isNotEmpty || min.isNotEmpty || max.isNotEmpty) {
          activeFilters[k] = SpecialFilter(exact: exact, min: min, max: max);
        }
      });
      onChanged(tempTags, activeFilters, tempCabinet, tempUnassigned);
      Navigator.pop(context);
    }

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) {
          final cs = Theme.of(ctx2).colorScheme;

          Map<String, dynamic> currentTreeLevel = settings.tagTree;
          for (String step in treePath) {
            currentTreeLevel = currentTreeLevel[step] ?? <String, dynamic>{};
          }
          final sortedCurrentLevel = currentTreeLevel.keys.toList()..sort();
          final sortedLoose = List<String>.from(settings.availableTags)..sort();

          return DraggableScrollableSheet(
            initialChildSize: 1.0, minChildSize: 0.5, maxChildSize: 1.0, expand: false,
            builder: (_, sc) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.onSurfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Filtri', style: Theme.of(ctx2).textTheme.titleMedium),
                  TextButton(
                    onPressed: () => setSt(() { 
                      tempTags.clear(); 
                      treePath.clear(); 
                      tempCabinet = null;
                      tempUnassigned = false;
                      for (final grp in tempCtrls.values) {
                        grp['exact']!.clear();
                        grp['min']!.clear();
                        grp['max']!.clear();
                      }
                    }),
                    child: const Text('Rimuovi tutti'),
                  ),
                ]),
                Expanded(
                  child: ListView(controller: sc, children: [
                    
                    SwitchListTile(
                      title: const Text('Mostra solo componenti senza posizione', style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text('Nasconde i componenti a cui è già stato assegnato un cassetto'),
                      value: tempUnassigned,
                      onChanged: (v) => setSt(() => tempUnassigned = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),

                    if (tempTags.isNotEmpty || tempCabinet != null) ...[
                      const SizedBox(height: 8),
                      Text('Tag rapidi', style: Theme.of(ctx2).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6, runSpacing: 10,
                        children: [
                          if (tempCabinet != null)
                            InputChip(
                              avatar: const Icon(Icons.kitchen_outlined, size: 16),
                              label: Text('N° $tempCabinet', style: const TextStyle(fontWeight: FontWeight.bold)),
                              backgroundColor: cs.primaryContainer,
                              onDeleted: () => setSt(() => tempCabinet = null),
                            ),
                          ...tempTags.map((tag) => InputChip(
                            label: Text(tag, style: const TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: cs.primaryContainer,
                            onDeleted: () => setSt(() {
                              final subtree = _findSubtree(tag, settings.tagTree);
                              _removeNodeAndDescendants(tag, subtree ?? {}, tempTags);
                              final idx = treePath.indexOf(tag);
                              if (idx != -1) treePath = treePath.sublist(0, idx);
                            }),
                          )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                    ],

                    if (settings.numCabinets > 1) ...[
                      const SizedBox(height: 12),
                      Text('Cassettiera', style: Theme.of(ctx2).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: List.generate(settings.numCabinets, (i) => i + 1).map((cab) {
                          return ChoiceChip(
                            label: Text('N° $cab'),
                            selected: tempCabinet == cab,
                            selectedColor: cs.primaryContainer,
                            onSelected: (val) {
                              setSt(() => tempCabinet = val ? cab : null);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                    ],

                    if (settings.tagTree.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Naviga nei tag', style: Theme.of(ctx2).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(color: cs.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, runSpacing: 4,
                          children: [
                            ActionChip(label: const Text('Inizio'), avatar: const Icon(Icons.home, size: 16), onPressed: () => setSt(() => treePath.clear())),
                            for (int i = 0; i < treePath.length; i++) ...[
                              const Icon(Icons.chevron_right, size: 16),
                              ActionChip(label: Text(treePath[i]), onPressed: () => setSt(() => treePath = treePath.sublist(0, i + 1))),
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
                            final isSelected = tempTags.contains(t);
                            return ChoiceChip(
                              label: Text(t),
                              selected: isSelected,
                              selectedColor: cs.primaryContainer,
                              onSelected: (sel) {
                                if (!sel) return;
                                setSt(() {
                                  final siblings = sortedCurrentLevel.where((k) => k != t);
                                  for (final s in siblings) {
                                    if (tempTags.contains(s)) {
                                      _removeNodeAndDescendants(s, currentTreeLevel[s], tempTags);
                                    }
                                  }
                                  if (!tempTags.contains(t)) tempTags.add(t);
                                  treePath.add(t);
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],

                    if (sortedLoose.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: Icon(showLooseTags ? Icons.expand_less : Icons.expand_more),
                        label: const Text('Mostra tag generici (sfusi)'),
                        onPressed: () => setSt(() => showLooseTags = !showLooseTags),
                      ),
                      if (showLooseTags) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8, runSpacing: 12,
                          children: sortedLoose.map((tag) {
                            final sel = tempTags.contains(tag);
                            return FilterChip(
                              label: Text(tag), selected: sel, selectedColor: cs.primaryContainer, backgroundColor: cs.surfaceContainerHighest,
                              onSelected: (v) => setSt(() => v ? tempTags.add(tag) : tempTags.remove(tag)),
                            );
                          }).toList(),
                        ),
                      ],
                    ],

                    if (settings.specialTags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Filtri per Proprietà', style: Theme.of(ctx2).textTheme.labelLarge),
                      ...settings.specialTags.map((st) {
                        final grp = tempCtrls[st.name]!;
                        final unit = st.unit.isNotEmpty ? ' (${st.unit})' : '';
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${st.name}$unit', style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              if (st.isString)
                                TextField(
                                  controller: grp['exact'],
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(labelText: 'Contiene testo...', border: OutlineInputBorder(), isDense: true),
                                  onSubmitted: (_) => applyFilters(),
                                )
                              else ...[
                                TextField(
                                  controller: grp['exact'],
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(labelText: 'Valore esatto', border: OutlineInputBorder(), isDense: true),
                                  onSubmitted: (_) => applyFilters(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: grp['min'],
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(labelText: 'Da (min)', border: OutlineInputBorder(), isDense: true),
                                        onSubmitted: (_) => applyFilters(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: grp['max'],
                                        textInputAction: TextInputAction.done,
                                        decoration: const InputDecoration(labelText: 'A (max)', border: OutlineInputBorder(), isDense: true),
                                        onSubmitted: (_) => applyFilters(),
                                      ),
                                    ),
                                  ],
                                ),
                              ]
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 20),
                  ]),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: applyFilters,
                    child: const Text('Applica filtri'),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}