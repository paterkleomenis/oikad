import '../utils/debug_config.dart';

class VersionService {
  /// Compare two version strings (e.g., "versionA" vs "versionB")
  /// Returns:
  /// - negative if version1 < version2
  /// - 0 if version1 == version2
  /// - positive if version1 > version2
  static int compareVersions(String version1, String version2) {
    // Remove any leading 'v' or 'V' and clean the strings
    // Split by '+' to separate version from build number
    final v1Clean = version1.replaceFirst(RegExp(r'^[vV]'), '');
    final v2Clean = version2.replaceFirst(RegExp(r'^[vV]'), '');

    // Extract version and build parts
    final v1Parts = v1Clean.split('+');
    final v2Parts = v2Clean.split('+');

    final v1 = v1Parts[0]; // main version
    final v2 = v2Parts[0]; // main version

    final v1Build = v1Parts.length > 1 ? int.tryParse(v1Parts[1]) ?? 0 : 0;
    final v2Build = v2Parts.length > 1 ? int.tryParse(v2Parts[1]) ?? 0 : 0;

    DebugConfig.debugLog(
      'Comparing versions: "$version1" vs "$version2" -> cleaned: "$v1" vs "$v2", builds: $v1Build vs $v2Build',
      tag: 'VersionService',
    );

    // Handle non-semantic versions by padding with zeros
    final parts1 = _parseVersionParts(v1);
    final parts2 = _parseVersionParts(v2);

    DebugConfig.debugLog(
      'Version parts: $parts1 vs $parts2',
      tag: 'VersionService',
    );

    // Pad shorter version with zeros
    final maxLength = parts1.length > parts2.length
        ? parts1.length
        : parts2.length;
    while (parts1.length < maxLength) {
      parts1.add(0);
    }
    while (parts2.length < maxLength) {
      parts2.add(0);
    }

    // Compare main version parts first
    for (int i = 0; i < maxLength; i++) {
      if (parts1[i] < parts2[i]) {
        DebugConfig.debugLog(
          'Version comparison result: $version1 < $version2 (at part $i: ${parts1[i]} < ${parts2[i]})',
          tag: 'VersionService',
        );
        return -1;
      }
      if (parts1[i] > parts2[i]) {
        DebugConfig.debugLog(
          'Version comparison result: $version1 > $version2 (at part $i: ${parts1[i]} > ${parts2[i]})',
          tag: 'VersionService',
        );
        return 1;
      }
    }

    // If main versions are equal, compare build numbers
    if (v1Build < v2Build) {
      DebugConfig.debugLog(
        'Version comparison result: $version1 < $version2 (build: $v1Build < $v2Build)',
        tag: 'VersionService',
      );
      return -1;
    }
    if (v1Build > v2Build) {
      DebugConfig.debugLog(
        'Version comparison result: $version1 > $version2 (build: $v1Build > $v2Build)',
        tag: 'VersionService',
      );
      return 1;
    }

    DebugConfig.debugLog(
      'Version comparison result: $version1 == $version2',
      tag: 'VersionService',
    );
    return 0;
  }

  /// Check if newVersion is newer than currentVersion
  static bool isNewerVersion(String currentVersion, String newVersion) {
    final result = compareVersions(currentVersion, newVersion) < 0;

    DebugConfig.debugLog(
      'isNewerVersion check: "$newVersion" newer than "$currentVersion"? $result',
      tag: 'VersionService',
    );
    return result;
  }

  /// Check if current version meets minimum required version
  static bool meetsMinimumVersion(String currentVersion, String minVersion) {
    return compareVersions(currentVersion, minVersion) >= 0;
  }

  /// Helper method to parse version parts safely
  static List<int> _parseVersionParts(String version) {
    try {
      // Handle different version formats
      if (version.isEmpty) return [0, 0, 0];

      // If it's just a number (like "1"), treat as major version
      if (!version.contains('.')) {
        final major = int.tryParse(version) ?? 0;
        return [major, 0, 0];
      }

      // Parse semantic version
      return version.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    } catch (e) {
      // Fallback to 0.0.0 for invalid versions
      return [0, 0, 0];
    }
  }

  /// Parse version string to semantic version components
  static Map<String, int> parseVersion(String version) {
    final cleaned = version.replaceFirst(RegExp(r'^[vV]'), '').split('+')[0];
    final parts = _parseVersionParts(cleaned);

    return {
      'major': parts.isNotEmpty ? parts[0] : 0,
      'minor': parts.length > 1 ? parts[1] : 0,
      'patch': parts.length > 2 ? parts[2] : 0,
    };
  }

  /// Format version for display
  static String formatVersion(String version) {
    final parts = parseVersion(version);
    return 'v${parts['major']}.${parts['minor']}.${parts['patch']}';
  }

  /// Get version severity based on version difference
  static UpdateSeverity getUpdateSeverity(
    String currentVersion,
    String newVersion,
  ) {
    final current = parseVersion(currentVersion);
    final newer = parseVersion(newVersion);

    if (newer['major']! > current['major']!) {
      return UpdateSeverity.major;
    } else if (newer['minor']! > current['minor']!) {
      return UpdateSeverity.minor;
    } else if (newer['patch']! > current['patch']!) {
      return UpdateSeverity.patch;
    }

    return UpdateSeverity.none;
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

enum UpdateSeverity { none, patch, minor, major }

extension UpdateSeverityExtension on UpdateSeverity {
  String get displayName {
    switch (this) {
      case UpdateSeverity.patch:
        return 'Bug Fixes';
      case UpdateSeverity.minor:
        return 'Feature Update';
      case UpdateSeverity.major:
        return 'Major Update';
      case UpdateSeverity.none:
        return 'No Update';
    }
  }

  bool get isImportant =>
      this == UpdateSeverity.major || this == UpdateSeverity.minor;
}
