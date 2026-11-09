import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/l10n/app_localizations.dart';
import 'package:inventario/models/component.dart';
import 'package:inventario/models/search_result.dart';
import 'package:inventario/screens/home_screen.dart';
import 'package:inventario/services/data_service.dart';
import 'package:inventario/widgets/cabinet_map_view.dart';
import 'package:inventario/widgets/component_tile.dart';
import 'package:inventario/widgets/global_search_delegate.dart';

Widget _createTestApp(DataService ds, Widget child) {
  return ChangeNotifierProvider<DataService>.value(
    value: ds,
    child: MaterialApp(
      locale: const Locale('it'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ScaffoldMessenger(
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ComponentTile and Search Map Highlight Tests', () {
    testWidgets(
        'Tapping position badge on ComponentTile navigates to MapView and highlights position',
        (tester) async {
      final ds = DataService();
      await ds.addComponent(Component(
        id: 'comp-101',
        name: 'Transistor BC547',
        cabinet: 1,
        drawer: 'B2',
        drawerZone: 1,
        quantity: 10,
      ));

      await tester.pumpWidget(_createTestApp(ds, const HomeScreen()));
      await tester.pumpAndSettle();

      // Initially in list mode
      expect(find.byType(ComponentTile), findsOneWidget);
      expect(find.byType(CabinetMapView), findsNothing);

      // Find the position badge on the tile (text 'B2\nZ1')
      final badgeFinder = find.descendant(
        of: find.byType(ComponentTile),
        matching: find.text('B2\nZ1'),
      );
      expect(badgeFinder, findsOneWidget);

      // Tap the position badge
      await tester.tap(badgeFinder);
      await tester.pumpAndSettle();

      // View switched to map view
      expect(find.byType(CabinetMapView), findsOneWidget);
      expect(find.byType(ComponentTile), findsNothing);

      // Verify the highlight banner appears with the component name and position
      expect(find.byIcon(Icons.location_on), findsWidgets);
      expect(find.textContaining('Transistor BC547'), findsWidgets);
      expect(find.textContaining('B2'), findsWidgets);

      // Close the highlight
      final closeButtonFinder = find.byIcon(Icons.close);
      expect(closeButtonFinder, findsOneWidget);
      await tester.tap(closeButtonFinder);
      await tester.pumpAndSettle();

      // Banner should be cleared
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets(
        'Tapping unassigned position badge on ComponentTile shows SnackBar and stays on list',
        (tester) async {
      final ds = DataService();
      await ds.addComponent(Component(
        id: 'comp-unassigned',
        name: 'Loose Capacitor',
        cabinet: 1,
        drawer: '',
        quantity: 2,
      ));

      await tester.pumpWidget(_createTestApp(ds, const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ComponentTile), findsOneWidget);

      // Find the unassigned position badge
      final unassignedBadgeFinder = find.descendant(
        of: find.byType(ComponentTile),
        matching: find.text('Non\nass.'),
      );
      expect(unassignedBadgeFinder, findsOneWidget);

      // Tap unassigned badge
      await tester.tap(unassignedBadgeFinder);
      await tester.pumpAndSettle();

      // Should show SnackBar and remain in list view
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.descendant(of: find.byType(SnackBar), matching: find.text('Non ass.')), findsOneWidget);
      expect(find.byType(CabinetMapView), findsNothing);
      expect(find.byType(ComponentTile), findsOneWidget);
    });

    testWidgets(
        'Tapping position badge in GlobalSearchResultTile triggers highlight on map',
        (tester) async {
      final ds = DataService();
      final comp = Component(
        id: 'comp-global-1',
        name: 'Optocoupler 4N35',
        cabinet: 1,
        drawer: 'C3',
        quantity: 4,
      );

      final res = GlobalSearchResult(
        component: comp,
        inventoryId: ds.currentInventoryId,
        inventoryName: 'Inventario Principale',
      );

      bool navigated = false;

      await tester.pumpWidget(
        _createTestApp(
          ds,
          Scaffold(
            body: GlobalSearchResultTile(
              res: res,
              query: 'Opto',
              ds: ds,
              onBeforeNavigate: () {
                navigated = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the leading position badge
      final badgeFinder = find.text('C3');
      expect(badgeFinder, findsOneWidget);

      await tester.tap(badgeFinder);
      await tester.pumpAndSettle();

      expect(navigated, isTrue);
      expect(ds.mapHighlightTarget, isNotNull);
      expect(ds.mapHighlightTarget!.drawer, equals('C3'));
      expect(ds.mapHighlightTarget!.componentName, equals('Optocoupler 4N35'));
    });

    testWidgets(
        'Tapping unassigned position badge in GlobalSearchResultTile shows SnackBar',
        (tester) async {
      final ds = DataService();
      final comp = Component(
        id: 'comp-global-unassigned',
        name: 'Unassigned Relay',
        cabinet: 1,
        drawer: '',
        quantity: 1,
      );

      final res = GlobalSearchResult(
        component: comp,
        inventoryId: ds.currentInventoryId,
        inventoryName: 'Inventario Principale',
      );

      bool navigated = false;

      await tester.pumpWidget(
        _createTestApp(
          ds,
          Scaffold(
            body: GlobalSearchResultTile(
              res: res,
              query: 'Relay',
              ds: ds,
              onBeforeNavigate: () {
                navigated = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find unassigned badge
      final badgeFinder = find.byIcon(Icons.location_off_outlined);
      expect(badgeFinder, findsOneWidget);

      await tester.tap(badgeFinder);
      await tester.pumpAndSettle();

      expect(navigated, isFalse);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.descendant(of: find.byType(SnackBar), matching: find.text('Non ass.')), findsOneWidget);
      expect(ds.mapHighlightTarget, isNull);
    });
  });
}
