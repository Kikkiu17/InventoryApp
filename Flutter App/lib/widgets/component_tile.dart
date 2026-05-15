import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import '../models/component.dart';
import '../models/settings.dart';
import '../services/data_service.dart';

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
    final cs    = theme.colorScheme;
    
    final hasCabinets = settings.numCabinets > 1;
    final isUnassigned = component.drawer.isEmpty;
    
    final drawerText = isUnassigned 
        ? 'Non\nass.' 
        : (hasCabinets ? '${component.cabinet}-${component.drawer}' : component.drawer);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTapTile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // RIGA 1: Badge + Info (Tutta la larghezza disponibile)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge cassetto
                  Container(
                    width: hasCabinets || isUnassigned ? 54 : 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isUnassigned ? cs.errorContainer : cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isUnassigned 
                              ? Icons.location_off_outlined 
                              : (hasCabinets ? Icons.kitchen_outlined : Icons.inbox_outlined),
                          size: 14, 
                          color: isUnassigned ? cs.onErrorContainer : cs.onSecondaryContainer
                        ),
                        const SizedBox(height: 2),
                        Text(drawerText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: isUnassigned ? 11 : 13,
                                height: 1.1,
                                fontWeight: FontWeight.bold,
                                color: isUnassigned ? cs.onErrorContainer : cs.onSecondaryContainer)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nome + tag
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(component.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        if (component.description.isNotEmpty)
                          Text(component.description,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        // Tag normali
                        if (component.tags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children:
                                component.tags.map((t) => _TagChip(label: t)).toList(),
                          ),
                        ],
                        // Valori tag speciali
                        if (component.specialTagValues.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: component.specialTagValues.entries.map((e) {
                              final st = settings.specialTags
                                  .where((s) => s.name == e.key)
                                  .firstOrNull;
                              final unit = st?.unit ?? '';
                              final formattedLabel = _formatValueWithUnit(e.value, unit);
                              return _TagChip(
                                label: '${e.key}: $formattedLabel',
                                special: true,
                              );
                            }).toList(),
                          ),
                        ],
                        // Allegati
                        if (component.attachments.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: component.attachments.map((a) {
                              return InkWell(
                                onTap: () => _openAttachment(context, a),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: cs.outlineVariant),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(a.isLink ? Icons.link : Icons.insert_drive_file, size: 12, color: cs.primary),
                                      const SizedBox(width: 4),
                                      Text(a.name, style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // RIGA 2: Azioni (Allineate a destra)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bottone Edit
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: cs.primary,
                    tooltip: 'Modifica',
                    onPressed: onEdit,
                  ),
                  // Bottone Duplica
                  IconButton(
                    icon: const Icon(Icons.copy_outlined),
                    color: cs.primary,
                    tooltip: 'Duplica',
                    onPressed: onDuplicate,
                  ),
                  const SizedBox(width: 8),
                  // Quantità
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: special ? cs.tertiaryContainer : cs.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color:
                  special ? cs.onTertiaryContainer : cs.onPrimaryContainer)),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityControl(
      {required this.quantity,
      required this.onIncrement,
      required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _QBtn(icon: Icons.remove, onTap: onDecrement),
        SizedBox(
          width: 40,
          child: Text('$quantity',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        _QBtn(icon: Icons.add, onTap: onIncrement),
      ]),
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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18),
        ),
      );
}