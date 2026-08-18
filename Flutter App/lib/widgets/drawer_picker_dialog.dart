import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/settings.dart';
import '../services/data_service.dart';

class DrawerGridPicker extends StatefulWidget {
  final AppSettings settings;
  final DataService dataService;
  final int selectedCabinetId;
  final String selectedCol;
  final String selectedRow;
  final int? selectedZone;
  final Function(int cabinetId, String col, String row, int? zone)
      onDrawerSelected;
  final Function(int cabinetId)? onCabinetChanged;
  final bool showCabinetSelector;

  const DrawerGridPicker({
    super.key,
    required this.settings,
    required this.dataService,
    required this.selectedCabinetId,
    required this.selectedCol,
    required this.selectedRow,
    this.selectedZone,
    required this.onDrawerSelected,
    this.onCabinetChanged,
    this.showCabinetSelector = true,
  });

  @override
  State<DrawerGridPicker> createState() => _DrawerGridPickerState();
}

class _DrawerGridPickerState extends State<DrawerGridPicker> {
  late int _currentCabinetId;
  late TransformationController _transformationController;
  int? _lastCabinetId;
  double? _lastViewportWidth;
  double? _lastViewportHeight;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _currentCabinetId = widget.selectedCabinetId;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DrawerGridPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCabinetId != widget.selectedCabinetId) {
      _currentCabinetId = widget.selectedCabinetId;
    }
  }

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
  Widget build(BuildContext context) {
    final containers = widget.settings.containers;
    final cs = Theme.of(context).colorScheme;

    if (containers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Nessun contenitore configurato nelle impostazioni.'),
      );
    }

    if (!containers.any((c) => c.id == _currentCabinetId)) {
      _currentCabinetId = containers.first.id;
    }

    final selectedContainer =
        containers.firstWhere((c) => c.id == _currentCabinetId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showCabinetSelector && containers.length > 1) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Seleziona contenitore:',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: containers.length,
              itemBuilder: (ctx, idx) {
                final c = containers[idx];
                final isSel = c.id == _currentCabinetId;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    avatar: Icon(Icons.kitchen_outlined,
                        size: 14,
                        color: isSel ? cs.onPrimary : cs.onSurfaceVariant),
                    label: Text(
                        c.name.isNotEmpty ? c.name : 'Contenitore ${c.id}',
                        style: const TextStyle(fontSize: 12)),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _currentCabinetId = c.id);
                        if (widget.onCabinetChanged != null) {
                          widget.onCabinetChanged!(c.id);
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Header status summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.selectedCol.isNotEmpty && widget.selectedRow.isNotEmpty
                      ? 'Selezionato: Cassetto ${widget.selectedCol.toUpperCase()}${widget.selectedRow}'
                          '${widget.selectedZone != null ? " (Zona ${widget.selectedZone})" : ""}'
                      : 'Tocca un cassetto per selezionarlo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Interactive grid container
        Container(
          height: 280,
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10),
            color: cs.surfaceContainerLowest,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportWidth = constraints.maxWidth;
                final viewportHeight = constraints.maxHeight;

                final contentWidth = selectedContainer.columns * 80.0 + 16.0;
                final contentHeight = selectedContainer.rows * 62.0 + 16.0;

                final double scaleX = viewportWidth > 0 && contentWidth > 0 ? viewportWidth / contentWidth : 1.0;
                final double scaleY = viewportHeight > 0 && contentHeight > 0 ? viewportHeight / contentHeight : 1.0;
                
                // Fit scale to ensure the entire cabinet fits in viewport
                final double fitScale = scaleX < scaleY ? scaleX : scaleY;
                final double initialScale = fitScale > 1.0 ? 1.0 : fitScale;
                final double minScale = (fitScale * 0.5).clamp(0.01, 1.0);
                final double maxScale = fitScale > 2.0 ? fitScale * 3.0 : 4.0;

                if (_lastCabinetId != _currentCabinetId ||
                    _lastViewportWidth != viewportWidth ||
                    _lastViewportHeight != viewportHeight) {
                  _lastCabinetId = _currentCabinetId;
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
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildGrid(context, selectedContainer),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, ContainerConfig container) {
    final rows = container.rows;
    final cols = container.columns;

    final cabinetComps = widget.dataService.components
        .where((c) => c.cabinet == container.id && c.bagName == null)
        .toList();
    final Map<String, List<Component>> compsByDrawer = {};
    for (final comp in cabinetComps) {
      compsByDrawer.putIfAbsent(comp.drawer, () => []).add(comp);
    }

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
          final coordsList = group.map((lbl) {
            final coords = _parseLabelCoords(lbl);
            final col = coords['col']!;
            final row = coords['row']!;
            final dCol = container.invertColumns ? (cols - 1 - col) : col;
            final dRow = container.invertRows ? (rows - 1 - row) : row;
            return {'col': col, 'row': row, 'dCol': dCol, 'dRow': dRow};
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

          if (c != minCol || r != minRow) {
            continue;
          }
        }

        final double left = minDCol * 80.0;
        final double top = minDRow * 62.0;
        final double width = (maxDCol - minDCol + 1) * 80.0 - 6.0;
        final double height = (maxDRow - minDRow + 1) * 62.0 - 6.0;

        positionedCells.add(Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: _buildDrawerCell(
            context,
            container,
            label,
            compsByDrawer,
            group: group,
          ),
        ));
      }
    }

    return SizedBox(
      width: cols * 80.0,
      height: rows * 62.0,
      child: Stack(
        children: positionedCells,
      ),
    );
  }

  Widget _buildDrawerCell(
    BuildContext context,
    ContainerConfig container,
    String label,
    Map<String, List<Component>> compsByDrawer, {
    List<String>? group,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDisabled = container.disabledDrawers.contains(label);
    final displayLabel = group != null ? group.join('+') : label;

    if (isDisabled) {
      return Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          displayLabel,
          style: TextStyle(
            fontSize: group != null ? 8 : 10,
            color: cs.onSurfaceVariant.withOpacity(0.25),
            decoration: TextDecoration.lineThrough,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final key = '${container.id}_$label';
    final totalZones = widget.settings.drawerDividers[key] ?? 1;

    final match = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(label);
    final colStr = match?.group(1)?.toUpperCase() ?? '';
    final rowStr = match?.group(2) ?? '';

    final isDrawerSelected = _currentCabinetId == widget.selectedCabinetId &&
        widget.selectedCol.toUpperCase() == colStr &&
        widget.selectedRow == rowStr;

    final List<Component> drawerComps = [];
    if (group != null) {
      for (final lbl in group) {
        final list = compsByDrawer[lbl];
        if (list != null) drawerComps.addAll(list);
      }
    } else {
      final list = compsByDrawer[label];
      if (list != null) drawerComps.addAll(list);
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDrawerSelected
              ? cs.primary
              : drawerComps.isNotEmpty
                  ? cs.primary.withOpacity(0.4)
                  : cs.outlineVariant.withOpacity(0.7),
          width: isDrawerSelected ? 2.5 : (drawerComps.isNotEmpty ? 1.5 : 1.0),
        ),
        boxShadow: isDrawerSelected
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            Positioned.fill(
              child: totalZones <= 1
                  ? _buildZoneCell(
                      context,
                      container.id,
                      colStr,
                      rowStr,
                      1,
                      1,
                      isDrawerSelected &&
                          (widget.selectedZone == null || widget.selectedZone == 1),
                      drawerComps,
                      cs,
                    )
                  : Column(
                      children: List.generate(totalZones, (i) {
                        final zoneIdx = totalZones - i;
                        final isZoneSel = isDrawerSelected &&
                            (widget.selectedZone == zoneIdx ||
                                (widget.selectedZone == null && zoneIdx == 1));
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
                              colStr,
                              rowStr,
                              zoneIdx,
                              totalZones,
                              isZoneSel,
                              zoneComps,
                              cs,
                            ),
                          ),
                        );
                      }),
                    ),
            ),

            // Central Drawer Label Overlay
            Align(
              alignment: Alignment.center,
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isDrawerSelected
                        ? cs.primaryContainer
                        : cs.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isDrawerSelected
                          ? cs.primary
                          : cs.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    displayLabel,
                    style: TextStyle(
                      fontSize: group != null ? 8 : 9,
                      fontWeight: FontWeight.bold,
                      color: isDrawerSelected
                          ? cs.onPrimaryContainer
                          : cs.onSurface,
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
    String colStr,
    String rowStr,
    int zoneIndex,
    int totalZones,
    bool isSelected,
    List<Component> comps,
    ColorScheme cs,
  ) {
    final isOccupied = comps.isNotEmpty;
    final backgroundColor = isSelected
        ? cs.primaryContainer
        : isOccupied
            ? cs.primaryContainer.withOpacity(totalZones > 1 ? 0.4 : 0.6)
            : cs.surface;

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: () {
          widget.onDrawerSelected(
              cabinetId, colStr, rowStr, totalZones > 1 ? zoneIndex : null);
        },
        child: Padding(
          padding: const EdgeInsets.all(1.5),
          child: Stack(
            children: [
              if (totalZones > 1)
                Positioned(
                  top: 0,
                  left: 2,
                  child: Text(
                    zoneIndex == 1
                        ? 'V'
                        : zoneIndex == totalZones
                            ? 'L'
                            : 'M',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ),
              if (isOccupied)
                Align(
                  alignment: totalZones > 1
                      ? Alignment.centerRight
                      : Alignment.bottomRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary
                          : cs.primary.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${comps.length}',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle,
                    size: 10,
                    color: cs.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerPickerDialog extends StatelessWidget {
  final AppSettings settings;
  final DataService dataService;
  final int initialCabinetId;
  final String initialCol;
  final String initialRow;
  final int? initialZone;

  const DrawerPickerDialog({
    super.key,
    required this.settings,
    required this.dataService,
    required this.initialCabinetId,
    required this.initialCol,
    required this.initialRow,
    this.initialZone,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required AppSettings settings,
    required DataService dataService,
    required int initialCabinetId,
    required String initialCol,
    required String initialRow,
    int? initialZone,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => DrawerPickerDialog(
        settings: settings,
        dataService: dataService,
        initialCabinetId: initialCabinetId,
        initialCol: initialCol,
        initialRow: initialRow,
        initialZone: initialZone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int cabinetId = initialCabinetId;
    String col = initialCol;
    String row = initialRow;
    int? zone = initialZone;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.grid_view),
          SizedBox(width: 8),
          Text('Seleziona Cassetto'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return DrawerGridPicker(
                settings: settings,
                dataService: dataService,
                selectedCabinetId: cabinetId,
                selectedCol: col,
                selectedRow: row,
                selectedZone: zone,
                onCabinetChanged: (newCab) {
                  setDialogState(() {
                    cabinetId = newCab;
                  });
                },
                onDrawerSelected: (cId, cStr, rStr, zIdx) {
                  setDialogState(() {
                    cabinetId = cId;
                    col = cStr;
                    row = rStr;
                    zone = zIdx;
                  });
                  Navigator.pop(context, {
                    'cabinetId': cabinetId,
                    'col': col,
                    'row': row,
                    'zone': zone,
                  });
                },
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
      ],
    );
  }
}
