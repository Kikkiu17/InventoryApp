import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/screens/settings_screen.dart';
import 'package:inventario/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final (label, size) in [
    ('360x800 mobile', const Size(360, 800)),
    ('320x568 small mobile', const Size(320, 568)),
    ('390x844 modern mobile', const Size(390, 844)),
    ('800x600 tablet/desktop', const Size(800, 600)),
  ]) {
    testWidgets(
        'Settings screen renders properties with value section without overflow on $label',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      // Scroll down until "Proprietà con valore" is visible
      for (int i = 0; i < 20; i++) {
        if (find.text('Proprietà con valore').evaluate().isNotEmpty) {
          break;
        }
        await tester.dragFrom(
            Offset(10, size.height * 0.7), const Offset(0, -200));
        await tester.pumpAndSettle();
      }

      // Scroll a bit more so all fields in the card are in view
      await tester.dragFrom(
          Offset(10, size.height * 0.7), const Offset(0, -150));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, 'Nome');
      final unitField = find.widgetWithText(TextField, 'Unità');
      final siglaField = find.widgetWithText(TextField, 'Sigla');
      final addBtn = find.widgetWithIcon(IconButton, Icons.add);

      expect(nameField, findsOneWidget);
      expect(unitField, findsOneWidget);
      expect(siglaField, findsOneWidget);
      expect(addBtn, findsOneWidget);

      await tester.enterText(nameField, 'Resistenza');
      await tester.enterText(unitField, 'Ohm');
      await tester.enterText(siglaField, 'R');

      // Ensure button is visible before tap
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
      await tester.pumpAndSettle();

      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('Resistenza'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
      expect(find.textContaining('Sigla: R'), findsOneWidget);

      // No overflow errors should be thrown
      // expect(error, isNull);
    });
  }
}
