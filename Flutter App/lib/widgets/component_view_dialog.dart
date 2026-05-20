import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import '../models/component.dart';
import '../models/settings.dart';
import '../services/data_service.dart';

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
    final cs = Theme.of(context).colorScheme;
    final ds = Provider.of<DataService>(context);

    // Get the latest component from the state in case it was updated (e.g. quantity changed)
    final currentComp = ds.components.firstWhere((c) => c.id == component.id, orElse: () => component);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(currentComp.name)),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica',
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
                return const _InfoRow(
                  icon: Icons.location_on_outlined, 
                  label: 'Posizione', 
                  value: 'Non assegnato'
                );
              }
              final basePos = settings.numCabinets > 1 
                  ? 'Cassettiera ${currentComp.cabinet}, Cassetto ${currentComp.drawer}' 
                  : 'Cassetto ${currentComp.drawer}';
              
              if (currentComp.drawerZone != null) {
                final key = '${currentComp.cabinet}_${currentComp.drawer}';
                final zones = settings.drawerDividers[key] ?? 1;
                final zoneText = getZoneLabel(currentComp.drawerZone!, zones);
                return _InfoRow(
                  icon: Icons.location_on_outlined, 
                  label: 'Posizione', 
                  value: '$basePos (Zona: $zoneText)'
                );
              }
              return _InfoRow(
                icon: Icons.location_on_outlined, 
                label: 'Posizione', 
                value: basePos
              );
            }(),
            const SizedBox(height: 16),
            // Quantità con bottoni
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Quantità:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Text('Tag:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Text('Proprietà:', style: TextStyle(fontWeight: FontWeight.bold)),
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
            // Allegati
            if (currentComp.attachments.isNotEmpty) ...[
              const Text('Allegati:', style: TextStyle(fontWeight: FontWeight.bold)),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi')),
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
