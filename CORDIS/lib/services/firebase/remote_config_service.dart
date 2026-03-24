import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Handles app-level remote configuration used during startup.
class RemoteConfigService {
  static const String minSupportedVersionKey = 'min_supported_version';
  static const String registrationEnabledKey = 'registration_enabled';
  static const String _defaultMinSupportedVersion = '0';
  static const bool _defaultRegistrationEnabled = true;

  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static bool _isInitialized = false;

  static Future<void> initializeAndFetch() async {
    if (!_isInitialized) {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 0)
              : const Duration(hours: 4),
        ),
      );

      await _remoteConfig.setDefaults(const {
        minSupportedVersionKey: _defaultMinSupportedVersion,
        registrationEnabledKey: _defaultRegistrationEnabled,
      });

      _isInitialized = true;
    }

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (error) {
      debugPrint('Remote Config fetch failed: $error');
    }
  }

  static int get minSupportedMajorVersion =>
      _parseSingleDigit(_remoteConfig.getString(minSupportedVersionKey));

  static Future<int> get currentAppMajorVersion async {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final majorPart = version.split('.').first;
    return int.tryParse(majorPart) ?? 0;
  }

  static Future<bool> isCurrentVersionSupported() async {
    final currentMajor = await currentAppMajorVersion;
    return currentMajor >= minSupportedMajorVersion;
  }

  static bool get isRegistrationEnabled =>
      _remoteConfig.getBool(registrationEnabledKey);

  static int _parseSingleDigit(String value) {
    if (value.isEmpty) {
      return 0;
    }

    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0 || parsed > 9) {
      return 0;
    }

    return parsed;
  }
}