import 'package:package_info_plus/package_info_plus.dart';

/// Utility class for getting app information consistently across the app
class AppInfo {
  static PackageInfo? _packageInfo;

  /// Initialize the app info (call this once at app startup)
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Get the current app version with safe fallback
  static String get version {
    return _packageInfo?.version ?? 'Unknown';
  }

  /// Get the current build number with safe fallback
  static String get buildNumber {
    return _packageInfo?.buildNumber ?? 'Unknown';
  }

  /// Check if app info has been properly initialized
  static bool get isInitialized {
    return _packageInfo != null;
  }

  /// Get version safely - returns null if not initialized
  static String? get versionSafe {
    return _packageInfo?.version;
  }

  /// Get build number safely - returns null if not initialized
  static String? get buildNumberSafe {
    return _packageInfo?.buildNumber;
  }

  /// Get the full version string (e.g., "1.0.0+1")
  static String get fullVersion {
    if (isInitialized) {
      return '${version}+${buildNumber}';
    }
    return 'Unknown Version';
  }

  /// Get the formatted version for display (e.g., "Version 1.0.0")
  static String get displayVersion {
    if (isInitialized) {
      return 'Version $version';
    }
    return 'Version Unknown';
  }

  /// Get the app name
  static String get appName {
    return _packageInfo?.appName ?? 'OIKAD';
  }

  /// Get the package name
  static String get packageName {
    return _packageInfo?.packageName ?? 'com.oikad.app';
  }

  /// Force refresh the package info
  static Future<void> refresh() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }
}
