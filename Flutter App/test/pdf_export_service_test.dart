import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/l10n/app_localizations_it.dart';
import 'package:inventario/models/component.dart';
import 'package:inventario/models/search_result.dart';
import 'package:inventario/models/settings.dart';
import 'package:inventario/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfExportService Document Generation Tests', () {
    test('generateComponentsPdfDocument produces valid PDF bytes', () async {
      final l10n = AppLocalizationsIt();

      final settings = AppSettings(
        numCabinets: 2,
        drawerDividers: {'1_A1': 2},
        specialTags: [
          SpecialTag(name: 'Resistenza', unit: 'Ω', shortId: 'R'),
        ],
      );

      final components = [
        Component(
          id: 'c1',
          name: 'Resistore 220',
          drawer: 'A1',
          cabinet: 1,
          drawerZone: 1,
          quantity: 100,
          description: 'Through-hole resistor',
          tags: ['resistor', 'tht'],
          specialTagValues: {'Resistenza': '220'},
        ),
        Component(
          id: 'c2',
          name: 'Condensatore Elettrolitico',
          drawer: '',
          quantity: 5,
        ),
      ];

      final doc = await PdfExportService.generateComponentsPdfDocument(
        l10n: l10n,
        items: components,
        settings: settings,
        title: 'Inventario Principale',
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
      // PDF documents start with '%PDF'
      expect(String.fromCharCodes(bytes.take(4)), equals('%PDF'));
    });

    test('generateGlobalSearchPdfDocument produces valid PDF bytes for multi-inventory and buffer items', () async {
      final l10n = AppLocalizationsIt();

      final settings = AppSettings(
        numCabinets: 1,
        drawerDividers: {},
        specialTags: [
          SpecialTag(name: 'Tensione', unit: 'V', shortId: 'V'),
        ],
      );

      final results = [
        GlobalSearchResult(
          inventoryId: 'inv-1',
          inventoryName: 'Magazzino Lab',
          component: Component(
            id: 'c-lab-1',
            name: 'Regolatore LM7805',
            drawer: 'D3',
            cabinet: 1,
            quantity: 12,
            description: '5V Voltage Regulator',
            tags: ['power', 'regulator'],
            specialTagValues: {'Tensione': '5'},
          ),
          specialTags: [
            SpecialTag(name: 'Tensione', unit: 'V', shortId: 'V'),
          ],
        ),
        GlobalSearchResult(
          inventoryId: '_buffer_',
          inventoryName: 'Buffer',
          component: Component(
            id: 'c-buf-1',
            name: 'Pulsante Normalmente Aperto',
            drawer: '',
            quantity: 30,
            description: 'Tactile switch',
            tags: ['switch'],
          ),
        ),
      ];

      final doc = await PdfExportService.generateGlobalSearchPdfDocument(
        l10n: l10n,
        items: results,
        settings: settings,
        query: 'Regolatore',
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
      expect(String.fromCharCodes(bytes.take(4)), equals('%PDF'));
    });
  });
}
