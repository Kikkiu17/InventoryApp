import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/component.dart';
import 'data_service.dart';

/// Holds sample data used for rendering dynamic visual examples
class FeatureSampleData {
  // Map Highlight Feature
  final String componentName;
  final String componentSubtitle;
  final int cabinet;
  final String drawer;
  final int zone;
  final bool isRealComponent;

  // Files Inspection Feature
  final String fileName;
  final String fileSubtitle;
  final String linkedComponentName;
  final String linkedComponentPosition;
  final bool isRealFile;

  // Auto-Save Settings Feature
  final bool isDarkMode;
  final String serverUrl;

  const FeatureSampleData({
    required this.componentName,
    required this.componentSubtitle,
    required this.cabinet,
    required this.drawer,
    required this.zone,
    required this.isRealComponent,
    required this.fileName,
    required this.fileSubtitle,
    required this.linkedComponentName,
    required this.linkedComponentPosition,
    required this.isRealFile,
    required this.isDarkMode,
    required this.serverUrl,
  });

  /// Extracts real data from DataService in memory (< 0.1ms, zero network calls),
  /// or falls back to standard mock samples if no suitable user data exists.
  factory FeatureSampleData.fromDataService(
      DataService? ds, AppLocalizations l10n) {
    if (ds == null || ds.components.isEmpty) {
      return FeatureSampleData.fallback(l10n);
    }

    // 1. Find a real component that has a drawer position assigned
    Component? mapComp;
    for (final c in ds.components) {
      if (c.drawer.trim().isNotEmpty && c.cabinet > 0) {
        mapComp = c;
        break;
      }
    }

    // 2. Find a real file or image attachment
    String? realFileName;
    String? realFileSub;
    String? realLinkedCompName;
    String? realLinkedCompPos;
    bool foundFile = false;

    for (final c in ds.components) {
      if (c.attachments.isNotEmpty) {
        final att = c.attachments.first;
        realFileName =
            att.name.isNotEmpty ? att.name : att.path.split('/').last;
        realFileSub = att.isLink ? 'Link' : 'File';
        realLinkedCompName = c.name;
        realLinkedCompPos = c.drawer.isNotEmpty
            ? '[${c.cabinet}] ${c.drawer} · ${c.drawerZone ?? 1}'
            : '';
        foundFile = true;
        break;
      } else if (c.images.isNotEmpty) {
        final img = c.images.first;
        realFileName = img.split('/').last;
        realFileSub = 'Foto';
        realLinkedCompName = c.name;
        realLinkedCompPos = c.drawer.isNotEmpty
            ? '[${c.cabinet}] ${c.drawer} · ${c.drawerZone ?? 1}'
            : '';
        foundFile = true;
        break;
      }
    }

    final isDark = ds.themeMode == ThemeMode.dark;
    final server = ds.serverUrl.isNotEmpty
        ? ds.serverUrl
        : 'http://192.168.1.2:8080';

    return FeatureSampleData(
      componentName: mapComp != null && mapComp.name.isNotEmpty
          ? mapComp.name
          : l10n.newFeatureMockResistor,
      componentSubtitle: mapComp != null && mapComp.description.isNotEmpty
          ? mapComp.description
          : (mapComp != null && mapComp.tags.isNotEmpty
              ? mapComp.tags.first
              : '0805 1% SMD'),
      cabinet: mapComp?.cabinet ?? 1,
      drawer: mapComp != null && mapComp.drawer.isNotEmpty
          ? mapComp.drawer
          : 'A1',
      zone: mapComp?.drawerZone ?? 2,
      isRealComponent: mapComp != null,
      fileName: foundFile && realFileName != null
          ? realFileName
          : l10n.newFeatureMockFile,
      fileSubtitle:
          foundFile && realFileSub != null ? realFileSub : '1.2 MB',
      linkedComponentName: foundFile && realLinkedCompName != null
          ? realLinkedCompName
          : 'Arduino Nano',
      linkedComponentPosition:
          foundFile && realLinkedCompPos != null && realLinkedCompPos.isNotEmpty
              ? realLinkedCompPos
              : '[1] B3 · 1',
      isRealFile: foundFile,
      isDarkMode: isDark,
      serverUrl: server,
    );
  }

  /// Default mock fallback when inventory is empty
  factory FeatureSampleData.fallback(AppLocalizations l10n) {
    return FeatureSampleData(
      componentName: l10n.newFeatureMockResistor,
      componentSubtitle: '0805 1% SMD',
      cabinet: 1,
      drawer: 'A1',
      zone: 2,
      isRealComponent: false,
      fileName: l10n.newFeatureMockFile,
      fileSubtitle: '1.2 MB',
      linkedComponentName: 'Arduino Nano',
      linkedComponentPosition: '[1] B3 · 1',
      isRealFile: false,
      isDarkMode: true,
      serverUrl: 'https://192.168.1.100',
    );
  }
}

/// Represents an individual feature presented in the walkthrough
class AppFeature {
  final String id;
  final String Function(AppLocalizations l10n) category;
  final IconData categoryIcon;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) subtitle;
  final Widget Function(BuildContext context, FeatureSampleData sample)
      visualBuilder;
  final IconData step1Icon;
  final String Function(AppLocalizations l10n) step1Text;
  final IconData step2Icon;
  final String Function(AppLocalizations l10n) step2Text;

  const AppFeature({
    required this.id,
    required this.category,
    required this.categoryIcon,
    required this.title,
    required this.subtitle,
    required this.visualBuilder,
    required this.step1Icon,
    required this.step1Text,
    required this.step2Icon,
    required this.step2Text,
  });
}

/// Catalog of features organized by version
class FeaturesCatalog {
  /// The current latest version that introduces new features
  static const String currentCatalogVersion = '1.19.0';

  /// List of features available for the current release
  static List<AppFeature> getFeatures() {
    return [
      AppFeature(
        id: 'map_highlight_from_tile',
        category: (l10n) => l10n.newFeatureMapCategory,
        categoryIcon: Icons.map_outlined,
        title: (l10n) => l10n.newFeatureMapTitle,
        subtitle: (l10n) => l10n.newFeatureMapSubtitle,
        visualBuilder: (context, sample) => _buildMapVisual(context, sample),
        step1Icon: Icons.touch_app_outlined,
        step1Text: (l10n) => l10n.newFeatureMapStep1,
        step2Icon: Icons.center_focus_strong_outlined,
        step2Text: (l10n) => l10n.newFeatureMapStep2,
      ),
      AppFeature(
        id: 'files_view_item_link',
        category: (l10n) => l10n.newFeatureFilesCategory,
        categoryIcon: Icons.folder_open_outlined,
        title: (l10n) => l10n.newFeatureFilesTitle,
        subtitle: (l10n) => l10n.newFeatureFilesSubtitle,
        visualBuilder: (context, sample) => _buildFilesVisual(context, sample),
        step1Icon: Icons.mouse_outlined,
        step1Text: (l10n) => l10n.newFeatureFilesStep1,
        step2Icon: Icons.visibility_outlined,
        step2Text: (l10n) => l10n.newFeatureFilesStep2,
      ),
      AppFeature(
        id: 'settings_instant_autosave',
        category: (l10n) => l10n.newFeatureSettingsCategory,
        categoryIcon: Icons.tune_outlined,
        title: (l10n) => l10n.newFeatureSettingsTitle,
        subtitle: (l10n) => l10n.newFeatureSettingsSubtitle,
        visualBuilder: (context, sample) =>
            _buildSettingsVisual(context, sample),
        step1Icon: Icons.edit_note_outlined,
        step1Text: (l10n) => l10n.newFeatureSettingsStep1,
        step2Icon: Icons.save_alt_outlined,
        step2Text: (l10n) => l10n.newFeatureSettingsStep2,
      ),
    ];
  }

  static Widget _buildMapVisual(
      BuildContext context, FeatureSampleData sample) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final tileMock = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clickable position badge with pointer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cs.primary, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, size: 14, color: cs.primary),
                const SizedBox(width: 3),
                Text(
                  '[${sample.cabinet}] ${sample.drawer} · ${sample.zone}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sample.componentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sample.componentSubtitle,
                  style: TextStyle(fontSize: 10, color: theme.hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final drawerMock = Container(
      width: 105,
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1208),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF9800), width: 3.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.5),
        child: Column(
          children: [
            // Top zone
            Expanded(
              child: Container(
                color: const Color(0xFF1E1208),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'L',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF5D4037),
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Middle target zone
            Expanded(
              child: Container(
                color: const Color(0xFF3E2723),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'I',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sample.drawer,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF9800),
                      ),
                      child: Text(
                        '${sample.zone}',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom non-target zone
            Expanded(
              child: Container(
                color: const Color(0xFF1E1208),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: const Row(
                  children: [
                    Text(
                      'V',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          tileMock,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child:
                Icon(Icons.arrow_forward_rounded, color: cs.primary, size: 24),
          ),
          drawerMock,
        ],
      ),
    );
  }

  static Widget _buildFilesVisual(
      BuildContext context, FeatureSampleData sample) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final fileWithMenuMock = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                sample.fileSubtitle.toLowerCase().contains('foto') ||
                        sample.fileName.endsWith('.png') ||
                        sample.fileName.endsWith('.jpg')
                    ? Icons.image
                    : Icons.picture_as_pdf,
                color: Colors.redAccent,
                size: 22,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sample.fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      sample.fileSubtitle,
                      style: TextStyle(fontSize: 9, color: theme.hintColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Context menu simulation
        Container(
          width: 140,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(7)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility,
                        size: 13, color: cs.onPrimaryContainer),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        l10n.newFeatureMockViewItem,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.share, size: 13, color: theme.hintColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        l10n.shareFile,
                        style: TextStyle(fontSize: 10, color: theme.hintColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final itemDetailsMock = Container(
      width: 135,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory, size: 15, color: cs.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  sample.linkedComponentName,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sample.linkedComponentPosition,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              l10n.goToPosition,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: cs.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          fileWithMenuMock,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child:
                Icon(Icons.arrow_forward_rounded, color: cs.primary, size: 24),
          ),
          itemDetailsMock,
        ],
      ),
    );
  }

  static Widget _buildSettingsVisual(
      BuildContext context, FeatureSampleData sample) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.dark_mode_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.themeDark,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: sample.isDarkMode,
                  onChanged: null,
                ),
              ),
            ],
          ),
          const Divider(height: 10),
          Row(
            children: [
              Icon(Icons.sync, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.useRemoteServer,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 13, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      l10n.newFeatureMockAutoSaved,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
