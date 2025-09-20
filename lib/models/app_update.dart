import '../utils/app_info.dart';

class AppUpdate {
  final String version;
  final String buildNumber;
  final String title;
  final String description;
  final String downloadUrl;
  final int fileSize;
  final DateTime publishedAt;
  final bool isForced;
  final bool isCritical;
  final List<String> features;
  final List<String> bugFixes;
  final String? minRequiredVersion;
  final String? checksum;
  final String? checksumType;
  final Map<String, dynamic> metadata;

  const AppUpdate({
    required this.version,
    required this.buildNumber,
    required this.title,
    required this.description,
    required this.downloadUrl,
    required this.fileSize,
    required this.publishedAt,
    this.isForced = false,
    this.isCritical = false,
    this.features = const [],
    this.bugFixes = const [],
    this.minRequiredVersion,
    this.checksum,
    this.checksumType = 'sha256',
    this.metadata = const {},
  });

  /// Get the minimum required version with smart default
  String get effectiveMinRequiredVersion {
    if (minRequiredVersion != null && minRequiredVersion!.isNotEmpty) {
      return minRequiredVersion!;
    }
    // Use current app version as minimum if not specified
    try {
      return AppInfo.version;
    } catch (e) {
      // Fallback to a reasonable default if AppInfo is not available
      return '0.0.0';
    }
  }

  factory AppUpdate.fromGitHubRelease(Map<String, dynamic> json) {
    final assets = json['assets'] as List<dynamic>? ?? [];
    String downloadUrl = '';
    int fileSize = 0;
    String? checksum;

    // Find the appropriate asset for the current platform
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      if (name.endsWith('.apk') ||
          name.endsWith('.exe') ||
          name.endsWith('.dmg') ||
          name.endsWith('.deb') ||
          name.endsWith('.rpm')) {
        downloadUrl = asset['browser_download_url'] as String? ?? '';
        fileSize = asset['size'] as int? ?? 0;
        break;
      }
    }

    // Look for checksum in release body or assets
    final body = json['body'] as String? ?? '';
    final checksumMatch = RegExp(
      r'(?:sha256|SHA256):\s*([a-fA-F0-9]{64})',
    ).firstMatch(body);
    if (checksumMatch != null) {
      checksum = checksumMatch.group(1);
    }

    final features = <String>[];
    final bugFixes = <String>[];

    // Parse release notes for features and bug fixes
    final lines = body.split('\n');
    bool inFeatures = false;
    bool inBugFixes = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().contains('features') ||
          trimmed.toLowerCase().contains('new')) {
        inFeatures = true;
        inBugFixes = false;
      } else if (trimmed.toLowerCase().contains('fix') ||
          trimmed.toLowerCase().contains('bug')) {
        inFeatures = false;
        inBugFixes = true;
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final item = trimmed.substring(2);
        if (inFeatures) {
          features.add(item);
        } else if (inBugFixes) {
          bugFixes.add(item);
        }
      }
    }

    // Extract additional metadata
    final metadata = <String, dynamic>{
      'prerelease': json['prerelease'] as bool? ?? false,
      'draft': json['draft'] as bool? ?? false,
      'html_url': json['html_url'] as String? ?? '',
      'author': json['author']?['login'] as String? ?? '',
      'release_id': json['id'] as int? ?? 0,
    };

    // Clean version string to handle different formats
    String cleanVersion = (json['tag_name'] as String? ?? '').replaceFirst(
      RegExp(r'^[vV]'),
      '',
    );

    // If version is just a number, convert to semantic version
    if (cleanVersion.isNotEmpty && !cleanVersion.contains('.')) {
      cleanVersion = '$cleanVersion.0.0';
    }

    // Fallback to current app version if parsing fails
    if (cleanVersion.isEmpty) {
      try {
        cleanVersion = AppInfo.version;
      } catch (e) {
        cleanVersion = 'Unknown';
      }
    }

    return AppUpdate(
      version: cleanVersion,
      buildNumber: '1', // GitHub releases don't have build numbers
      title: json['name'] as String? ?? 'New Update',
      description: body,
      downloadUrl: downloadUrl,
      fileSize: fileSize,
      publishedAt: DateTime.parse(
        json['published_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      isForced:
          body.toLowerCase().contains('critical') ||
          body.toLowerCase().contains('security') ||
          body.toLowerCase().contains('forced'),
      isCritical: body.toLowerCase().contains('critical'),
      features: features,
      bugFixes: bugFixes,
      checksum: checksum,
      checksumType: 'sha256',
      metadata: metadata,
    );
  }

  bool get hasDownload => downloadUrl.isNotEmpty;

  bool get hasChecksum => checksum != null && checksum!.isNotEmpty;

  bool get isPrerelease => metadata['prerelease'] as bool? ?? false;

  bool get isDraft => metadata['draft'] as bool? ?? false;

  String get releaseUrl => metadata['html_url'] as String? ?? '';

  String get author => metadata['author'] as String? ?? '';
}
