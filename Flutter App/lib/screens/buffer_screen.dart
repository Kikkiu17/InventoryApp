import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../models/settings.dart';
import '../services/data_service.dart';
import '../widgets/component_dialog.dart';
import '../widgets/component_view_dialog.dart';

class BufferScreen extends StatefulWidget {
  const BufferScreen({super.key});

  @override
  State<BufferScreen> createState() => _BufferScreenState();
}

class _BufferScreenState extends State<BufferScreen> {
  String? _isPlacingId;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addComponent(BuildContext context, DataService ds) async {
    final comp = await showDialog<Component>(
      context: context,
      builder: (ctx) => ComponentDialog(
        settings: ds.settings,
        isBuffer: true,
      ),
    );
    if (comp != null) {
      await ds.addBufferComponent(comp);
    }
  }

  void _editComponent(BuildContext context, Component component, DataService ds) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => ComponentDialog(
        existing: component,
        settings: ds.settings,
        isBuffer: true,
      ),
    );
    if (result is Component) {
      await ds.updateBufferComponent(result);
    } else if (result == 'DELETE') {
      await ds.deleteBufferComponent(component.id);
    }
  }

  void _deleteComponent(BuildContext context, Component component, DataService ds) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina componente'),
        content: Text('Sei sicuro di voler eliminare "${component.name}" dal buffer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ds.deleteBufferComponent(component.id);
    }
  }

  void _showPlaceItemDialog(BuildContext context, Component component, DataService ds) async {
    setState(() => _isPlacingId = component.id);

    try {
      final initialTargetId = component.targetInventoryId;
      AppSettings targetSettings;
      if (initialTargetId != null) {
        targetSettings = await ds.getSettingsForInventory(initialTargetId);
      } else {
        targetSettings = AppSettings(containers: []);
      }
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => PlaceItemDialog(
          component: component,
          settings: targetSettings,
          onEditTags: () {
            _editComponent(context, component, ds);
          },
          onPlace: (cabinet, drawer, zone) async {
            await ds.placeComponent(component, component.targetInventoryId!, cabinet, drawer, zone);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${component.name}" posizionato con successo!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricamento delle impostazioni: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingId = null);
      }
    }
  }

  void _viewComponent(BuildContext context, Component component, DataService ds) {
    showDialog(
      context: context,
      builder: (ctx) => ComponentViewDialog(
        component: component,
        settings: ds.settings,
        onEdit: () {
          _editComponent(context, component, ds);
        },
      ),
    );
  }

  String _getTargetInventoryName(DataService ds, String? targetId) {
    if (targetId == null) return '';
    if (!ds.isRemote) return 'Inventario Locale';
    final inv = ds.inventories.firstWhere(
      (i) => i.id == targetId,
      orElse: () => InventoryMeta(id: targetId, name: targetId),
    );
    return inv.name;
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final items = ds.bufferComponents;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final filteredItems = items.where((comp) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final nameMatch = comp.name.toLowerCase().contains(q);
      final descMatch = comp.description.toLowerCase().contains(q);
      final noteMatch = comp.note.toLowerCase().contains(q);
      final tagsMatch = comp.tags.any((t) => t.toLowerCase().contains(q));
      return nameMatch || descMatch || noteMatch || tagsMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buffer di Transito'),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 72,
                      color: cs.onSurfaceVariant.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Il buffer è vuoto',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aggiungi i componenti per registrarli temporaneamente prima di posizionarli.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _addComponent(context, ds),
                      icon: const Icon(Icons.add),
                      label: const Text('Aggiungi Componente'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: SizedBox(
                    height: 40,
                    child: SearchBar(
                      controller: _searchCtrl,
                      hintText: 'Cerca per nome, tag, descrizione o nota...',
                      leading: const Icon(Icons.search, size: 18),
                      trailing: _query.isNotEmpty
                          ? [
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchCtrl.clear();
                                    _query = '';
                                  });
                                },
                              )
                            ]
                          : null,
                      onChanged: (val) {
                        setState(() {
                          _query = val.trim();
                        });
                      },
                      elevation: const WidgetStatePropertyAll(0),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                        ),
                      ),
                      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: cs.onSurfaceVariant.withOpacity(0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nessun risultato trovato',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nessun componente nel buffer corrisponde alla tua ricerca.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 88),
                          itemCount: filteredItems.length,
                          itemBuilder: (ctx, idx) {
                            final comp = filteredItems[idx];
                            final hasTarget = comp.targetInventoryId != null;
                            final targetName = _getTargetInventoryName(ds, comp.targetInventoryId);
                            final isLoadingThis = _isPlacingId == comp.id;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: hasTarget 
                                      ? cs.outlineVariant.withOpacity(0.4)
                                      : cs.error.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Status Badge, Name/Description, Actions
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Status Badge
                                        Tooltip(
                                          message: hasTarget 
                                              ? 'Destinazione assegnata: $targetName'
                                              : 'Destinazione non specificata',
                                          child: Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: hasTarget
                                                  ? cs.primaryContainer
                                                  : cs.errorContainer,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                hasTarget
                                                    ? Icons.inventory_2_outlined
                                                    : Icons.location_off_outlined,
                                                size: 20,
                                                color: hasTarget
                                                    ? cs.onPrimaryContainer
                                                    : cs.onErrorContainer,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Name and Description
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => _viewComponent(context, comp, ds),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  comp.name,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16.0,
                                                  ),
                                                ),
                                                if (comp.description.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    comp.description,
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      color: cs.onSurfaceVariant,
                                                      fontSize: 13.0,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Edit and Delete Actions
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          style: IconButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          onPressed: () => _editComponent(context, comp, ds),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          style: IconButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          onPressed: () => _deleteComponent(context, comp, ds),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Row 2: Details (Target / Note / Tags), Actions (Qty / Place)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Destination display
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.subdirectory_arrow_right,
                                              size: 14,
                                              color: hasTarget ? cs.primary : cs.error,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                hasTarget ? targetName : 'Senza destinazione',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: hasTarget ? cs.onSurface : cs.error,
                                                  fontWeight: hasTarget ? FontWeight.bold : FontWeight.bold,
                                                  fontSize: 13.0,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Note display
                                        if (comp.note.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(Icons.edit_note_outlined, size: 13, color: cs.secondary),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  comp.note,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                    fontStyle: FontStyle.italic,
                                                    fontSize: 11.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        // Tags Wrap
                                        if (comp.tags.isNotEmpty) ...[
                                          const SizedBox(height: 5),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: comp.tags
                                                .map((t) => Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: cs.surfaceContainerHighest,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        t,
                                                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.0),
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        // Actions Row (Quantity & Place button)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Quantity control
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: cs.outline.withOpacity(0.3)),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  InkWell(
                                                    onTap: comp.quantity > 0 
                                                        ? () => ds.updateBufferQuantity(comp.id, -1) 
                                                        : null,
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(6),
                                                      child: Icon(
                                                        Icons.remove, 
                                                        size: 18, 
                                                        color: comp.quantity > 0 ? null : theme.disabledColor
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 36,
                                                    child: Text('${comp.quantity}',
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                  ),
                                                  InkWell(
                                                    onTap: () => ds.updateBufferQuantity(comp.id, 1),
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: const Padding(
                                                      padding: const EdgeInsets.all(6),
                                                      child: Icon(Icons.add, size: 18),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Place button
                                            FilledButton.icon(
                                              style: FilledButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              onPressed: isLoadingThis 
                                                  ? null 
                                                  : () => _showPlaceItemDialog(context, comp, ds),
                                              icon: isLoadingThis
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.0,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : const Icon(Icons.inbox, size: 16),
                                              label: const Text('Posiziona', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: items.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'fab_buffer',
              onPressed: () => _addComponent(context, ds),
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi'),
            )
          : null,
    );
  }
}

class PlaceItemDialog extends StatefulWidget {
  final Component component;
  final AppSettings settings;
  final VoidCallback onEditTags;
  final Function(int cabinet, String drawer, int? zone) onPlace;

  const PlaceItemDialog({
    super.key,
    required this.component,
    required this.settings,
    required this.onEditTags,
    required this.onPlace,
  });

  @override
  State<PlaceItemDialog> createState() => _PlaceItemDialogState();
}

class _PlaceItemDialogState extends State<PlaceItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _selectedCabinet;
  final _colCtrl = TextEditingController();
  final _rowCtrl = TextEditingController();
  int? _selectedZone;

  @override
  void initState() {
    super.initState();
    _selectedCabinet = widget.settings.containers.isNotEmpty ? widget.settings.containers.first.id : 1;
    _colCtrl.addListener(_onCoordinatesChanged);
    _rowCtrl.addListener(_onCoordinatesChanged);
  }

  @override
  void dispose() {
    _colCtrl.dispose();
    _rowCtrl.dispose();
    super.dispose();
  }

  void _onCoordinatesChanged() {
    setState(() {});
  }

  void _submit() {
    if (widget.component.targetInventoryId == null) return;
    if (!_formKey.currentState!.validate()) return;

    final col = _colCtrl.text.trim().toUpperCase();
    final row = _rowCtrl.text.trim();
    final drawer = '$col$row';

    final key = '${_selectedCabinet}_$drawer';
    final zones = widget.settings.drawerDividers[key] ?? 1;
    int? finalZone;
    if (zones >= 2) {
      finalZone = _selectedZone ?? 1;
    }

    widget.onPlace(_selectedCabinet, drawer, finalZone);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const double opacityGreen = 0.2;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ds = Provider.of<DataService>(context, listen: false);

    final targetId = widget.component.targetInventoryId;
    final hasTarget = targetId != null;

    String targetName = '';
    if (hasTarget) {
      if (!ds.isRemote) {
        targetName = 'Inventario Locale';
      } else {
        final inv = ds.inventories.firstWhere(
          (i) => i.id == targetId,
          orElse: () => InventoryMeta(id: targetId, name: targetId),
        );
        targetName = inv.name;
      }
    }

    final col = _colCtrl.text.trim().toUpperCase();
    final row = _rowCtrl.text.trim();
    final drawer = col.isNotEmpty && row.isNotEmpty ? '$col$row' : '';
    final key = '${_selectedCabinet}_$drawer';
    final zones = widget.settings.drawerDividers[key] ?? 1;

    return AlertDialog(
      title: Text('Posiziona "${widget.component.name}"'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Specifica la posizione fisica per spostare il componente dal buffer all\'inventario.'),
              const SizedBox(height: 16),
              
              if (hasTarget) ...[
                // Display current target inventory name
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Destinazione: $targetName',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Button to change destination (opens edit flow)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // close PlaceItemDialog
                    widget.onEditTags();
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Cambia destinazione (e tag)'),
                ),
                const SizedBox(height: 16),
                
                if (widget.settings.containers.length > 1) ...[
                  DropdownButtonFormField<int>(
                    value: _selectedCabinet,
                    decoration: InputDecoration(
                      labelText: 'Cassettiera',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.green.withOpacity(opacityGreen),
                    ),
                    items: widget.settings.containers
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name.isNotEmpty ? c.name : 'N° ${c.id}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCabinet = v ?? 1),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _colCtrl,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Colonna',
                          hintText: 'Es: A',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.green.withOpacity(opacityGreen),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obbligatorio';
                          if (widget.settings.containers.isEmpty) return null;
                          final colStr = v.trim().toUpperCase();
                          final container = widget.settings.containers.firstWhere(
                            (c) => c.id == _selectedCabinet,
                            orElse: () => widget.settings.containers.first,
                          );
                          final r = _rowCtrl.text.trim();
                          if (r.isNotEmpty) {
                            final label = '$colStr$r';
                            if (container.disabledDrawers.contains(label)) {
                              return 'Disattivato';
                            }
                            if (!container.isDrawerValid(label)) {
                              return 'Max colonna: ${container.columnLabels.last}';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _rowCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Riga',
                          hintText: 'Es: 3',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.green.withOpacity(opacityGreen),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obbligatorio';
                          if (widget.settings.containers.isEmpty) return null;
                          final rowVal = int.tryParse(v.trim()) ?? 0;
                          final container = widget.settings.containers.firstWhere(
                            (c) => c.id == _selectedCabinet,
                            orElse: () => widget.settings.containers.first,
                          );
                          if (rowVal < 1 || rowVal > container.rows) {
                            return 'Max riga: ${container.rows}';
                          }
                          final cStr = _colCtrl.text.trim().toUpperCase();
                          if (cStr.isNotEmpty) {
                            final label = '$cStr$rowVal';
                            if (container.disabledDrawers.contains(label)) {
                              return 'Disattivato';
                            }
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ),
                  ],
                ),
                if (zones >= 2) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedZone == null || _selectedZone! < 1 || _selectedZone! > zones ? 1 : _selectedZone,
                    decoration: InputDecoration(
                      labelText: 'Zona del cassetto (Separatore)',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.green.withOpacity(opacityGreen),
                    ),
                    items: List.generate(zones, (i) => i + 1)
                        .map((z) => DropdownMenuItem(
                              value: z,
                              child: Text(getZoneLabel(z, zones)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedZone = v ?? 1),
                  ),
                ],
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: cs.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Seleziona prima un inventario di destinazione.',
                              style: TextStyle(color: cs.error, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // close PlaceItemDialog
                          widget.onEditTags();
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Imposta destinazione e tag'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        if (hasTarget)
          FilledButton(
            onPressed: _submit,
            child: const Text('Salva Posizione'),
          ),
      ],
    );
  }
}
