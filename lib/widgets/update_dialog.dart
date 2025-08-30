import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_update.dart';
import '../services/update_service.dart';
import '../services/version_service.dart';

class UpdateDialog extends StatelessWidget {
  final AppUpdate update;
  final bool canSkip;

  const UpdateDialog({super.key, required this.update, this.canSkip = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, child) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                update.isCritical ? Icons.warning : Icons.system_update,
                color: update.isCritical ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  update.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVersionInfo(context, updateService),
                const SizedBox(height: 16),
                _buildUpdateContent(context),
                if (updateService.isDownloading) ...[
                  const SizedBox(height: 16),
                  _buildDownloadProgress(context, updateService),
                ],
              ],
            ),
          ),
          actions: updateService.isDownloading
              ? [_buildCancelButton(context, updateService)]
              : _buildActionButtons(context, updateService),
        );
      },
    );
  }

  Widget _buildVersionInfo(BuildContext context, UpdateService updateService) {
    final info = updateService.getUpdateInfo();
    final severity = updateService.getUpdateSeverity();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Version:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                info['currentVersion'] ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Version:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                info['newVersion'] ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Download Size:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                info['fileSize'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: severity.isImportant ? Colors.orange : Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              severity.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (update.description.isNotEmpty) ...[
          Text(
            'What\'s New:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              update.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        if (update.features.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'New Features:',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...update.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (update.bugFixes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Bug Fixes:',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...update.bugFixes.map(
            (fix) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      fix,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (update.isCritical) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a critical security update. Please install immediately.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloadProgress(
    BuildContext context,
    UpdateService updateService,
  ) {
    return Column(
      children: [
        Text(
          'Downloading Update...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: updateService.downloadProgress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(updateService.downloadProgress * 100).toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    UpdateService updateService,
  ) {
    final buttons = <Widget>[];

    // Skip button (only if allowed and not forced)
    if (canSkip && !update.isForced) {
      buttons.add(
        TextButton(
          onPressed: () {
            updateService.skipCurrentVersion();
            Navigator.of(context).pop();
          },
          child: const Text('Skip'),
        ),
      );
    }

    // Later button (only if not forced)
    if (!update.isForced) {
      buttons.add(
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Later'),
        ),
      );
    }

    // Update button
    buttons.add(
      FilledButton(
        onPressed: () async {
          final success = await updateService.downloadAndInstall();
          if (success && context.mounted) {
            Navigator.of(context).pop();
            _showUpdateSuccessSnackbar(context);
          } else if (context.mounted) {
            _showUpdateErrorSnackbar(context);
          }
        },
        child: Text(update.isForced ? 'Update Now' : 'Update'),
      ),
    );

    return buttons;
  }

  Widget _buildCancelButton(BuildContext context, UpdateService updateService) {
    return TextButton(
      onPressed: () {
        // Cancel download - you might want to implement this in UpdateService
        Navigator.of(context).pop();
      },
      child: const Text('Cancel'),
    );
  }

  void _showUpdateSuccessSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Update downloaded successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showUpdateErrorSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to download update. Please try again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

/// Show update dialog helper function
Future<void> showUpdateDialog(
  BuildContext context,
  AppUpdate update, {
  bool canSkip = true,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: !update.isForced,
    builder: (BuildContext context) {
      return UpdateDialog(update: update, canSkip: canSkip);
    },
  );
}
