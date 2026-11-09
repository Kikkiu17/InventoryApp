import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/new_features_screen.dart';
import 'update_service.dart';

class NewFeaturesService {
  static const String prefKeyLastSeenVersion = 'new_features_last_seen_version';
  static const String prefKeyDontShowOnUpdate =
      'new_features_dont_show_on_update';

  static final ValueNotifier<bool> isAutoShowDisabledNotifier =
      ValueNotifier<bool>(false);

  static bool get isAutoShowDisabled => isAutoShowDisabledNotifier.value;

  /// Whether the screen is currently open
  static bool isShowing = false;

  /// Loads initial preferences into reactive notifier
  static Future<void> initPreferences() async {
    await isDontShowOnUpdateEnabled();
  }

  /// Whether the user opted out of showing new features screen on updates
  static Future<bool> isDontShowOnUpdateEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(prefKeyDontShowOnUpdate) ?? false;
      isAutoShowDisabledNotifier.value = val;
      return val;
    } catch (_) {
      return false;
    }
  }

  /// Sets or clears the opt-out preference for showing on updates
  static Future<void> setDontShowOnUpdate(bool value) async {
    isAutoShowDisabledNotifier.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyDontShowOnUpdate, value);
    } catch (_) {}
  }

  /// Gets the last version for which new features were seen or dismissed
  static Future<String?> getLastSeenVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(prefKeyLastSeenVersion);
    } catch (_) {
      return null;
    }
  }

  /// Marks the given version (or current app version) as seen
  static Future<void> markCurrentVersionSeen([String? version]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ver = version ?? await getCurrentAppVersion();
      await prefs.setString(prefKeyLastSeenVersion, ver);
    } catch (_) {}
  }

  static String? versionOverride;

  /// Gets the current running application version
  static Future<String> getCurrentAppVersion() async {
    if (versionOverride != null) return versionOverride!;
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version.isNotEmpty ? info.version : '1.19.0';
    } catch (_) {
      return '1.19.0';
    }
  }

  /// Determines if the new features screen should be shown automatically
  static Future<bool> shouldShow() async {
    final dontShow = await isDontShowOnUpdateEnabled();
    if (dontShow) return false;

    final lastSeen = await getLastSeenVersion();
    final current = await getCurrentAppVersion();

    if (lastSeen == null) {
      // First time running with this feature: show to inform user
      return true;
    }

    final cleanCurrent = UpdateService.cleanVersion(current);
    final cleanLastSeen = UpdateService.cleanVersion(lastSeen);

    return UpdateService.isNewerVersion(cleanCurrent, cleanLastSeen);
  }

  /// Automatically prompts the new features screen on app startup if applicable
  static Future<void> checkAndPrompt(BuildContext context) async {
    if (isShowing) return;
    final should = await shouldShow();
    if (should && context.mounted) {
      await show(context);
    }
  }

  /// Opens the new features screen
  static Future<void> show(BuildContext context) async {
    if (isShowing) return;
    isShowing = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => const NewFeaturesScreen(),
        ),
      );
    } finally {
      isShowing = false;
    }
  }
}
