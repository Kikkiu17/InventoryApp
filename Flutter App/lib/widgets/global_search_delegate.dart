import 'package:flutter/material.dart';

import '../models/search_result.dart';
import '../services/data_service.dart';
import 'component_view_dialog.dart';
import '../main.dart';

class GlobalSearchDelegate extends SearchDelegate<void> {
  final DataService ds;
  Future<List<GlobalSearchResult>>? _searchFuture;
  String? _lastQuery;

  GlobalSearchDelegate(this.ds) : super(searchFieldLabel: 'Cerca in tutti gli inventari...');

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
          return Center(child: Text('Errore: ${snapshot.error}'));
        }

        final allResults = snapshot.data ?? [];
        final inventoryResults = allResults.where((r) => r.inventoryId != '_buffer_').toList();
        final bufferResults = allResults.where((r) => r.inventoryId == '_buffer_').toList();

        if (inventoryResults.isEmpty && bufferResults.isEmpty) {
          return const Center(child: Text('Nessun componente trovato.'));
        }

        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        return ListView(
          children: [
            if (inventoryResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'COMPONENTI INVENTARI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: cs.primary,
                  ),
                ),
              ),
              ...inventoryResults.map((res) => _buildResultTile(context, res)),
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
                  'COMPONENTI BUFFER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: cs.secondary,
                  ),
                ),
              ),
              ...bufferResults.map((res) => _buildResultTile(context, res)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildResultTile(BuildContext context, GlobalSearchResult res) {
    final c = res.component;
    final isBuffer = res.inventoryId == '_buffer_';
    return ListTile(
      leading: Icon(
        isBuffer ? Icons.inbox : Icons.memory,
        color: isBuffer
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBuffer
                ? (c.description.isNotEmpty ? c.description : "Nessuna descrizione")
                : '${c.drawer.isEmpty ? "Non ass." : c.drawer}${c.description.isNotEmpty ? " • ${c.description}" : ""}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (c.tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: c.tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isBuffer
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          res.inventoryName,
          style: TextStyle(
            fontSize: 10,
            color: isBuffer
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      onTap: () async {
        try {
          final mainContext = globalMainShellKey.currentContext;
          if (isBuffer) {
            if (context.mounted && mainContext != null) {
              ScaffoldMessenger.of(mainContext).showSnackBar(const SnackBar(
                content: Text('Passato al Buffer'),
                behavior: SnackBarBehavior.floating,
              ));
              close(context, null); // chiude la ricerca
              
              // Passa alla tab Buffer (indice 1)
              globalMainShellKey.currentState?.switchTab(1);
              
              // Mostra il ComponentViewDialog
              showDialog(
                context: mainContext,
                builder: (ctx) => ComponentViewDialog(
                  component: c,
                  settings: ds.settings,
                  onEdit: () {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Modifica il componente direttamente dalla lista.'),
                    ));
                  },
                ),
              );
            }
          } else {
            await ds.switchInventory(res.inventoryId);
            ds.setGlobalSearchQuery(query);
            if (context.mounted && mainContext != null) {
              ScaffoldMessenger.of(mainContext).showSnackBar(SnackBar(
                content: Text('Passato all\'inventario "${res.inventoryName}"'),
                behavior: SnackBarBehavior.floating,
              ));
              close(context, null); // chiude la ricerca
              
              // Passa alla tab Home
              globalMainShellKey.currentState?.switchTab(0);
              
              // Mostra il ComponentViewDialog
              showDialog(
                context: mainContext,
                builder: (ctx) => ComponentViewDialog(
                  component: c,
                  settings: ds.settings,
                  onEdit: () {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Modifica il componente direttamente dalla lista.'),
                    ));
                  },
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
          }
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Cerca componenti in tutti gli inventari.'),
    );
  }
}
