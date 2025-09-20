import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_update.dart';
import '../services/update_service.dart';
import '../utils/app_info.dart';

import '../widgets/update_dialog.dart';

/// Comprehensive update manager with safety checks and testing capabilities
class UpdateManager {
  static const String _testModeKey = 'update_test_mode';
  static const String _safetyCheckKey = 'update_safety_check_enabled';
  static const String _updateChannelKey = 'update_channel';

  final UpdateService _updateService;
  bool _testMode = false;
  bool _safetyChecksEnabled = true;
  String _updateChannel = 'stable';

  UpdateManager(this._updateService);

  /// Initialize the update manager
  Future<void> initialize() async {
    await _loadSettings();
    await _updateService.initialize();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _testMode = prefs.getBool(_testModeKey) ?? false;
      _safetyChecksEnabled = prefs.getBool(_safetyCheckKey) ?? true;
      _updateChannel = prefs.getString(_updateChannelKey) ?? 'stable';

      if (kDebugMode) {
        debugPrint('UpdateManager initialized:');
        debugPrint('- Test Mode: $_testMode');
        debugPrint('- Safety Checks: $_safetyChecksEnabled');
        debugPrint('- Update Channel: $_updateChannel');
      }
    } catch (e) {
      debugPrint('Error loading UpdateManager settings: $e');
    }
  }

  /// Enable/disable test mode
  Future<void> setTestMode(bool enabled) async {
    _testMode = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_testModeKey, enabled);
      if (kDebugMode) {
        debugPrint('Test mode ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      debugPrint('Error saving test mode setting: $e');
    }
  }

  /// Enable/disable safety checks
  Future<void> setSafetyChecks(bool enabled) async {
    _safetyChecksEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_safetyCheckKey, enabled);
      if (kDebugMode) {
        debugPrint('Safety checks ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      debugPrint('Error saving safety check setting: $e');
    }
  }

  /// Set update channel (stable, beta, alpha)
  Future<void> setUpdateChannel(String channel) async {
    if (!['stable', 'beta', 'alpha'].contains(channel)) {
      throw ArgumentError('Invalid update channel: $channel');
    }

    _updateChannel = channel;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_updateChannelKey, channel);
      if (kDebugMode) {
        debugPrint('Update channel set to: $channel');
      }
    } catch (e) {
      debugPrint('Error saving update channel setting: $e');
    }
  }

  /// Perform comprehensive safety checks before update
  Future<UpdateSafetyResult> performSafetyChecks() async {
    final issues = <String>[];
    final warnings = <String>[];

    try {
      // Check available storage space
      if (Platform.isAndroid) {
        final storageResult = await _checkStorageSpace();
        if (!storageResult.hasSufficientSpace) {
          issues.add(
            'Insufficient storage space. Need at least ${storageResult.requiredMB}MB, have ${storageResult.availableMB}MB',
          );
        } else if (storageResult.availableMB < storageResult.requiredMB * 2) {
          warnings.add(
            'Low storage space. Consider freeing up more space before updating.',
          );
        }
      }

      // Check network connection
      final networkResult = await _checkNetworkConnection();
      if (!networkResult.isConnected) {
        issues.add('No internet connection available');
      } else if (networkResult.isMetered && !networkResult.isWiFi) {
        warnings.add(
          'Update will use mobile data. Consider connecting to WiFi to avoid data charges.',
        );
      }

      // Check device compatibility
      final deviceResult = await _checkDeviceCompatibility();
      if (!deviceResult.isCompatible) {
        issues.add('Device not compatible: ${deviceResult.reason}');
      }

      // Check battery level (if available)
      final batteryResult = await _checkBatteryLevel();
      if (batteryResult.level < 20) {
        warnings.add(
          'Low battery (${batteryResult.level}%). Consider charging before updating.',
        );
      }

      // Check if app is running in foreground
      if (!_isAppInForeground()) {
        warnings.add('App should remain in foreground during update.');
      }
    } catch (e) {
      issues.add('Error during safety checks: $e');
    }

    return UpdateSafetyResult(
      isSafe: issues.isEmpty,
      issues: issues,
      warnings: warnings,
    );
  }

  /// Check available storage space
  Future<StorageCheckResult> _checkStorageSpace() async {
    try {
      if (!Platform.isAndroid) {
        return StorageCheckResult(
          hasSufficientSpace: true,
          availableMB: 1000, // Assume sufficient for non-Android
          requiredMB: 50,
        );
      }

      // For Android, estimate based on current app size
      final estimatedSizeMB = 50; // Conservative estimate for APK size

      // Note: Getting exact storage space requires additional platform-specific code
      // For now, we'll assume sufficient space if no error occurs
      return StorageCheckResult(
        hasSufficientSpace: true,
        availableMB:
            500, // Placeholder - would need platform channel for exact value
        requiredMB: estimatedSizeMB,
      );
    } catch (e) {
      debugPrint('Error checking storage space: $e');
      return StorageCheckResult(
        hasSufficientSpace: false,
        availableMB: 0,
        requiredMB: 50,
      );
    }
  }

  /// Check network connection quality
  Future<NetworkCheckResult> _checkNetworkConnection() async {
    try {
      // Basic connectivity check
      final result = await InternetAddress.lookup('github.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      return NetworkCheckResult(
        isConnected: isConnected,
        isWiFi: false, // Would need platform channel for exact detection
        isMetered: false, // Would need platform channel for exact detection
        connectionType: 'unknown',
      );
    } catch (e) {
      return NetworkCheckResult(
        isConnected: false,
        isWiFi: false,
        isMetered: true,
        connectionType: 'none',
      );
    }
  }

  /// Check device compatibility
  Future<DeviceCompatibilityResult> _checkDeviceCompatibility() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final sdkVersion = androidInfo.version.sdkInt;

        // Check minimum SDK version (API 21 / Android 5.0)
        if (sdkVersion < 21) {
          return DeviceCompatibilityResult(
            isCompatible: false,
            reason:
                'Android version too old (API $sdkVersion). Minimum required: API 21',
          );
        }

        // Check architecture
        final abis = androidInfo.supportedAbis;
        if (!abis.contains('arm64-v8a') && !abis.contains('armeabi-v7a')) {
          return DeviceCompatibilityResult(
            isCompatible: false,
            reason: 'Unsupported device architecture: ${abis.join(', ')}',
          );
        }
      }

      return DeviceCompatibilityResult(
        isCompatible: true,
        reason: 'Device is compatible',
      );
    } catch (e) {
      debugPrint('Error checking device compatibility: $e');
      return DeviceCompatibilityResult(
        isCompatible: false,
        reason: 'Unable to verify device compatibility: $e',
      );
    }
  }

  /// Check battery level (placeholder - would need platform channel)
  Future<BatteryCheckResult> _checkBatteryLevel() async {
    // Placeholder implementation - would need battery_plus package or platform channel
    return BatteryCheckResult(level: 100); // Assume sufficient battery
  }

  /// Check if app is in foreground
  bool _isAppInForeground() {
    // This would need to be implemented with platform channels
    // For now, assume app is in foreground
    return true;
  }

  /// Smart update check with context awareness
  Future<bool> smartUpdateCheck(
    BuildContext context, {
    bool silent = false,
    bool respectUserSettings = true,
  }) async {
    try {
      // Respect user's auto-update settings
      if (respectUserSettings) {
        final autoCheck = await _updateService.getAutoUpdateCheck();
        if (!autoCheck && !_testMode) {
          if (kDebugMode) {
            debugPrint('Auto-update disabled by user, skipping check');
          }
          return false;
        }
      }

      // Perform safety checks if enabled
      if (_safetyChecksEnabled && !_testMode) {
        final safetyResult = await performSafetyChecks();
        if (!safetyResult.isSafe) {
          if (kDebugMode) {
            debugPrint(
              'Safety checks failed: ${safetyResult.issues.join(', ')}',
            );
          }
          if (!silent && context.mounted) {
            await _showSafetyWarningDialog(context, safetyResult);
          }
          return false;
        }
      }

      // Check for updates
      final hasUpdate = await _updateService.checkForUpdates(silent: silent);

      if (hasUpdate && context.mounted) {
        final update = _updateService.availableUpdate;
        if (update != null) {
          // Filter updates based on channel
          if (!_shouldShowUpdateForChannel(update)) {
            if (kDebugMode) {
              debugPrint('Update filtered out for channel $_updateChannel');
            }
            return false;
          }

          await showUpdateDialog(context, update);
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error in smart update check: $e');
      return false;
    }
  }

  /// Check if update should be shown based on current channel
  bool _shouldShowUpdateForChannel(AppUpdate update) {
    switch (_updateChannel) {
      case 'stable':
        return !update.isPrerelease;
      case 'beta':
        return true; // Show all updates including prereleases
      case 'alpha':
        return true; // Show all updates
      default:
        return !update.isPrerelease;
    }
  }

  /// Show safety warning dialog
  Future<void> _showSafetyWarningDialog(
    BuildContext context,
    UpdateSafetyResult result,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
        title: const Text('Update Safety Check'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.issues.isNotEmpty) ...[
              const Text(
                'Issues found:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              ...result.issues.map((issue) => Text('• $issue')),
              const SizedBox(height: 8),
            ],
            if (result.warnings.isNotEmpty) ...[
              const Text(
                'Warnings:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              ...result.warnings.map((warning) => Text('• $warning')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Test update functionality (for debugging)
  Future<Map<String, dynamic>> runUpdateTest() async {
    final testResults = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'testMode': _testMode,
    };

    try {
      // Test 1: Basic service initialization
      testResults['serviceInitialized'] = _updateService.currentVersion != null;

      // Test 2: Network connectivity
      final networkResult = await _checkNetworkConnection();
      testResults['networkConnected'] = networkResult.isConnected;

      // Test 3: GitHub API access
      final updateCheckResult = await _updateService.checkForUpdates(
        silent: true,
      );
      testResults['githubApiAccessible'] = true; // If no exception thrown
      testResults['hasUpdate'] = updateCheckResult;

      // Test 4: Permission checks (Android only)
      if (Platform.isAndroid) {
        testResults['installPermission'] =
            _updateService.installPermissionGranted;
      }

      // Test 5: Safety checks
      final safetyResult = await performSafetyChecks();
      testResults['safetyChecks'] = {
        'passed': safetyResult.isSafe,
        'issues': safetyResult.issues,
        'warnings': safetyResult.warnings,
      };

      // Test 6: File system access
      try {
        final directory = await _updateService.getDownloadDirectory();
        testResults['fileSystemAccess'] = await directory.exists();
      } catch (e) {
        testResults['fileSystemAccess'] = false;
        testResults['fileSystemError'] = e.toString();
      }

      testResults['overallStatus'] = _calculateOverallTestStatus(testResults);
    } catch (e) {
      testResults['error'] = e.toString();
      testResults['overallStatus'] = 'failed';
    }

    if (kDebugMode) {
      debugPrint('Update test results: $testResults');
    }

    return testResults;
  }

  /// Calculate overall test status
  String _calculateOverallTestStatus(Map<String, dynamic> results) {
    final critical = [
      results['serviceInitialized'] == true,
      results['networkConnected'] == true,
      results['githubApiAccessible'] == true,
    ];

    if (critical.every((test) => test)) {
      return 'passed';
    } else if (critical.any((test) => test)) {
      return 'partial';
    } else {
      return 'failed';
    }
  }

  /// Get current settings
  Map<String, dynamic> getSettings() {
    return {
      'testMode': _testMode,
      'safetyChecksEnabled': _safetyChecksEnabled,
      'updateChannel': _updateChannel,
    };
  }

  /// Get comprehensive diagnostic information
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final diagnostics = _updateService.getDiagnosticInfo();
    final settings = getSettings();
    final testResults = await runUpdateTest();

    return {
      'updateManager': {'version': AppInfo.version, 'settings': settings},
      'updateService': diagnostics,
      'testResults': testResults,
      'systemInfo': await _getSystemInfo(),
    };
  }

  /// Get system information
  Future<Map<String, dynamic>> _getSystemInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      final systemInfo = <String, dynamic>{
        'platform': Platform.operatingSystem,
        'appInfo': {
          'version': packageInfo.version,
          'buildNumber': packageInfo.buildNumber,
          'packageName': packageInfo.packageName,
        },
      };

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        systemInfo['device'] = {
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'androidVersion': androidInfo.version.release,
          'sdkVersion': androidInfo.version.sdkInt,
          'supportedAbis': androidInfo.supportedAbis,
        };
      }

      return systemInfo;
    } catch (e) {
      return {'error': 'Failed to get system info: $e'};
    }
  }
}

/// Result of update safety checks
class UpdateSafetyResult {
  final bool isSafe;
  final List<String> issues;
  final List<String> warnings;

  UpdateSafetyResult({
    required this.isSafe,
    required this.issues,
    required this.warnings,
  });
}

/// Result of storage space check
class StorageCheckResult {
  final bool hasSufficientSpace;
  final int availableMB;
  final int requiredMB;

  StorageCheckResult({
    required this.hasSufficientSpace,
    required this.availableMB,
    required this.requiredMB,
  });
}

/// Result of network connectivity check
class NetworkCheckResult {
  final bool isConnected;
  final bool isWiFi;
  final bool isMetered;
  final String connectionType;

  NetworkCheckResult({
    required this.isConnected,
    required this.isWiFi,
    required this.isMetered,
    required this.connectionType,
  });
}

/// Result of device compatibility check
class DeviceCompatibilityResult {
  final bool isCompatible;
  final String reason;

  DeviceCompatibilityResult({required this.isCompatible, required this.reason});
}

/// Result of battery level check
class BatteryCheckResult {
  final int level;

  BatteryCheckResult({required this.level});
}
