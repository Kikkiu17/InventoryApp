import 'component.dart';
import 'settings.dart';

class GlobalSearchResult {
  final String inventoryId;
  final String inventoryName;
  final Component component;
  final List<SpecialTag>? specialTags;
  final AppSettings? settings;

  GlobalSearchResult({
    required this.inventoryId,
    required this.inventoryName,
    required this.component,
    this.specialTags,
    this.settings,
  });

  factory GlobalSearchResult.fromJson(Map<String, dynamic> json) {
    return GlobalSearchResult(
      inventoryId: json['inventoryId'] as String,
      inventoryName: json['inventoryName'] as String,
      component: Component.fromJson(json['component'] as Map<String, dynamic>),
      specialTags: (json['specialTags'] as List?)
          ?.map((t) => SpecialTag.fromJson(t as Map<String, dynamic>))
          .toList(),
      settings: json['settings'] != null
          ? AppSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventoryId': inventoryId,
      'inventoryName': inventoryName,
      'component': component.toJson(),
      if (specialTags != null)
        'specialTags': specialTags!.map((t) => t.toJson()).toList(),
      if (settings != null)
        'settings': settings!.toJson(),
    };
  }
}
