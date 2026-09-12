import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../models/settings.dart';
import '../services/data_service.dart';
import '../l10n/app_localizations.dart';

class CabinetMapView extends StatefulWidget {
  final AppSettings settings;
  final DataService dataService;
  final Function(Component) onViewComponent;
  final Function(Component) onEditComponent;
  final Future<void> Function(int cabinetId, String drawerLabel, int zoneIndex)
      onAddComponentAt;

  const CabinetMapView({
    super.key,
    required this.settings,
    required this.dataService,
    required this.onViewComponent,
    required this.onEditComponent,
    required this.onAddComponentAt,
  });

  @override
  State<CabinetMapView> createState() => _CabinetMapViewState();
}

class _CabinetMapViewState extends State<CabinetMapView> {
  int? _selectedCabinetId;
  late TransformationController _transformationController;
  int? _lastCabinetId;
  double? _lastViewportWidth;
  double? _lastViewportHeight;

  Map<String, int> _parseLabelCoords(String label) {
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(label);
    if (match == null) return {'col': 0, 'row': 0};
    final colStr = match.group(1)!;
    final rowVal = int.tryParse(match.group(2)!) ?? 1;

    int colIdx = 0;
    for (int i = 0; i < colStr.length; i++) {
      colIdx = colIdx * 26 + (colStr.codeUnitAt(i) - 65 + 1);
    }
    colIdx -= 1;
    return {'col': colIdx, 'row': rowVal - 1};
  }

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    if (widget.settings.containers.isNotEmpty) {
      _selectedCabinetId = widget.settings.containers.first.id;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final containers = widget.settings.containers;

    final l10n = context.l10n;
    if (containers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(l10n.noContainersConfigured),
        ),
      );
    }

    // Adjust selected cabinet if the list changes or it becomes invalid
    if (_selectedCabinetId == null ||
        !containers.any((c) => c.id == _selectedCabinetId)) {
      _selectedCabinetId = containers.first.id;
    }

    final selectedContainer =
        containers.firstWhere((c) => c.id == _selectedCabinetId);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabinet Selector ChoiceChips
        if (containers.length > 1) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.selectContainerPrompt,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: containers.length,
              itemBuilder: (ctx, idx) {
                final c = containers[idx];
                final isSelected = c.id == _selectedCabinetId;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    avatar: Icon(Icons.kitchen_outlined,
                        size: 16,
                        color: isSelected ? cs.onPrimary : cs.onSurfaceVariant),
                    label: Text(
                        c.name.isNotEmpty ? c.name : l10n.containerNumber(c.id)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedCabinetId = c.id);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.kitchen_outlined, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  selectedContainer.name.isNotEmpty
                      ? selectedContainer.name
                      : l10n.containerNumber(selectedContainer.id),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],

        // Scrolling Instructions & Statistics
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.dragToScrollGrid,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.activeDrawersCount(selectedContainer.rows * selectedContainer.columns - selectedContainer.disabledDrawers.length),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.7)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Grid visualizer wrapping double SingleChildScrollView
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
              color: cs.surfaceContainerLowest,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportWidth = constraints.maxWidth;
                  final viewportHeight = constraints.maxHeight;

                  final contentWidth = selectedContainer.columns * 88.0 + 24.0;
                  final contentHeight = selectedContainer.rows * 68.0 + 24.0;

                  final double scaleX = viewportWidth > 0 && contentWidth > 0 ? viewportWidth / contentWidth : 1.0;
                  final double scaleY = viewportHeight > 0 && contentHeight > 0 ? viewportHeight / contentHeight : 1.0;
                  
                  // Fit scale to ensure the entire cabinet fits in viewport
                  final double fitScale = scaleX < scaleY ? scaleX : scaleY;
                  final double initialScale = fitScale > 1.0 ? 1.0 : fitScale;
                  final double minScale = (fitScale * 0.5).clamp(0.01, 1.0);
                  final double maxScale = fitScale > 2.0 ? fitScale * 3.0 : 4.0;

                  if (_lastCabinetId != selectedContainer.id ||
                      _lastViewportWidth != viewportWidth ||
                      _lastViewportHeight != viewportHeight) {
                    _lastCabinetId = selectedContainer.id;
                    _lastViewportWidth = viewportWidth;
                    _lastViewportHeight = viewportHeight;

                    double dx = 0.0;
                    double dy = 0.0;
                    if (contentWidth * initialScale < viewportWidth) {
                      dx = (viewportWidth - contentWidth * initialScale) / 2.0;
                    }
                    if (contentHeight * initialScale < viewportHeight) {
                      dy = (viewportHeight - contentHeight * initialScale) / 2.0;
                    }

                    final newMatrix = Matrix4.diagonal3Values(initialScale, initialScale, 1.0)
                      ..setTranslationRaw(dx, dy, 0.0);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _transformationController.value = newMatrix;
                      }
                    });
                  }

                  return InteractiveViewer(
                    transformationController: _transformationController,
                    constrained: false,
                    scaleEnabled: true,
                    minScale: minScale,
                    maxScale: maxScale,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _buildGrid(
                            context, selectedContainer, widget.settings, ds),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, ContainerConfig container,
      AppSettings settings, DataService ds) {
    final rows = container.rows;
    final cols = container.columns;

    // Pre-group components for this container by drawer coordinate to optimize performance to O(N + C)
    final cabinetComps = ds.components
        .where((c) => c.cabinet == container.id && c.bagName == null)
        .toList();
    final Map<String, List<Component>> compsByDrawer = {};
    for (final comp in cabinetComps) {
      compsByDrawer.putIfAbsent(comp.drawer, () => []).add(comp);
    }

    // Create merge lookup
    final Map<String, List<String>> mergeGroups = {};
    for (final group in container.mergedDrawers) {
      for (final label in group) {
        mergeGroups[label] = group;
      }
    }

    final List<Widget> positionedCells = [];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final label = '${container.columnLabels[c]}${r + 1}';
        final group = mergeGroups[label];

        int minCol = c;
        int minRow = r;
        int minDCol = container.invertColumns ? (cols - 1 - c) : c;
        int maxDCol = minDCol;
        int minDRow = container.invertRows ? (rows - 1 - r) : r;
        int maxDRow = minDRow;

        if (group != null) {
          // Parse all coordinates in the group
          final coordsList = group.map((lbl) {
            final coords = _parseLabelCoords(lbl);
            final col = coords['col']!;
            final row = coords['row']!;
            final dCol = container.invertColumns ? (cols - 1 - col) : col;
            final dRow = container.invertRows ? (rows - 1 - row) : row;
            return {
              'col': col,
              'row': row,
              'dCol': dCol,
              'dRow': dRow,
            };
          }).toList();

          minCol =
              coordsList.map((e) => e['col']!).reduce((a, b) => a < b ? a : b);
          minRow =
              coordsList.map((e) => e['row']!).reduce((a, b) => a < b ? a : b);

          minDCol =
              coordsList.map((e) => e['dCol']!).reduce((a, b) => a < b ? a : b);
          maxDCol =
              coordsList.map((e) => e['dCol']!).reduce((a, b) => a > b ? a : b);
          minDRow =
              coordsList.map((e) => e['dRow']!).reduce((a, b) => a < b ? a : b);
          maxDRow =
              coordsList.map((e) => e['dRow']!).reduce((a, b) => a > b ? a : b);

          // Skip if this is not the top-left cell of the group in logical coordinates
          if (c != minCol || r != minRow) {
            continue;
          }
        }

        final double left = minDCol * 88.0;
        final double top = minDRow * 68.0;
        final double width = (maxDCol - minDCol + 1) * 88.0 - 8.0;
        final double height = (maxDRow - minDRow + 1) * 68.0 - 8.0;

        positionedCells.add(Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: _buildDrawerCell(
            context,
            container,
            label,
            settings,
            compsByDrawer,
            group: group,
          ),
        ));
      }
    }

    return SizedBox(
      width: cols * 88.0,
      height: rows * 68.0,
      child: Stack(
        children: positionedCells,
      ),
    );
  }

  Widget _buildDrawerCell(
    BuildContext context,
    ContainerConfig container,
    String label,
    AppSettings settings,
    Map<String, List<Component>> compsByDrawer, {
    List<String>? group,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDisabled = container.disabledDrawers.contains(label);
    final displayLabel = group != null ? group.join('+') : label;

    if (isDisabled) {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          displayLabel,
          style: TextStyle(
            fontSize: group != null ? 9 : 11,
            color: cs.onSurfaceVariant.withOpacity(0.25),
            decoration: TextDecoration.lineThrough,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final key = '${container.id}_$label';
    final totalZones = settings.drawerDividers[key] ?? 1;

    final List<Component> drawerComps = [];
    if (group != null) {
      for (final lbl in group) {
        final list = compsByDrawer[lbl];
        if (list != null) {
          drawerComps.addAll(list);
        }
      }
    } else {
      final list = compsByDrawer[label];
      if (list != null) {
        drawerComps.addAll(list);
      }
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: drawerComps.isNotEmpty
              ? cs.primary.withOpacity(0.6)
              : cs.outlineVariant.withOpacity(0.7),
          width: drawerComps.isNotEmpty ? 1.5 : 1.0,
        ),
        boxShadow: drawerComps.isNotEmpty
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            // Zones rendering
            Positioned.fill(
              child: totalZones <= 1
                  ? _buildZoneCell(
                      context,
                      container.id,
                      label,
                      1,
                      1,
                      drawerComps,
                      cs,
                    )
                  : Column(
                      children: List.generate(totalZones, (i) {
                        final zoneIdx = totalZones - i;
                        final zoneComps = drawerComps
                            .where((c) => (c.drawerZone ?? 1) == zoneIdx)
                            .toList();
                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: i < totalZones - 1
                                  ? Border(
                                      bottom: BorderSide(
                                          color: cs.outlineVariant.withOpacity(0.4),
                                          width: 0.8))
                                  : null,
                            ),
                            child: _buildZoneCell(
                              context,
                              container.id,
                              label,
                              zoneIdx,
                              totalZones,
                              zoneComps,
                              cs,
                            ),
                          ),
                        );
                      }),
                    ),
            ),

            // Drawer central label overlay (IgnorePointer)
            Align(
              alignment: Alignment.center,
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Text(
                    displayLabel,
                    style: TextStyle(
                      fontSize: group != null ? 8.5 : 9.5,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCell(
    BuildContext context,
    int cabinetId,
    String drawerLabel,
    int zoneIndex,
    int totalZones,
    List<Component> comps,
    ColorScheme cs,
  ) {
    final isOccupied = comps.isNotEmpty;
    return Material(
      color: isOccupied
          ? cs.primaryContainer.withOpacity(totalZones > 1 ? 0.75 : 0.9)
          : cs.surface,
      child: InkWell(
        onTap: () => _showDrawerDetails(context, cabinetId, drawerLabel),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Stack(
            children: [
              // Position letter for divided zones
              if (totalZones > 1)
                Positioned(
                  top: 0,
                  left: 2,
                  child: Text(
                    () {
                      final label = getZoneLabel(zoneIndex, totalZones, context.l10n);
                      return label.isNotEmpty ? label[0].toUpperCase() : '';
                    }(),
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      color: isOccupied
                          ? cs.onPrimaryContainer.withOpacity(0.65)
                          : cs.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
              // Quantity components count badge
              if (isOccupied)
                Align(
                  alignment: totalZones > 1
                      ? Alignment.centerRight
                      : Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${comps.length}',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDrawerDetails(
      BuildContext context, int cabinetId, String drawerLabel) {
    final container =
        widget.settings.containers.firstWhere((c) => c.id == cabinetId);
    final mergeGroup = container.mergedDrawers.firstWhere(
      (g) => g.contains(drawerLabel),
      orElse: () => <String>[],
    );
    final primaryLabel = mergeGroup.isNotEmpty ? mergeGroup.first : drawerLabel;
    final key = '${cabinetId}_$primaryLabel';
    final totalZones = widget.settings.drawerDividers[key] ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bSheetCtx) {
        return Consumer<DataService>(
          builder: (context, currentDs, __) {
            final l10n = context.l10n;
            final drawerComps = currentDs.components
                .where((c) =>
                    c.cabinet == cabinetId &&
                    (mergeGroup.isEmpty
                        ? c.drawer == drawerLabel
                        : mergeGroup.contains(c.drawer)) &&
                    c.bagName == null)
                .toList();

            final cs = Theme.of(context).colorScheme;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(bSheetCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pull indicator handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Bottom sheet Header details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mergeGroup.isNotEmpty
                                ? l10n.mergedDrawers(mergeGroup.join('+'))
                                : l10n.drawerNumber(drawerLabel),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            container.name.isNotEmpty
                                ? container.name
                                : l10n.containerNumber(cabinetId),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(bSheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Zone contents
                  Expanded(
                    child: ListView.builder(
                      itemCount: totalZones,
                      itemBuilder: (ctx2, index) {
                        final zoneIdx = index + 1;
                        final zoneLabel = getZoneLabel(zoneIdx, totalZones, l10n);
                        final zoneComps = drawerComps
                            .where((c) => (c.drawerZone ?? 1) == zoneIdx)
                            .toList();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          color: cs.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: cs.outlineVariant.withOpacity(0.5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Zone header bar with "Aggiungi" button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.layers_outlined,
                                              size: 18, color: cs.primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              totalZones > 1
                                                  ? '${l10n.compZoneLabel} $zoneIdx ($zoneLabel)'
                                                  : l10n.drawerContent,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: cs.primary,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.add, size: 16),
                                      label: Text(l10n.add,
                                          style: const TextStyle(fontSize: 12)),
                                      onPressed: () => _addComponentAtZone(
                                          bSheetCtx,
                                          cabinetId,
                                          primaryLabel,
                                          zoneIdx),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),

                                // Zone item contents list
                                if (zoneComps.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20.0),
                                    child: Center(
                                      child: Text(
                                        l10n.emptyZoneNotice,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: cs.onSurfaceVariant
                                              .withOpacity(0.7),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: zoneComps.map((comp) {
                                      return _buildComponentItem(
                                          context, comp, currentDs, cs);
                                    }).toList(),
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
            );
          },
        );
      },
    );
  }

  Widget _buildComponentItem(
    BuildContext context,
    Component comp,
    DataService ds,
    ColorScheme cs,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          comp.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (comp.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                comp.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
            if (comp.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: comp.tags
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                                fontSize: 9,
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.w500),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decrement quantity button
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: () {
                if (comp.quantity > 0) {
                  ds.updateQuantity(comp.id, -1);
                }
              },
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            // Quantity badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${comp.quantity}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: cs.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Increment quantity button
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: () => ds.updateQuantity(comp.id, 1),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        onTap: () {
          // Open details viewer
          widget.onViewComponent(comp);
        },
      ),
    );
  }

  Future<void> _addComponentAtZone(
    BuildContext context,
    int cabinetId,
    String drawerLabel,
    int zoneIndex,
  ) async {
    final l10n = context.l10n;
    final ds = widget.dataService;
    final hasUnassigned =
        ds.components.any((c) => c.drawer.isEmpty && c.bagName == null);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(l10n.addComponentTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.add),
                ),
                title: Text(l10n.newComponent),
                subtitle:
                    Text(l10n.createFromScratchAndInsert),
                onTap: () {
                  Navigator.pop(dialogCtx);
                  widget.onAddComponentAt(cabinetId, drawerLabel, zoneIndex);
                },
              ),
              const Divider(),
              ListTile(
                enabled: hasUnassigned,
                leading: CircleAvatar(
                  backgroundColor: hasUnassigned ? null : Colors.grey.shade300,
                  child: Icon(Icons.drive_file_move_outlined,
                      color: hasUnassigned ? null : Colors.grey),
                ),
                title: Text(l10n.assignExisting),
                subtitle: Text(hasUnassigned
                    ? l10n.chooseFromUnassigned
                    : l10n.noUnassignedAvailable),
                onTap: hasUnassigned
                    ? () {
                        Navigator.pop(dialogCtx);
                        _showUnassignedPicker(
                            context, cabinetId, drawerLabel, zoneIndex);
                      }
                    : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  void _showUnassignedPicker(
    BuildContext context,
    int cabinetId,
    String drawerLabel,
    int zoneIndex,
  ) {
    showDialog(
      context: context,
      builder: (pickerCtx) {
        return _UnassignedComponentPickerDialog(
          dataService: widget.dataService,
          cabinetId: cabinetId,
          drawerLabel: drawerLabel,
          zoneIndex: zoneIndex,
        );
      },
    );
  }
}

class _UnassignedComponentPickerDialog extends StatefulWidget {
  final DataService dataService;
  final int cabinetId;
  final String drawerLabel;
  final int zoneIndex;

  const _UnassignedComponentPickerDialog({
    required this.dataService,
    required this.cabinetId,
    required this.drawerLabel,
    required this.zoneIndex,
  });

  @override
  State<_UnassignedComponentPickerDialog> createState() =>
      _UnassignedComponentPickerDialogState();
}

class _UnassignedComponentPickerDialogState
    extends State<_UnassignedComponentPickerDialog> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final allUnassigned = widget.dataService.components
        .where((c) => c.drawer.isEmpty && c.bagName == null)
        .toList();

    final filtered = allUnassigned
        .where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.description.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return AlertDialog(
      title: Text(l10n.assignExistingComponentTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n.searchByName,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: cs.surfaceContainerLow,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    l10n.noComponentsFound,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final comp = filtered[idx];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                            color: cs.outlineVariant.withOpacity(0.5)),
                      ),
                      child: ListTile(
                        title: Text(comp.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (comp.description.isNotEmpty)
                              Text(comp.description,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (comp.tags.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: comp.tags
                                    .map((t) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: cs.secondaryContainer
                                                .withOpacity(0.5),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(t,
                                              style: TextStyle(
                                                  fontSize: 8,
                                                  color:
                                                      cs.onSecondaryContainer)),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.qtyShort(comp.quantity),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ),
                        onTap: () async {
                          final updated = comp.copyWith(
                            cabinet: widget.cabinetId,
                            drawer: widget.drawerLabel,
                            drawerZone: widget.zoneIndex,
                          );
                          try {
                            await widget.dataService.updateComponent(updated);
                            if (ctx.mounted) {
                              Navigator.pop(ctx); // Close picker dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        l10n.componentAssignedSuccess(comp.name))),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        l10n.assignError(e.toString()))),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
