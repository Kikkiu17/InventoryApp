import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/search_result.dart';
import '../services/data_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/global_search_delegate.dart';

/// Schermata per visualizzare, selezionare, creare, rinominare ed eliminare
/// gli inventari presenti sul server, con barra di ricerca globale in tempo reale.
class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounceTimer;
  bool _isSearching = false;
  List<GlobalSearchResult>? _searchResults;
  Object? _searchError;
  int _searchVersion = 0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String val) {
    final trimmed = val.trim();
    if (trimmed == _query && _searchResults != null) return;

    _debounceTimer?.cancel();
    setState(() {
      _query = trimmed;
      if (_query.isEmpty) {
        _isSearching = false;
        _searchResults = null;
        _searchError = null;
      } else {
        _isSearching = true;
      }
    });

    if (trimmed.isEmpty) return;

    final currentVersion = ++_searchVersion;
    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      final ds = context.read<DataService>();
      try {
        final results = await ds.globalSearch(trimmed);
        if (!mounted || currentVersion != _searchVersion) return;
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _searchError = null;
        });
      } catch (e) {
        if (!mounted || currentVersion != _searchVersion) return;
        setState(() {
          _searchError = e;
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds    = context.watch<DataService>();
    final l10n  = context.l10n;
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.inventoriesTitle),
            if (ds.isRemote && ds.serverConnected)
              Text(
                ds.serverUrl,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: l10n.exportPdfTooltip,
            onPressed: (_query.isNotEmpty &&
                    !_isSearching &&
                    _searchResults != null &&
                    _searchResults!.isNotEmpty)
                ? () => PdfExportService.exportGlobalSearchResults(
                      context: context,
                      items: _searchResults!,
                      settings: ds.settings,
                      query: _query,
                    )
                : null,
          ),
          if (ds.isRemote && ds.serverConnected)
            IconButton(
              icon: ds.syncing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              tooltip: l10n.refreshList,
              onPressed: ds.syncing ? null : () => ds.refreshInventoryList(),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: SizedBox(
              height: 40,
              child: SearchBar(
                controller: _searchCtrl,
                hintText: l10n.searchAllInventoriesPlaceholder,
                leading: const Icon(Icons.search, size: 18),
                trailing: [
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: l10n.clear,
                      onPressed: () {
                        _searchCtrl.clear();
                        _onQueryChanged('');
                      },
                    ),
                ],
                onChanged: _onQueryChanged,
                elevation: const WidgetStatePropertyAll(0),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? _buildNormalBody(ds, cs, l10n)
                : _buildSearchResults(context, ds, cs, theme, l10n),
          ),
        ],
      ),
      floatingActionButton: _query.isEmpty && ds.isRemote && ds.serverConnected
          ? FloatingActionButton.extended(
              heroTag: 'fab_inventories',
              onPressed: () => _showCreateDialog(context, ds),
              icon: const Icon(Icons.add),
              label: Text(l10n.newInventory),
            )
          : null,
    );
  }

  Widget _buildNormalBody(DataService ds, ColorScheme cs, AppLocalizations l10n) {
    if (!ds.isRemote) {
      return _Placeholder(
        icon: Icons.cloud_off_outlined,
        title: l10n.localModeTitle,
        subtitle: l10n.localModeDesc,
        cs: cs,
      );
    } else if (ds.syncing && ds.inventories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } else if (!ds.serverConnected && ds.inventories.isEmpty) {
      return _Placeholder(
        icon: Icons.wifi_off_rounded,
        title: l10n.serverUnreachableTitle,
        subtitle: l10n.serverUnreachableDesc,
        cs: cs,
        action: FilledButton.icon(
          onPressed: () => ds.refreshFromServer(),
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retry),
        ),
      );
    } else if (ds.inventories.isEmpty) {
      return _Placeholder(
        icon: Icons.inventory_2_outlined,
        title: l10n.noInventoriesTitle,
        subtitle: l10n.noInventoriesDesc,
        cs: cs,
        action: FilledButton.icon(
          onPressed: () => _showCreateDialog(context, ds),
          icon: const Icon(Icons.add),
          label: Text(l10n.createInventory),
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
        itemCount: ds.inventories.length,
        itemBuilder: (ctx, i) {
          final inv       = ds.inventories[i];
          final isCurrent = inv.id == ds.currentInventoryId;
          return _InventoryCard(
            inv:       inv,
            isCurrent: isCurrent,
            canDelete: ds.inventories.length > 1,
            onSelect:  () => _selectInventory(context, ds, inv.id),
            onRename:  () => _showRenameDialog(context, ds, inv),
            onDelete:  () => _confirmDelete(context, ds, inv),
          );
        },
      );
    }
  }

  Widget _buildSearchResults(
      BuildContext context, DataService ds, ColorScheme cs, ThemeData theme, AppLocalizations l10n) {
    if (_isSearching && _searchResults == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(
                l10n.searchError('$_searchError'),
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.error),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _onQueryChanged(_searchCtrl.text),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final allResults = _searchResults ?? [];
    final matchingInventories = ds.inventories
        .where((inv) =>
            inv.name.toLowerCase().contains(_query.toLowerCase()) ||
            inv.description.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final inventoryResults =
        allResults.where((r) => r.inventoryId != '_buffer_').toList();
    final bufferResults =
        allResults.where((r) => r.inventoryId == '_buffer_').toList();

    if (matchingInventories.isEmpty &&
        inventoryResults.isEmpty &&
        bufferResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off,
                  size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                l10n.noResults,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noResultsDescription(_query),
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
      children: [
        if (_isSearching) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
        ],
        if (matchingInventories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Text(
              'INVENTARI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
                color: cs.primary,
              ),
            ),
          ),
          ...matchingInventories.map((inv) {
            final isCurrent = inv.id == ds.currentInventoryId;
            return _InventoryCard(
              inv: inv,
              isCurrent: isCurrent,
              canDelete: ds.inventories.length > 1,
              onSelect: () => _selectInventory(context, ds, inv.id),
              onRename: () => _showRenameDialog(context, ds, inv),
              onDelete: () => _confirmDelete(context, ds, inv),
            );
          }),
        ],
        if (matchingInventories.isNotEmpty &&
            (inventoryResults.isNotEmpty || bufferResults.isNotEmpty)) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, thickness: 1),
          ),
        ],
        if (inventoryResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Text(
              l10n.inventoryComponentsSectionHeader,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
                color: cs.primary,
              ),
            ),
          ),
          ...inventoryResults.map((res) => GlobalSearchResultTile(
                res: res,
                query: _query,
              )),
        ],
        if (inventoryResults.isNotEmpty && bufferResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, thickness: 1),
          ),
        ],
        if (bufferResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Text(
              l10n.bufferComponentsSectionHeader,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
                color: cs.secondary,
              ),
            ),
          ),
          ...bufferResults.map((res) => GlobalSearchResultTile(
                res: res,
                query: _query,
              )),
        ],
      ],
    );
  }

  // ── Seleziona ───────────────────────────────────────────────────────────────
  Future<void> _selectInventory(
      BuildContext context, DataService ds, String id) async {
    final l10n = context.l10n;
    if (id == ds.currentInventoryId) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.inventoryAlreadyActive),
          behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      await ds.switchInventory(id);
      if (context.mounted) {
        final name = ds.currentInventory?.name ?? id;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.switchedToInventory(name)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        final l10nErr = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10nErr.error}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  // ── Crea ────────────────────────────────────────────────────────────────────
  Future<void> _showCreateDialog(BuildContext context, DataService ds) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newInventory),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
                labelText: l10n.nameRequired, border: const OutlineInputBorder()),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            decoration: InputDecoration(
                labelText: l10n.descriptionOptional,
                border: const OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.create)),
        ],
      ),
    );

    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    try {
      final created = await ds.createInventory(name,
          description: descCtrl.text.trim());
      await ds.switchInventory(created.id);
      if (context.mounted) {
        final l10nSuccess = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10nSuccess.inventoryCreatedAndSelected(name)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        final l10nErr = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10nErr.error}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  // ── Rinomina ────────────────────────────────────────────────────────────────
  Future<void> _showRenameDialog(
      BuildContext context, DataService ds, InventoryMeta inv) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController(text: inv.name);
    final descCtrl = TextEditingController(text: inv.description);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.renameInventoryTitle),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
                labelText: l10n.nameLabel, border: const OutlineInputBorder()),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            decoration: InputDecoration(
                labelText: l10n.descriptionOptional, border: const OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.save)),
        ],
      ),
    );

    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      await ds.renameInventory(inv.id, name,
          description: descCtrl.text.trim());
    } catch (e) {
      if (context.mounted) {
        final l10nErr = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10nErr.error}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  // ── Elimina ─────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(
      BuildContext context, DataService ds, InventoryMeta inv) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteInventoryTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteInventoryConfirm(inv.name)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded,
                    color: Theme.of(ctx).colorScheme.onErrorContainer,
                    size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.deleteInventoryPermanentWarning,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(ctx).colorScheme.onErrorContainer),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await ds.deleteInventory(inv.id);
    } catch (e) {
      if (context.mounted) {
        final l10nErr = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10nErr.error}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }
}

// ── Card inventario ─────────────────────────────────────────────────────────
class _InventoryCard extends StatelessWidget {
  final InventoryMeta inv;
  final bool isCurrent;
  final bool canDelete;
  final VoidCallback onSelect;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _InventoryCard({
    required this.inv,
    required this.isCurrent,
    required this.canDelete,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n  = context.l10n;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isCurrent
            ? BorderSide(color: cs.primary, width: 2.5)
            : BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      elevation: isCurrent ? 2 : 0,
      color: isCurrent ? cs.primaryContainer.withOpacity(0.25) : cs.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            // Icona
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isCurrent ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCurrent ? Icons.inventory_2 : Icons.inventory_2_outlined,
                color: isCurrent ? cs.onPrimary : cs.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        inv.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCurrent ? cs.primary : null,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(l10n.activeBadge,
                            style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  if (inv.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(inv.description,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 3),
                  Text('ID: ${inv.id}',
                      style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withOpacity(0.5))),
                ],
              ),
            ),
            // Menu azioni
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
              tooltip: l10n.actions,
              onSelected: (v) {
                if (v == 'rename') onRename();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Row(children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(l10n.renameAction),
                  ]),
                ),
                if (canDelete)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 10),
                      Text(l10n.delete,
                          style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.error)),
                    ]),
                  ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Placeholder ─────────────────────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme cs;
  final Widget? action;

  const _Placeholder({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cs,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 64, color: cs.onSurfaceVariant.withOpacity(0.35)),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ]),
        ),
      );
}
