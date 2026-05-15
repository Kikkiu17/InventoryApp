import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../widgets/global_search_delegate.dart';

/// Schermata per visualizzare, selezionare, creare, rinominare ed eliminare
/// gli inventari presenti sul server.
class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds    = context.watch<DataService>();
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    Widget body;

    if (!ds.isRemote) {
      body = _Placeholder(
        icon: Icons.cloud_off_outlined,
        title: 'Modalità locale',
        subtitle: 'Attiva il server remoto nelle Impostazioni per gestire più inventari.',
        cs: cs,
      );
    } else if (ds.syncing && ds.inventories.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (!ds.serverConnected && ds.inventories.isEmpty) {
      body = _Placeholder(
        icon: Icons.wifi_off_rounded,
        title: 'Server non raggiungibile',
        subtitle: 'Controlla la connessione e l\'indirizzo del server.',
        cs: cs,
        action: FilledButton.icon(
          onPressed: () => ds.refreshFromServer(),
          icon: const Icon(Icons.refresh),
          label: const Text('Riprova'),
        ),
      );
    } else if (ds.inventories.isEmpty) {
      body = _Placeholder(
        icon: Icons.inventory_2_outlined,
        title: 'Nessun inventario',
        subtitle: 'Crea il primo inventario per iniziare.',
        cs: cs,
        action: FilledButton.icon(
          onPressed: () => _showCreateDialog(context, ds),
          icon: const Icon(Icons.add),
          label: const Text('Crea inventario'),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inventari'),
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
            icon: const Icon(Icons.search),
            tooltip: 'Cerca globalmente',
            onPressed: () => showSearch(context: context, delegate: GlobalSearchDelegate(ds)),
          ),
          if (ds.isRemote && ds.serverConnected)
            IconButton(
              icon: ds.syncing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              tooltip: 'Aggiorna lista',
              onPressed: ds.syncing ? null : () => ds.refreshInventoryList(),
            ),
        ],
      ),
      body: body,
      floatingActionButton: ds.isRemote && ds.serverConnected
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context, ds),
              icon: const Icon(Icons.add),
              label: const Text('Nuovo inventario'),
            )
          : null,
    );
  }

  // ── Seleziona ───────────────────────────────────────────────────────────────
  Future<void> _selectInventory(
      BuildContext context, DataService ds, String id) async {
    if (id == ds.currentInventoryId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Inventario già attivo'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      await ds.switchInventory(id);
      if (context.mounted) {
        final name = ds.currentInventory?.name ?? id;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Passato a "$name"'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  // ── Crea ────────────────────────────────────────────────────────────────────
  Future<void> _showCreateDialog(BuildContext context, DataService ds) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuovo inventario'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Nome *', border: OutlineInputBorder()),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
                border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Crea')),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$name" creato e selezionato'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  // ── Rinomina ────────────────────────────────────────────────────────────────
  Future<void> _showRenameDialog(
      BuildContext context, DataService ds, InventoryMeta inv) async {
    final nameCtrl = TextEditingController(text: inv.name);
    final descCtrl = TextEditingController(text: inv.description);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rinomina inventario'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Nome', border: OutlineInputBorder()),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(
                labelText: 'Descrizione', border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salva')),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  // ── Elimina ─────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(
      BuildContext context, DataService ds, InventoryMeta inv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina inventario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Eliminare "${inv.name}"?'),
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
                    'Tutti i componenti verranno eliminati definitivamente.',
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

    if (ok != true) return;
    try {
      await ds.deleteInventory(inv.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
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
                        child: Text('Attivo',
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
              tooltip: 'Azioni',
              onSelected: (v) {
                if (v == 'rename') onRename();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Rinomina'),
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
                      Text('Elimina',
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
