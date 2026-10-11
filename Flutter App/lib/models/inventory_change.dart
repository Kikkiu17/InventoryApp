import '../models/component.dart';

enum ComponentChangeType {
  added,
  modified,
  deleted,
}

class ComponentFieldChange {
  final String fieldName;
  final String oldValue;
  final String newValue;

  const ComponentFieldChange({
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
  });

  Map<String, dynamic> toJson() => {
        'fieldName': fieldName,
        'oldValue': oldValue,
        'newValue': newValue,
      };

  factory ComponentFieldChange.fromJson(Map<String, dynamic> json) =>
      ComponentFieldChange(
        fieldName: json['fieldName'] as String? ?? '',
        oldValue: json['oldValue'] as String? ?? '',
        newValue: json['newValue'] as String? ?? '',
      );
}

class ComponentChange {
  final String inventoryId;
  final String inventoryName;
  final ComponentChangeType type;
  /// The current component (for added or modified) or previous component (for deleted)
  final Component component;
  /// The previous component before modification (null if added)
  final Component? oldComponent;
  final List<ComponentFieldChange> fieldChanges;

  const ComponentChange({
    required this.inventoryId,
    required this.inventoryName,
    required this.type,
    required this.component,
    this.oldComponent,
    this.fieldChanges = const [],
  });

  bool get isAdded => type == ComponentChangeType.added;
  bool get isModified => type == ComponentChangeType.modified;
  bool get isDeleted => type == ComponentChangeType.deleted;

  int? get quantityDelta {
    if (oldComponent != null) {
      return component.quantity - oldComponent!.quantity;
    }
    return null;
  }
}

class InventoryChangesReport {
  final DateTime timestamp;
  /// Map of inventoryId -> list of changes in that inventory
  final Map<String, List<ComponentChange>> changesByInventory;
  /// Map of inventoryId -> inventoryName
  final Map<String, String> inventoryNames;

  const InventoryChangesReport({
    required this.timestamp,
    required this.changesByInventory,
    required this.inventoryNames,
  });

  bool get hasChanges =>
      changesByInventory.values.any((list) => list.isNotEmpty);

  int get totalChangesCount =>
      changesByInventory.values.fold(0, (sum, list) => sum + list.length);

  List<String> get inventoryIdsWithChanges => changesByInventory.entries
      .where((e) => e.value.isNotEmpty)
      .map((e) => e.key)
      .toList();
}
