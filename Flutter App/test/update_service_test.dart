import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UpdateService.availableUpdateNotifier.value = null;
  });

  group('UpdateService Version Comparison', () {
    test('cleanVersion handles v prefix, metadata, and whitespace', () {
      expect(UpdateService.cleanVersion('v1.2.3'), '1.2.3');
      expect(UpdateService.cleanVersion('V2.0.0'), '2.0.0');
      expect(UpdateService.cleanVersion('1.2.3+45'), '1.2.3');
      expect(UpdateService.cleanVersion('v1.2.3-beta.1'), '1.2.3');
      expect(UpdateService.cleanVersion('  v1.0.0  '), '1.0.0');
    });

    test('isNewerVersion correctly compares versions', () {
      expect(UpdateService.isNewerVersion('1.12.0', '1.11.0'), isTrue);
      expect(UpdateService.isNewerVersion('2.0.0', '1.99.99'), isTrue);
      expect(UpdateService.isNewerVersion('1.11.1', '1.11.0'), isTrue);
      expect(UpdateService.isNewerVersion('1.11.0', '1.11.0'), isFalse);
      expect(UpdateService.isNewerVersion('1.10.9', '1.11.0'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.0', '2.0.0'), isFalse);
    });

    test('cleanReleaseNotes deduplicates repeated release notes', () {
      const duplicatedNotes =
          '**Full Changelog**: https://github.com/Kikkiu17/InventoryApp/compare/v1.12.2...v1.12.3\n\n'
          '**Full Changelog**: https://github.com/Kikkiu17/InventoryApp/compare/v1.12.2...v1.12.3';
      expect(
        UpdateService.cleanReleaseNotes(duplicatedNotes),
        '**Full Changelog**: https://github.com/Kikkiu17/InventoryApp/compare/v1.12.2...v1.12.3',
      );

      const duplicatedMultiBlock =
          '## What\'s Changed\n* Added search\n\n**Full Changelog**: https://github.com/...\n\n'
          '## What\'s Changed\n* Added search\n\n**Full Changelog**: https://github.com/...';
      expect(
        UpdateService.cleanReleaseNotes(duplicatedMultiBlock),
        '## What\'s Changed\n* Added search\n\n**Full Changelog**: https://github.com/...',
      );

      const nonDuplicated = '## What\'s Changed\n* feat: nice\n\n**Full Changelog**: https://...';
      expect(UpdateService.cleanReleaseNotes(nonDuplicated), nonDuplicated);

      expect(UpdateService.cleanReleaseNotes(''), '');
      expect(UpdateService.cleanReleaseNotes('   '), '');
    });
  });

  group('UpdateService GitHub API & Dialog', () {
    test('checkUpdate parses release info and finds assets', () async {
      final mockResponse = jsonEncode({
        'tag_name': 'v1.12.0',
        'name': 'v1.12.0 - New Features',
        'body': '- Added awesome feature\n- Fixed bugs',
        'html_url': 'https://github.com/Kikkiu17/InventoryApp/releases/tag/v1.12.0',
        'assets': [
          {
            'name': 'app-release.apk',
            'browser_download_url': 'https://github.com/Kikkiu17/InventoryApp/releases/download/v1.12.0/app-release.apk',
            'size': 15000000,
          },
          {
            'name': 'Inventario-Windows-x64-Setup.exe',
            'browser_download_url': 'https://github.com/Kikkiu17/InventoryApp/releases/download/v1.12.0/Inventario-Windows-x64-Setup.exe',
            'size': 20000000,
          },
          {
            'name': 'Inventario-x86_64.AppImage',
            'browser_download_url': 'https://github.com/Kikkiu17/InventoryApp/releases/download/v1.12.0/Inventario-x86_64.AppImage',
            'size': 25000000,
          }
        ],
      });

      final mockClient = MockClient((request) async {
        return http.Response(mockResponse, 200);
      });

      final updateInfo = await UpdateService.checkUpdate(
        client: mockClient,
        currentVersionOverride: '1.11.0',
      );

      expect(updateInfo, isNotNull);
      expect(updateInfo!.hasUpdate, isTrue);
      expect(updateInfo.latestVersion, '1.12.0');
      expect(updateInfo.currentVersion, '1.11.0');
      expect(updateInfo.releaseName, 'v1.12.0 - New Features');
      expect(updateInfo.releaseNotes, contains('Added awesome feature'));
      expect(updateInfo.downloadUrl, isNotNull);
      expect(UpdateService.availableUpdateNotifier.value, equals(updateInfo));
    });

    testWidgets('checkAndPromptUpdate shows dialog with checkbox and saves preference',
        (WidgetTester tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Inventario',
        packageName: 'com.example.inventario',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );

      final mockResponse = jsonEncode({
        'tag_name': 'v2.0.0',
        'name': 'v2.0.0 Major Release',
        'body': 'Major update release notes',
        'html_url': 'https://github.com/Kikkiu17/InventoryApp/releases/tag/v2.0.0',
        'assets': [],
      });

      final mockClient = MockClient((request) async {
        return http.Response(mockResponse, 200);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  UpdateService.checkAndPromptUpdate(
                    context,
                    client: mockClient,
                  );
                },
                child: const Text('Check'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('Aggiornamento disponibile'), findsOneWidget);
      expect(find.text('Non mostrare più all\'avvio'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      // Check the "don't show again" checkbox
      await tester.tap(find.text('Non mostrare più all\'avvio'));
      await tester.pumpAndSettle();

      // Dismiss dialog
      await tester.tap(find.text('Più tardi'));
      await tester.pumpAndSettle();

      expect(find.text('Aggiornamento disponibile'), findsNothing);

      // Verify ignored version was stored in SharedPreferences
      expect(await UpdateService.isVersionIgnored('2.0.0'), isTrue);

      // Trigger update check again (simulating startup) - should NOT show dialog because it was ignored
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('Aggiornamento disponibile'), findsNothing);
      // But availableUpdateNotifier still has the update info so top bar icon can be shown!
      expect(UpdateService.availableUpdateNotifier.value, isNotNull);
      expect(UpdateService.availableUpdateNotifier.value!.latestVersion, '2.0.0');
    });
  });
}
