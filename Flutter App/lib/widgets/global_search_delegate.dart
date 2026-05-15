import 'package:flutter/material.dart';

import '../models/search_result.dart';
import '../services/data_service.dart';
import 'component_view_dialog.dart';
import '../main.dart';

class GlobalSearchDelegate extends SearchDelegate<void> {
  final DataService ds;

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

    return FutureBuilder<List<GlobalSearchResult>>(
      future: ds.globalSearch(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('Nessun componente trovato.'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final res = results[index];
            final c = res.component;
            return ListTile(
              leading: Icon(Icons.memory, color: Theme.of(context).colorScheme.primary),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${c.drawer.isEmpty ? "Non ass." : c.drawer} • ${c.description}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  res.inventoryName,
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              onTap: () async {
                // Seleziona l'inventario
                try {
                  await ds.switchInventory(res.inventoryId);
                  
                  // Imposta la query di ricerca per popolare la HomeScreen
                  ds.setGlobalSearchQuery(query);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Passato all\'inventario "${res.inventoryName}"'),
                      behavior: SnackBarBehavior.floating,
                    ));
                    close(context, null); // chiude la ricerca
                    
                    // Passa alla tab Home
                    globalMainShellKey.currentState?.switchTab(0);
                    
                    // Mostra il ComponentViewDialog
                    showDialog(
                      context: context,
                      builder: (ctx) => ComponentViewDialog(
                        component: c,
                        settings: ds.settings,
                        onEdit: () {
                          // Dato che siamo già in HomeScreen (avendo cambiato tab),
                          // l'utente può semplicemente chiudere il dialog e cercare il componente.
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Modifica il componente direttamente dalla lista.'),
                          ));
                        },
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
                  }
                }
              },
            );
          },
        );
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
