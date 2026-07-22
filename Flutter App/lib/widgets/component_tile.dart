import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import '../models/component.dart';
import '../models/settings.dart';
import '../services/data_service.dart';
import 'image_viewer.dart';

class ComponentTile extends StatelessWidget {
  final Component component;
  final AppSettings settings;
  final VoidCallback onTapTile;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ComponentTile({
    super.key,
    required this.component,
    required this.settings,
    required this.onTapTile,
    required this.onEdit,
    required this.onDuplicate,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasCabinets = settings.numCabinets > 1;
    final isUnassigned = component.drawer.isEmpty;
    final hasZone = component.drawerZone != null;

    final drawerText = isUnassigned
        ? 'Non\nass.'
        : (hasCabinets
            ? '${component.cabinet}-${component.drawer}${hasZone ? '\nZ${component.drawerZone}' : ''}'
            : '${component.drawer}${hasZone ? '\nZ${component.drawerZone}' : ''}');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTapTile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Drawer Badge, Name & Description, Image (if any), Popup Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Drawer Badge
                  Tooltip(
                    message: isUnassigned
                        ? 'Posizione non assegnata'
                        : () {
                            final container = settings.containers.firstWhere(
                              (c) => c.id == component.cabinet,
                              orElse: () => ContainerConfig(id: component.cabinet, name: 'Contenitore ${component.cabinet}', rows: 4, columns: 6),
                            );
                            return container.name.isNotEmpty ? container.name : 'Contenitore ${container.id}';
                          }(),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isUnassigned
                            ? cs.errorContainer
                            : cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              isUnassigned
                                  ? Icons.location_off_outlined
                                  : (hasCabinets
                                      ? Icons.kitchen_outlined
                                      : Icons.inbox_outlined),
                              size: 16,
                              color: isUnassigned
                                  ? cs.onErrorContainer
                                  : cs.onSecondaryContainer),
                          const SizedBox(height: 1),
                          Text(drawerText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: isUnassigned ? 11 : 12,
                                  height: 1.05,
                                  fontWeight: FontWeight.bold,
                                  color: isUnassigned
                                      ? cs.onErrorContainer
                                      : cs.onSecondaryContainer)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name and Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          component.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.0,
                          ),
                        ),
                        if (component.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            component.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 13.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Image Thumbnail (if any)
                  if (component.images.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullscreenImageViewer(
                              images: component.images,
                              initialIndex: 0,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: _buildImageWidget(context, component.images.first),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Edit and Duplicate Actions
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onDuplicate,
                  ),
                ],
              ),
              // Row 2: Spacer, Unified Tags/Attachments Wrap, Quantity Control
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Unified Tags and Attachments Wrap
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...component.tags.map((t) => _TagChip(label: t)),
                        ...component.specialTagValues.entries.map((e) {
                          final st = settings.specialTags
                              .where((s) => s.name == e.key)
                              .firstOrNull;
                          final unit = st?.unit ?? '';
                          final formattedLabel = _formatValueWithUnit(e.value, unit);
                          return _TagChip(
                            label: '${e.key}: $formattedLabel',
                            special: true,
                          );
                        }),
                        ...component.attachments.map((a) => _AttachmentChip(
                              attachment: a,
                              onTap: () => _openAttachment(context, a),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Quantity Control
                  _QuantityControl(
                    quantity: component.quantity,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAttachment(BuildContext context, Attachment a) async {
    if (a.isLink) {
      final uri = Uri.parse(a.path);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    } else {
      final ds = Provider.of<DataService>(context, listen: false);
      if (ds.mode == StorageMode.remote && ds.serverConnected) {
        final url = ds.getAttachmentUrl(a.path);
        final uri = Uri.parse(url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      } else {
        final localPath = await ds.getLocalAttachmentPath(a.path);
        await OpenFilex.open(localPath);
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
}

/// Helper per formattare "10K" con "Ω" -> "10KΩ"
/// e "3K3" con "Ω" -> "3K3Ω"
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

class _TagChip extends StatelessWidget {
  final String label;
  final bool special;
  const _TagChip({required this.label, this.special = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: special ? cs.tertiaryContainer : cs.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9.5,
              color: special ? cs.onTertiaryContainer : cs.onPrimaryContainer)),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onTap;
  const _AttachmentChip({required this.attachment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              attachment.isLink ? Icons.link : Icons.insert_drive_file,
              size: 10,
              color: cs.primary,
            ),
            const SizedBox(width: 3),
            Text(
              attachment.name,
              style: TextStyle(
                fontSize: 9.5,
                color: cs.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityControl({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QBtn(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 36,
            child: Text('$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          _QBtn(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _QBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16),
        ),
      );
}
