import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  group('Settings Animations and Android Back Gesture Tests', () {
    testWidgets(
        'Entering a submenu animates and renders BackButton with no save button in AppBar',
        (tester) async {
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

      // Verify no save button on main screen
      expect(find.text('Salva impostazioni'), findsNothing);

      // Tap on "Aspetto" submenu
      await tester.tap(find.text('Aspetto'));
      // Pump halfway to verify transition is underway
      await tester.pump(const Duration(milliseconds: 100));
      // Settle animation
      await tester.pumpAndSettle();

      // Inside submenu: Back button is present, but NO save button
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Salva impostazioni'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Salva'), findsNothing);
    });

    testWidgets(
        'Predictive back gesture observer drives screen animation from left to right while underway',
        (tester) async {
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

      // Enter "Aspetto" submenu
      await tester.tap(find.text('Aspetto'));
      await tester.pumpAndSettle();

      final modalRoute = ModalRoute.of(
              tester.element(find.text("Tema dell'app"))) as PageRoute;
      expect(modalRoute.isCurrent, isTrue);

      // Initial state: fully opened (animation at 1.0)
      expect(modalRoute.animation?.value, equals(1.0));

      // Simulate Android PredictiveBackEvent start and progress
      final startEvent = PredictiveBackEvent.fromMap({
        'touchOffset': [10.0, 300.0],
        'progress': 0.0,
        'swipeEdge': 0, // left edge
        'isButtonEvent': false,
      });

      // Find the observer state
      final observerFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_PredictiveBackObserverWidget',
      );
      expect(observerFinder, findsOneWidget);
      final observerState =
          tester.state(observerFinder) as WidgetsBindingObserver;

      final handled = observerState.handleStartBackGesture(startEvent);
      expect(handled, isTrue);

      // Simulate gesture underway: dragging 35% from left to right
      final updateEvent1 = PredictiveBackEvent.fromMap({
        'touchOffset': [120.0, 300.0],
        'progress': 0.35,
        'swipeEdge': 0,
        'isButtonEvent': false,
      });
      observerState.handleUpdateBackGestureProgress(updateEvent1);
      await tester.pump();

      // Route animation value should track progress (1 - 0.35 = 0.65)
      expect(modalRoute.animation?.value, closeTo(0.65, 0.05));

      // Simulate gesture progressing further to 75%
      final updateEvent2 = PredictiveBackEvent.fromMap({
        'touchOffset': [260.0, 300.0],
        'progress': 0.75,
        'swipeEdge': 0,
        'isButtonEvent': false,
      });
      observerState.handleUpdateBackGestureProgress(updateEvent2);
      await tester.pump();

      // Route animation value should be at 0.25 (screen shifted 75% to the right)
      expect(modalRoute.animation?.value, closeTo(0.25, 0.05));

      // Commit back gesture
      observerState.handleCommitBackGesture();
      await tester.pumpAndSettle();

      // Returned to main menu
      expect(find.text('Server remoto'), findsOneWidget);
      expect(find.text('Aspetto'), findsOneWidget);
    });

    testWidgets(
        'Predictive back gesture can be canceled, restoring screen to full view',
        (tester) async {
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

      // Enter "Aspetto" submenu
      await tester.tap(find.text('Aspetto'));
      await tester.pumpAndSettle();

      final modalRoute = ModalRoute.of(
              tester.element(find.text("Tema dell'app"))) as PageRoute;

      final observerFinder = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_PredictiveBackObserverWidget',
      );
      final observerState =
          tester.state(observerFinder) as WidgetsBindingObserver;

      observerState.handleStartBackGesture(PredictiveBackEvent.fromMap({
        'touchOffset': [10.0, 300.0],
        'progress': 0.0,
        'swipeEdge': 0,
        'isButtonEvent': false,
      }));

      observerState.handleUpdateBackGestureProgress(PredictiveBackEvent.fromMap({
        'touchOffset': [80.0, 300.0],
        'progress': 0.2,
        'swipeEdge': 0,
        'isButtonEvent': false,
      }));
      await tester.pump();

      expect(modalRoute.animation?.value, closeTo(0.8, 0.05));

      // User cancels gesture
      observerState.handleCancelBackGesture();
      await tester.pumpAndSettle();

      // Restored back to full view inside "Aspetto"
      expect(modalRoute.animation?.value, equals(1.0));
      expect(find.text("Tema dell'app"), findsOneWidget);
    });
  });

  group('Settings Auto-Save Tests', () {
    testWidgets('Adding generic tag auto-saves immediately to DataService',
        (tester) async {
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

      // Scroll if needed and tap "Tag Generici (Sfusi)"
      for (int i = 0; i < 20; i++) {
        if (find.text('Tag Generici (Sfusi)').evaluate().isNotEmpty) {
          break;
        }
        await tester.dragFrom(const Offset(10, 400), const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Tag Generici (Sfusi)'));
      await tester.pumpAndSettle();

      // No save button in AppBar
      expect(find.text('Salva impostazioni'), findsNothing);

      // Add a tag
      final tagField = find.widgetWithText(TextField, 'Nuovo tag generico');
      expect(tagField, findsOneWidget);
      await tester.enterText(tagField, 'auto_saved_tag');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(FilledButton, Icons.add));
      await tester.pumpAndSettle();

      // Verify tag is in DataService settings immediately
      expect(ds.settings.availableTags, contains('auto_saved_tag'));
    });

    testWidgets('Adding special property auto-saves immediately to DataService',
        (tester) async {
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

      // Scroll if needed and tap "Proprietà con valore"
      for (int i = 0; i < 20; i++) {
        if (find.text('Proprietà con valore').evaluate().isNotEmpty) {
          break;
        }
        await tester.dragFrom(const Offset(10, 400), const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Proprietà con valore'));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, 'Nome');
      final unitField = find.widgetWithText(TextField, 'Unità');
      final siglaField = find.widgetWithText(TextField, 'Sigla');
      final addBtn = find.widgetWithIcon(IconButton, Icons.add);

      await tester.enterText(nameField, 'Capacità');
      await tester.enterText(unitField, 'uF');
      await tester.enterText(siglaField, 'C');
      await tester.pumpAndSettle();

      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Verify special tag is in DataService immediately
      expect(
          ds.settings.specialTags.any(
              (t) => t.name == 'Capacità' && t.unit == 'uF' && t.shortId == 'C'),
          isTrue);
    });

    testWidgets('Exiting submenu auto-saves changes to DataService',
        (tester) async {
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

      // Scroll and tap generic tags
      for (int i = 0; i < 20; i++) {
        if (find.text('Tag Generici (Sfusi)').evaluate().isNotEmpty) {
          break;
        }
        await tester.dragFrom(const Offset(10, 400), const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Tag Generici (Sfusi)'));
      await tester.pumpAndSettle();

      // Add a tag
      final tagField = find.widgetWithText(TextField, 'Nuovo tag generico');
      await tester.enterText(tagField, 'exit_save_tag');
      await tester.tap(find.widgetWithIcon(FilledButton, Icons.add));
      await tester.pumpAndSettle();

      // Tap Back button to exit menu
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(ds.settings.availableTags, contains('exit_save_tag'));
    });

    testWidgets(
        'Remote server menu has no save button and serverUrl is retained',
        (tester) async {
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

      // Enter Remote server menu
      await tester.tap(find.text('Server remoto'));
      await tester.pumpAndSettle();

      // Verify save button is REMOVED
      expect(find.widgetWithText(FilledButton, 'Salva'), findsNothing);
      expect(find.text('Salva impostazioni'), findsNothing);

      // Verify back button works to exit
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Server remoto'), findsOneWidget);
    });

    testWidgets('App lifecycle change (closing/backgrounding) auto-saves settings',
        (tester) async {
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

      // Scroll and tap generic tags
      for (int i = 0; i < 20; i++) {
        if (find.text('Tag Generici (Sfusi)').evaluate().isNotEmpty) {
          break;
        }
        await tester.dragFrom(const Offset(10, 400), const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Tag Generici (Sfusi)'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Nuovo tag generico'), 'lifecycle_tag');
      await tester.tap(find.widgetWithIcon(FilledButton, Icons.add));
      await tester.pumpAndSettle();

      // Simulate app paused / backgrounded / closed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(ds.settings.availableTags, contains('lifecycle_tag'));
    });
  });
}
