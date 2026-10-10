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
import '../services/update_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/component_tile.dart';
import '../widgets/component_dialog.dart';
import '../widgets/component_view_dialog.dart';
import '../widgets/cabinet_map_view.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isShowingConflict = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  List<String> _selectedTags = [];
  SortMode _sortMode = SortMode.name;
  String? _sortSpecialTag; 
  bool _sortAscending = true;
  Map<String, SpecialFilter> _specialFilters = {};
  int? _cabinetFilter; 
  bool _unassignedPosition = false;
  String _viewMode = 'list';
  
  String _lastInventoryId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkAndPromptUpdate(context);
      final ds = context.read<DataService>();
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
  Future<void> _exportToPdf(List<Component> items, AppSettings settings, [String? title]) async {
    await PdfExportService.exportComponents(
      context: context,
      items: items,
      settings: settings,
      title: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final l10n = context.l10n;

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

    final results = ds.search(_query, _selectedTags, _sortMode, _specialFilters, _sortSpecialTag, _cabinetFilter, _unassignedPosition, _sortAscending);
    final hasFilter = _query.isNotEmpty || _selectedTags.isNotEmpty || _specialFilters.isNotEmpty || _cabinetFilter != null || _unassignedPosition;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'list',
                icon: const Icon(Icons.list, size: 20),
                tooltip: l10n.viewList,
              ),
              ButtonSegment<String>(
                value: 'map',
                icon: const Icon(Icons.grid_view, size: 20),
                tooltip: l10n.viewMap,
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (newSelection) {
              setState(() {
                _viewMode = newSelection.first;
              });
            },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        actions: [
          ValueListenableBuilder<UpdateInfo?>(
            valueListenable: UpdateService.availableUpdateNotifier,
            builder: (context, updateInfo, _) {
              if (updateInfo == null || !updateInfo.hasUpdate) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Badge(
                  backgroundColor: cs.primary,
                  smallSize: 8,
                  child: Icon(Icons.system_update_alt, color: cs.primary),
                ),
                tooltip:
                    l10n.updateAvailableBadge(updateInfo.latestVersion),
                onPressed: () =>
                    UpdateService.showUpdateDialog(context, updateInfo),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: l10n.exportPdfTooltip,
            onPressed: () => _exportToPdf(
              results,
              ds.settings,
              ds.currentInventory?.name,
            ),
          ),
          if (ds.isRemote)
            ds.syncing
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    icon: const Icon(Icons.sync),
                    tooltip: l10n.sync,
                    onPressed: () => ds.refreshFromServer(),
                  ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sortTitle,
            onSelected: (val) {
              setState(() {
                if (val == 'toggle_direction') {
                  _sortAscending = !_sortAscending;
                } else if (val.startsWith('sp_')) {
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
              _sortItem('name', l10n.sortName, Icons.sort_by_alpha, _sortMode == SortMode.name),
              _sortItem('quantity', l10n.sortQuantity, Icons.format_list_numbered, _sortMode == SortMode.quantity),
              _sortItem('drawer', l10n.sortDrawer, Icons.inbox, _sortMode == SortMode.drawer),
              if (ds.settings.specialTags.any((st) => !st.isString)) const PopupMenuDivider(),
              ...ds.settings.specialTags.where((st) => !st.isString).map((st) => 
                _sortItem('sp_${st.name}', '${l10n.sortBy} ${st.name}', Icons.tune, _sortMode == SortMode.specialTag && _sortSpecialTag == st.name)
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'toggle_direction',
                child: Row(
                  children: [
                    Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 20),
                    const SizedBox(width: 8),
                    Text(_sortAscending ? l10n.sortAscending : l10n.sortDescending),
                  ],
                ),
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
              showDialog(
                context: context,
                builder: (context) {
                  return Consumer<DataService>(
                    builder: (context, ds, _) {
                      return AlertDialog(
                        title: Text(l10n.selectInventory),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: ds.inventories.length,
                            itemBuilder: (context, index) {
                              final inv = ds.inventories[index];
                              final isCurrent = inv.id == ds.currentInventoryId;
                              return ListTile(
                                leading: Icon(
                                  isCurrent ? Icons.inventory_2 : Icons.inventory_2_outlined,
                                  color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                                ),
                                title: Text(
                                  inv.name,
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: isCurrent ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                                onTap: () async {
                                  Navigator.pop(context);
                                  try {
                                    await ds.switchInventory(inv.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.errorChangingInventory(e.toString()))),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.close),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),



        if (_viewMode == 'map')
          Expanded(
            child: CabinetMapView(
              settings: ds.settings,
              dataService: ds,
              onViewComponent: (comp) => _viewComponent(context, comp),
              onEditComponent: (comp) => _editComponent(context, comp),
              onAddComponentAt: (cabinetId, drawerLabel, zoneIndex) async {
                final result = await showDialog<Component>(
                  context: context,
                  builder: (_) => ComponentDialog(
                    settings: ds.settings,
                    prefilledCabinet: cabinetId,
                    prefilledDrawer: drawerLabel,
                    prefilledDrawerZone: zoneIndex,
                  ),
                );
                if (result != null) {
                  try {
                    await ds.addComponent(result);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${l10n.error}: $e')),
                      );
                    }
                  }
                }
              },
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: SearchBar(
                    controller: _searchCtrl,
                    hintText: l10n.searchPlaceholder,
                    leading: const Icon(Icons.search, size: 18),
                    trailing: _query.isNotEmpty
                        ? [
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          ]
                        : null,
                    onChanged: (v) => setState(() => _query = v),
                    elevation: const WidgetStatePropertyAll(0),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                      ),
                    ),
                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (hasFilter && _query.isEmpty) ...[
                IconButton.filledTonal(
                  icon: const Icon(Icons.filter_alt_off),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: l10n.clearFilters,
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
                        label: Text(l10n.filterUnassigned, style: const TextStyle(fontWeight: FontWeight.bold)),
                        onDeleted: () => setState(() => _unassignedPosition = false),
                      ),
                    ),
                  if (_cabinetFilter != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        avatar: const Icon(Icons.kitchen_outlined, size: 16),
                        label: Text(() {
                          final container = ds.settings.containers.firstWhere(
                            (c) => c.id == _cabinetFilter,
                            orElse: () => ContainerConfig(id: _cabinetFilter!, name: '${l10n.cabinetContainer} $_cabinetFilter', rows: 4, columns: 6),
                          );
                          return container.name.isNotEmpty ? container.name : '${l10n.cabinetContainer} ${container.id}';
                        }()),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!ds.isRemote) ...[
                  Expanded(
                    child: Text(
                      ds.currentInventory?.name ?? l10n.tabInventory,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  hasFilter
                      ? l10n.resultsCount(results.length)
                      : '${l10n.componentsCount(results.length)} · ${_sortLabel(l10n)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text(l10n.noComponentsFound),
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
        ],
      ]),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_home',
        onPressed: () => _addComponent(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.add),
      ),
    );
  }

  Future<void> _showConflictDialog(DataService ds) async {
    final conflict = ds.pendingConflict;
    if (conflict == null) return;
    final l10n = context.l10n;

    String formatTs(DateTime? dt) => dt != null 
        ? "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}" 
        : l10n.none;

    final choice = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.conflictTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.conflictDesc),
            const SizedBox(height: 16),
            _ConflictOption(
              icon: Icons.phone_android,
              title: l10n.useLocal,
              subtitle: formatTs(conflict.localTimestamp),
            ),
            const SizedBox(height: 8),
            _ConflictOption(
              icon: Icons.cloud,
              title: l10n.useRemote,
              subtitle: formatTs(conflict.remoteTimestamp),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.useRemote)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.useLocal)),
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

  String _sortLabel(AppLocalizations l10n) {
    String label = '';
    if (_sortMode == SortMode.specialTag && _sortSpecialTag != null) {
      label = '${l10n.sortBy} $_sortSpecialTag';
    } else {
      label = switch (_sortMode) { 
        SortMode.name => l10n.sortName, 
        SortMode.quantity => l10n.sortQuantity, 
        SortMode.drawer => l10n.sortDrawer, 
        _ => '' 
      };
    }
    return _sortAscending ? '$label (${l10n.sortAscending})' : '$label (${l10n.sortDescending})';
  }

  Future<void> _addComponent(BuildContext context) async {
    final ds = context.read<DataService>();
    final result = await showDialog<Component>(context: context, builder: (_) => ComponentDialog(settings: ds.settings));
    if (result != null) {
      try { await ds.addComponent(result); } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
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
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
      }
    } else if (result == 'DELETE') {
      try { 
        await ds.deleteComponent(comp.id); 
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
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
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
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
    final l10n = context.l10n;
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
                  inventoryName ?? (isConnected ? 'Server' : 'Offline'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isConnected
                          ? Colors.green[800]
                          : cs.onErrorContainer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isConnected)
                  Text(
                    error ?? l10n.offlineUsingLocal,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onErrorContainer.withOpacity(0.7)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
              label: Text(l10n.switchButton, style: const TextStyle(fontSize: 11)),
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
    final l10n   = context.l10n;
    final count  = selectedTags.length + specialFilters.length + (selectedCabinet != null ? 1 : 0) + (unassignedPos ? 1 : 0);

    return Badge(
      isLabelVisible: active, label: Text('$count'),
      child: IconButton.filled(
        icon: const Icon(Icons.filter_list), tooltip: l10n.filterAll,
        style: active ? null : IconButton.styleFrom(backgroundColor: cs.surfaceContainerHighest, foregroundColor: cs.onSurface),
        onPressed: () => _showFilterSheet(context),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final l10n = context.l10n;
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
                  Text(l10n.filterAll, style: Theme.of(ctx2).textTheme.titleMedium),
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
                    child: Text(l10n.filterRemoveAll),
                  ),
                ]),
                Expanded(
                  child: ListView(controller: sc, children: [
                    
                    SwitchListTile(
                      title: Text(l10n.filterOnlyUnassigned, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(l10n.filterOnlyUnassignedDesc),
                      value: tempUnassigned,
                      onChanged: (v) => setSt(() => tempUnassigned = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),

                    if (tempTags.isNotEmpty || tempCabinet != null) ...[
                      const SizedBox(height: 8),
                      Text(l10n.quickTags, style: Theme.of(ctx2).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
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

                    if (settings.containers.length > 1) ...[
                      const SizedBox(height: 12),
                      Text(l10n.cabinetContainer, style: Theme.of(ctx2).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: settings.containers.map((container) {
                          final labelText = container.name.isNotEmpty ? container.name : '${l10n.cabinetContainer} ${container.id}';
                          return ChoiceChip(
                            label: Text(labelText),
                            selected: tempCabinet == container.id,
                            selectedColor: cs.primaryContainer,
                            onSelected: (val) {
                              setSt(() => tempCabinet = val ? container.id : null);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                    ],

                    if (settings.tagTree.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(l10n.navigateTagTree, style: Theme.of(ctx2).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(color: cs.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, runSpacing: 4,
                          children: [
                            ActionChip(label: Text(l10n.tagTreeRoot), avatar: const Icon(Icons.home, size: 16), onPressed: () => setSt(() => treePath.clear())),
                            for (int i = 0; i < treePath.length; i++) ...[
                              const Icon(Icons.chevron_right, size: 16),
                              ActionChip(label: Text(treePath[i]), onPressed: () => setSt(() => treePath = treePath.sublist(0, i + 1))),
                            ]
                          ]
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (sortedCurrentLevel.isEmpty)
                        Text(l10n.noSubtags, style: TextStyle(fontStyle: FontStyle.italic, color: cs.onSurfaceVariant))
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
                        label: Text(l10n.showGenericTags),
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
                      Text(l10n.propertyFilters, style: Theme.of(ctx2).textTheme.labelLarge),
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
                                  decoration: InputDecoration(labelText: l10n.containsText, border: const OutlineInputBorder(), isDense: true),
                                  onSubmitted: (_) => applyFilters(),
                                )
                              else ...[
                                TextField(
                                  controller: grp['exact'],
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(labelText: l10n.exactValue, border: const OutlineInputBorder(), isDense: true),
                                  onSubmitted: (_) => applyFilters(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: grp['min'],
                                        textInputAction: TextInputAction.next,
                                        decoration: InputDecoration(labelText: l10n.fromMin, border: const OutlineInputBorder(), isDense: true),
                                        onSubmitted: (_) => applyFilters(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: grp['max'],
                                        textInputAction: TextInputAction.done,
                                        decoration: InputDecoration(labelText: l10n.toMax, border: const OutlineInputBorder(), isDense: true),
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
                    child: Text(l10n.applyFilters),
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