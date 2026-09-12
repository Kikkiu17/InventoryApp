import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/search_result.dart';
import '../models/settings.dart';
import '../services/data_service.dart';
import 'component_view_dialog.dart';
import '../main.dart';

class GlobalSearchDelegate extends SearchDelegate<void> {
  final DataService ds;
  Future<List<GlobalSearchResult>>? _searchFuture;
  String? _lastQuery;

  GlobalSearchDelegate(this.ds);

  @override
  String? get searchFieldLabel =>
      AppLocalizations.current.searchAllInventoriesPlaceholder;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final l10n = context.l10n;
    if (query.trim().isEmpty) return const SizedBox();

    if (_lastQuery != query) {
      _lastQuery = query;
      _searchFuture = ds.globalSearch(query);
    }

    return FutureBuilder<List<GlobalSearchResult>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${l10n.error}: ${snapshot.error}'));
        }

        final allResults = snapshot.data ?? [];
        final inventoryResults = allResults.where((r) => r.inventoryId != '_buffer_').toList();
        final bufferResults = allResults.where((r) => r.inventoryId == '_buffer_').toList();

        if (inventoryResults.isEmpty && bufferResults.isEmpty) {
          return Center(child: Text(l10n.noComponentsFound));
        }

        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        return ListView(
          children: [
            if (inventoryResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    query: query,
                    ds: ds,
                    onBeforeNavigate: () => close(context, null),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    query: query,
                    ds: ds,
                    onBeforeNavigate: () => close(context, null),
                  )),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(
        child: Text(context.l10n.searchInAllInventories),
      );
    }
    return buildResults(context);
  }
}

class GlobalSearchResultTile extends StatelessWidget {
  final GlobalSearchResult res;
  final String query;
  final DataService? ds;
  final VoidCallback? onBeforeNavigate;

  const GlobalSearchResultTile({
    super.key,
    required this.res,
    required this.query,
    this.ds,
    this.onBeforeNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final effectiveDs = ds ?? context.read<DataService>();
    final c = res.component;
    final isBuffer = res.inventoryId == '_buffer_';
    final cs = Theme.of(context).colorScheme;

    // Resolve property definitions for this component's inventory
    final availableSpecialTags = res.specialTags ??
        effectiveDs.getSpecialTagsForInventory(res.inventoryId) ??
        effectiveDs.settings.specialTags;

    // Filter properties with non-empty value and configured short identifier
    final shortProperties = <MapEntry<SpecialTag, String>>[];
    for (final entry in c.specialTagValues.entries) {
      final val = entry.value.trim();
      if (val.isEmpty) continue;
      final st =
          availableSpecialTags.where((s) => s.name == entry.key).firstOrNull;
      if (st != null && st.shortId.trim().isNotEmpty) {
        shortProperties.add(MapEntry(st, val));
      }
    }

    return ListTile(
      leading: Icon(
        isBuffer ? Icons.inbox : Icons.memory,
        color: isBuffer ? cs.secondary : cs.primary,
      ),
      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBuffer
                ? (c.description.isNotEmpty ? c.description : l10n.noDescription)
                : '${c.drawer.isEmpty ? l10n.unassignedDrawerShort : c.drawer}${c.description.isNotEmpty ? " • ${c.description}" : ""}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (c.tags.isNotEmpty || shortProperties.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ...c.tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                )),
                ...shortProperties.map((entry) {
                  final st = entry.key;
                  final val = entry.value;
                  final formattedVal = formatValueWithUnit(val, st.unit);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${st.shortId}: $formattedVal',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isBuffer ? cs.secondaryContainer : cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              res.inventoryName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isBuffer ? cs.onSecondaryContainer : cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: c.quantity == 0
                  ? cs.errorContainer.withValues(alpha: 0.6)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.qtyShort(c.quantity),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: c.quantity == 0 ? cs.error : cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      onTap: () async {
        try {
          final mainContext = globalMainShellKey.currentContext;
          if (isBuffer) {
            if (context.mounted && mainContext != null) {
              ScaffoldMessenger.of(mainContext).showSnackBar(SnackBar(
                content: Text(l10n.passedToBuffer),
                behavior: SnackBarBehavior.floating,
              ));
              onBeforeNavigate?.call();
              
              // Passa alla tab Buffer (indice 1)
              globalMainShellKey.currentState?.switchTab(1);
              
              // Mostra il ComponentViewDialog
              showDialog(
                context: mainContext,
                builder: (ctx) => ComponentViewDialog(
                  component: c,
                  settings: effectiveDs.settings,
                  onEdit: () {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(l10n.editComponentDirectlyFromList),
                    ));
                  },
                ),
              );
            }
          } else {
            await effectiveDs.switchInventory(res.inventoryId);
            effectiveDs.setGlobalSearchQuery(query);
            if (context.mounted && mainContext != null) {
              ScaffoldMessenger.of(mainContext).showSnackBar(SnackBar(
                content: Text(l10n.switchedToInventory(res.inventoryName)),
                behavior: SnackBarBehavior.floating,
              ));
              onBeforeNavigate?.call();
              
              // Passa alla tab Home
              globalMainShellKey.currentState?.switchTab(0);
              
              // Mostra il ComponentViewDialog
              showDialog(
                context: mainContext,
                builder: (ctx) => ComponentViewDialog(
                  component: c,
                  settings: effectiveDs.settings,
                  onEdit: () {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(l10n.editComponentDirectlyFromList),
                    ));
                  },
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
          }
        }
      },
    );
  }
}
