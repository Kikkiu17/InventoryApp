import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/component.dart';
import '../models/inventory_change.dart';
import '../widgets/component_view_dialog.dart';
import 'data_service.dart';

class InventoryChangesService {
  static const String prefKeyDontShowPopup = 'whats_new_dont_show_popup';
  static const String prefKeyLastSnapshot = 'inventory_snapshot_last_session';

  /// ValueNotifier holding current changes report
  static final ValueNotifier<InventoryChangesReport?> changesNotifier =
      ValueNotifier<InventoryChangesReport?>(null);

  /// ValueNotifier holding whether the popup is disabled
  static final ValueNotifier<bool> isPopupDisabledNotifier =
      ValueNotifier<bool>(false);

  static bool _isInitialized = false;

  /// Whether the user has opted to not display the popup automatically
  static bool get isPopupDisabled => isPopupDisabledNotifier.value;

  /// Initialize preference cache
  static Future<void> initPreferences() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      isPopupDisabledNotifier.value =
          prefs.getBool(prefKeyDontShowPopup) ?? false;
      _isInitialized = true;
    } catch (_) {}
  }

  /// Sets whether the popup should be suppressed on launch
  static Future<void> setDontShowPopup(bool disabled) async {
    isPopupDisabledNotifier.value = disabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyDontShowPopup, disabled);
    } catch (_) {}
  }

  /// Loads the saved inventory snapshot from SharedPreferences
  static Future<Map<String, List<Component>>?> loadSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(prefKeyLastSnapshot);
      if (str == null) return null;

      final Map<String, dynamic> decoded = jsonDecode(str);
      final Map<String, dynamic> inventoriesJson =
          decoded['inventories'] as Map<String, dynamic>? ?? {};

      final Map<String, List<Component>> snapshot = {};
      for (final entry in inventoriesJson.entries) {
        if (entry.value is List) {
          snapshot[entry.key] = (entry.value as List)
              .map((c) => Component.fromJson(c as Map<String, dynamic>))
              .toList();
        }
      }
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  /// Saves the current inventories snapshot to SharedPreferences
  static Future<void> saveSnapshot(
      Map<String, List<Component>> inventories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> payload = {
        'timestamp': DateTime.now().toIso8601String(),
        'inventories': inventories.map((key, comps) =>
            MapEntry(key, comps.map((c) => c.toJson()).toList())),
      };
      await prefs.setString(prefKeyLastSnapshot, jsonEncode(payload));
    } catch (_) {}
  }

  /// Computes diff between current inventories and previous snapshot
  static InventoryChangesReport computeChanges({
    required Map<String, List<Component>> currentInventories,
    required Map<String, List<Component>>? previousInventories,
    required Map<String, String> inventoryNames,
  }) {
    if (previousInventories == null) {
      return InventoryChangesReport(
        timestamp: DateTime.now(),
        changesByInventory: {},
        inventoryNames: inventoryNames,
      );
    }

    final Map<String, List<ComponentChange>> changesByInventory = {};
    final allInventoryIds = {
      ...currentInventories.keys,
      ...previousInventories.keys,
    };

    for (final invId in allInventoryIds) {
      final currentList = currentInventories[invId] ?? [];
      final previousList = previousInventories[invId] ?? [];

      final currentMap = {for (final c in currentList) c.id: c};
      final previousMap = {for (final c in previousList) c.id: c};

      final invName = inventoryNames[invId] ?? invId;
      final List<ComponentChange> invChanges = [];

      // 1. Added & Modified
      for (final currentComp in currentList) {
        final previousComp = previousMap[currentComp.id];
        if (previousComp == null) {
          // Added
          invChanges.add(ComponentChange(
            inventoryId: invId,
            inventoryName: invName,
            type: ComponentChangeType.added,
            component: currentComp,
          ));
        } else {
          // Check for modifications
          final fieldChanges = _diffComponents(previousComp, currentComp);
          if (fieldChanges.isNotEmpty) {
            invChanges.add(ComponentChange(
              inventoryId: invId,
              inventoryName: invName,
              type: ComponentChangeType.modified,
              component: currentComp,
              oldComponent: previousComp,
              fieldChanges: fieldChanges,
            ));
          }
        }
      }

      // 2. Deleted
      for (final previousComp in previousList) {
        if (!currentMap.containsKey(previousComp.id)) {
          invChanges.add(ComponentChange(
            inventoryId: invId,
            inventoryName: invName,
            type: ComponentChangeType.deleted,
            component: previousComp,
            oldComponent: previousComp,
          ));
        }
      }

      if (invChanges.isNotEmpty) {
        changesByInventory[invId] = invChanges;
      }
    }

    return InventoryChangesReport(
      timestamp: DateTime.now(),
      changesByInventory: changesByInventory,
      inventoryNames: inventoryNames,
    );
  }

  static List<ComponentFieldChange> _diffComponents(
      Component oldComp, Component newComp) {
    final List<ComponentFieldChange> diffs = [];

    // Quantity
    if (oldComp.quantity != newComp.quantity) {
      diffs.add(ComponentFieldChange(
        fieldName: 'quantity',
        oldValue: oldComp.quantity.toString(),
        newValue: newComp.quantity.toString(),
      ));
    }

    // Location / Drawer
    final oldLocation =
        '${oldComp.cabinet > 1 ? "Cab ${oldComp.cabinet} " : ""}${oldComp.drawer}${oldComp.drawerZone != null ? " (z${oldComp.drawerZone})" : ""}';
    final newLocation =
        '${newComp.cabinet > 1 ? "Cab ${newComp.cabinet} " : ""}${newComp.drawer}${newComp.drawerZone != null ? " (z${newComp.drawerZone})" : ""}';
    if (oldLocation != newLocation) {
      diffs.add(ComponentFieldChange(
        fieldName: 'drawer',
        oldValue: oldLocation,
        newValue: newLocation,
      ));
    }

    // Name
    if (oldComp.name != newComp.name) {
      diffs.add(ComponentFieldChange(
        fieldName: 'name',
        oldValue: oldComp.name,
        newValue: newComp.name,
      ));
    }

    // Description
    if (oldComp.description != newComp.description) {
      diffs.add(ComponentFieldChange(
        fieldName: 'description',
        oldValue: oldComp.description,
        newValue: newComp.description,
      ));
    }

    // Tags
    if (!listEquals(oldComp.tags, newComp.tags)) {
      diffs.add(ComponentFieldChange(
        fieldName: 'tags',
        oldValue: oldComp.tags.join(', '),
        newValue: newComp.tags.join(', '),
      ));
    }

    // Special tag values / properties
    if (!mapEquals(oldComp.specialTagValues, newComp.specialTagValues)) {
      final allPropKeys = {
        ...oldComp.specialTagValues.keys,
        ...newComp.specialTagValues.keys,
      };
      for (final k in allPropKeys) {
        final oldVal = oldComp.specialTagValues[k] ?? '';
        final newVal = newComp.specialTagValues[k] ?? '';
        if (oldVal != newVal) {
          diffs.add(ComponentFieldChange(
            fieldName: 'property:$k',
            oldValue: oldVal,
            newValue: newVal,
          ));
        }
      }
    }

    // Note
    if (oldComp.note != newComp.note) {
      diffs.add(ComponentFieldChange(
        fieldName: 'note',
        oldValue: oldComp.note,
        newValue: newComp.note,
      ));
    }

    // Bag name
    if (oldComp.bagName != newComp.bagName) {
      diffs.add(ComponentFieldChange(
        fieldName: 'bagName',
        oldValue: oldComp.bagName ?? '',
        newValue: newComp.bagName ?? '',
      ));
    }

    return diffs;
  }

  /// Checks for changes since last session on app launch and prompts popup if appropriate
  static Future<void> checkAndPromptChanges(
      BuildContext context, DataService ds) async {
    await initPreferences();

    final currentInventories = await ds.getAllInventoriesComponents();
    final inventoryNames = ds.getAllInventoryNames();
    final previousSnapshot = await loadSnapshot();

    if (previousSnapshot == null) {
      // First launch ever: save current baseline and return
      await saveSnapshot(currentInventories);
      return;
    }

    final report = computeChanges(
      currentInventories: currentInventories,
      previousInventories: previousSnapshot,
      inventoryNames: inventoryNames,
    );

    if (report.hasChanges) {
      changesNotifier.value = report;

      // If user chose not to display popup anymore, we do NOT show dialog automatically.
      // In this case, the icon on the top will appear!
      if (!isPopupDisabled && context.mounted) {
        await showChangesDialog(context, report, ds: ds);
      }
    }
  }

  /// Saves current state as the baseline snapshot
  static Future<void> saveCurrentAsBaseline(DataService ds) async {
    try {
      final currentInventories = await ds.getAllInventoriesComponents();
      await saveSnapshot(currentInventories);
    } catch (_) {}
  }

  /// Navigates to the inventory and opens the component view dialog
  static Future<void> navigateToComponentChange(
    BuildContext context,
    DataService ds,
    ComponentChange change,
  ) async {
    final l10n = context.l10n;
    if (change.isDeleted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.whatsNewComponentDeletedNotice),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final isBuffer = change.inventoryId == '_buffer_';
    final mainShell = globalMainShellKey.currentState;
    final mainContext = globalMainShellKey.currentContext ?? context;

    try {
      if (isBuffer) {
        mainShell?.switchTab(1); // Buffer tab
        if (mainContext.mounted) {
          showDialog(
            context: mainContext,
            builder: (ctx) => ComponentViewDialog(
              component: change.component,
              settings: ds.settings,
              onEdit: () {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(l10n.editComponentDirectlyFromList),
                ));
              },
            ),
          );
        }
      } else {
        if (ds.currentInventoryId != change.inventoryId) {
          await ds.switchInventory(change.inventoryId);
          if (mainContext.mounted) {
            ScaffoldMessenger.of(mainContext).showSnackBar(SnackBar(
              content: Text(l10n.switchedToInventory(change.inventoryName)),
              behavior: SnackBarBehavior.floating,
            ));
          }
        }

        // Set search query on home screen so it is focused/highlighted
        ds.setGlobalSearchQuery(change.component.name);
        mainShell?.switchTab(0); // Home tab

        if (mainContext.mounted) {
          showDialog(
            context: mainContext,
            builder: (ctx) => ComponentViewDialog(
              component: change.component,
              settings: ds.settings,
              onEdit: () {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(l10n.editComponentDirectlyFromList),
                ));
              },
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    }
  }

  /// Opens the "What's changed" dialog
  static Future<void> showChangesDialog(
    BuildContext context,
    InventoryChangesReport report, {
    required DataService ds,
  }) async {
    await initPreferences();
    if (!context.mounted) return;

    bool dontShowAgain = isPopupDisabled;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final l10n = dialogCtx.l10n;
        final theme = Theme.of(dialogCtx);
        final cs = theme.colorScheme;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.published_with_changes,
                        color: cs.onPrimaryContainer, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.whatsNewTitle,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.whatsNewSubtitle,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.close,
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // List of changes separate for each inventory
                      ...report.inventoryIdsWithChanges.map((invId) {
                        final changes = report.changesByInventory[invId] ?? [];
                        final invName = report.inventoryNames[invId] ?? invId;
                        final isBuffer = invId == '_buffer_';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Inventory Section Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(13)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isBuffer
                                          ? Icons.shopping_bag_outlined
                                          : Icons.folder_outlined,
                                      size: 18,
                                      color: isBuffer
                                          ? cs.secondary
                                          : cs.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        invName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isBuffer
                                            ? cs.secondaryContainer
                                            : cs.primaryContainer,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        l10n.whatsNewChangesCount(changes.length),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isBuffer
                                              ? cs.onSecondaryContainer
                                              : cs.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Components changes in this inventory
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: changes.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  indent: 14,
                                  endIndent: 14,
                                  color: cs.outlineVariant.withValues(alpha: 0.3),
                                ),
                                itemBuilder: (ctx2, idx) {
                                  final change = changes[idx];
                                  return _buildChangeTile(
                                    ctx2,
                                    change,
                                    l10n,
                                    cs,
                                    onTap: () {
                                      Navigator.pop(dialogCtx);
                                      navigateToComponentChange(
                                          context, ds, change);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 6),
                      // Checkbox: "Non mostrare più questo popup all'avvio"
                      InkWell(
                        onTap: () {
                          setDialogState(() {
                            dontShowAgain = !dontShowAgain;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: dontShowAgain,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      dontShowAgain = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.whatsNewDontShowAgain,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.done_all, size: 18),
                  label: Text(l10n.whatsNewMarkAsRead),
                  onPressed: () async {
                    await setDontShowPopup(dontShowAgain);
                    await saveCurrentAsBaseline(ds);
                    changesNotifier.value = null;
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                ),
                FilledButton(
                  onPressed: () async {
                    await setDontShowPopup(dontShowAgain);
                    await saveCurrentAsBaseline(ds);
                    changesNotifier.value = null;
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                  child: Text(l10n.close),
                ),
              ],
            );
          },
        );
      },
    );

    // Save preference when dialog completes
    await setDontShowPopup(dontShowAgain);
  }

  static Widget _buildChangeTile(
    BuildContext context,
    ComponentChange change,
    AppLocalizations l10n,
    ColorScheme cs, {
    required VoidCallback onTap,
  }) {
    Color badgeColor;
    Color badgeTextColor;
    String badgeText;
    IconData typeIcon;

    if (change.isAdded) {
      badgeColor = Colors.green.withValues(alpha: 0.18);
      badgeTextColor = Colors.green.shade800;
      badgeText = l10n.whatsNewAdded;
      typeIcon = Icons.add_circle_outline;
    } else if (change.isModified) {
      badgeColor = Colors.blue.withValues(alpha: 0.18);
      badgeTextColor = Colors.blue.shade800;
      badgeText = l10n.whatsNewModified;
      typeIcon = Icons.edit_outlined;
    } else {
      badgeColor = cs.errorContainer.withValues(alpha: 0.5);
      badgeTextColor = cs.error;
      badgeText = l10n.whatsNewDeleted;
      typeIcon = Icons.delete_outline;
    }

    final c = change.component;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(typeIcon, size: 18, color: badgeTextColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            decoration: change.isDeleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: change.isDeleted
                                ? cs.onSurfaceVariant
                                : cs.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Change details
                  if (change.isAdded) ...[
                    Text(
                      '${c.drawer.isNotEmpty ? "${c.drawer} • " : ""}${l10n.qtyShort(c.quantity)}${c.description.isNotEmpty ? " • ${c.description}" : ""}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (change.isDeleted) ...[
                    Text(
                      '${c.drawer.isNotEmpty ? "${c.drawer} • " : ""}${l10n.qtyShort(c.quantity)}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ] else if (change.isModified) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: change.fieldChanges.map((fc) {
                        String text;
                        if (fc.fieldName == 'quantity') {
                          final delta = change.quantityDelta;
                          final deltaStr = delta != null
                              ? ' (${delta > 0 ? "+$delta" : "$delta"})'
                              : '';
                          text =
                              '${l10n.whatsNewQuantityChanged(fc.oldValue, fc.newValue)}$deltaStr';
                        } else if (fc.fieldName == 'drawer') {
                          text = l10n.whatsNewDrawerChanged(
                              fc.oldValue, fc.newValue);
                        } else if (fc.fieldName == 'name') {
                          text = l10n.whatsNewNameChanged(
                              fc.oldValue, fc.newValue);
                        } else if (fc.fieldName == 'description') {
                          text = l10n.whatsNewDescriptionChanged;
                        } else if (fc.fieldName == 'tags') {
                          text = l10n.whatsNewTagsChanged;
                        } else if (fc.fieldName.startsWith('property:')) {
                          final propName = fc.fieldName.substring(9);
                          text = '$propName: ${fc.oldValue} → ${fc.newValue}';
                        } else {
                          text = '${fc.fieldName}: ${fc.newValue}';
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (!change.isDeleted)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 4),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: cs.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Manually show recent changes (e.g. from Settings)
  static Future<void> showRecentChanges(
      BuildContext context, DataService ds) async {
    final report = changesNotifier.value;
    if (report != null && report.hasChanges) {
      await showChangesDialog(context, report, ds: ds);
    } else {
      // Recompute against current snapshot
      final currentInventories = await ds.getAllInventoriesComponents();
      final inventoryNames = ds.getAllInventoryNames();
      final previousSnapshot = await loadSnapshot();

      final recomputed = computeChanges(
        currentInventories: currentInventories,
        previousInventories: previousSnapshot,
        inventoryNames: inventoryNames,
      );

      if (recomputed.hasChanges && context.mounted) {
        changesNotifier.value = recomputed;
        await showChangesDialog(context, recomputed, ds: ds);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.whatsNewNoChanges),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}
