import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:open_file/open_file.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../models/app_update.dart';
import '../utils/app_info.dart';
import '../utils/debug_config.dart';
import 'version_service.dart';

class UpdateService extends ChangeNotifier {
  static String get _githubRepoUrl =>
      dotenv.env['GITHUB_REPO_URL'] ??
      'https://api.github.com/repos/paterkleomenis/oikad/releases';
  static const String _lastCheckKey = 'last_update_check';

  static const String _autoCheckKey = 'auto_check_updates';
  // GitHub token loaded from environment variable
  static String? get _githubToken => dotenv.env['GITHUB_TOKEN'];

  // Debug override to force showing updates (for testing)
  bool _debugForceShowUpdates = false;
  final Dio _dio = Dio();
  AppUpdate? _availableUpdate;
  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadPath;
  String? _currentVersion;
  String? _packageName;
  bool _installPermissionGranted = false;
  bool _lastFailureWasPermission = false;

  // Getters
  AppUpdate? get availableUpdate => _availableUpdate;
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get hasUpdate => _availableUpdate != null;
  String? get currentVersion => _currentVersion;
  bool get installPermissionGranted => _installPermissionGranted;
  bool get lastFailureWasPermission => _lastFailureWasPermission;

  /// Initialize the update service
  Future<void> initialize() async {
    DebugConfig.debugLog('Starting initialization...', tag: 'UpdateService');
    await _loadCurrentVersion();
    await _loadPackageName();
    await _configureDio();

    if (Platform.isAndroid) {
      await _checkInstallPermission();
    }

    await _schedulePeriodicCheck();
    await _cleanupOldUpdateFiles();

    // Do an initial update check to populate status
    DebugConfig.debugLog(
      'Performing initial update check...',
      tag: 'UpdateService',
    );
    await checkForUpdates(silent: true);

    DebugConfig.debugLog('Initialization completed', tag: 'UpdateService');
  }

  /// Load GitHub token from secure storage
  Future<String?> _loadGitHubToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('github_token');
    } catch (e) {
      DebugConfig.logError(
        'Error loading GitHub token',
        tag: 'UpdateService',
        error: e,
      );
      return null;
    }
  }

  /// Configure Dio with authentication headers if token is available
  Future<void> _configureDio() async {
    // Try to load token from secure storage first, fallback to hardcoded
    final token = await _loadGitHubToken() ?? _githubToken;

    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      _dio.options.headers['Accept'] = 'application/vnd.github.v3+json';
      DebugConfig.debugLog(
        'GitHub API configured with authentication',
        tag: 'UpdateService',
      );
    } else {
      _dio.options.headers['Accept'] = 'application/vnd.github.v3+json';
      DebugConfig.logWarning(
        'GitHub API configured without authentication (rate limited)',
        tag: 'UpdateService',
      );
    }
  }

  /// Set GitHub token securely
  Future<void> setGitHubToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('github_token', token);
      DebugConfig.debugLog('GitHub token saved securely', tag: 'UpdateService');
    } catch (e) {
      DebugConfig.logError(
        'Error saving GitHub token',
        tag: 'UpdateService',
        error: e,
      );
    }
  }

  /// Load current app version
  Future<void> _loadCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      DebugConfig.debugLog(
        'Current version loaded from PackageInfo: $_currentVersion',
        tag: 'UpdateService',
      );
      DebugConfig.debugLog(
        'Full package info - name: ${packageInfo.appName}, buildNumber: ${packageInfo.buildNumber}',
        tag: 'UpdateService',
      );
    } catch (e) {
      DebugConfig.logError(
        'Error loading package info',
        tag: 'UpdateService',
        error: e,
      );
      _currentVersion = AppInfo.version; // Fallback version
      DebugConfig.debugLog(
        'Using fallback version from AppInfo: $_currentVersion',
        tag: 'UpdateService',
      );
    }
  }

  /// Load package name
  Future<void> _loadPackageName() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _packageName = packageInfo.packageName;
      DebugConfig.debugLog('Package name: $_packageName', tag: 'UpdateService');
    } catch (e) {
      DebugConfig.logError(
        'Error loading package name',
        tag: 'UpdateService',
        error: e,
      );
      _packageName = AppInfo.packageName; // Fallback package name
    }
  }

  /// Schedule periodic update checks
  Future<void> _schedulePeriodicCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final autoCheck = prefs.getBool(_autoCheckKey) ?? true;

    if (!autoCheck) return;

    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dayInMs = 24 * 60 * 60 * 1000;

    // Check for updates if it's been more than 24 hours
    if (now - lastCheck > dayInMs) {
      await checkForUpdates(silent: true);
    }
  }

  /// Check for available updates with retry mechanism
  Future<bool> checkForUpdates({
    bool silent = false,
    int retryCount = 3,
  }) async {
    if (_isChecking) {
      DebugConfig.debugLog(
        'Already checking for updates, skipping',
        tag: 'UpdateService',
      );
      return false;
    }

    DebugConfig.debugLog('Starting update check', tag: 'UpdateService');

    _isChecking = true;
    if (!silent) notifyListeners();

    bool hasUpdate = false;

    try {
      for (int attempt = 0; attempt < retryCount; attempt++) {
        try {
          final response = await _dio
              .get(_githubRepoUrl)
              .timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final releases = response.data as List<dynamic>;

            if (releases.isNotEmpty) {
              final latestRelease = releases.first as Map<String, dynamic>;

              try {
                final update = AppUpdate.fromGitHubRelease(latestRelease);

                DebugConfig.debugLog(
                  'Checking if update is newer: current=$_currentVersion, latest=${update.version}',
                  tag: 'UpdateService',
                );

                final isNewer =
                    _currentVersion != null &&
                    VersionService.isNewerVersion(
                      _currentVersion!,
                      update.version,
                    );

                if (isNewer || _debugForceShowUpdates) {
                  // Show updates if newer OR if debug override is enabled
                  _availableUpdate = update;
                  DebugConfig.debugLog(
                    'Update found! Setting available update to version ${update.version} (isNewer: $isNewer, debugForce: $_debugForceShowUpdates)',
                    tag: 'UpdateService',
                  );

                  // Save last check time
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt(
                    _lastCheckKey,
                    DateTime.now().millisecondsSinceEpoch,
                  );

                  notifyListeners();
                  return true;
                } else {
                  DebugConfig.debugLog(
                    'No newer version found. Current: $_currentVersion, Latest: ${update.version}',
                    tag: 'UpdateService',
                  );
                }
              } catch (parseError) {
                DebugConfig.logError(
                  'Error parsing update from release',
                  tag: 'UpdateService',
                  error: parseError,
                );
              }
            }
          }

          // If we reach here, no update was found
          _availableUpdate = null;
          break; // Exit the retry loop
        } catch (e) {
          if (e is DioException) {
            if (e.response?.statusCode == 403) {
              DebugConfig.logWarning(
                'GitHub API rate limit exceeded',
                tag: 'UpdateService',
              );
              break; // Don't retry rate limit errors
            }
          }

          if (attempt == retryCount - 1) {
            DebugConfig.logError(
              'Error checking for updates after $retryCount attempts',
              tag: 'UpdateService',
              error: e,
            );
            _availableUpdate = null;
            break; // Exit the retry loop
          }

          // Wait before retry with exponential backoff
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
        }
      }
    } finally {
      DebugConfig.debugLog(
        'Finishing update check, hasUpdate: $hasUpdate',
        tag: 'UpdateService',
      );
      _isChecking = false;
      if (!silent) notifyListeners();
    }

    return hasUpdate;
  }

  /// Download and install update with fallback mechanisms
  Future<bool> downloadAndInstall([BuildContext? context]) async {
    if (_availableUpdate == null ||
        !_availableUpdate!.hasDownload ||
        _isDownloading) {
      return false;
    }

    if (Platform.isIOS) {
      // iOS apps must be updated through App Store
      return await _openAppStore();
    }

    // For Android, check install permission first
    if (Platform.isAndroid && context != null) {
      final hasPermission = await requestInstallPermission(context);
      if (!hasPermission) {
        if (kDebugMode) {
          debugPrint(
            'Install permission not granted, cannot proceed with update',
          );
        }
        _lastFailureWasPermission = true;
        return false;
      }
    }

    // Reset permission failure flag if we get this far
    _lastFailureWasPermission = false;

    // Try primary download with retries
    bool success = await _downloadAndInstallUpdate();

    if (!success && context != null) {
      // Fallback: direct browser download
      if (kDebugMode) {
        debugPrint('Primary download failed, trying fallback browser download');
      }
      success = await _fallbackBrowserDownload();
    }

    return success;
  }

  /// Fallback: open download URL in browser
  Future<bool> _fallbackBrowserDownload() async {
    try {
      final uri = Uri.parse(_availableUpdate!.downloadUrl);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      DebugConfig.logError(
        'Fallback browser download failed',
        tag: 'UpdateService',
        error: e,
      );
      return false;
    }
  }

  /// Download and install update for Android/Desktop with retry mechanism
  Future<bool> _downloadAndInstallUpdate({int retryCount = 3}) async {
    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();

    for (int attempt = 0; attempt < retryCount; attempt++) {
      try {
        // Get download directory (no permissions needed for app-specific storage)
        final directory = await getDownloadDirectory();
        final fileName = _getFileName();
        _downloadPath = '${directory.path}/$fileName';

        DebugConfig.debugLog(
          'Download attempt ${attempt + 1}/$retryCount to: $_downloadPath',
          tag: 'UpdateService',
        );

        // Remove existing file if it exists
        final existingFile = File(_downloadPath!);
        if (await existingFile.exists()) {
          await existingFile.delete();
        }

        // Download the file with timeout and progress tracking
        await _dio.download(
          _availableUpdate!.downloadUrl,
          _downloadPath,
          options: Options(
            receiveTimeout: const Duration(minutes: 10),
            sendTimeout: const Duration(minutes: 5),
          ),
          onReceiveProgress: (received, total) {
            if (total != -1) {
              _downloadProgress = received / total;
              notifyListeners();

              if (DebugConfig.enableVerboseLogging &&
                  received % (1024 * 1024) == 0) {
                // Log progress every MB
                DebugConfig.debugLog(
                  'Download progress: ${(received / total * 100).toStringAsFixed(1)}%',
                  tag: 'UpdateService',
                );
              }
            }
          },
        );

        DebugConfig.debugLog(
          'Download completed successfully on attempt ${attempt + 1}',
          tag: 'UpdateService',
        );

        // Verify the downloaded file
        final isValid = await _verifyDownloadedFile(_downloadPath!);
        if (!isValid) {
          DebugConfig.logError(
            'Downloaded file verification failed on attempt ${attempt + 1}',
            tag: 'UpdateService',
          );
          if (attempt < retryCount - 1) {
            continue; // Retry download
          }
          return false;
        }

        // For Android, recheck permission before installing
        if (Platform.isAndroid) {
          await _checkInstallPermission();
          if (!_installPermissionGranted) {
            DebugConfig.logWarning(
              'Install permission lost during download, cannot install',
              tag: 'UpdateService',
            );
            return false;
          }
        }

        // Install the downloaded file
        return await _installDownloadedFile();
      } catch (e) {
        DebugConfig.logError(
          'Download attempt ${attempt + 1} failed',
          tag: 'UpdateService',
          error: e,
        );

        if (attempt == retryCount - 1) {
          DebugConfig.logError(
            'All download attempts failed',
            tag: 'UpdateService',
            error: e,
          );
          return false;
        }

        // Wait before retry with exponential backoff
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));

        // Reset progress for retry
        _downloadProgress = 0.0;
        notifyListeners();
      }
    }

    return false;
  }

  /// Get appropriate download directory
  Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Use app-specific external storage (no permissions needed on Android 10+)
      try {
        final appDir = await getApplicationDocumentsDirectory();
        DebugConfig.debugLog(
          'Using app documents directory: ${appDir.path}',
          tag: 'UpdateService',
        );
        return appDir;
      } catch (e) {
        DebugConfig.logError(
          'App documents directory not available',
          tag: 'UpdateService',
          error: e,
        );
        // Fallback to internal storage
        final tempDir = await getTemporaryDirectory();
        DebugConfig.debugLog(
          'Using temporary directory: ${tempDir.path}',
          tag: 'UpdateService',
        );
        return tempDir;
      }
    } else {
      return await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }
  }

  /// Get appropriate file name for download
  String _getFileName() {
    if (Platform.isAndroid) {
      return 'oikad_${_availableUpdate!.version}.apk';
    } else if (Platform.isWindows) {
      return 'oikad_${_availableUpdate!.version}.exe';
    } else if (Platform.isMacOS) {
      return 'oikad_${_availableUpdate!.version}.dmg';
    } else if (Platform.isLinux) {
      return 'oikad_${_availableUpdate!.version}.deb';
    }
    return 'oikad_${_availableUpdate!.version}';
  }

  /// Check if install unknown apps permission is granted
  Future<void> _checkInstallPermission() async {
    if (!Platform.isAndroid) return;

    try {
      // Check if we can install packages from unknown sources
      _installPermissionGranted = await _canInstallFromUnknownSources();

      DebugConfig.debugLog(
        'Install permission granted: $_installPermissionGranted',
        tag: 'UpdateService',
      );
    } catch (e) {
      DebugConfig.logError(
        'Error checking install permission',
        tag: 'UpdateService',
        error: e,
      );
      _installPermissionGranted = false;
    }
  }

  /// Check if app can install packages from unknown sources
  Future<bool> _canInstallFromUnknownSources() async {
    if (!Platform.isAndroid) return true;

    try {
      // For Android 8.0+ (API 26+), check REQUEST_INSTALL_PACKAGES permission
      const platform = MethodChannel('flutter.dev/install_permission');
      final result = await platform.invokeMethod('canRequestPackageInstalls');
      return result as bool? ?? false;
    } catch (e) {
      // Fallback: assume permission is granted on older versions or if check fails
      return true;
    }
  }

  /// Request install unknown apps permission
  Future<bool> requestInstallPermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    try {
      // Check current permission status
      await _checkInstallPermission();

      if (_installPermissionGranted) {
        return true;
      }

      // Show dialog explaining why permission is needed
      if (!context.mounted) return false;
      final shouldRequest = await _showInstallPermissionDialog(context);

      if (!shouldRequest) {
        return false;
      }

      // Open settings to allow user to grant permission
      await _openInstallPermissionSettings();

      // Wait a moment then recheck permission
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkInstallPermission();

      return _installPermissionGranted;
    } catch (e) {
      DebugConfig.logError(
        'Error requesting install permission',
        tag: 'UpdateService',
        error: e,
      );
      return false;
    }
  }

  /// Show dialog explaining install permission
  Future<bool> _showInstallPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To install app updates automatically, OIKAD needs permission to install unknown apps.',
                ),
                SizedBox(height: 16),
                Text(
                  'This is required only once. After granting permission, future updates will install seamlessly.',
                ),
                SizedBox(height: 16),
                Text('Steps:'),
                Text('1. Tap "Open Settings"'),
                Text('2. Enable "Allow from this source"'),
                Text('3. Return to the app'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Open Android settings for install unknown apps permission
  Future<void> _openInstallPermissionSettings() async {
    try {
      // Try to open the specific app install settings
      final intent = AndroidIntent(
        action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
        data: 'package:${_packageName ?? AppInfo.packageName}',
      );
      await intent.launch();
    } catch (e) {
      try {
        // Fallback to general security settings
        final intent = AndroidIntent(
          action: 'android.settings.SECURITY_SETTINGS',
        );
        await intent.launch();
      } catch (fallbackError) {
        if (kDebugMode) {
          debugPrint(
            'Error opening install settings: $e, fallback: $fallbackError',
          );
        }
        // Last resort: try to open app settings
        try {
          final appIntent = AndroidIntent(
            action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
            data: 'package:${_packageName ?? AppInfo.packageName}',
          );
          await appIntent.launch();
        } catch (finalError) {
          if (kDebugMode) {
            debugPrint('All settings launch attempts failed: $finalError');
          }
        }
      }
    }
  }

  /// Install downloaded file
  Future<bool> _installDownloadedFile() async {
    if (_downloadPath == null) {
      return false;
    }

    // Verify file exists
    final file = File(_downloadPath!);
    if (!await file.exists()) {
      DebugConfig.logError(
        'Downloaded file not found at: $_downloadPath',
        tag: 'UpdateService',
      );
      return false;
    }

    final fileSize = await file.length();
    DebugConfig.debugLog(
      'Installing file: $_downloadPath ($fileSize bytes)',
      tag: 'UpdateService',
    );

    try {
      if (Platform.isAndroid) {
        // Final permission check before installation
        if (!_installPermissionGranted) {
          DebugConfig.logWarning(
            'Install permission not granted, cannot install APK',
            tag: 'UpdateService',
          );
          return false;
        }

        // For Android, use open_file to prompt user to install APK
        final result = await OpenFile.open(_downloadPath!);
        DebugConfig.debugLog(
          'OpenFile result: ${result.type}',
          tag: 'UpdateService',
        );

        // If result is done, the installer was launched successfully
        if (result.type == ResultType.done) {
          // Clear the update since installation was initiated
          clearUpdate();
          return true;
        } else {
          DebugConfig.logError(
            'Failed to open APK installer: ${result.message}',
            tag: 'UpdateService',
          );
          return false;
        }
      } else {
        // For desktop platforms, open the installer
        final uri = Uri.file(_downloadPath!);
        final success = await launchUrl(uri);
        if (success) {
          clearUpdate();
        }
        return success;
      }
    } catch (e) {
      DebugConfig.logError(
        'Error installing update',
        tag: 'UpdateService',
        error: e,
      );
      return false;
    }
  }

  /// Open App Store for iOS updates
  Future<bool> _openAppStore() async {
    // Replace with your actual App Store URL when published
    const appStoreUrl = 'https://apps.apple.com/app/oikad/id123456789';
    final uri = Uri.parse(appStoreUrl);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Clear available update
  void clearUpdate() {
    _availableUpdate = null;
    notifyListeners();
  }

  /// Enable/disable automatic update checks
  Future<void> setAutoUpdateCheck(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCheckKey, enabled);
  }

  /// Get auto update check preference
  Future<bool> getAutoUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoCheckKey) ?? true;
  }

  /// Get update severity
  UpdateSeverity getUpdateSeverity() {
    if (_currentVersion == null || _availableUpdate == null) {
      return UpdateSeverity.none;
    }
    return VersionService.getUpdateSeverity(
      _currentVersion!,
      _availableUpdate!.version,
    );
  }

  /// Refresh install permission status
  Future<void> refreshInstallPermission() async {
    if (Platform.isAndroid) {
      await _checkInstallPermission();
      notifyListeners();
    }
  }

  /// Get formatted update info
  Map<String, String> getUpdateInfo() {
    if (_availableUpdate == null) return {};

    return {
      'currentVersion': VersionService.formatVersion(
        _currentVersion ?? AppInfo.version,
      ),
      'newVersion': VersionService.formatVersion(_availableUpdate!.version),
      'fileSize': VersionService.formatFileSize(_availableUpdate!.fileSize),
      'severity': getUpdateSeverity().displayName,
    };
  }

  /// Verify downloaded file integrity
  Future<bool> _verifyDownloadedFile(String filePath) async {
    try {
      final file = File(filePath);

      // Check file exists
      if (!await file.exists()) {
        debugPrint('Downloaded file not found: $filePath');
        return false;
      }

      // Check file size matches expected
      final actualSize = await file.length();
      if (actualSize != _availableUpdate!.fileSize) {
        DebugConfig.logError(
          'File size mismatch: expected ${_availableUpdate!.fileSize}, got $actualSize',
          tag: 'UpdateService',
        );
        return false;
      }

      // If checksum is available from release, verify it
      if (_availableUpdate!.hasChecksum) {
        final fileBytes = await file.readAsBytes();
        final digest = sha256.convert(fileBytes);
        final calculatedChecksum = digest.toString();

        if (calculatedChecksum.toLowerCase() !=
            _availableUpdate!.checksum!.toLowerCase()) {
          DebugConfig.logError(
            'Checksum verification failed. Expected: ${_availableUpdate!.checksum}, Got: $calculatedChecksum',
            tag: 'UpdateService',
          );
          return false;
        }

        DebugConfig.debugLog(
          'File verification successful. Size: $actualSize, SHA-256: $calculatedChecksum',
          tag: 'UpdateService',
        );
      } else {
        // If no checksum available, just calculate for logging
        final fileBytes = await file.readAsBytes();
        final digest = sha256.convert(fileBytes);
        final checksum = digest.toString();

        DebugConfig.debugLog(
          'File verification completed (no checksum to verify). Size: $actualSize, SHA-256: $checksum',
          tag: 'UpdateService',
        );
      }

      return true;
    } catch (e) {
      DebugConfig.logError(
        'Error verifying downloaded file',
        tag: 'UpdateService',
        error: e,
      );
      return false;
    }
  }

  /// Clean up old update files
  Future<void> _cleanupOldUpdateFiles() async {
    try {
      final directory = await getDownloadDirectory();
      final files = directory.listSync();
      int cleanedCount = 0;

      for (final file in files) {
        if (file is File &&
            file.path.contains('oikad_') &&
            (file.path.endsWith('.apk') ||
                file.path.endsWith('.exe') ||
                file.path.endsWith('.dmg') ||
                file.path.endsWith('.deb') ||
                file.path.endsWith('.rpm'))) {
          final stat = await file.stat();
          final daysSinceModified = DateTime.now()
              .difference(stat.modified)
              .inDays;

          if (daysSinceModified > 7) {
            // Clean files older than 7 days
            try {
              await file.delete();
              cleanedCount++;
              DebugConfig.debugLog(
                'Cleaned up old update file: ${file.path}',
                tag: 'UpdateService',
              );
            } catch (deleteError) {
              DebugConfig.logError(
                'Failed to delete old update file ${file.path}',
                tag: 'UpdateService',
                error: deleteError,
              );
            }
          }
        }
      }

      if (cleanedCount > 0) {
        DebugConfig.debugLog(
          'Cleanup completed: removed $cleanedCount old update files',
          tag: 'UpdateService',
        );
      }
    } catch (e) {
      DebugConfig.logError(
        'Error cleaning up old update files',
        tag: 'UpdateService',
        error: e,
      );
    }
  }

  /// Debug method to manually test update checking
  Future<Map<String, dynamic>> debugCheckUpdates() async {
    try {
      DebugConfig.debugLog(
        'Debug: Starting manual update check',
        tag: 'UpdateService',
      );
      DebugConfig.debugLog(
        'Debug: Current version: $_currentVersion',
        tag: 'UpdateService',
      );
      DebugConfig.debugLog(
        'Debug: GitHub URL: $_githubRepoUrl',
        tag: 'UpdateService',
      );

      final response = await _dio
          .get(_githubRepoUrl)
          .timeout(const Duration(seconds: 30));

      DebugConfig.debugLog(
        'Debug: GitHub API response status: ${response.statusCode}',
        tag: 'UpdateService',
      );

      if (response.statusCode == 200) {
        final releases = response.data as List<dynamic>;
        DebugConfig.debugLog(
          'Debug: Found ${releases.length} releases',
          tag: 'UpdateService',
        );

        if (releases.isNotEmpty) {
          final latestRelease = releases.first as Map<String, dynamic>;
          final tagName = latestRelease['tag_name'] as String?;
          final name = latestRelease['name'] as String?;
          final publishedAt = latestRelease['published_at'] as String?;

          DebugConfig.debugLog(
            'Debug: Latest release tag: $tagName',
            tag: 'UpdateService',
          );
          DebugConfig.debugLog(
            'Debug: Latest release name: $name',
            tag: 'UpdateService',
          );
          DebugConfig.debugLog(
            'Debug: Published at: $publishedAt',
            tag: 'UpdateService',
          );

          try {
            final update = AppUpdate.fromGitHubRelease(latestRelease);
            DebugConfig.debugLog(
              'Debug: Parsed version: ${update.version}',
              tag: 'UpdateService',
            );
            DebugConfig.debugLog(
              'Debug: Download URL: ${update.downloadUrl}',
              tag: 'UpdateService',
            );

            final isNewer = VersionService.isNewerVersion(
              _currentVersion!,
              update.version,
            );
            DebugConfig.debugLog(
              'Debug: Is newer version? $isNewer',
              tag: 'UpdateService',
            );
            DebugConfig.debugLog(
              'Debug: Version comparison: $_currentVersion vs ${update.version}',
              tag: 'UpdateService',
            );

            return {
              'success': true,
              'current_version': _currentVersion,
              'latest_version': update.version,
              'is_newer': isNewer,
              'download_url': update.downloadUrl,
              'tag_name': tagName,
              'release_name': name,
              'published_at': publishedAt,
              'releases_count': releases.length,
            };
          } catch (parseError) {
            DebugConfig.logError(
              'Debug: Error parsing update',
              tag: 'UpdateService',
              error: parseError,
            );
            return {
              'success': false,
              'error': 'Parse error: $parseError',
              'raw_release': latestRelease,
            };
          }
        } else {
          return {
            'success': false,
            'error': 'No releases found',
            'releases_count': 0,
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'response_data': response.data,
        };
      }
    } catch (e) {
      DebugConfig.logError(
        'Debug: Error during manual update check',
        tag: 'UpdateService',
        error: e,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Enable debug mode to force showing updates (for testing)
  void enableDebugForceUpdates(bool enable) {
    _debugForceShowUpdates = enable;
    DebugConfig.debugLog('Debug force updates: $enable', tag: 'UpdateService');
  }

  /// Force check for updates bypassing all caches and restrictions
  Future<bool> forceCheckForUpdates() async {
    DebugConfig.debugLog('Force checking for updates...', tag: 'UpdateService');

    // Clear any existing update to force fresh check
    _availableUpdate = null;

    // Force a fresh check with aggressive retry
    return await checkForUpdates(silent: false, retryCount: 5);
  }

  /// Get diagnostic information for troubleshooting
  Map<String, dynamic> getDiagnosticInfo() {
    return {
      'currentVersion': _currentVersion ?? 'Unknown',
      'packageName': _packageName ?? 'Unknown',
      'hasUpdate': hasUpdate,
      'isChecking': isChecking,
      'isDownloading': isDownloading,
      'downloadProgress': downloadProgress,
      'installPermissionGranted': installPermissionGranted,
      'debugForceShowUpdates': _debugForceShowUpdates,
      'availableUpdate': _availableUpdate != null
          ? {
              'version': _availableUpdate!.version,
              'downloadUrl': _availableUpdate!.downloadUrl,
              'fileSize': _availableUpdate!.fileSize,
              'hasChecksum': _availableUpdate!.hasChecksum,
              'isForced': _availableUpdate!.isForced,
              'isCritical': _availableUpdate!.isCritical,
            }
          : null,
    };
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }
}
