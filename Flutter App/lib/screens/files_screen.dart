import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import '../services/data_service.dart';
import '../models/component.dart';
import '../widgets/image_viewer.dart';

class FilesScreenItem {
  final Component component;
  final String name;
  final String path;
  final bool isLink;
  final bool isImage;

  FilesScreenItem({
    required this.component,
    required this.name,
    required this.path,
    this.isLink = false,
    this.isImage = false,
  });
}

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

  Future<void> _openAttachment(BuildContext context, FilesScreenItem item) async {
    if (item.isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullscreenImageViewer(
            images: [item.path],
            initialIndex: 0,
          ),
        ),
      );
      return;
    }

    if (item.isLink) {
      final uri = Uri.parse(item.path);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Impossibile aprire il link')));
        }
      }
    } else {
      final ds = Provider.of<DataService>(context, listen: false);
      if (ds.mode == StorageMode.remote && ds.serverConnected) {
        final url = ds.getAttachmentUrl(item.path);
        final uri = Uri.parse(url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Impossibile aprire il file')));
          }
        }
      } else {
        try {
          final localPath = await ds.getLocalAttachmentPath(item.path);
          await OpenFilex.open(localPath);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Impossibile aprire il file locale')));
          }
        }
      }
    }
  }

  Future<void> _renameAttachment(
      BuildContext context, FilesScreenItem item) async {
    if (item.isImage) return; // Images don't support custom display names in this screen
    final ctrl = TextEditingController(text: item.name);
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
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Salva')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != item.name) {
      final newAttachments = item.component.attachments.map((att) {
        if (att.path == item.path && att.name == item.name) {
          return Attachment(name: newName, path: item.path, isLink: item.isLink);
        }
        return att;
      }).toList();

      try {
        await context
            .read<DataService>()
            .updateComponent(item.component.copyWith(attachments: newAttachments));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Errore: $e')));
        }
      }
    }
  }

  Future<void> _deleteAttachment(
      BuildContext context, FilesScreenItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.isImage ? 'Elimina immagine' : 'Elimina file'),
        content: Text('Vuoi eliminare definitivamente "${item.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Elimina')),
        ],
      ),
    );

    if (confirm == true) {
      final ds = context.read<DataService>();
      try {
        if (!item.isLink) {
          await ds.deleteAttachment(item.path);
        }
        if (item.isImage) {
          final newImages = item.component.images
              .where((img) => img != item.path)
              .toList();
          await ds.updateComponent(item.component.copyWith(images: newImages));
        } else {
          final newAttachments = item.component.attachments
              .where((att) => att.path != item.path || att.name != item.name)
              .toList();
          await ds.updateComponent(item.component.copyWith(attachments: newAttachments));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Errore: $e')));
        }
      }
    }
  }

  Widget _buildImageWidget(BuildContext context, String imagePath) {
    final ds = Provider.of<DataService>(context, listen: false);
    if (imagePath.startsWith('/')) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image),
      );
    } else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image),
      );
    } else {
      if (ds.mode == StorageMode.remote && ds.serverConnected) {
        return Image.network(
          ds.getAttachmentUrl(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image),
        );
      } else {
        final localPath = ds.getLocalAttachmentPathSync(imagePath);
        return Image.file(
          File(localPath),
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final cs = Theme.of(context).colorScheme;

    // Raccoglie tutti i file, i link e le immagini
    final List<FilesScreenItem> allItems = [];
    for (final c in ds.components) {
      for (final a in c.attachments) {
        allItems.add(FilesScreenItem(
          component: c,
          name: a.name,
          path: a.path,
          isLink: a.isLink,
          isImage: false,
        ));
      }
      for (final imgPath in c.images) {
        allItems.add(FilesScreenItem(
          component: c,
          name: imgPath.split('/').last,
          path: imgPath,
          isLink: false,
          isImage: true,
        ));
      }
    }

    // Filtra per query
    final filtered = allItems.where((item) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return item.name.toLowerCase().contains(q) ||
          item.component.name.toLowerCase().contains(q);
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
              padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length} file trovati',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
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
                        Icon(Icons.attachment_outlined,
                            size: 64,
                            color: cs.onSurfaceVariant.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text('Nessun file trovato'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return ListTile(
                        leading: item.isImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: _buildImageWidget(context, item.path),
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: cs.primaryContainer,
                                child: Icon(
                                    item.isLink ? Icons.link : Icons.insert_drive_file,
                                    color: cs.primary),
                              ),
                        title: Text(item.name),
                        subtitle: Text('Componente: ${item.component.name}'),
                        onTap: () => _openAttachment(context, item),
                        trailing: PopupMenuButton<String>(
                          icon:
                              Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                          tooltip: 'Opzioni',
                          onSelected: (val) {
                            if (val == 'rename') {
                              _renameAttachment(context, item);
                            }
                            if (val == 'delete') {
                              _deleteAttachment(context, item);
                            }
                          },
                          itemBuilder: (_) => [
                            if (!item.isImage)
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
                                Icon(Icons.delete_outline,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.error),
                                const SizedBox(width: 10),
                                Text('Elimina',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error)),
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
