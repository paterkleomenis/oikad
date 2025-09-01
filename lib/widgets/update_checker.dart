import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/update_service.dart';
import '../services/version_service.dart';
import 'update_dialog.dart';

class UpdateChecker extends StatefulWidget {
  final Widget child;
  final bool autoCheck;
  final Duration checkInterval;

  const UpdateChecker({
    super.key,
    required this.child,
    this.autoCheck = true,
    this.checkInterval = const Duration(hours: 24),
  });

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check for updates when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoCheck) {
        _checkForUpdates();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check for updates when app comes to foreground
    if (state == AppLifecycleState.resumed && widget.autoCheck) {
      _checkForUpdates();
      // Also refresh install permission status on Android
      if (Platform.isAndroid) {
        _refreshInstallPermission();
      }
    }
  }

  Future<void> _refreshInstallPermission() async {
    try {
      final updateService = context.read<UpdateService>();
      await updateService.refreshInstallPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error refreshing install permission: $e');
      }
    }
  }

  Future<void> _checkForUpdates() async {
    final updateService = context.read<UpdateService>();

    if (kDebugMode) {
      debugPrint('UpdateChecker: Starting silent update check');
    }

    try {
      final hasUpdate = await updateService.checkForUpdates(silent: true);

      if (kDebugMode) {
        debugPrint(
          'UpdateChecker: Silent update check completed, hasUpdate: $hasUpdate',
        );
      }

      if (hasUpdate && mounted) {
        final update = updateService.availableUpdate;
        if (update != null) {
          // Show update dialog
          await showUpdateDialog(context, update);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UpdateChecker: Error checking for updates: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, child) {
        return Stack(
          children: [
            widget.child,
            if (updateService.isChecking)
              const Positioned(
                top: 50,
                right: 16,
                child: UpdateCheckingIndicator(),
              ),
          ],
        );
      },
    );
  }
}

class UpdateCheckingIndicator extends StatelessWidget {
  const UpdateCheckingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Checking for updates...',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Manual update check button widget
class UpdateCheckButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final bool showProgress;

  const UpdateCheckButton({
    super.key,
    this.text,
    this.icon,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, child) {
        return FilledButton.icon(
          onPressed: updateService.isChecking
              ? null
              : () async {
                  try {
                    final hasUpdate = await updateService.checkForUpdates();

                    if (hasUpdate && context.mounted) {
                      final update = updateService.availableUpdate;
                      if (update != null) {
                        await showUpdateDialog(context, update);
                      }
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No updates available'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to check for updates'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
          icon: updateService.isChecking && showProgress
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon ?? Icons.system_update),
          label: Text(text ?? 'Check for Updates'),
        );
      },
    );
  }
}

/// Update notification banner
class UpdateNotificationBanner extends StatelessWidget {
  final bool dismissible;

  const UpdateNotificationBanner({super.key, this.dismissible = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateService>(
      builder: (context, updateService, child) {
        if (!updateService.hasUpdate) {
          return const SizedBox.shrink();
        }

        final update = updateService.availableUpdate!;
        final severity = updateService.getUpdateSeverity();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: severity.isImportant
                ? Colors.orange.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            border: Border.all(
              color: severity.isImportant ? Colors.orange : Colors.blue,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                update.isCritical ? Icons.warning : Icons.system_update,
                color: update.isCritical ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Update Available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Version ${update.version} is now available',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (update.isCritical)
                      Text(
                        'Critical security update',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  await showUpdateDialog(context, update);
                },
                child: const Text('Update'),
              ),
              if (dismissible && !update.isForced) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    updateService.clearUpdate();
                  },
                  icon: const Icon(Icons.close),
                  tooltip: 'Dismiss',
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
