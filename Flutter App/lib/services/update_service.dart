import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final bool hasUpdate;
  final String releaseName;
  final String releaseNotes;
  final String htmlUrl;
  final String? downloadUrl;
  final String? assetName;
  final int? assetSize;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.hasUpdate,
    required this.releaseName,
    required this.releaseNotes,
    required this.htmlUrl,
    this.downloadUrl,
    this.assetName,
    this.assetSize,
  });
}

class UpdateService {
  static const String repoOwner = 'Kikkiu17';
  static const String repoName = 'InventoryApp';
  static const String releasesApiUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';
  static const String releasesHtmlUrl =
      'https://github.com/$repoOwner/$repoName/releases';
  static const String prefKeyIgnoredVersion = 'ignored_update_version';

  /// Reactive notifier holding the current update info if available
  static final ValueNotifier<UpdateInfo?> availableUpdateNotifier =
      ValueNotifier<UpdateInfo?>(null);

  /// Checks if a version was marked as ignored ("don't show again")
  static Future<bool> isVersionIgnored(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ignored = prefs.getString(prefKeyIgnoredVersion);
      return ignored == version;
    } catch (_) {
      return false;
    }
  }

  /// Sets or clears the ignored version preference
  static Future<void> setVersionIgnored(String version, bool ignored) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (ignored) {
        await prefs.setString(prefKeyIgnoredVersion, version);
      } else {
        await prefs.remove(prefKeyIgnoredVersion);
      }
    } catch (_) {}
  }

  /// Cleans version string (removes leading 'v', build metadata '+...', pre-release tags)
  static String cleanVersion(String v) {
    var clean = v.trim();
    if (clean.startsWith('v') || clean.startsWith('V')) {
      clean = clean.substring(1);
    }
    final plusIdx = clean.indexOf('+');
    if (plusIdx != -1) {
      clean = clean.substring(0, plusIdx);
    }
    final dashIdx = clean.indexOf('-');
    if (dashIdx != -1) {
      clean = clean.substring(0, dashIdx);
    }
    return clean;
  }

  /// Compares two semver strings (e.g. "1.12.0" > "1.11.0")
  static bool isNewerVersion(String latest, String current) {
    final lParts =
        latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final cParts =
        current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = lParts.length > cParts.length ? lParts.length : cParts.length;
    for (int i = 0; i < maxLen; i++) {
      final l = i < lParts.length ? lParts[i] : 0;
      final c = i < cParts.length ? cParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  /// Checks GitHub for the latest release
  static Future<UpdateInfo?> checkUpdate({
    http.Client? client,
    String? currentVersionOverride,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final currentVersion = currentVersionOverride ??
          (await PackageInfo.fromPlatform()).version;

      final response = await httpClient.get(
        Uri.parse(releasesApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'InventoryApp',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final releaseName = data['name'] as String? ?? tagName;
      final releaseNotes = data['body'] as String? ?? '';
      final htmlUrl = data['html_url'] as String? ?? releasesHtmlUrl;
      final assets = (data['assets'] as List<dynamic>?) ?? [];

      final cleanLatest = cleanVersion(tagName);
      final cleanCurrent = cleanVersion(currentVersion);
      final hasUpdate = isNewerVersion(cleanLatest, cleanCurrent);

      String? downloadUrl;
      String? assetName;
      int? assetSize;

      if (Platform.isAndroid) {
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.toLowerCase().endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String?;
            assetName = name;
            assetSize = asset['size'] as int?;
            break;
          }
        }
      } else if (Platform.isWindows) {
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.toLowerCase().endsWith('.exe')) {
            downloadUrl = asset['browser_download_url'] as String?;
            assetName = name;
            assetSize = asset['size'] as int?;
            break;
          }
        }
      } else if (Platform.isLinux) {
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.toLowerCase().endsWith('.appimage')) {
            downloadUrl = asset['browser_download_url'] as String?;
            assetName = name;
            assetSize = asset['size'] as int?;
            break;
          }
        }
      }

      final updateInfo = UpdateInfo(
        latestVersion: cleanLatest,
        currentVersion: cleanCurrent,
        hasUpdate: hasUpdate,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        htmlUrl: htmlUrl,
        downloadUrl: downloadUrl,
        assetName: assetName,
        assetSize: assetSize,
      );

      if (hasUpdate) {
        availableUpdateNotifier.value = updateInfo;
      } else {
        availableUpdateNotifier.value = null;
      }

      return updateInfo;
    } catch (e) {
      debugPrint('Errore durante il controllo degli aggiornamenti: $e');
      return null;
    }
  }

  /// Checks GitHub and prompts user if an update is available
  static Future<void> checkAndPromptUpdate(
    BuildContext context, {
    bool showNoUpdateFeedback = false,
    http.Client? client,
  }) async {
    final updateInfo = await checkUpdate(client: client);
    if (!context.mounted) return;

    if (updateInfo != null && updateInfo.hasUpdate) {
      availableUpdateNotifier.value = updateInfo;
      final isIgnored = await isVersionIgnored(updateInfo.latestVersion);

      // If it's a manual check OR the user hasn't ignored this version, show the dialog
      if (showNoUpdateFeedback || !isIgnored) {
        await showUpdateDialog(context, updateInfo);
      }
    } else if (showNoUpdateFeedback) {
      final currentVer = updateInfo?.currentVersion ??
          (await PackageInfo.fromPlatform()).version;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'L\'applicazione è aggiornata all\'ultima versione (v$currentVer).',
            ),
          ),
        );
      }
    }
  }

  /// Shows confirmation dialog with "Don't show anymore" checkbox before downloading
  static Future<void> showUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    final cs = Theme.of(context).colorScheme;
    bool dontShowAgain = await isVersionIgnored(updateInfo.latestVersion);

    final shouldUpdate = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            icon: Icon(Icons.system_update_rounded, size: 36, color: cs.primary),
            title: const Text('Aggiornamento disponibile'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Installata: v${updateInfo.currentVersion}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        const Icon(Icons.arrow_forward, size: 16),
                        Text('Nuova: v${updateInfo.latestVersion}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: cs.primary)),
                      ],
                    ),
                  ),
                  if (updateInfo.releaseNotes.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Note di rilascio:',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      width: double.maxFinite,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          updateInfo.releaseNotes.trim(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text(
                    'È disponibile una nuova versione. Vuoi scaricarla e installarla adesso?',
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        dontShowAgain = !dontShowAgain;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: dontShowAgain,
                              onChanged: (val) {
                                setDialogState(() {
                                  dontShowAgain = val ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Non mostrare più all\'avvio',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Più tardi'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Aggiorna ora'),
                onPressed: () => Navigator.pop(dialogCtx, true),
              ),
            ],
          );
        },
      ),
    );

    // Save "don't show again" preference
    await setVersionIgnored(updateInfo.latestVersion, dontShowAgain);

    if (shouldUpdate == true && context.mounted) {
      await _downloadAndInstall(context, updateInfo);
    }
  }

  /// Downloads the release asset and launches installer
  static Future<void> _downloadAndInstall(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    if (updateInfo.downloadUrl == null) {
      final uri = Uri.parse(updateInfo.htmlUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    double progress = 0.0;
    int receivedBytes = 0;
    int totalBytes = updateInfo.assetSize ?? 0;
    bool isDownloading = true;
    String? errorMessage;
    StateSetter? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            dialogSetState = setState;
            return AlertDialog(
              title: Text(
                  isDownloading ? 'Download in corso...' : 'Aggiornamento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDownloading) ...[
                    LinearProgressIndicator(
                        value: totalBytes > 0 ? progress : null),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          totalBytes > 0
                              ? '${(receivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                              : '${(receivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (totalBytes > 0)
                          Text('${(progress * 100).toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ] else if (errorMessage != null) ...[
                    Text(errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 12),
                    const Text(
                        'Puoi scaricare l\'aggiornamento manualmente da GitHub.'),
                  ],
                ],
              ),
              actions: [
                if (!isDownloading && errorMessage != null) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(dlgCtx),
                    child: const Text('Chiudi'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      Navigator.pop(dlgCtx);
                      final uri = Uri.parse(updateInfo.htmlUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text('Apri su GitHub'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );

    try {
      final client = http.Client();
      final request =
          http.Request('GET', Uri.parse(updateInfo.downloadUrl!));
      request.headers['User-Agent'] = 'InventoryApp';
      final response = await client.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.contentLength != null && response.contentLength! > 0) {
          totalBytes = response.contentLength!;
        }

        Directory? saveDir;
        if (Platform.isAndroid) {
          saveDir = await getExternalStorageDirectory() ??
              await getTemporaryDirectory();
        } else {
          saveDir = await getTemporaryDirectory();
        }

        final fileName = updateInfo.assetName ??
            (Platform.isAndroid
                ? 'update.apk'
                : (Platform.isWindows ? 'update.exe' : 'update.AppImage'));
        final filePath = '${saveDir.path}/$fileName';
        final file = File(filePath);
        final sink = file.openWrite();

        await response.stream.listen(
          (chunk) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            if (totalBytes > 0) {
              progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
            }
            dialogSetState?.call(() {});
          },
        ).asFuture();

        await sink.flush();
        await sink.close();

        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (Platform.isLinux) {
          try {
            await Process.run('chmod', ['+x', file.path]);
          } catch (_) {}
        }

        final openRes = await OpenFilex.open(file.path);
        if (openRes.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File scaricato in: ${file.path}')),
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        dialogSetState?.call(() {
          isDownloading = false;
          errorMessage = 'Errore durante il download: $e';
        });
      }
    }
  }
}
