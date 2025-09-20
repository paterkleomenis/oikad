import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers.dart';
import '../services/localization_service.dart';
import '../services/update_service.dart';
import '../utils/app_info.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoCheckUpdates = true;
  bool _isCheckingUpdates = false;

  String t(String locale, String key) => LocalizationService.t(locale, key);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final updateService = context.read<UpdateService>();
    final autoCheck = await updateService.getAutoUpdateCheck();

    if (mounted) {
      setState(() {
        _autoCheckUpdates = autoCheck;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;
    final themeNotifier = context.watch<ThemeNotifier>();
    final updateService = context.watch<UpdateService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t(locale, 'settings')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Updates Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.system_update,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'App Updates',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Current Version
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline),
                      title: Text(t(locale, 'current_version')),
                      subtitle: Text(
                        updateService.currentVersion ?? AppInfo.version,
                      ),
                    ),

                    // Check for Updates Button
                    Consumer<UpdateService>(
                      builder: (context, updateService, child) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _isCheckingUpdates
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_download),
                          title: Text(t(locale, 'check_updates')),
                          subtitle: _isCheckingUpdates
                              ? Text(t(locale, 'tap_to_check'))
                              : updateService.hasUpdate
                              ? Text(
                                  '${t(locale, 'update_available')}: v${updateService.availableUpdate!.version}',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(t(locale, 'no_updates_available')),
                          trailing: updateService.hasUpdate
                              ? Badge(
                                  backgroundColor: Colors.red,
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                )
                              : Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                          onTap: _isCheckingUpdates ? null : _checkForUpdates,
                        );
                      },
                    ),

                    // Auto-check Updates Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.autorenew),
                      title: Text('Auto-check for updates'),
                      subtitle: Text('Automatically check for updates daily'),
                      value: _autoCheckUpdates,
                      onChanged: _toggleAutoCheck,
                    ),

                    if (updateService.hasUpdate) ...[
                      const Divider(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  updateService.availableUpdate!.isCritical
                                      ? Icons.warning
                                      : Icons.system_update,
                                  color:
                                      updateService.availableUpdate!.isCritical
                                      ? Colors.red
                                      : Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    updateService.availableUpdate!.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Version ${updateService.availableUpdate!.version}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _showUpdateDialog(),
                                icon: const Icon(Icons.download),
                                label: Text(t(locale, 'update_now')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Appearance Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Appearance',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Theme Selection
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        themeNotifier.themeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : themeNotifier.themeMode == ThemeMode.light
                            ? Icons.light_mode
                            : Icons.brightness_auto,
                      ),
                      title: const Text('Theme'),
                      subtitle: Text(
                        themeNotifier.themeMode == ThemeMode.dark
                            ? 'Dark'
                            : themeNotifier.themeMode == ThemeMode.light
                            ? 'Light'
                            : 'System',
                      ),
                      trailing: DropdownButton<ThemeMode>(
                        value: themeNotifier.themeMode,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                        ],
                        onChanged: (ThemeMode? mode) {
                          if (mode != null) {
                            themeNotifier.setThemeMode(mode);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Language Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Language',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Language Selection
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.translate),
                      title: const Text('App Language'),
                      subtitle: Text(locale == 'en' ? 'English' : 'Ελληνικά'),
                      trailing: DropdownButton<String>(
                        value: locale,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(
                            value: 'el',
                            child: Text('Ελληνικά'),
                          ),
                        ],
                        onChanged: (String? newLocale) {
                          if (newLocale != null) {
                            context.read<LocaleNotifier>().setLocale(newLocale);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // App Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 12),
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.apps),
                      title: const Text('OIKAD'),
                      subtitle: const Text('Dormitory Registration System'),
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.code),
                      title: const Text('Version'),
                      subtitle: Text(
                        updateService.currentVersion ?? AppInfo.version,
                      ),
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bug_report),
                      title: const Text('Report Issue'),
                      subtitle: const Text('GitHub Issues'),
                      trailing: const Icon(Icons.open_in_new, size: 16),
                      onTap: () {
                        // Open GitHub issues page
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80), // Bottom padding
          ],
        ),
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    if (_isCheckingUpdates) return;

    setState(() {
      _isCheckingUpdates = true;
    });

    final updateService = context.read<UpdateService>();
    final locale = context.read<LocaleNotifier>().locale;

    try {
      // Add timeout to prevent infinite loading
      final hasUpdate = await updateService
          .checkForUpdates(silent: false)
          .timeout(const Duration(seconds: 30));

      if (mounted) {
        setState(() {
          _isCheckingUpdates = false;
        });

        if (hasUpdate) {
          final update = updateService.availableUpdate;
          if (update != null) {
            await showUpdateDialog(context, update);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(locale, 'no_updates_available')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUpdates = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(locale, 'update_check_failed')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _toggleAutoCheck(bool value) async {
    final updateService = context.read<UpdateService>();
    await updateService.setAutoUpdateCheck(value);

    setState(() {
      _autoCheckUpdates = value;
    });
  }

  Future<void> _showUpdateDialog() async {
    final updateService = context.read<UpdateService>();
    final update = updateService.availableUpdate;

    if (update != null) {
      await showUpdateDialog(context, update);
    }
  }
}
