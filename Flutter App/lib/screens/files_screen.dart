import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import '../l10n/app_localizations.dart';
import '../services/data_service.dart';
import '../models/component.dart';
import '../widgets/image_viewer.dart';
import '../widgets/component_view_dialog.dart';
import '../widgets/component_dialog.dart';
import '../main.dart';

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

  Future<void> _openAttachment(
      BuildContext context, FilesScreenItem item) async {
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
              SnackBar(content: Text(context.l10n.cannotOpenLink)));
        }
      }
    } else {
      final ds = Provider.of<DataService>(context, listen: false);
      try {
        final localPath = await ds.getOrDownloadAttachment(item.path);
        await OpenFilex.open(localPath);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.cannotOpenFile)));
        }
      }
    }
  }

  Future<void> _renameAttachment(
      BuildContext context, FilesScreenItem item) async {
    if (item.isImage) {
      return; // Images don't support custom display names in this screen
    }
    final ctrl = TextEditingController(text: item.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.renameFileTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.nameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancelButton)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(context.l10n.saveButton)),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != item.name) {
      final newAttachments = item.component.attachments.map((att) {
        if (att.path == item.path && att.name == item.name) {
          return Attachment(
              name: newName, path: item.path, isLink: item.isLink);
        }
        return att;
      }).toList();

      if (!context.mounted) return;
      try {
        await context.read<DataService>().updateComponent(
            item.component.copyWith(attachments: newAttachments));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${context.l10n.error}: $e')));
        }
      }
    }
  }

  Future<void> _deleteAttachment(
      BuildContext context, FilesScreenItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = context.l10n;
        return AlertDialog(
          title:
              Text(item.isImage ? l10n.deleteImageTitle : l10n.deleteFileTitle),
          content: Text(l10n.deleteAttachmentConfirm(item.name)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancelButton)),
            FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                    foregroundColor: Theme.of(ctx).colorScheme.onError),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.deleteButton)),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!context.mounted) return;
      final ds = context.read<DataService>();
      try {
        if (!item.isLink) {
          await ds.deleteAttachment(item.path);
        }
        if (item.isImage) {
          final newImages =
              item.component.images.where((img) => img != item.path).toList();
          await ds.updateComponent(item.component.copyWith(images: newImages));
        } else {
          final newAttachments = item.component.attachments
              .where((att) => att.path != item.path || att.name != item.name)
              .toList();
          await ds.updateComponent(
              item.component.copyWith(attachments: newAttachments));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${context.l10n.error}: $e')));
        }
      }
    }
  }

  List<Component> _findConnectedComponents(
      DataService ds, FilesScreenItem item) {
    final Set<String> seenIds = {};
    final List<Component> connected = [];

    final candidates = <Component>[...ds.components, ...ds.bufferComponents];
    for (final comp in candidates) {
      final isMatch = comp.id == item.component.id ||
          comp.images.contains(item.path) ||
          comp.attachments.any((a) => a.path == item.path);

      if (isMatch && seenIds.add(comp.id)) {
        connected.add(comp);
      }
    }

    if (connected.isEmpty) {
      connected.add(item.component);
    }

    return connected;
  }

  Future<Component?> _chooseItemDialog(
      BuildContext context, List<Component> items) {
    final l10n = context.l10n;
    return showDialog<Component>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.selectItemToView),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, index) {
              final comp = items[index];
              final subtitleParts = <String>[];
              if (comp.cabinet > 0 && comp.drawer.isNotEmpty) {
                subtitleParts.add('${comp.cabinet}${comp.drawer}');
              }
              if (comp.description.isNotEmpty) {
                subtitleParts.add(comp.description);
              } else if (comp.tags.isNotEmpty) {
                subtitleParts.add(comp.tags.join(', '));
              }

              return ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(comp.name),
                subtitle: subtitleParts.isNotEmpty
                    ? Text(subtitleParts.join(' • '))
                    : null,
                onTap: () => Navigator.pop(ctx, comp),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelButton),
          ),
        ],
      ),
    );
  }

  Future<void> _seeItem(BuildContext context, FilesScreenItem item) async {
    final ds = context.read<DataService>();
    final connected = _findConnectedComponents(ds, item);

    if (connected.isEmpty) return;

    final Component? target;
    if (connected.length == 1) {
      target = connected.first;
    } else {
      target = await _chooseItemDialog(context, connected);
    }

    if (target != null && context.mounted) {
      await _viewComponent(context, target);
    }
  }

  Future<void> _viewComponent(BuildContext context, Component comp) async {
    final ds = context.read<DataService>();
    final isBuffer = ds.bufferComponents.any((c) => c.id == comp.id);
    await showDialog(
      context: context,
      builder: (ctx) => ComponentViewDialog(
        component: comp,
        inventoryId: isBuffer ? null : ds.currentInventoryId,
        settings: ds.settings,
        onEdit: () {
          _editComponent(context, comp);
        },
        onGoToPosition: () async {
          try {
            final l10n = context.l10n;
            final mainShell = globalMainShellKey.currentState;
            final mainContext = globalMainShellKey.currentContext ?? context;

            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }

            if (isBuffer) {
              mainShell?.switchTab(1);
              if (mainContext.mounted) {
                ScaffoldMessenger.of(mainContext).showSnackBar(SnackBar(
                  content: Text(l10n.passedToBuffer),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            } else {
              ds.setGlobalSearchQuery(comp.name);
              if (comp.drawer.isNotEmpty) {
                ds.highlightComponentOnMap(comp);
              }
              mainShell?.switchTab(0);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${context.l10n.error}: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _editComponent(BuildContext context, Component comp) async {
    final ds = context.read<DataService>();
    final isBuffer = ds.bufferComponents.any((c) => c.id == comp.id);
    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => ComponentDialog(
        existing: comp,
        settings: ds.settings,
        isBuffer: isBuffer,
      ),
    );

    if (result is Component) {
      try {
        if (isBuffer) {
          await ds.updateBufferComponent(result);
        } else {
          await ds.updateComponent(result);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.l10n.error}: $e')),
          );
        }
      }
    }
  }

  List<PopupMenuEntry<String>> _buildContextMenuItems(
      BuildContext context, FilesScreenItem item) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return [
      PopupMenuItem<String>(
        value: 'see_item',
        child: Row(
          children: [
            const Icon(Icons.visibility_outlined, size: 18),
            const SizedBox(width: 10),
            Text(l10n.seeItem),
          ],
        ),
      ),
      if (!item.isImage)
        PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 10),
              Text(l10n.renameAction),
            ],
          ),
        ),
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete_outline,
                size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            Text(
              l10n.delete,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _handleContextMenuSelection(
      BuildContext context, FilesScreenItem item, String action) async {
    switch (action) {
      case 'see_item':
        await _seeItem(context, item);
        break;
      case 'rename':
        await _renameAttachment(context, item);
        break;
      case 'delete':
        await _deleteAttachment(context, item);
        break;
    }
  }

  Future<void> _showItemContextMenu(
      BuildContext context, FilesScreenItem item, [Offset? globalPosition]) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final RelativeRect position;
    if (globalPosition != null) {
      position = RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      );
    } else {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final center = renderBox.localToGlobal(
            Offset(renderBox.size.width / 2, renderBox.size.height / 2));
        position = RelativeRect.fromRect(
          Rect.fromPoints(center, center),
          Offset.zero & overlay.size,
        );
      } else {
        position = RelativeRect.fromRect(
          Rect.zero,
          Offset.zero & overlay.size,
        );
      }
    }

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: _buildContextMenuItems(context, item),
    );

    if (selected != null && context.mounted) {
      await _handleContextMenuSelection(context, item, selected);
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
    } else if (imagePath.startsWith('http://') ||
        imagePath.startsWith('https://')) {
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

  String _formatImageName(String path, int index, String componentName) {
    final rawName = path.split('/').last;
    String name = rawName;
    final prefixMatch = RegExp(r'^[0-9a-fA-F]{8,16}_(.*)$').firstMatch(name);
    if (prefixMatch != null) {
      name = prefixMatch.group(1)!;
    }

    if (name.contains('scaled_') ||
        name.contains('image_picker_') ||
        RegExp(r'^[0-9a-fA-F\-]{25,}').hasMatch(name)) {
      final extMatch = RegExp(r'\.[a-zA-Z0-9]+$').firstMatch(rawName);
      final ext = extMatch != null ? extMatch.group(0)!.toLowerCase() : '.jpg';

      final cleanComp = componentName
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');

      final shortBase = cleanComp.isNotEmpty
          ? (cleanComp.length > 20
              ? cleanComp.substring(0, 20).replaceAll(RegExp(r'_+$'), '')
              : cleanComp)
          : 'foto';
      return '${shortBase}_${index + 1}$ext';
    }

    return name;
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final l10n = context.l10n;
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
      for (int i = 0; i < c.images.length; i++) {
        final imgPath = c.images[i];
        allItems.add(FilesScreenItem(
          component: c,
          name: _formatImageName(imgPath, i, c.name),
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
          item.path.toLowerCase().contains(q) ||
          item.component.name.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.uploadedFilesTitle),
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
              hintText: l10n.searchFileOrComponentPlaceholder,
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
                  l10n.filesFoundCount(filtered.length),
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
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(l10n.noFilesFound),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onSecondaryTapUp: (details) => _showItemContextMenu(
                            context, item, details.globalPosition),
                        onLongPressStart: (details) => _showItemContextMenu(
                            context, item, details.globalPosition),
                        child: ListTile(
                          leading: item.isImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child:
                                        _buildImageWidget(context, item.path),
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: cs.primaryContainer,
                                  child: Icon(
                                      item.isLink
                                          ? Icons.link
                                          : Icons.insert_drive_file,
                                      color: cs.primary),
                                ),
                          title: Text(item.name),
                          subtitle: Text(
                              '${l10n.itemPrefix}: ${item.component.name}'),
                          onTap: () => _openAttachment(context, item),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                color: cs.onSurfaceVariant),
                            tooltip: l10n.options,
                            onSelected: (val) =>
                                _handleContextMenuSelection(context, item, val),
                            itemBuilder: (menuCtx) =>
                                _buildContextMenuItems(menuCtx, item),
                          ),
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
