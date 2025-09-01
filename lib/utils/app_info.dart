import 'package:package_info_plus/package_info_plus.dart';

/// Utility class for getting app information consistently across the app
class AppInfo {
  static PackageInfo? _packageInfo;

  /// Initialize the app info (call this once at app startup)
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Get the current app version (e.g., "1.1.1")
  static String get version {
    return _packageInfo?.version ?? '1.1.1';
  }

  /// Get the current build number (e.g., "1")
  static String get buildNumber {
    return _packageInfo?.buildNumber ?? '1';
  }

  /// Get the full version string (e.g., "1.1.1+1")
  static String get fullVersion {
    return '${version}+${buildNumber}';
  }

  /// Get the formatted version for display (e.g., "Version 1.1.1")
  static String get displayVersion {
    return 'Version $version';
  }

  /// Get the app name
  static String get appName {
    return _packageInfo?.appName ?? 'OIKAD';
  }

  /// Get the package name
  static String get packageName {
    return _packageInfo?.packageName ?? 'com.oikad.app';
  }

  /// Check if app info is initialized
  static bool get isInitialized {
    return _packageInfo != null;
  }

  /// Force refresh the package info
  static Future<void> refresh() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }
}
