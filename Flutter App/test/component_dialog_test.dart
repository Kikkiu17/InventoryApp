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

  testWidgets(
      'ComponentDialog switches to map view without semantics or scheduler error',
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

  testWidgets(
      'ComponentDialog automatically sets name from tree tags but ignores generic tags',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings(
      containers: [
        ContainerConfig(id: 1, name: 'Cabinet 1', rows: 4, columns: 4),
      ],
      availableTags: ['SMD', 'Through-Hole'],
      tagTree: {
        'diode': {
          'schottky': {
            'bat54': <String, dynamic>{},
          },
          'zener': <String, dynamic>{},
        },
        'resistor': <String, dynamic>{},
      },
    );

    final dataService = DataService();
    await dataService.updateSettings(settings);
    Component? createdComponent;

    await tester.pumpWidget(
      ChangeNotifierProvider<DataService>.value(
        value: dataService,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  createdComponent = await showDialog<Component>(
                    context: ctx,
                    builder: (_) => ComponentDialog(settings: settings),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Initially name is empty
    final nameField = find.widgetWithText(TextFormField, 'Nome *');
    expect(nameField, findsOneWidget);
    TextFormField nameWidget = tester.widget(nameField);
    expect(nameWidget.controller?.text, isEmpty);

    // Scroll and tap tree tag 'diode'
    final diodeChip = find.widgetWithText(ChoiceChip, 'diode');
    await tester.ensureVisible(diodeChip);
    await tester.tap(diodeChip);
    await tester.pumpAndSettle();

    nameWidget = tester.widget(nameField);
    expect(nameWidget.controller?.text, equals('diode'));

    // Scroll and tap tree tag 'schottky'
    final schottkyChip = find.widgetWithText(ChoiceChip, 'schottky');
    await tester.ensureVisible(schottkyChip);
    await tester.tap(schottkyChip);
    await tester.pumpAndSettle();

    nameWidget = tester.widget(nameField);
    expect(nameWidget.controller?.text, equals('diode schottky'));

    // Expand loose tags and select generic tag 'SMD'
    final looseBtn = find.text('Mostra tag generici (sfusi)');
    await tester.ensureVisible(looseBtn);
    await tester.tap(looseBtn);
    await tester.pumpAndSettle();

    final smdChip = find.widgetWithText(FilterChip, 'SMD');
    await tester.ensureVisible(smdChip);
    await tester.tap(smdChip);
    await tester.pumpAndSettle();

    // Generic tag should NOT be added to component name
    nameWidget = tester.widget(nameField);
    expect(nameWidget.controller?.text, equals('diode schottky'));

    // Tap submit button 'Aggiungi'
    final addBtn = find.text('Aggiungi');
    await tester.ensureVisible(addBtn);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    expect(createdComponent, isNotNull);
    expect(createdComponent!.name, equals('diode schottky'));
    expect(createdComponent!.tags, containsAll(['diode', 'schottky', 'SMD']));
  });
}
