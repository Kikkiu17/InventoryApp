/// Helper per formattare "10K" con "Ω" -> "10KΩ" e "10" con "mm" -> "10mm"
String formatValueWithUnit(String value, String unit) {
  if (unit.isEmpty) return value;
  final v = value.trim();

  final regEnd = RegExp(r'^([0-9]+(?:\.[0-9]+)?)([a-zA-Zµ])$');
  final match = regEnd.firstMatch(v);
  if (match != null) {
    return '${match.group(1)}${match.group(2)}$unit';
  }

  return '$v$unit';
}

class SpecialTag {
  String name;
  String unit;
  bool isString; // Specifica se è una stringa di testo libero
  String shortId; // Identificatore breve (es. "L", "W")

  SpecialTag({
    required this.name,
    this.unit = '',
    this.isString = false,
    this.shortId = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
        'isString': isString,
        'shortId': shortId,
      };

  factory SpecialTag.fromJson(Map<String, dynamic> json) => SpecialTag(
        name: json['name'] as String,
        unit: json['unit'] as String? ?? '',
        isString: json['isString'] as bool? ?? false,
        shortId: json['shortId'] as String? ??
            json['shortName'] as String? ??
            json['abbreviation'] as String? ??
            '',
      );

  SpecialTag clone() => SpecialTag(
        name: name,
        unit: unit,
        isString: isString,
        shortId: shortId,
      );

  SpecialTag copyWith({
    String? name,
    String? unit,
    bool? isString,
    String? shortId,
  }) =>
      SpecialTag(
        name: name ?? this.name,
        unit: unit ?? this.unit,
        isString: isString ?? this.isString,
        shortId: shortId ?? this.shortId,
      );
}

class ContainerConfig {
  final int id; // Corrisponde al campo cabinet di Component
  String name;
  int rows;
  int columns;
  List<String> disabledDrawers; // Lista dei cassetti disattivati (es. "A1")
  bool invertRows;
  bool invertColumns;
  List<List<String>> mergedDrawers; // Lista dei gruppi di cassetti uniti (es. [["A1", "A2"]])

  ContainerConfig({
    required this.id,
    this.name = '',
    required this.rows,
    required this.columns,
    List<String>? disabledDrawers,
    this.invertRows = false,
    this.invertColumns = false,
    List<List<String>>? mergedDrawers,
  })  : disabledDrawers = disabledDrawers ?? [],
        mergedDrawers = mergedDrawers ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rows': rows,
        'columns': columns,
        'disabledDrawers': disabledDrawers,
        'invertRows': invertRows,
        'invertColumns': invertColumns,
        'mergedDrawers': mergedDrawers.map((list) => list).toList(),
      };

  factory ContainerConfig.fromJson(Map<String, dynamic> json) => ContainerConfig(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        rows: json['rows'] as int? ?? 4,
        columns: json['columns'] as int? ?? 6,
        disabledDrawers: List<String>.from(json['disabledDrawers'] as List? ?? []),
        invertRows: json['invertRows'] as bool? ?? false,
        invertColumns: json['invertColumns'] as bool? ?? false,
        mergedDrawers: (json['mergedDrawers'] as List?)
            ?.map((e) => List<String>.from(e as List))
            .toList() ?? [],
      );

  List<String> get columnLabels => List.generate(columns, (i) {
        String name = '';
        int index = i;
        while (index >= 0) {
          name = String.fromCharCode(65 + (index % 26)) + name;
          index = (index ~/ 26) - 1;
        }
        return name;
      });

  List<String> get rowLabels =>
      List.generate(rows, (i) => '${i + 1}');

  List<String> get drawerLabels {
    final labels = <String>[];
    for (final col in columnLabels) {
      for (final row in rowLabels) {
        final label = '$col$row';
        if (!disabledDrawers.contains(label)) {
          labels.add(label);
        }
      }
    }
    return labels;
  }

  bool isDrawerValid(String label) {
    if (disabledDrawers.contains(label)) return false;
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(label);
    if (match == null) return false;
    
    final colStr = match.group(1)!;
    final rowVal = int.tryParse(match.group(2)!) ?? 0;
    
    if (rowVal < 1 || rowVal > rows) return false;
    
    int colIdx = 0;
    for (int i = 0; i < colStr.length; i++) {
      colIdx = colIdx * 26 + (colStr.codeUnitAt(i) - 65 + 1);
    }
    colIdx -= 1;
    if (colIdx < 0 || colIdx >= columns) return false;
    
    return true;
  }
}

class AppSettings {
  List<ContainerConfig> containers;
  List<String> availableTags;
  Map<String, dynamic> tagTree;
  List<SpecialTag> specialTags;
  Map<String, int> drawerDividers;
  List<String> bufferBags;

  AppSettings({
    List<ContainerConfig>? containers,
    int? numCabinets,
    int? drawerRows,
    int? drawerColumns,
    List<String>? availableTags,
    Map<String, dynamic>? tagTree,
    List<SpecialTag>? specialTags,
    Map<String, int>? drawerDividers,
    List<String>? bufferBags,
  })  : availableTags = availableTags ?? [],
        tagTree = tagTree ?? {},
        specialTags = specialTags ?? [],
        drawerDividers = drawerDividers ?? {},
        containers = containers ?? [],
        bufferBags = bufferBags ?? [] {
    if (this.containers.isEmpty) {
      final legacyNumCabinets = numCabinets ?? 1;
      final legacyRows = drawerRows ?? 4;
      final legacyCols = drawerColumns ?? 6;
      this.containers = List.generate(
        legacyNumCabinets,
        (i) => ContainerConfig(
          id: i + 1,
          name: 'Contenitore ${i + 1}',
          rows: legacyRows,
          columns: legacyCols,
          disabledDrawers: [],
        ),
      );
    }
  }

  int get numCabinets => containers.length;
  int get drawerRows => containers.isNotEmpty ? containers.first.rows : 4;
  int get drawerColumns => containers.isNotEmpty ? containers.first.columns : 6;

  Map<String, dynamic> toJson() => {
        'numCabinets': numCabinets,
        'drawerRows': drawerRows,
        'drawerColumns': drawerColumns,
        'containers': containers.map((c) => c.toJson()).toList(),
        'availableTags': availableTags,
        'tagTree': tagTree,
        'specialTags': specialTags.map((t) => t.toJson()).toList(),
        'drawerDividers': drawerDividers,
        'bufferBags': bufferBags,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    List<ContainerConfig>? parsedContainers;
    if (json['containers'] != null) {
      parsedContainers = (json['containers'] as List)
          .map((e) => ContainerConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return AppSettings(
      containers: parsedContainers,
      numCabinets: json['numCabinets'] as int?,
      drawerRows: json['drawerRows'] as int?,
      drawerColumns: json['drawerColumns'] as int?,
      availableTags: List<String>.from(json['availableTags'] as List? ?? []),
      tagTree: _parseTree(json['tagTree']),
      specialTags: (json['specialTags'] as List? ?? [])
          .map((e) => SpecialTag.fromJson(e))
          .toList(),
      drawerDividers: (json['drawerDividers'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      bufferBags: List<String>.from(json['bufferBags'] as List? ?? []),
    );
  }

  static Map<String, dynamic> _parseTree(dynamic jsonMap) {
    if (jsonMap is! Map) return {};
    final map = <String, dynamic>{};
    for (final key in jsonMap.keys) {
      map[key.toString()] = _parseTree(jsonMap[key]);
    }
    return map;
  }

  void _flattenTree(Map<String, dynamic> node, Set<String> out) {
    for (final k in node.keys) {
      out.add(k);
      if (node[k] is Map<String, dynamic>) {
        _flattenTree(node[k], out);
      }
    }
  }

  List<String> get columnLabels => containers.isNotEmpty ? containers.first.columnLabels : [];
  List<String> get rowLabels => containers.isNotEmpty ? containers.first.rowLabels : [];

  String drawerLabel(String col, String row) => '$col$row';

  List<String> get drawerLabels {
    final labels = <String>[];
    if (containers.isNotEmpty) {
      labels.addAll(containers.first.drawerLabels);
    }
    return labels;
  }

  List<String> get allTags {
    final set = <String>{};
    _flattenTree(tagTree, set);
    set.addAll(availableTags);
    final list = set.toList()..sort();
    return list;
  }
}