import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/l10n/app_localizations.dart';
import 'package:inventario/models/component.dart';
import 'package:inventario/screens/files_screen.dart';
import 'package:inventario/services/data_service.dart';
import 'package:inventario/widgets/component_view_dialog.dart';

Widget _createTestApp({
  required DataService dataService,
  required Widget child,
  Locale locale = const Locale('en'),
}) {
  return ChangeNotifierProvider<DataService>.value(
    value: dataService,
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FilesScreen Terminology & Context Menu Tests', () {
    testWidgets('FilesScreen translates Item in all supported languages',
        (tester) async {
      final ds = DataService();
      await ds.addComponent(Component(
        id: 'c1',
        name: 'Resistor 10k',
        drawer: 'A1',
        cabinet: 1,
        attachments: [
          Attachment(name: 'doc1.pdf', path: '/local/doc1.pdf'),
        ],
      ));

      // Test English
      await tester.pumpWidget(
        _createTestApp(
          dataService: ds,
          child: const FilesScreen(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Search file or item...'), findsOneWidget);
      expect(find.text('Item: Resistor 10k'), findsOneWidget);

      // Test Italian
      await tester.pumpWidget(
        _createTestApp(
          dataService: ds,
          child: const FilesScreen(),
          locale: const Locale('it'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cerca file o elemento...'), findsOneWidget);
      expect(find.text('Elemento: Resistor 10k'), findsOneWidget);

      // Test Spanish
      await tester.pumpWidget(
        _createTestApp(
          dataService: ds,
          child: const FilesScreen(),
          locale: const Locale('es'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Buscar archivo o elemento...'), findsOneWidget);
      expect(find.text('Elemento: Resistor 10k'), findsOneWidget);

      // Test French
      await tester.pumpWidget(
        _createTestApp(
          dataService: ds,
          child: const FilesScreen(),
          locale: const Locale('fr'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rechercher un fichier ou un élément...'), findsOneWidget);
      expect(find.text('Élément: Resistor 10k'), findsOneWidget);

      // Test German
      await tester.pumpWidget(
        _createTestApp(
          dataService: ds,
          child: const FilesScreen(),
          locale: const Locale('de'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Datei oder Element suchen...'), findsOneWidget);
      expect(find.text('Element: Resistor 10k'), findsOneWidget);
    });

    testWidgets('3-dots menu shows View item, Rename and Delete for files',
        (tester) async {
      final ds = DataService();
      await ds.addComponent(Component(
        id: 'c1',
        name: 'Capacitor 100uF',
        drawer: 'B2',
        cabinet: 1,
        attachments: [
          Attachment(name: 'cap_specs.pdf', path: '/local/cap_specs.pdf'),
        ],
      ));

      await tester.pumpWidget(
        _createTestApp(
          dataService: ds,
          child: const FilesScreen(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 3-dots icon
      final moreButton = find.byIcon(Icons.more_vert);
      expect(moreButton, findsOneWidget);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Check context menu entries
      expect(find.text('View item'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Right click (secondary tap) opens the same context menu',
        (tester) async {
      final ds = DataService();
      await ds.addComponent(Component(
        id: 'c1',
        name: 'Diode 1N4007',
        drawer: 'C3',
        cabinet: 1,
        attachments: [
          Attachment(name: 'diode_sheet.pdf', path: '/local/diode_sheet.pdf'),
        ],
      ));

      await tester.pumpWidget(
        _createTestApp(
          dataService: ds,
          child: const FilesScreen(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      // Perform right-click on the tile
      final tileFinder = find.text('diode_sheet.pdf');
      expect(tileFinder, findsOneWidget);
      await tester.tap(tileFinder, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      // Menu should be open with options
      expect(find.text('View item'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Long press opens the same context menu', (tester) async {
      final ds = DataService();
      await ds.addComponent(Component(
        id: 'c1',
        name: 'Transistor 2N2222',
        drawer: 'D4',
        cabinet: 1,
        attachments: [
          Attachment(name: 'transistor.pdf', path: '/local/transistor.pdf'),
        ],
      ));

      await tester.pumpWidget(
        _createTestApp(
          dataService: ds,
          child: const FilesScreen(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      // Long press on the tile
      final tileFinder = find.text('transistor.pdf');
      expect(tileFinder, findsOneWidget);
      await tester.longPress(tileFinder);
      await tester.pumpAndSettle();

      // Menu should be open with options
      expect(find.text('View item'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets(
        'View item opens ComponentViewDialog with Go to position button when 1 item is connected',
        (tester) async {
      final ds = DataService();
      await ds.addComponent(Component(
        id: 'c1',
        name: 'Inductor 10uH',
        drawer: 'E5',
        cabinet: 1,
        description: 'Power inductor',
        attachments: [
          Attachment(name: 'inductor.pdf', path: '/local/inductor.pdf'),
        ],
      ));

      await tester.pumpWidget(
        _createTestApp(
          dataService: ds,
          child: const FilesScreen(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      // Long press to open menu
      await tester.longPress(find.text('inductor.pdf'));
      await tester.pumpAndSettle();

      // Tap 'View item'
      await tester.tap(find.text('View item'));
      await tester.pumpAndSettle();

      // ComponentViewDialog should be open for Inductor 10uH
      expect(find.byType(ComponentViewDialog), findsOneWidget);
      expect(find.text('Inductor 10uH'), findsWidgets);
      expect(find.text('Power inductor'), findsOneWidget);

      // Verify that 'Go to position' button is present (same as global search result)
      final goToPositionBtn = find.text('Go to position');
      expect(goToPositionBtn, findsOneWidget);
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);

      // Tapping 'Go to position' should close dialog and set globalSearchQuery
      await tester.tap(goToPositionBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ComponentViewDialog), findsNothing);
      expect(ds.globalSearchQuery, equals('Inductor 10uH'));
    });

    testWidgets(
        'View item prompts user to choose when multiple items are connected, then opens selected item with Go to position',
        (tester) async {
      final ds = DataService();
      // Two components sharing the same attachment path
      await ds.addComponent(Component(
        id: 'c1',
        name: 'LED Red 5mm',
        drawer: 'F1',
        cabinet: 1,
        description: 'Red indicator LED',
        attachments: [
          Attachment(name: 'led_datasheet.pdf', path: '/shared/led_datasheet.pdf'),
        ],
      ));
      await ds.addComponent(Component(
        id: 'c2',
        name: 'LED Green 5mm',
        drawer: 'F2',
        cabinet: 1,
        description: 'Green indicator LED',
        attachments: [
          Attachment(name: 'led_datasheet.pdf', path: '/shared/led_datasheet.pdf'),
        ],
      ));

      await tester.pumpWidget(
        _createTestApp(
          dataService: ds,
          child: const FilesScreen(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      // There are two tiles with led_datasheet.pdf
      final firstTile = find.text('Item: LED Red 5mm');
      expect(firstTile, findsOneWidget);

      // Right-click on the first tile
      await tester.tap(firstTile, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      // Tap 'View item'
      await tester.tap(find.text('View item'));
      await tester.pumpAndSettle();

      // Selection dialog should appear
      expect(find.text('Select item'), findsOneWidget);
      expect(find.text('LED Red 5mm'), findsWidgets);
      expect(find.text('LED Green 5mm'), findsOneWidget);

      // Select 'LED Green 5mm'
      await tester.tap(find.text('LED Green 5mm'));
      await tester.pumpAndSettle();

      // ComponentViewDialog should be open for LED Green 5mm with Go to position button
      expect(find.byType(ComponentViewDialog), findsOneWidget);
      expect(find.text('Green indicator LED'), findsOneWidget);
      final goToPositionBtn = find.text('Go to position');
      expect(goToPositionBtn, findsOneWidget);

      await tester.tap(goToPositionBtn);
      await tester.pumpAndSettle();
      expect(find.byType(ComponentViewDialog), findsNothing);
      expect(ds.globalSearchQuery, equals('LED Green 5mm'));
    });
  });
}
