import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/screens/settings_screen.dart';
import 'package:inventario/services/data_service.dart';

void main() {
  testWidgets('debug overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    FlutterError.onError = (FlutterErrorDetails details) {
      print('DEBUG OVERFLOW DETAILS:');
      print(details.toString());
      for (final node in details.informationCollector?.call() ?? <DiagnosticsNode>[]) {
        print('INFO NODE: ${node.name}');
        print(node.toStringDeep());
      }
    };

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

    final ddRowFinder = find.byWidgetPredicate((w) => w is Row && w.children.any((c) => c is DropdownButton<int>));
    final ro = tester.renderObject<RenderFlex>(ddRowFinder);
    print('DD ROW RENDER OBJECT: size=${ro.size}, constraints=${ro.constraints}');
    RenderBox? c = ro.firstChild;
    int idx = 0;
    while (c != null) {
      print('  CHILD $idx: type=${c.runtimeType}, size=${c.hasSize ? c.size : "no size"}');
      if (idx == 1) {
        print('CHILD 1 DEEP:');
        print(c.toStringDeep());
      }
      c = ro.childAfter(c);
      idx++;
    }
    final ds2 = ds;
    for (final c in ds2.settings.containers) {
      print('CONTAINER IN SETTINGS: id=${c.id}, name="${c.name}"');
    }
  });
}
