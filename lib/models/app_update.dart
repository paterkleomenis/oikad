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
  final String minRequiredVersion;

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
    this.minRequiredVersion = '1.0.0',
  });

  factory AppUpdate.fromGitHubRelease(Map<String, dynamic> json) {
    final assets = json['assets'] as List<dynamic>? ?? [];
    String downloadUrl = '';
    int fileSize = 0;

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

    final body = json['body'] as String? ?? '';
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

    // Clean version string to handle different formats
    String cleanVersion = (json['tag_name'] as String? ?? '').replaceFirst(
      RegExp(r'^[vV]'),
      '',
    );

    // If version is just a number, convert to semantic version
    if (cleanVersion.isNotEmpty && !cleanVersion.contains('.')) {
      cleanVersion = '$cleanVersion.0.0';
    }

    // Fallback to 1.0.0 if version is invalid
    if (cleanVersion.isEmpty) {
      cleanVersion = '1.0.0';
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
          body.toLowerCase().contains('security'),
      isCritical: body.toLowerCase().contains('critical'),
      features: features,
      bugFixes: bugFixes,
    );
  }

  bool get hasDownload => downloadUrl.isNotEmpty;
}
