import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import '../l10n/app_localizations.dart';
import '../models/component.dart';
import '../models/settings.dart';
import '../services/data_service.dart';
import 'image_viewer.dart';

class ComponentViewDialog extends StatelessWidget {
  final Component component;
  final AppSettings settings;
  final VoidCallback onEdit;

  const ComponentViewDialog({
    super.key,
    required this.component,
    required this.settings,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final ds = Provider.of<DataService>(context);

    // Get the latest component from the state in case it was updated (e.g. quantity changed)
    final currentComp = ds.components.firstWhere((c) => c.id == component.id, orElse: () => component);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(currentComp.name)),
          if (ds.isRemote && ds.inventories.length > 1)
            IconButton(
              icon: const Icon(Icons.drive_file_move_outlined),
              tooltip: l10n.moveToAnotherInventory,
              color: cs.secondary,
              onPressed: () => _showMoveDialog(context, ds, currentComp),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editAction,
            color: cs.primary,
            onPressed: () {
              Navigator.pop(context); // close view
              onEdit();
            },
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentComp.description.isNotEmpty) ...[
              Text(currentComp.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
            ],
            // Posizione
            () {
              if (currentComp.drawer.isEmpty) {
                return _InfoRow(
                  icon: Icons.location_on_outlined, 
                  label: l10n.positionTitle, 
                  value: l10n.notAssigned,
                );
              }
              final container = settings.containers.firstWhere(
                (c) => c.id == currentComp.cabinet,
                orElse: () => ContainerConfig(id: currentComp.cabinet, name: l10n.containerNumber(currentComp.cabinet), rows: 4, columns: 6),
              );
              final containerDisplayName = container.name.isNotEmpty ? container.name : l10n.containerNumber(container.id);
              
              final basePos = settings.numCabinets > 1 
                  ? '$containerDisplayName, ${l10n.drawerNumber(currentComp.drawer)}' 
                  : l10n.drawerNumber(currentComp.drawer);
              
              if (currentComp.drawerZone != null) {
                final key = '${currentComp.cabinet}_${currentComp.drawer}';
                final zones = settings.drawerDividers[key] ?? 1;
                final zoneText = getZoneLabel(currentComp.drawerZone!, zones, l10n);
                return _InfoRow(
                  icon: Icons.location_on_outlined, 
                  label: l10n.positionTitle, 
                  value: '$basePos (${l10n.compZoneLabel}: $zoneText)',
                );
              }
              return _InfoRow(
                icon: Icons.location_on_outlined, 
                label: l10n.positionTitle, 
                value: basePos,
              );
            }(),
            const SizedBox(height: 16),
            // Quantità con bottoni
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(l10n.quantityLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.remove), onPressed: () => ds.updateQuantity(currentComp.id, -1)),
                SizedBox(
                  width: 40,
                  child: Text('${currentComp.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: () => ds.updateQuantity(currentComp.id, 1)),
              ],
            ),
            const SizedBox(height: 16),
            // Tags
            if (currentComp.tags.isNotEmpty) ...[
              Text(l10n.tagsLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: currentComp.tags.map((t) => Chip(
                  label: Text(t, style: TextStyle(color: cs.onPrimaryContainer, fontSize: 12)), 
                  backgroundColor: cs.primaryContainer,
                  padding: EdgeInsets.zero,
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // Proprietà (Special Tags)
            if (currentComp.specialTagValues.isNotEmpty) ...[
              Text(l10n.propertiesLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...currentComp.specialTagValues.entries.map((e) {
                final st = settings.specialTags.where((s) => s.name == e.key).firstOrNull;
                final unit = st?.unit ?? '';
                final formatted = _formatValueWithUnit(e.value, unit);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('${e.key}: ', style: TextStyle(color: cs.onSurfaceVariant)),
                      Text(formatted, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            // Immagini
            if (currentComp.images.isNotEmpty) ...[
              Text(l10n.imagesSectionTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: currentComp.images.asMap().entries.map((entry) {
                      final index = entry.key;
                      final path = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullscreenImageViewer(
                                  images: currentComp.images,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: _buildImageWidget(context, path),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Allegati
            if (currentComp.attachments.isNotEmpty) ...[
              Text(l10n.attachmentsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: currentComp.attachments.map((a) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(a.isLink ? Icons.link : Icons.insert_drive_file, color: cs.primary),
                  title: Text(a.name, style: TextStyle(color: cs.primary, decoration: TextDecoration.underline)),
                  onTap: () => _openAttachment(context, a, ds),
                )).toList(),
              ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
      ],
    );
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

  Future<void> _openAttachment(BuildContext context, Attachment a, DataService ds) async {
    if (a.isLink) {
      final uri = Uri.parse(a.path);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    } else {
      try {
        final localPath = await ds.getOrDownloadAttachment(a.path);
        await OpenFilex.open(localPath);
      } catch (_) {}
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

  Future<void> _showMoveDialog(BuildContext context, DataService ds, Component component) async {
    final l10n = context.l10n;
    final otherInventories = ds.inventories.where((inv) => inv.id != ds.currentInventoryId).toList();
    if (otherInventories.isEmpty) return;

    InventoryMeta? selectedInventory = otherInventories.first;

    final targetInv = await showDialog<InventoryMeta>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.moveComponentTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.selectDestinationInventoryFor(component.name)),
                const SizedBox(height: 16),
                DropdownButtonFormField<InventoryMeta>(
                  initialValue: selectedInventory,
                  decoration: InputDecoration(
                    labelText: l10n.targetInventoryLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: otherInventories.map((inv) => DropdownMenuItem<InventoryMeta>(
                    value: inv,
                    child: Text(inv.name),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedInventory = val;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: selectedInventory != null ? () => Navigator.pop(ctx, selectedInventory) : null,
                child: Text(l10n.moveAction),
              ),
            ],
          );
        }
      ),
    );

    if (targetInv == null) return;

    try {
      // Close the view dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      await ds.moveComponent(component.id, targetInv.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.componentMovedTo(targetInv.name)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.errorDuringMove(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
