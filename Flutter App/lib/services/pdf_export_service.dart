import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

import '../l10n/app_localizations.dart';
import '../models/component.dart';
import '../models/search_result.dart';
import '../models/settings.dart';

class PdfExportService {
  static Future<pw.Document> _createDocument() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);
      return pw.Document(theme: pw.ThemeData.withFont(base: ttf));
    } catch (_) {
      return pw.Document();
    }
  }

  static Future<pw.Document> generateComponentsPdfDocument({
    required AppLocalizations l10n,
    required List<Component> items,
    required AppSettings settings,
    String? title,
  }) async {
    final effectiveTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : l10n.exportPdfTitle;
    final pdf = await _createDocument();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              effectiveTitle,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: [
              l10n.colName,
              l10n.colPosition,
              l10n.colQuantity,
              l10n.colDetails,
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: const {
              0: pw.FlexColumnWidth(1.6),
              1: pw.FixedColumnWidth(70),
              2: pw.FixedColumnWidth(40),
              3: pw.FlexColumnWidth(4.9),
            },
            data: items.map((c) {
              final key = '${c.cabinet}_${c.drawer}';
              final zones = settings.drawerDividers[key] ?? 1;
              var pos = c.drawer.isEmpty
                  ? l10n.unassignedPosition
                  : (settings.numCabinets > 1
                      ? '${c.cabinet}-${c.drawer}'
                      : c.drawer);
              if (c.drawer.isNotEmpty && c.drawerZone != null && zones >= 2) {
                pos += '\nZ${c.drawerZone}';
              }
              final props = c.specialTagValues.entries.map((e) {
                final st = settings.specialTags
                    .where((s) => s.name == e.key)
                    .firstOrNull;
                return '${e.key}: ${formatValueWithUnit(e.value, st?.unit ?? '')}';
              }).join(', ');
              final details = [
                if (c.description.isNotEmpty) c.description,
                if (c.tags.isNotEmpty) c.tags.join(', '),
                if (props.isNotEmpty) props,
              ].join('\n');

              return [c.name, pos, c.quantity.toString(), details];
            }).toList(),
          ),
        ],
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generateGlobalSearchPdfDocument({
    required AppLocalizations l10n,
    required List<GlobalSearchResult> items,
    AppSettings? settings,
    String? query,
    String? title,
  }) async {
    final effectiveTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : ((query != null && query.trim().isNotEmpty)
            ? '${l10n.exportPdfTitle} - ${query.trim()}'
            : l10n.exportPdfTitle);
    final pdf = await _createDocument();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              effectiveTitle,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: [
              l10n.colName,
              l10n.tabInventory,
              l10n.colPosition,
              l10n.colQuantity,
              l10n.colDetails,
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: const {
              0: pw.FlexColumnWidth(2.0),
              1: pw.FlexColumnWidth(1.4),
              2: pw.FixedColumnWidth(65),
              3: pw.FixedColumnWidth(40),
              4: pw.FlexColumnWidth(3.6),
            },
            data: items.map((res) {
              final c = res.component;
              final isBuffer = res.inventoryId == '_buffer_';
              final key = '${c.cabinet}_${c.drawer}';
              final zones = settings?.drawerDividers[key] ?? 1;

              var pos = isBuffer
                  ? '-'
                  : (c.drawer.isEmpty
                      ? l10n.unassignedPosition
                      : ((settings?.numCabinets ?? 1) > 1
                          ? '${c.cabinet}-${c.drawer}'
                          : c.drawer));

              if (!isBuffer &&
                  c.drawer.isNotEmpty &&
                  c.drawerZone != null &&
                  zones >= 2) {
                pos += '\nZ${c.drawerZone}';
              }

              final availableSpecialTags =
                  res.specialTags ?? settings?.specialTags;
              final props = c.specialTagValues.entries.map((e) {
                final st = availableSpecialTags
                    ?.where((s) => s.name == e.key)
                    .firstOrNull;
                return '${e.key}: ${formatValueWithUnit(e.value, st?.unit ?? '')}';
              }).join(', ');

              final details = [
                if (c.description.isNotEmpty) c.description,
                if (c.tags.isNotEmpty) c.tags.join(', '),
                if (props.isNotEmpty) props,
              ].join('\n');

              return [
                c.name,
                res.inventoryName,
                pos,
                c.quantity.toString(),
                details,
              ];
            }).toList(),
          ),
        ],
      ),
    );
    return pdf;
  }

  static Future<void> saveAndOpenPdf({
    required BuildContext context,
    required pw.Document pdf,
    String filename = 'inventario_export.pdf',
  }) async {
    final l10n = context.l10n;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.exportError}: $e')),
        );
      }
    }
  }

  static Future<void> exportComponents({
    required BuildContext context,
    required List<Component> items,
    required AppSettings settings,
    String? title,
  }) async {
    final pdf = await generateComponentsPdfDocument(
      l10n: context.l10n,
      items: items,
      settings: settings,
      title: title,
    );
    if (!context.mounted) return;
    await saveAndOpenPdf(context: context, pdf: pdf);
  }

  static Future<void> exportGlobalSearchResults({
    required BuildContext context,
    required List<GlobalSearchResult> items,
    AppSettings? settings,
    String? query,
    String? title,
  }) async {
    final pdf = await generateGlobalSearchPdfDocument(
      l10n: context.l10n,
      items: items,
      settings: settings,
      query: query,
      title: title,
    );
    if (!context.mounted) return;
    await saveAndOpenPdf(context: context, pdf: pdf);
  }
}
