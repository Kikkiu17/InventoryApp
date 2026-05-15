import 'component.dart';

class GlobalSearchResult {
  final String inventoryId;
  final String inventoryName;
  final Component component;

  GlobalSearchResult({
    required this.inventoryId,
    required this.inventoryName,
    required this.component,
  });

  factory GlobalSearchResult.fromJson(Map<String, dynamic> json) {
    return GlobalSearchResult(
      inventoryId: json['inventoryId'] as String,
      inventoryName: json['inventoryName'] as String,
      component: Component.fromJson(json['component'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventoryId': inventoryId,
      'inventoryName': inventoryName,
      'component': component.toJson(),
    };
  }
}
