import 'package:uuid/uuid.dart';

double _getMultiplier(String letter) {
  switch (letter) {
    case 'T': case 't': return 1e12;
    case 'G': case 'g': return 1e9;
    case 'M':           return 1e6;  
    case 'k': case 'K': return 1e3;  
    case 'm':           return 1e-3; 
    case 'u': case 'U': case 'µ': return 1e-6; 
    case 'n': case 'N': return 1e-9; 
    case 'p': case 'P': return 1e-12; 
    case 'f': case 'F': return 1e-15; 
    default: return 1.0; 
  }
}

double? parseSpecialValue(String text) {
  String v = text.trim().replaceAll(',', '.');
  if (v.isEmpty) return null;
  
  final direct = double.tryParse(v);
  if (direct != null) return direct;

  final reg1 = RegExp(r'^([0-9]+)([a-zA-Zµ])([0-9]*)$');
  final match1 = reg1.firstMatch(v);
  
  if (match1 != null) {
    final part1 = match1.group(1)!;
    final letter = match1.group(2)!;
    final part2 = match1.group(3)!;

    final numStr = '$part1.${part2.isEmpty ? '0' : part2}';
    final baseNum = double.tryParse(numStr);
    if (baseNum != null) {
      return baseNum * _getMultiplier(letter);
    }
  }

  final reg2 = RegExp(r'^([0-9]*\.?[0-9]+)([a-zA-Zµ])$');
  final match2 = reg2.firstMatch(v);
  if (match2 != null) {
    final baseNum = double.tryParse(match2.group(1)!);
    final letter = match2.group(2)!;
    if (baseNum != null) {
      return baseNum * _getMultiplier(letter);
    }
  }

  return null;
}

class Attachment {
  final String name;
  final String path;
  final bool isLink;

  Attachment({required this.name, required this.path, this.isLink = false});

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'isLink': isLink,
      };

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        name: json['name'] as String? ?? '',
        path: json['path'] as String? ?? '',
        isLink: json['isLink'] as bool? ?? false,
      );
}

class Component {
  final String id;
  String name;
  String description;
  int quantity;
  int cabinet;
  String drawer;
  List<String> tags;
  Map<String, String> specialTagValues; // Ora salviamo esattamente ciò che scrivi!
  List<Attachment> attachments;
  int? drawerZone;
  String? bagName;
  String note;
  String? targetInventoryId;
  List<String> images;
 
  Component({
    String? id,
    required this.name,
    this.description = '',
    this.quantity = 0,
    this.cabinet = 1,
    required this.drawer,
    this.tags = const [],
    Map<String, String>? specialTagValues,
    List<Attachment>? attachments,
    this.drawerZone,
    this.bagName,
    this.note = '',
    this.targetInventoryId,
    List<String>? images,
  })  : id = id ?? const Uuid().v4(),
        specialTagValues = specialTagValues ?? {},
        attachments = attachments ?? [],
        images = images ?? [];
 
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'quantity': quantity,
        'cabinet': cabinet,
        'drawer': drawer,
        'tags': tags,
        'specialTagValues': specialTagValues,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        if (drawerZone != null) 'drawerZone': drawerZone,
        if (bagName != null) 'bagName': bagName,
        'note': note,
        if (targetInventoryId != null) 'targetInventoryId': targetInventoryId,
        'images': images,
      };
 
  factory Component.fromJson(Map<String, dynamic> json) => Component(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        cabinet: json['cabinet'] as int? ?? 1,
        drawer: json['drawer'] as String,
        tags: List<String>.from(json['tags'] as List? ?? []),
        specialTagValues: (json['specialTagValues'] as Map<String, dynamic>?)
                ?.map((k, v) {
                  // Gestisce la retro-compatibilità con i vecchi double salvati!
                  String strVal;
                  if (v is num) {
                    strVal = (v == v.truncateToDouble()) ? v.toInt().toString() : v.toString();
                  } else {
                    strVal = v.toString();
                  }
                  return MapEntry(k, strVal);
                }) ??
            {},
        attachments: (json['attachments'] as List?)
                ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        drawerZone: json['drawerZone'] as int?,
        bagName: json['bagName'] as String?,
        note: json['note'] as String? ?? '',
        targetInventoryId: json['targetInventoryId'] as String?,
        images: List<String>.from(json['images'] as List? ?? []),
      );
 
  Component copyWith({
    String? name,
    String? description,
    int? quantity,
    int? cabinet,
    String? drawer,
    List<String>? tags,
    Map<String, String>? specialTagValues,
    List<Attachment>? attachments,
    int? drawerZone,
    String? bagName,
    bool clearBagName = false,
    String? note,
    String? targetInventoryId,
    bool clearTargetInventoryId = false,
    List<String>? images,
  }) =>
      Component(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        quantity: quantity ?? this.quantity,
        cabinet: cabinet ?? this.cabinet,
        drawer: drawer ?? this.drawer,
        tags: tags ?? this.tags,
        specialTagValues: specialTagValues ?? this.specialTagValues,
        attachments: attachments ?? this.attachments,
        drawerZone: drawerZone ?? this.drawerZone,
        bagName: clearBagName ? null : (bagName ?? this.bagName),
        note: note ?? this.note,
        targetInventoryId: clearTargetInventoryId ? null : (targetInventoryId ?? this.targetInventoryId),
        images: images ?? this.images,
      );
}

String getZoneLabel(int zoneIndex, int totalZones, [dynamic l10n]) {
  if (l10n != null) {
    if (zoneIndex == 1) return l10n.zoneNearLabel;
    if (zoneIndex == totalZones) return l10n.zoneFarLabel;
    if (totalZones == 3) return l10n.zoneMiddleLabel;
    return l10n.zoneMiddleIndex(zoneIndex);
  }
  if (zoneIndex == 1) return 'Vicina (davanti)';
  if (zoneIndex == totalZones) return 'Lontana (retro)';
  if (totalZones == 3) return 'In mezzo';
  return 'In mezzo ($zoneIndex)';
}