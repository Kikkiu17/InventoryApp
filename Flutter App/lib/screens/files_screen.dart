import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import '../services/data_service.dart';
import '../models/component.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openAttachment(BuildContext context, Attachment a) async {
    if (a.isLink) {
      final uri = Uri.parse(a.path);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossibile aprire il link')));
        }
      }
    } else {
      final ds = Provider.of<DataService>(context, listen: false);
      if (ds.mode == StorageMode.remote && ds.serverConnected) {
        final url = ds.getAttachmentUrl(a.path);
        final uri = Uri.parse(url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossibile aprire il file')));
          }
        }
      } else {
        try {
          final localPath = await ds.getLocalAttachmentPath(a.path);
          await OpenFilex.open(localPath);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossibile aprire il file locale')));
          }
        }
      }
    }
  }

  Future<void> _renameAttachment(BuildContext context, Component comp, Attachment a) async {
    final ctrl = TextEditingController(text: a.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rinomina file'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Salva')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != a.name) {
      final newAttachments = comp.attachments.map((att) {
        if (att.path == a.path && att.name == a.name) {
          return Attachment(name: newName, path: a.path, isLink: a.isLink);
        }
        return att;
      }).toList();

      try {
        await context.read<DataService>().updateComponent(comp.copyWith(attachments: newAttachments));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
        }
      }
    }
  }

  Future<void> _deleteAttachment(BuildContext context, Component comp, Attachment a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina file'),
        content: Text('Vuoi eliminare definitivamente "${a.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error, foregroundColor: Theme.of(ctx).colorScheme.onError),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Elimina')
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ds = context.read<DataService>();
      try {
        if (!a.isLink) {
          await ds.deleteAttachment(a.path);
        }
        final newAttachments = comp.attachments.where((att) => att.path != a.path || att.name != a.name).toList();
        await ds.updateComponent(comp.copyWith(attachments: newAttachments));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final cs = Theme.of(context).colorScheme;

    // Raccoglie tutti i file e i link
    final allAttachments = ds.components.expand((c) => c.attachments.map((a) => (c, a))).toList();

    // Filtra per query
    final filtered = allAttachments.where((pair) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return pair.$2.name.toLowerCase().contains(q) || pair.$1.name.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('File Caricati'),
            if (ds.isRemote && ds.currentInventory != null)
              Text(
                ds.currentInventory!.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Cerca file o componente...',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length} file trovati',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attachment_outlined, size: 64, color: cs.onSurfaceVariant.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text('Nessun file trovato'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final comp = filtered[i].$1;
                      final a = filtered[i].$2;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Icon(a.isLink ? Icons.link : Icons.insert_drive_file, color: cs.primary),
                        ),
                        title: Text(a.name),
                        subtitle: Text('Componente: ${comp.name}'),
                        onTap: () => _openAttachment(context, a),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                          tooltip: 'Opzioni',
                          onSelected: (val) {
                            if (val == 'rename') _renameAttachment(context, comp, a);
                            if (val == 'delete') _deleteAttachment(context, comp, a);
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
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                                const SizedBox(width: 10),
                                Text('Elimina', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                              ]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
