import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:inventario/models/component.dart';
import 'package:inventario/models/settings.dart';
import 'package:inventario/services/data_service.dart';
import 'package:inventario/widgets/component_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ComponentDialog switches to map view without semantics or scheduler error',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings(
      containers: [
        ContainerConfig(
          id: 1,
          name: 'Cabinet 1',
          rows: 6,
          columns: 8,
        ),
      ],
    );

    final dataService = DataService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DataService>.value(
            value: dataService,
            child: ComponentDialog(
              settings: settings,
              existing: Component(
                id: 'comp_1',
                name: 'Test Component',
                description: 'Description',
                quantity: 10,
                cabinet: 1,
                drawer: 'A1',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the SegmentedButton segment for 'Mappa'
    final mappaBtn = find.text('Mappa');
    expect(mappaBtn, findsOneWidget);

    // Tap on 'Mappa'
    await tester.tap(mappaBtn);
    await tester.pumpAndSettle();

    // Verify no exception was thrown and map is visible
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
