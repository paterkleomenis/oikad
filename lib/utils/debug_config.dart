import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

/// Debug configuration utility for OIKAD
///
/// This class manages debug features and logging based on build mode
/// and environment variables. In production builds, debug features
/// are automatically disabled for security and performance.
class DebugConfig {
  // Environment-based debug controls
  static bool get _debugModeFromEnv =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  static bool get _enableDebugMenuFromEnv =>
      dotenv.env['ENABLE_DEBUG_MENU']?.toLowerCase() == 'true';

  static bool get _enableVerboseLoggingFromEnv =>
      dotenv.env['ENABLE_VERBOSE_LOGGING']?.toLowerCase() == 'true';

  /// Whether debug features are enabled
  /// Only true in debug builds when explicitly enabled
  static bool get isDebugEnabled => kDebugMode && _debugModeFromEnv;

  /// Whether debug menu should be shown
  /// Only available in debug builds
  static bool get showDebugMenu => kDebugMode && _enableDebugMenuFromEnv;

  /// Whether verbose logging is enabled
  /// Disabled in release builds for performance
  static bool get enableVerboseLogging =>
      kDebugMode && _enableVerboseLoggingFromEnv;

  /// Whether to show debug overlays
  static bool get showDebugOverlays => kDebugMode && isDebugEnabled;

  /// Whether to enable performance monitoring
  static bool get enablePerformanceMonitoring => kDebugMode || kProfileMode;

  /// App environment (development, staging, production)
  static String get appEnvironment =>
      dotenv.env['APP_ENV'] ?? (kDebugMode ? 'development' : 'production');

  /// Whether app is running in production
  static bool get isProduction =>
      appEnvironment == 'production' && kReleaseMode;

  /// Whether app is running in staging
  static bool get isStaging => appEnvironment == 'staging';

  /// Whether app is running in development
  static bool get isDevelopment =>
      appEnvironment == 'development' && kDebugMode;

  /// Safe debug print that only prints in debug mode
  static void debugLog(String message, {String? tag}) {
    if (kDebugMode && enableVerboseLogging) {
      final prefix = tag != null ? '[$tag] ' : '[DEBUG] ';
      developer.log('$prefix$message');
    }
  }

  /// Log important information (allowed in release builds)
  static void logInfo(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '[INFO] ';
    if (kDebugMode) {
      developer.log('$prefix$message');
    }
  }

  /// Log warnings (allowed in release builds)
  static void logWarning(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '[WARNING] ';
    if (kDebugMode) {
      developer.log('$prefix$message');
    }
  }

  /// Log errors (always enabled)
  static void logError(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final prefix = tag != null ? '[$tag] ' : '[ERROR] ';
    if (kDebugMode) {
      developer.log('$prefix$message');

      if (error != null) {
        developer.log('Error: $error');
      }

      if (stackTrace != null) {
        developer.log('Stack trace: $stackTrace');
      }
    }
  }

  /// Get debug configuration summary
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isDebugBuild': kDebugMode,
      'isReleaseBuild': kReleaseMode,
      'isProfileBuild': kProfileMode,
      'appEnvironment': appEnvironment,
      'isDebugEnabled': isDebugEnabled,
      'showDebugMenu': showDebugMenu,
      'enableVerboseLogging': enableVerboseLogging,
      'showDebugOverlays': showDebugOverlays,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'isProduction': isProduction,
      'isStaging': isStaging,
      'isDevelopment': isDevelopment,
    };
  }

  /// Performance timing utility
  static void timeOperation(String operationName, Function operation) {
    if (!enablePerformanceMonitoring) {
      operation();
      return;
    }

    final stopwatch = Stopwatch()..start();
    try {
      operation();
    } finally {
      stopwatch.stop();
      debugLog(
        'Operation "$operationName" took ${stopwatch.elapsedMilliseconds}ms',
        tag: 'PERFORMANCE',
      );
    }
  }

  /// Async performance timing utility
  static Future<T> timeAsyncOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!enablePerformanceMonitoring) {
      return await operation();
    }

    final stopwatch = Stopwatch()..start();
    try {
      return await operation();
    } finally {
      stopwatch.stop();
      debugLog(
        'Async operation "$operationName" took ${stopwatch.elapsedMilliseconds}ms',
        tag: 'PERFORMANCE',
      );
    }
  }

  /// Assert that only works in debug mode
  static void debugAssert(bool condition, String message) {
    if (kDebugMode && !condition) {
      throw AssertionError('Debug assertion failed: $message');
    }
  }

  /// Feature flag utility
  static bool isFeatureEnabled(String featureName) {
    final envKey = 'ENABLE_${featureName.toUpperCase()}';
    final envValue = dotenv.env[envKey]?.toLowerCase();

    // Default to true for development, false for production
    final defaultValue = isDevelopment;

    switch (envValue) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
      default:
        return defaultValue;
    }
  }

  /// Network debug configuration
  static bool get enableNetworkLogging =>
      kDebugMode &&
      dotenv.env['ENABLE_NETWORK_LOGGING']?.toLowerCase() == 'true';

  /// Database debug configuration
  static bool get enableDatabaseLogging =>
      kDebugMode &&
      dotenv.env['ENABLE_DATABASE_LOGGING']?.toLowerCase() == 'true';

  /// Update system debug configuration
  static bool get enableUpdateSystemLogging =>
      kDebugMode &&
      dotenv.env['ENABLE_UPDATE_LOGGING']?.toLowerCase() == 'true';

  /// Memory usage monitoring
  static bool get enableMemoryMonitoring =>
      kDebugMode &&
      dotenv.env['ENABLE_MEMORY_MONITORING']?.toLowerCase() == 'true';
}

/// Debug-only widget wrapper
///
/// Wraps a widget that should only be visible in debug builds
class DebugOnly extends StatelessWidget {
  final Widget child;
  final Widget? replacement;

  const DebugOnly({super.key, required this.child, this.replacement});

  @override
  Widget build(BuildContext context) {
    if (DebugConfig.isDebugEnabled) {
      return child;
    }

    return replacement ?? const SizedBox.shrink();
  }
}

/// Development-only widget wrapper
///
/// Wraps a widget that should only be visible in development environment
class DevOnly extends StatelessWidget {
  final Widget child;
  final Widget? replacement;

  const DevOnly({super.key, required this.child, this.replacement});

  @override
  Widget build(BuildContext context) {
    if (DebugConfig.isDevelopment) {
      return child;
    }

    return replacement ?? const SizedBox.shrink();
  }
}
