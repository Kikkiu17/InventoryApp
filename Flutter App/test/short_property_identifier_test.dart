import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/models/component.dart';
import 'package:inventario/models/search_result.dart';
import 'package:inventario/models/settings.dart';
import 'package:inventario/screens/settings_screen.dart';
import 'package:inventario/services/data_service.dart';
import 'package:inventario/widgets/global_search_delegate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SpecialTag Model Tests', () {
    test('serializes and deserializes shortId correctly', () {
      final tag = SpecialTag(
        name: 'Lunghezza',
        unit: 'mm',
        isString: false,
        shortId: 'L',
      );

      final json = tag.toJson();
      expect(json['name'], 'Lunghezza');
      expect(json['unit'], 'mm');
      expect(json['isString'], false);
      expect(json['shortId'], 'L');

      final fromJson = SpecialTag.fromJson(json);
      expect(fromJson.name, 'Lunghezza');
      expect(fromJson.unit, 'mm');
      expect(fromJson.isString, false);
      expect(fromJson.shortId, 'L');
    });

    test('backward compatibility: missing shortId defaults to empty string', () {
      final tag = SpecialTag.fromJson({
        'name': 'Larghezza',
        'unit': 'cm',
        'isString': true,
      });

      expect(tag.name, 'Larghezza');
      expect(tag.unit, 'cm');
      expect(tag.isString, true);
      expect(tag.shortId, '');
    });

    test('clone and copyWith preserve shortId', () {
      final tag = SpecialTag(name: 'Altezza', unit: 'mm', shortId: 'H');
      final cloned = tag.clone();
      expect(cloned.shortId, 'H');

      final modified = tag.copyWith(shortId: 'ALT');
      expect(modified.shortId, 'ALT');
      expect(modified.name, 'Altezza');
    });

    test('formatValueWithUnit helper formats correctly', () {
      expect(formatValueWithUnit('10', 'mm'), '10mm');
      expect(formatValueWithUnit('100', ''), '100');
      expect(formatValueWithUnit('10K', 'Ω'), '10KΩ');
      expect(formatValueWithUnit('3.3', 'V'), '3.3V');
    });
  });

  group('GlobalSearchResultTile Short Identifier Display Tests', () {
    testWidgets('displays shortened identifier badge for properties with shortId', (tester) async {
      final ds = DataService();

      final specialTags = [
        SpecialTag(name: 'Lunghezza', unit: 'mm', shortId: 'L'),
        SpecialTag(name: 'Larghezza', unit: 'mm', shortId: 'W'),
        SpecialTag(name: 'Resistenza', unit: 'Ω', shortId: ''), // No shortId
      ];

      final component = Component(
        id: 'comp-test',
        name: 'Barra Alluminio',
        drawer: 'A1',
        description: 'Profilo estruso',
        tags: ['metallico'],
        quantity: 5,
        specialTagValues: {
          'Lunghezza': '100',
          'Larghezza': '20',
          'Resistenza': '0', // Should NOT be shown because shortId is empty
          'Altro': '',       // Empty value, should NOT be shown
        },
      );

      final res = GlobalSearchResult(
        inventoryId: 'inv-1',
        inventoryName: 'Magazzino 1',
        component: component,
        specialTags: specialTags,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DataService>.value(
          value: ds,
          child: MaterialApp(
            home: Scaffold(
              body: GlobalSearchResultTile(
                res: res,
                query: 'Barra',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Component name and description
      expect(find.text('Barra Alluminio'), findsOneWidget);
      expect(find.text('metallico'), findsOneWidget);

      // Short identifiers must be displayed formatted as <shortId>: <value><unit>
      expect(find.text('L: 100mm'), findsOneWidget);
      expect(find.text('W: 20mm'), findsOneWidget);

      // Full property names or properties without shortId should NOT be displayed as badges
      expect(find.textContaining('Resistenza'), findsNothing);
      expect(find.textContaining('Altro'), findsNothing);
    });

    testWidgets('displays multiple short identifiers when component has more than one', (tester) async {
      final ds = DataService();

      final specialTags = [
        SpecialTag(name: 'Length', unit: 'mm', shortId: 'L'),
        SpecialTag(name: 'Width', unit: 'mm', shortId: 'W'),
        SpecialTag(name: 'Height', unit: 'mm', shortId: 'H'),
      ];

      final component = Component(
        id: 'box-1',
        name: 'Scatola Plastica',
        drawer: 'B1',
        quantity: 10,
        specialTagValues: {
          'Length': '120',
          'Width': '80',
          'Height': '45',
        },
      );

      final res = GlobalSearchResult(
        inventoryId: 'inv-1',
        inventoryName: 'Magazzino Plastica',
        component: component,
        specialTags: specialTags,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DataService>.value(
          value: ds,
          child: MaterialApp(
            home: Scaffold(
              body: GlobalSearchResultTile(
                res: res,
                query: 'Scatola',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('L: 120mm'), findsOneWidget);
      expect(find.text('W: 80mm'), findsOneWidget);
      expect(find.text('H: 45mm'), findsOneWidget);
    });

    testWidgets('does not display badges if component has no properties with shortId', (tester) async {
      final ds = DataService();

      final specialTags = [
        SpecialTag(name: 'Colore', isString: true, shortId: ''),
      ];

      final component = Component(
        id: 'comp-plain',
        name: 'Componente Base',
        drawer: 'C1',
        quantity: 1,
        specialTagValues: {
          'Colore': 'Blu',
        },
      );

      final res = GlobalSearchResult(
        inventoryId: 'inv-1',
        inventoryName: 'Test Inv',
        component: component,
        specialTags: specialTags,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DataService>.value(
          value: ds,
          child: MaterialApp(
            home: Scaffold(
              body: GlobalSearchResultTile(
                res: res,
                query: 'Base',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Componente Base'), findsOneWidget);
      expect(find.textContaining('Colore'), findsNothing);
    });
  });

  group('SettingsScreen Short Identifier Tests', () {
    testWidgets('allows adding a property with Sigla in Settings', (tester) async {
      final ds = DataService();

      await tester.pumpWidget(
        ChangeNotifierProvider<DataService>.value(
          value: ds,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down to "Proprietà con valore"
      await tester.scrollUntilVisible(
        find.text('Proprietà con valore'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Find the inputs in "Proprietà con valore"
      final siglaFieldFinder = find.widgetWithText(TextField, 'Sigla');
      expect(siglaFieldFinder, findsOneWidget);

      final nameFieldFinder = find.widgetWithText(TextField, 'Nome');
      expect(nameFieldFinder, findsOneWidget);

      final unitFieldFinder = find.widgetWithText(TextField, 'Unità');
      expect(unitFieldFinder, findsOneWidget);

      // Enter values: Name = "Spessore", Unit = "mm", Sigla = "S"
      await tester.enterText(nameFieldFinder, 'Spessore');
      await tester.enterText(unitFieldFinder, 'mm');
      await tester.enterText(siglaFieldFinder, 'S');

      // Tap add button
      final addPropFinder = find.widgetWithIcon(IconButton, Icons.add);
      await tester.tap(addPropFinder);
      await tester.pumpAndSettle();

      // Verify that the property appears in the list with its sigla badge
      expect(find.text('Spessore'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.textContaining('Sigla: S'), findsOneWidget);
    });

    testWidgets('allows editing an existing property to set or update its Sigla', (tester) async {
      final ds = DataService();
      // Pre-populate settings with a property without sigla
      await ds.updateSettings(AppSettings(
        specialTags: [
          SpecialTag(name: 'Lunghezza', unit: 'mm', shortId: ''),
        ],
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider<DataService>.value(
          value: ds,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down to "Proprietà con valore"
      await tester.scrollUntilVisible(
        find.text('Proprietà con valore'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Lunghezza'), findsOneWidget);

      // Tap the edit button on the item
      final editBtnFinder = find.byIcon(Icons.edit_outlined);
      expect(editBtnFinder, findsOneWidget);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();

      // Verify the edit dialog opened
      expect(find.text('Modifica proprietà'), findsOneWidget);

      // Enter Sigla "L" in dialog
      final dialogSiglaFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextField, 'Sigla'),
      );
      expect(dialogSiglaFinder, findsOneWidget);
      await tester.enterText(dialogSiglaFinder, 'L');

      // Tap Salva inside dialog
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Salva'),
      ));
      await tester.pumpAndSettle();

      // Verify updated sigla badge appears on the list item
      expect(find.text('L'), findsOneWidget);
      expect(find.textContaining('Sigla: L'), findsOneWidget);
    });
  });
}
