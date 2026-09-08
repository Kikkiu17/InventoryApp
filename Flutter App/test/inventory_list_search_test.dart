import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/models/component.dart';
import 'package:inventario/screens/inventory_list_screen.dart';
import 'package:inventario/services/data_service.dart';
import 'package:inventario/widgets/global_search_delegate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('InventoryListScreen Search Tests', () {
    testWidgets('renders SearchBar and has no search button in AppBar actions', (tester) async {
      final ds = DataService();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DataService>.value(
            value: ds,
            child: const InventoryListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that SearchBar exists with the correct hint text
      final searchBarFinder = find.byType(SearchBar);
      expect(searchBarFinder, findsOneWidget);
      expect(find.text('Cerca in tutti gli inventari…'), findsOneWidget);

      // Verify that the AppBar has no IconButton with Icons.search
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
      final searchIconInAppBar = find.descendant(
        of: appBarFinder,
        matching: find.byIcon(Icons.search),
      );
      expect(searchIconInAppBar, findsNothing);
    });

    testWidgets('typing in SearchBar triggers live search and displays matching components', (tester) async {
      final ds = DataService();
      // Add a buffer component to test live search
      await ds.addBufferComponent(Component(
        id: 'comp-1',
        name: 'Resistore 10k',
        drawer: 'A1',
        description: 'Pull-up resistor',
        tags: ['resistor', 'smd'],
        quantity: 42,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DataService>.value(
            value: ds,
            child: const InventoryListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(SearchBar), 'Resist');
      await tester.pump(); // Triggers onChanged and starts debounce

      // Before debounce completes (under 250ms), debounce timer is running
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Expect to find results
      expect(find.text('COMPONENTI BUFFER'), findsOneWidget);
      expect(find.text('Resistore 10k'), findsOneWidget);
      expect(find.text('Pull-up resistor'), findsOneWidget);
      expect(find.text('Q.tà: 42'), findsOneWidget);

      // Expect clear button to be present and functional
      final clearButtonFinder = find.byIcon(Icons.clear);
      expect(clearButtonFinder, findsOneWidget);

      await tester.tap(clearButtonFinder);
      await tester.pumpAndSettle();

      // Search results should be cleared
      expect(find.text('COMPONENTI BUFFER'), findsNothing);
      expect(find.text('Resistore 10k'), findsNothing);
      expect(find.text('Q.tà: 42'), findsNothing);
    });

    testWidgets('shows empty state when search returns no matching results', (tester) async {
      final ds = DataService();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DataService>.value(
            value: ds,
            child: const InventoryListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'InesistenteXYZ');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Nessun risultato'), findsOneWidget);
      expect(find.text('Nessun componente o inventario corrisponde a "InesistenteXYZ".'), findsOneWidget);
    });
  });

  group('GlobalSearchDelegate Tests', () {
    testWidgets('buildSuggestions returns live results when query is not empty', (tester) async {
      final ds = DataService();
      await ds.addBufferComponent(Component(
        id: 'comp-2',
        name: 'Condensatore 100nF',
        drawer: 'B2',
        quantity: 15,
      ));

      final delegate = GlobalSearchDelegate(ds);

      await tester.pumpWidget(
        ChangeNotifierProvider<DataService>.value(
          value: ds,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  delegate.query = 'Condensatore';
                  return delegate.buildSuggestions(context);
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('COMPONENTI BUFFER'), findsOneWidget);
      expect(find.text('Condensatore 100nF'), findsOneWidget);
      expect(find.text('Q.tà: 15'), findsOneWidget);
    });
  });
}
