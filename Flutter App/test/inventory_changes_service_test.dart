import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inventario/l10n/app_localizations.dart';
import 'package:inventario/models/component.dart';
import 'package:inventario/models/inventory_change.dart';
import 'package:inventario/services/data_service.dart';
import 'package:inventario/services/inventory_changes_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InventoryChangesService.changesNotifier.value = null;
    InventoryChangesService.isPopupDisabledNotifier.value = false;
  });

  group('InventoryChangesService Diff Computation', () {
    test('computeChanges returns no changes when previous snapshot is null', () {
      final current = {
        'inv1': [
          Component(id: 'c1', name: 'Resistor 10k', drawer: 'A1', quantity: 10),
        ],
      };

      final report = InventoryChangesService.computeChanges(
        currentInventories: current,
        previousInventories: null,
        inventoryNames: {'inv1': 'Main Inventory'},
      );

      expect(report.hasChanges, isFalse);
      expect(report.totalChangesCount, equals(0));
      expect(report.changesByInventory, isEmpty);
    });

    test('computeChanges returns no changes when inventories are identical', () {
      final comp1 = Component(
        id: 'c1',
        name: 'Resistor 10k',
        drawer: 'A1',
        quantity: 10,
        tags: ['smd'],
        specialTagValues: {'Val': '10k'},
      );

      final current = {
        'inv1': [comp1],
      };
      final previous = {
        'inv1': [comp1.copyWith()],
      };

      final report = InventoryChangesService.computeChanges(
        currentInventories: current,
        previousInventories: previous,
        inventoryNames: {'inv1': 'Main Inventory'},
      );

      expect(report.hasChanges, isFalse);
      expect(report.totalChangesCount, equals(0));
    });

    test('computeChanges detects added components', () {
      final comp1 = Component(id: 'c1', name: 'Resistor 10k', drawer: 'A1', quantity: 10);
      final comp2 = Component(id: 'c2', name: 'Capacitor 100uF', drawer: 'B2', quantity: 5);

      final previous = {
        'inv1': [comp1],
      };
      final current = {
        'inv1': [comp1, comp2],
      };

      final report = InventoryChangesService.computeChanges(
        currentInventories: current,
        previousInventories: previous,
        inventoryNames: {'inv1': 'Main Inventory'},
      );

      expect(report.hasChanges, isTrue);
      expect(report.totalChangesCount, equals(1));
      expect(report.changesByInventory['inv1']?.length, equals(1));

      final change = report.changesByInventory['inv1']!.first;
      expect(change.type, equals(ComponentChangeType.added));
      expect(change.component.name, equals('Capacitor 100uF'));
      expect(change.isAdded, isTrue);
    });

    test('computeChanges detects deleted components', () {
      final comp1 = Component(id: 'c1', name: 'Resistor 10k', drawer: 'A1', quantity: 10);
      final comp2 = Component(id: 'c2', name: 'Old Motor', drawer: 'C3', quantity: 2);

      final previous = {
        'inv1': [comp1, comp2],
      };
      final current = {
        'inv1': [comp1],
      };

      final report = InventoryChangesService.computeChanges(
        currentInventories: current,
        previousInventories: previous,
        inventoryNames: {'inv1': 'Main Inventory'},
      );

      expect(report.hasChanges, isTrue);
      expect(report.totalChangesCount, equals(1));
      final change = report.changesByInventory['inv1']!.first;
      expect(change.type, equals(ComponentChangeType.deleted));
      expect(change.component.name, equals('Old Motor'));
      expect(change.isDeleted, isTrue);
    });

    test('computeChanges detects quantity changes with correct delta', () {
      final oldComp = Component(id: 'c1', name: 'LED Red', drawer: 'A1', quantity: 10);
      final newComp = Component(id: 'c1', name: 'LED Red', drawer: 'A1', quantity: 25);

      final previous = {'inv1': [oldComp]};
      final current = {'inv1': [newComp]};

      final report = InventoryChangesService.computeChanges(
        currentInventories: current,
        previousInventories: previous,
        inventoryNames: {'inv1': 'Main Inventory'},
      );

      expect(report.hasChanges, isTrue);
      final change = report.changesByInventory['inv1']!.first;
      expect(change.type, equals(ComponentChangeType.modified));
      expect(change.isModified, isTrue);
      expect(change.quantityDelta, equals(15));
      expect(change.fieldChanges.any((f) => f.fieldName == 'quantity' && f.oldValue == '10' && f.newValue == '25'), isTrue);
    });

    test('computeChanges detects location, tag, and property modifications', () {
      final oldComp = Component(
        id: 'c1',
        name: 'Transistor',
        drawer: 'A1',
        cabinet: 1,
        tags: ['bjt'],
        specialTagValues: {'Package': 'TO-92'},
        description: 'Old desc',
      );
      final newComp = Component(
        id: 'c1',
        name: 'Transistor NPN',
        drawer: 'B3',
        cabinet: 2,
        tags: ['bjt', 'npn'],
        specialTagValues: {'Package': 'SOT-23'},
        description: 'New desc',
      );

      final previous = {'inv1': [oldComp]};
      final current = {'inv1': [newComp]};

      final report = InventoryChangesService.computeChanges(
        currentInventories: current,
        previousInventories: previous,
        inventoryNames: {'inv1': 'Lab 1'},
      );

      final change = report.changesByInventory['inv1']!.first;
      expect(change.type, equals(ComponentChangeType.modified));
      expect(change.fieldChanges.any((f) => f.fieldName == 'name'), isTrue);
      expect(change.fieldChanges.any((f) => f.fieldName == 'drawer'), isTrue);
      expect(change.fieldChanges.any((f) => f.fieldName == 'tags'), isTrue);
      expect(change.fieldChanges.any((f) => f.fieldName == 'property:Package'), isTrue);
      expect(change.fieldChanges.any((f) => f.fieldName == 'description'), isTrue);
    });

    test('computeChanges separates changes across multiple inventories and buffer', () {
      final compInv1Old = Component(id: 'c1', name: 'Item 1', drawer: 'A1', quantity: 5);
      final compInv1New = Component(id: 'c1', name: 'Item 1', drawer: 'A1', quantity: 12);

      final compInv2New = Component(id: 'c2', name: 'Item 2 in Inv 2', drawer: 'B1', quantity: 1);

      final compBufferOld = Component(id: 'cb', name: 'Buffer Item', drawer: '', quantity: 1);

      final previous = {
        'inv1': [compInv1Old],
        'inv2': <Component>[],
        '_buffer_': [compBufferOld],
      };
      final current = {
        'inv1': [compInv1New],
        'inv2': [compInv2New],
        '_buffer_': <Component>[],
      };

      final report = InventoryChangesService.computeChanges(
        currentInventories: current,
        previousInventories: previous,
        inventoryNames: {
          'inv1': 'Electronics Lab',
          'inv2': 'Mechanical Workshop',
          '_buffer_': 'Buffer',
        },
      );

      expect(report.hasChanges, isTrue);
      expect(report.totalChangesCount, equals(3));
      expect(report.inventoryIdsWithChanges, containsAll(['inv1', 'inv2', '_buffer_']));

      // inv1: modified
      expect(report.changesByInventory['inv1']!.first.isModified, isTrue);
      expect(report.changesByInventory['inv1']!.first.inventoryName, equals('Electronics Lab'));

      // inv2: added
      expect(report.changesByInventory['inv2']!.first.isAdded, isTrue);
      expect(report.changesByInventory['inv2']!.first.inventoryName, equals('Mechanical Workshop'));

      // _buffer_: deleted
      expect(report.changesByInventory['_buffer_']!.first.isDeleted, isTrue);
      expect(report.changesByInventory['_buffer_']!.first.inventoryName, equals('Buffer'));
    });
  });

  group('InventoryChangesService Snapshot Persistence', () {
    test('saveSnapshot and loadSnapshot properly round-trip components', () async {
      final comp = Component(
        id: 'c10',
        name: 'Microcontroller',
        drawer: 'D4',
        quantity: 3,
        tags: ['mcu', 'arm'],
        specialTagValues: {'Clock': '16MHz'},
      );

      final toSave = {
        'inv_main': [comp],
        '_buffer_': [
          Component(id: 'cb1', name: 'Unsorted Pack', drawer: '', quantity: 1),
        ],
      };

      await InventoryChangesService.saveSnapshot(toSave);
      final loaded = await InventoryChangesService.loadSnapshot();

      expect(loaded, isNotNull);
      expect(loaded!.containsKey('inv_main'), isTrue);
      expect(loaded.containsKey('_buffer_'), isTrue);

      final loadedComp = loaded['inv_main']!.first;
      expect(loadedComp.id, equals('c10'));
      expect(loadedComp.name, equals('Microcontroller'));
      expect(loadedComp.drawer, equals('D4'));
      expect(loadedComp.quantity, equals(3));
      expect(loadedComp.tags, equals(['mcu', 'arm']));
      expect(loadedComp.specialTagValues['Clock'], equals('16MHz'));
    });
  });

  group('InventoryChangesService Preference Management', () {
    test('isPopupDisabled defaults to false and setDontShowPopup updates correctly', () async {
      await InventoryChangesService.initPreferences();
      expect(InventoryChangesService.isPopupDisabled, isFalse);

      await InventoryChangesService.setDontShowPopup(true);
      expect(InventoryChangesService.isPopupDisabled, isTrue);
      expect(InventoryChangesService.isPopupDisabledNotifier.value, isTrue);

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(InventoryChangesService.prefKeyDontShowPopup), isTrue);

      await InventoryChangesService.setDontShowPopup(false);
      expect(InventoryChangesService.isPopupDisabled, isFalse);
    });
  });

  group('InventoryChangesService Dialog UI Tests', () {
    testWidgets('shows changes separated by inventory and handles close', (tester) async {
      final compAdded = Component(id: 'c1', name: 'New Sensor', drawer: 'A1', quantity: 5);
      final compModified = Component(id: 'c2', name: 'Resistor', drawer: 'B2', quantity: 20);
      final compModifiedOld = Component(id: 'c2', name: 'Resistor', drawer: 'A2', quantity: 10);

      final report = InventoryChangesService.computeChanges(
        currentInventories: {
          'inv1': [compAdded],
          'inv2': [compModified],
        },
        previousInventories: {
          'inv1': [],
          'inv2': [compModifiedOld],
        },
        inventoryNames: {
          'inv1': 'Inventory Alpha',
          'inv2': 'Inventory Beta',
        },
      );

      final ds = DataService();

      await tester.pumpWidget(
        ChangeNotifierProvider<DataService>.value(
          value: ds,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => InventoryChangesService.showChangesDialog(
                        context,
                        report,
                        ds: ds,
                      ),
                      child: const Text('Open Dialog'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text("What's Changed"), findsOneWidget);

      // Verify separate sections for each inventory
      expect(find.text('Inventory Alpha'), findsOneWidget);
      expect(find.text('Inventory Beta'), findsOneWidget);

      // Verify components displayed
      expect(find.text('New Sensor'), findsOneWidget);
      expect(find.text('Resistor'), findsOneWidget);

      // Verify "Don't show this popup on startup anymore" checkbox exists
      expect(find.text("Don't show this popup on startup anymore"), findsOneWidget);

      // Verify "Mark as read" and "Close" buttons exist
      expect(find.text('Mark as read'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text("What's Changed"), findsNothing);
    });

    testWidgets('toggling dont show popup updates preference and persists', (tester) async {
      final comp = Component(id: 'c1', name: 'New Component', drawer: 'A1', quantity: 1);
      final report = InventoryChangesService.computeChanges(
        currentInventories: {'inv1': [comp]},
        previousInventories: {'inv1': []},
        inventoryNames: {'inv1': 'My Inventory'},
      );

      final ds = DataService();

      await tester.pumpWidget(
        ChangeNotifierProvider<DataService>.value(
          value: ds,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => InventoryChangesService.showChangesDialog(
                        context,
                        report,
                        ds: ds,
                      ),
                      child: const Text('Open Dialog'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(InventoryChangesService.isPopupDisabled, isFalse);

      // Tap on the "Don't show this popup on startup anymore" checkbox row
      await tester.tap(find.text("Don't show this popup on startup anymore"));
      await tester.pumpAndSettle();

      // Close dialog to persist
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Now popup is marked as disabled (so top icon will be shown instead)
      expect(InventoryChangesService.isPopupDisabled, isTrue);
      expect(InventoryChangesService.isPopupDisabledNotifier.value, isTrue);
    });

    testWidgets('tapping deleted component shows SnackBar notice', (tester) async {
      final comp = Component(id: 'c_del', name: 'Deleted Part', drawer: 'D1', quantity: 2);
      final report = InventoryChangesService.computeChanges(
        currentInventories: {'inv1': []},
        previousInventories: {'inv1': [comp]},
        inventoryNames: {'inv1': 'Inventory 1'},
      );

      final ds = DataService();

      await tester.pumpWidget(
        ChangeNotifierProvider<DataService>.value(
          value: ds,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => InventoryChangesService.showChangesDialog(
                        context,
                        report,
                        ds: ds,
                      ),
                      child: const Text('Open Dialog'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap on the deleted item tile
      await tester.tap(find.text('Deleted Part'));
      await tester.pumpAndSettle();

      // Verify SnackBar notice appears
      expect(find.text('This component was deleted from the inventory'), findsOneWidget);
    });

    testWidgets('top bar icon appears when popup is disabled and changes exist', (tester) async {
      final comp = Component(id: 'c1', name: 'New Component', drawer: 'A1', quantity: 1);
      final report = InventoryChangesService.computeChanges(
        currentInventories: {'inv1': [comp]},
        previousInventories: {'inv1': []},
        inventoryNames: {'inv1': 'My Inventory'},
      );

      // Popup disabled by user preference
      InventoryChangesService.isPopupDisabledNotifier.value = true;
      InventoryChangesService.changesNotifier.value = report;

      final ds = DataService();

      await tester.pumpWidget(
        ChangeNotifierProvider<DataService>.value(
          value: ds,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  ValueListenableBuilder<InventoryChangesReport?>(
                    valueListenable: InventoryChangesService.changesNotifier,
                    builder: (context, r, _) {
                      if (r == null || !r.hasChanges) {
                        return const SizedBox.shrink();
                      }
                      return ValueListenableBuilder<bool>(
                        valueListenable: InventoryChangesService.isPopupDisabledNotifier,
                        builder: (context, isDisabled, _) {
                          if (!isDisabled) return const SizedBox.shrink();
                          return IconButton(
                            icon: Badge(
                              label: Text('${r.totalChangesCount}'),
                              child: const Icon(Icons.published_with_changes),
                            ),
                            onPressed: () => InventoryChangesService.showChangesDialog(
                              context,
                              r,
                              ds: ds,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the top bar icon is rendered
      expect(find.byIcon(Icons.published_with_changes), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // badge count

      // Tapping the icon opens the changes dialog
      await tester.tap(find.byIcon(Icons.published_with_changes));
      await tester.pumpAndSettle();

      expect(find.text("What's Changed"), findsOneWidget);
      expect(find.text('New Component'), findsOneWidget);
    });
  });
}
