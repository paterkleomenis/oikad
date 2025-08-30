import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/app_update.dart';
import 'version_service.dart';

class UpdateService extends ChangeNotifier {
  static const String _githubRepoUrl =
      'https://api.github.com/repos/paterkleomenis/oikad/releases';
  static const String _lastCheckKey = 'last_update_check';
  static const String _skipVersionKey = 'skip_version';
  static const String _autoCheckKey = 'auto_check_updates';

  final Dio _dio = Dio();
  AppUpdate? _availableUpdate;
  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadPath;
  String? _currentVersion;
  bool _permissionsGranted = false;

  // Getters
  AppUpdate? get availableUpdate => _availableUpdate;
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get hasUpdate => _availableUpdate != null;
  String? get currentVersion => _currentVersion;

  /// Initialize the update service
  Future<void> initialize() async {
    await _loadCurrentVersion();
    if (Platform.isAndroid) {
      _permissionsGranted = await _checkExistingPermissions();
    }
    await _schedulePeriodicCheck();
  }

  /// Load current app version
  Future<void> _loadCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
    } catch (e) {
      debugPrint('Error loading package info: $e');
      _currentVersion = '1.0.0'; // Fallback version
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

  /// Check for available updates
  Future<bool> checkForUpdates({bool silent = false}) async {
    if (_isChecking) return false;

    _isChecking = true;
    if (!silent) notifyListeners();

    try {
      final response = await _dio.get(_githubRepoUrl);

      if (response.statusCode == 200) {
        final releases = response.data as List<dynamic>;

        if (releases.isNotEmpty) {
          final latestRelease = releases.first as Map<String, dynamic>;

          try {
            final update = AppUpdate.fromGitHubRelease(latestRelease);

            if (_currentVersion != null &&
                VersionService.isNewerVersion(
                  _currentVersion!,
                  update.version,
                )) {
              // Check if user has skipped this version
              final prefs = await SharedPreferences.getInstance();
              final skippedVersion = prefs.getString(_skipVersionKey);

              if (skippedVersion != update.version || update.isForced) {
                _availableUpdate = update;

                // Save last check time
                await prefs.setInt(
                  _lastCheckKey,
                  DateTime.now().millisecondsSinceEpoch,
                );

                if (!silent) notifyListeners();
                return true;
              }
            }
          } catch (parseError) {
            debugPrint('Error parsing update from release: $parseError');
          }
        }
      }

      _availableUpdate = null;
      if (!silent) notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      _availableUpdate = null;
      if (!silent) notifyListeners();
      return false;
    } finally {
      _isChecking = false;
      if (!silent) notifyListeners();
    }
  }

  /// Download and install update
  Future<bool> downloadAndInstall() async {
    if (_availableUpdate == null ||
        !_availableUpdate!.hasDownload ||
        _isDownloading) {
      return false;
    }

    if (Platform.isIOS) {
      // iOS apps must be updated through App Store
      return await _openAppStore();
    }

    return await _downloadAndInstallUpdate();
  }

  /// Download and install update for Android/Desktop
  Future<bool> _downloadAndInstallUpdate() async {
    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      // Request storage permission on Android (only if not already granted)
      if (Platform.isAndroid && !_permissionsGranted) {
        _permissionsGranted = await _requestStoragePermissions();
        if (!_permissionsGranted) {
          throw Exception('Storage permissions denied');
        }
      }

      // Get download directory
      final directory = await _getDownloadDirectory();
      final fileName = _getFileName();
      _downloadPath = '${directory.path}/$fileName';

      // Download the file
      await _dio.download(
        _availableUpdate!.downloadUrl,
        _downloadPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress = received / total;
            notifyListeners();
          }
        },
      );

      // Install the downloaded file
      return await _installDownloadedFile();
    } catch (e) {
      debugPrint('Error downloading/installing update: $e');
      return false;
    } finally {
      _isDownloading = false;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Get appropriate download directory
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        // Try external storage first
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return externalDir;
        }
      } catch (e) {
        debugPrint('External storage not available: $e');
      }

      // Fallback to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      return appDir;
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

  /// Install downloaded file
  Future<bool> _installDownloadedFile() async {
    if (_downloadPath == null) {
      return false;
    }

    // Verify file exists
    final file = File(_downloadPath!);
    if (!await file.exists()) {
      debugPrint('Downloaded file not found at: $_downloadPath');
      return false;
    }

    try {
      if (Platform.isAndroid) {
        // For Android, try multiple installation methods

        // Method 1: Use Android platform channel for direct installation
        try {
          const platform = MethodChannel('com.example.oikad/installer');
          final result = await platform.invokeMethod('installApk', {
            'filePath': _downloadPath,
          });

          if (result == true) {
            return true;
          }
        } catch (e) {
          debugPrint('Platform channel installation failed: $e');
        }

        // Method 2: Try to open with file manager/installer
        final uri = Uri.file(_downloadPath!);

        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (success) {
          return true;
        }

        // Method 3: Try with different URI scheme
        try {
          final fileName = _downloadPath!.split('/').last;
          final contentUri = Uri.parse(
            'content://com.example.oikad.fileprovider/$fileName',
          );
          final success2 = await launchUrl(
            contentUri,
            mode: LaunchMode.externalApplication,
          );

          if (success2) {
            return true;
          }
        } catch (e) {
          debugPrint('FileProvider URI method failed: $e');
        }

        // Method 4: Open Downloads folder for manual installation
        try {
          final downloadsUri = Uri.parse(
            'content://com.android.externalstorage.documents/document/primary:Download',
          );
          await launchUrl(downloadsUri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Could not open Downloads folder: $e');
        }

        // If all automatic methods fail, the file is still downloaded
        // Return true because download succeeded
        return true;
      } else {
        // For desktop platforms, open the installer
        final uri = Uri.file(_downloadPath!);
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error installing update: $e');
      // Return true because download succeeded
      return true;
    }
  }

  /// Check existing permissions without requesting
  Future<bool> _checkExistingPermissions() async {
    try {
      final storageStatus = await Permission.storage.status;
      final isGranted = storageStatus.isGranted || storageStatus.isLimited;
      return isGranted;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  /// Request storage permissions once and cache the result
  Future<bool> _requestStoragePermissions() async {
    try {
      // Check if permissions are already granted
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted || storageStatus.isLimited) {
        return true;
      }

      // Request permissions only if not granted
      final storageResult = await Permission.storage.request();
      return storageResult.isGranted || storageResult.isLimited;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
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

  /// Skip current update version
  Future<void> skipCurrentVersion() async {
    if (_availableUpdate != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_skipVersionKey, _availableUpdate!.version);
      _availableUpdate = null;
      notifyListeners();
    }
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

  /// Force check for updates (ignores skip preferences)
  Future<bool> forceCheckForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skipVersionKey);
    return await checkForUpdates();
  }

  /// Get formatted update info
  Map<String, String> getUpdateInfo() {
    if (_availableUpdate == null) return {};

    return {
      'currentVersion': VersionService.formatVersion(
        _currentVersion ?? '1.0.6',
      ),
      'newVersion': VersionService.formatVersion(_availableUpdate!.version),
      'fileSize': VersionService.formatFileSize(_availableUpdate!.fileSize),
      'severity': getUpdateSeverity().displayName,
    };
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }
}
