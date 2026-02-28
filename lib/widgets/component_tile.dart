import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/settings.dart';

class ComponentTile extends StatelessWidget {
  final Component component;
  final AppSettings settings;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ComponentTile({
    super.key,
    required this.component,
    required this.settings,
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
    final drawerText = hasCabinets ? '${component.cabinet}-${component.drawer}' : component.drawer;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onEdit,
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
                    width: hasCabinets ? 54 : 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(hasCabinets ? Icons.kitchen_outlined : Icons.inbox_outlined,
                            size: 14, color: cs.onSecondaryContainer),
                        const SizedBox(height: 2),
                        Text(drawerText,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: cs.onSecondaryContainer)),
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
}

/// Helper per formattare "10K" con "Ω" -> "10 KΩ" 
/// e "3K3" con "Ω" -> "3K3 Ω"
String _formatValueWithUnit(String value, String unit) {
  if (unit.isEmpty) return value;
  final v = value.trim();
  
  final regEnd = RegExp(r'^([0-9]+(?:\.[0-9]+)?)([a-zA-Zµ])$');
  final match = regEnd.firstMatch(v);
  if (match != null) {
    return '${match.group(1)} ${match.group(2)}$unit'; 
  }
  
  return '$v $unit';
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