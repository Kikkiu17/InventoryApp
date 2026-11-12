import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/l10n/app_localizations.dart';
import 'package:inventario/models/component.dart';
import 'package:inventario/screens/new_features_screen.dart';
import 'package:inventario/screens/settings_screen.dart';
import 'package:inventario/services/data_service.dart';
import 'package:inventario/services/features_catalog.dart';
import 'package:inventario/services/new_features_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'inventario',
      packageName: 'com.example.inventario',
      version: '1.19.3',
      buildNumber: '1',
      buildSignature: '',
    );
    NewFeaturesService.isShowing = false;
  });

  Widget buildTestableWidget(Widget child, {Locale locale = const Locale('it')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  group('NewFeaturesService Unit Tests', () {
    test('Preferences toggle for dontShowOnUpdate works correctly', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await NewFeaturesService.isDontShowOnUpdateEnabled(), isFalse);
      expect(NewFeaturesService.isAutoShowDisabled, isFalse);

      await NewFeaturesService.setDontShowOnUpdate(true);
      expect(await NewFeaturesService.isDontShowOnUpdateEnabled(), isTrue);
      expect(NewFeaturesService.isAutoShowDisabled, isTrue);

      await NewFeaturesService.setDontShowOnUpdate(false);
      expect(await NewFeaturesService.isDontShowOnUpdateEnabled(), isFalse);
      expect(NewFeaturesService.isAutoShowDisabled, isFalse);
    });

    test('Version seen tracking saves and retrieves correctly', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await NewFeaturesService.getLastSeenVersion(), isNull);

      await NewFeaturesService.markCurrentVersionSeen('1.18.0');
      expect(await NewFeaturesService.getLastSeenVersion(), equals('1.18.0'));
    });

    test('shouldShow returns true on fresh run or newer version, false when seen or disabled', () async {
      SharedPreferences.setMockInitialValues({});

      // Fresh run with no seen version
      expect(await NewFeaturesService.shouldShow(), isTrue);

      // Current version marked seen
      final currentVer = await NewFeaturesService.getCurrentAppVersion();
      await NewFeaturesService.markCurrentVersionSeen(currentVer);
      expect(await NewFeaturesService.shouldShow(), isFalse);

      // Old version was seen
      await NewFeaturesService.markCurrentVersionSeen('1.0.0');
      expect(await NewFeaturesService.shouldShow(), isTrue);

      // Opted out of future auto-show
      await NewFeaturesService.setDontShowOnUpdate(true);
      expect(await NewFeaturesService.shouldShow(), isFalse);
    });
  });

  group('NewFeaturesScreen Widget & Navigation Tests', () {
    testWidgets('Renders Page 1 with structure, category, title, visual mockup, and controls', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(buildTestableWidget(const NewFeaturesScreen()));
      await tester.pumpAndSettle();

      // Header title and version tag
      expect(find.text("Novità dell'app"), findsOneWidget);
      expect(find.byKey(const Key('new_features_skip_button')), findsOneWidget);

      // Page 1 category and title
      expect(find.text('Mappa & Posizione'), findsOneWidget);
      expect(find.text('Trova sulla mappa in un tocco'), findsOneWidget);

      // Visual mockup elements for Map feature
      expect(find.text('[1] A1 · 2'), findsOneWidget);
      expect(find.text('Resistore 10kΩ'), findsOneWidget);
      expect(find.text('A1'), findsOneWidget);

      // Back button not visible on page 0
      expect(find.byKey(const Key('new_features_back_button')), findsNothing);

      // Next button visible
      expect(find.byKey(const Key('new_features_next_done_button')), findsOneWidget);
      expect(find.text('Avanti'), findsOneWidget);

      // "Don't show for new versions" checkbox is present
      expect(find.byKey(const Key('new_features_dont_show_checkbox')), findsOneWidget);
      expect(find.text('Non mostrare per le nuove versioni'), findsOneWidget);
    });

    testWidgets('Forward and Back navigation works smoothly through all 3 pages', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(buildTestableWidget(const NewFeaturesScreen()));
      await tester.pumpAndSettle();

      // Page 1
      expect(find.text('Mappa & Posizione'), findsOneWidget);

      // Tap Next to go to Page 2
      await tester.tap(find.byKey(const Key('new_features_next_done_button')));
      await tester.pumpAndSettle();

      // Page 2
      expect(find.text('Gestione File'), findsOneWidget);
      expect(find.text('Vedi elemento direttamente dai file'), findsOneWidget);
      expect(find.text('datasheet.pdf'), findsOneWidget);
      expect(find.text('Vedi elemento'), findsOneWidget);
      expect(find.text('Arduino Nano'), findsOneWidget);
      expect(find.text('Vai alla posizione'), findsOneWidget);

      // Back button is now available
      expect(find.byKey(const Key('new_features_back_button')), findsOneWidget);
      expect(find.text('Avanti'), findsOneWidget);

      // Tap Next to go to Page 3
      await tester.tap(find.byKey(const Key('new_features_next_done_button')));
      await tester.pumpAndSettle();

      // Page 3
      expect(find.text('Impostazioni'), findsOneWidget);
      expect(find.text('Salvataggio immediato senza tasti'), findsOneWidget);
      expect(find.text('Salvataggio automatico'), findsOneWidget);

      // Button is now Done ("Ho capito")
      expect(find.text('Ho capito'), findsOneWidget);
      expect(find.text('Avanti'), findsNothing);

      // Tap Back to return to Page 2
      await tester.tap(find.byKey(const Key('new_features_back_button')));
      await tester.pumpAndSettle();
      expect(find.text('Gestione File'), findsOneWidget);

      // Tap Back to return to Page 1
      await tester.tap(find.byKey(const Key('new_features_back_button')));
      await tester.pumpAndSettle();
      expect(find.text('Mappa & Posizione'), findsOneWidget);
      expect(find.byKey(const Key('new_features_back_button')), findsNothing);
    });

    testWidgets('Toggling "Don\'t show for new versions" checkbox updates preference', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(buildTestableWidget(const NewFeaturesScreen()));
      await tester.pumpAndSettle();

      final checkboxFinder = find.byKey(const Key('new_features_dont_show_checkbox'));
      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

      // Tap checkbox tile
      await tester.tap(find.byKey(const Key('new_features_dont_show_checkbox_tile')));
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
      expect(await NewFeaturesService.isDontShowOnUpdateEnabled(), isTrue);

      // Tap again to uncheck
      await tester.tap(find.byKey(const Key('new_features_dont_show_checkbox_tile')));
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
      expect(await NewFeaturesService.isDontShowOnUpdateEnabled(), isFalse);
    });

    testWidgets('Done button on final page dismisses screen and marks version seen', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => NewFeaturesService.show(ctx),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open screen
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text("Novità dell'app"), findsOneWidget);

      // Navigate to last page
      await tester.tap(find.byKey(const Key('new_features_next_done_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new_features_next_done_button')));
      await tester.pumpAndSettle();

      expect(find.text('Ho capito'), findsOneWidget);

      // Tap Done
      await tester.tap(find.byKey(const Key('new_features_next_done_button')));
      await tester.pumpAndSettle();

      // Screen dismissed
      expect(find.text("Novità dell'app"), findsNothing);
      expect(find.text('Open'), findsOneWidget);

      // Version marked seen
      expect(await NewFeaturesService.getLastSeenVersion(), isNotNull);
    });

    testWidgets('Skip button dismisses screen and marks version seen', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => NewFeaturesService.show(ctx),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text("Novità dell'app"), findsOneWidget);

      // Tap Skip
      await tester.tap(find.byKey(const Key('new_features_skip_button')));
      await tester.pumpAndSettle();

      expect(find.text("Novità dell'app"), findsNothing);
      expect(find.text('Open'), findsOneWidget);
      expect(await NewFeaturesService.getLastSeenVersion(), isNotNull);
    });

    testWidgets('Localizations work properly in English locale', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(buildTestableWidget(const NewFeaturesScreen(), locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text("Don't show for new versions"), findsOneWidget);
      expect(find.text('Map & Position'), findsOneWidget);
      expect(find.text('Find on Map in One Tap'), findsOneWidget);
    });
  });

  group('Settings Integration Tests', () {
    testWidgets('Info and updates menu shows New Features tile and Auto-Show switch', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final ds = DataService();

      await tester.pumpWidget(
        ChangeNotifierProvider<DataService>.value(
          value: ds,
          child: buildTestableWidget(
            const SettingsScreen(initialSubmenu: SettingsSubmenu.about),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Info and updates is open
      expect(find.byKey(const Key('settings_new_features_tile')), findsOneWidget);
      expect(find.text('Guida alle funzionalità'), findsOneWidget);
      expect(find.byKey(const Key('settings_new_features_auto_show_switch')), findsOneWidget);

      // Tap New Features tile -> opens NewFeaturesScreen
      await tester.tap(find.byKey(const Key('settings_new_features_tile')));
      await tester.pumpAndSettle();

      expect(find.text("Novità dell'app"), findsOneWidget);

      // Dismiss
      await tester.tap(find.byKey(const Key('new_features_skip_button')));
      await tester.pumpAndSettle();

      // Back in settings
      expect(find.byKey(const Key('settings_new_features_tile')), findsOneWidget);

      // Toggle switch in settings
      final switchFinder = find.byKey(const Key('settings_new_features_auto_show_switch'));
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
      expect(await NewFeaturesService.isDontShowOnUpdateEnabled(), isTrue);
    });
  });

  group('Dynamic Sample Data & Catalog Tests', () {
    test('FeatureSampleData extracts real user component and file when present in DataService', () async {
      final ds = DataService();
      ds.components.add(
        Component(
          name: 'ESP32-WROOM-32',
          description: 'Modulo WiFi e Bluetooth',
          cabinet: 2,
          drawer: 'C10',
          drawerZone: 3,
          attachments: [
            Attachment(name: 'esp32_pinout.pdf', path: '/storage/esp32_pinout.pdf'),
          ],
        ),
      );

      final l10n = AppLocalizations.fromLocale(const Locale('it'));
      final sample = FeatureSampleData.fromDataService(ds, l10n);

      expect(sample.isRealComponent, isTrue);
      expect(sample.componentName, equals('ESP32-WROOM-32'));
      expect(sample.cabinet, equals(2));
      expect(sample.drawer, equals('C10'));
      expect(sample.zone, equals(3));

      expect(sample.isRealFile, isTrue);
      expect(sample.fileName, equals('esp32_pinout.pdf'));
      expect(sample.linkedComponentName, equals('ESP32-WROOM-32'));
      expect(sample.linkedComponentPosition, equals('[2] C10 · 3'));
    });

    test('FeatureSampleData cleanly falls back when DataService is empty', () async {
      final ds = DataService();
      ds.components.clear();

      final l10n = AppLocalizations.fromLocale(const Locale('it'));
      final sample = FeatureSampleData.fromDataService(ds, l10n);

      expect(sample.isRealComponent, isFalse);
      expect(sample.componentName, equals(l10n.newFeatureMockResistor));
      expect(sample.drawer, equals('A1'));
      expect(sample.zone, equals(2));

      expect(sample.isRealFile, isFalse);
      expect(sample.fileName, equals(l10n.newFeatureMockFile));
    });

    testWidgets('NewFeaturesScreen displays real user item when DataService is provided', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final ds = DataService();
      ds.components.add(
        Component(
          name: 'Condensatore 100uF',
          description: 'Elettrolitico 25V',
          cabinet: 1,
          drawer: 'D5',
          drawerZone: 1,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<DataService>.value(
          value: ds,
          child: buildTestableWidget(const NewFeaturesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Real user item name and drawer should appear in the visual mockup
      expect(find.text('Condensatore 100uF'), findsOneWidget);
      expect(find.text('[1] D5 · 1'), findsOneWidget);
      expect(find.text('D5'), findsOneWidget);
    });

    test('FeaturesCatalog contains features for current version', () {
      expect(FeaturesCatalog.currentCatalogVersion, equals('1.19.0'));
      final features = FeaturesCatalog.getFeatures();
      expect(features.length, equals(3));
      expect(features.map((f) => f.id).toList(), containsAll([
        'map_highlight_from_tile',
        'files_view_item_link',
        'settings_instant_autosave',
      ]));
    });
  });
}
