class SpecialTag {
  String name;
  String unit;
  bool isString; // Specifica se è una stringa di testo libero

  SpecialTag({required this.name, this.unit = '', this.isString = false});

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
        'isString': isString,
      };

  factory SpecialTag.fromJson(Map<String, dynamic> json) => SpecialTag(
        name: json['name'] as String,
        unit: json['unit'] as String? ?? '',
        isString: json['isString'] as bool? ?? false,
      );
}

class AppSettings {
  int numCabinets;
  int drawerRows;
  int drawerColumns;
  List<String> availableTags;
  Map<String, dynamic> tagTree;
  List<SpecialTag> specialTags;

  AppSettings({
    this.numCabinets = 1,
    this.drawerRows = 4,
    this.drawerColumns = 6,
    List<String>? availableTags,
    Map<String, dynamic>? tagTree,
    List<SpecialTag>? specialTags,
  })  : availableTags = availableTags ?? [],
        tagTree = tagTree ?? {},
        specialTags = specialTags ?? [];

  Map<String, dynamic> toJson() => {
        'numCabinets': numCabinets,
        'drawerRows': drawerRows,
        'drawerColumns': drawerColumns,
        'availableTags': availableTags,
        'tagTree': tagTree,
        'specialTags': specialTags.map((t) => t.toJson()).toList(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      numCabinets: json['numCabinets'] as int? ?? 1,
      drawerRows: json['drawerRows'] as int? ?? 4,
      drawerColumns: json['drawerColumns'] as int? ?? 6,
      availableTags: List<String>.from(json['availableTags'] as List? ?? []),
      tagTree: _parseTree(json['tagTree']),
      specialTags: (json['specialTags'] as List? ?? [])
          .map((e) => SpecialTag.fromJson(e))
          .toList(),
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

  List<String> get columnLabels => List.generate(drawerColumns, (i) {
        String name = '';
        int index = i;
        while (index >= 0) {
          name = String.fromCharCode(65 + (index % 26)) + name;
          index = (index ~/ 26) - 1;
        }
        return name;
      });

  List<String> get rowLabels =>
      List.generate(drawerRows, (i) => '${i + 1}');

  String drawerLabel(String col, String row) => '$col$row';

  List<String> get drawerLabels {
    final labels = <String>[];
    for (final col in columnLabels) {
      for (final row in rowLabels) {
        labels.add('$col$row');
      }
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