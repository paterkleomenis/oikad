import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers.dart';
import '../services/localization_service.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../widgets/widgets.dart';
import '../widgets/update_checker.dart';
import '../widgets/update_dialog.dart';
import 'registration_screen.dart';
import 'documents_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic> _userStatistics = {};
  bool _isLoading = true;

  String t(String locale, String key) => LocalizationService.t(locale, key);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh completion status from database first
      if (mounted) {
        await context.read<CompletionNotifier>().refreshCompletionStatus();
      }

      // Load user profile and statistics
      final profile = await AuthService.getCurrentUserProfile();
      final stats = await _loadUserStatistics();

      // Debug output to help troubleshoot
      debugPrint('User profile loaded: $profile');
      if (profile != null) {
        debugPrint('Name: ${profile['name']}');
        debugPrint('Family name: ${profile['family_name']}');
        debugPrint('Full name: ${profile['full_name']}');
        debugPrint('Email: ${AuthService.currentUser?.email}');
      }

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _userStatistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _loadUserStatistics() async {
    // Mock data - replace with actual API calls
    return {'total_documents': 3, 'application_status': 'submitted'};
  }

  // Removed - using TextUtils.formatFileSize instead

  String _getUserDisplayName() {
    if (_userProfile == null) {
      // Try to get user email as fallback
      final userEmail = AuthService.currentUser?.email;
      if (userEmail != null) {
        // Extract name part from email (before @)
        final emailName = userEmail.split('@')[0];
        return emailName
            .replaceAll('.', ' ')
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1)
                  : '',
            )
            .join(' ');
      }
      return 'User';
    }

    final firstName = _userProfile!['name']?.toString().trim() ?? '';
    final lastName = _userProfile!['family_name']?.toString().trim() ?? '';

    // Try different combinations
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    }

    // Check for other possible name fields
    final fullName = _userProfile!['full_name']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) {
      return fullName;
    }

    // Fallback to email-based name
    final userEmail = AuthService.currentUser?.email;
    if (userEmail != null) {
      final emailName = userEmail.split('@')[0];
      return emailName
          .replaceAll('.', ' ')
          .replaceAll('_', ' ')
          .split(' ')
          .map(
            (word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : '',
          )
          .join(' ');
    }

    return 'User';
  }

  void _signOut() {
    final locale = context.read<LocaleNotifier>().locale;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(locale, 'confirm_sign_out')),
        content: Text(t(locale, 'sign_out_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(locale, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/welcome');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(t(locale, 'sign_out')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;
    final completion = context.watch<CompletionNotifier>();

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF64B5F6)
                : Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t(locale, 'dashboard')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: t(locale, 'refresh'),
          ),
          const LanguageSelector(),
          const ThemeToggle(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'settings':
                      _openSettings();
                      break;
                    case 'check_updates':
                      _checkForUpdates();
                      break;
                    case 'sign_out':
                      _signOut();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings),
                        const SizedBox(width: 8),
                        Text(t(locale, 'settings')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'check_updates',
                    child: Row(
                      children: [
                        const Icon(Icons.system_update),
                        const SizedBox(width: 8),
                        Text(t(locale, 'check_updates')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'sign_out',
                    child: Row(
                      children: [
                        const Icon(Icons.exit_to_app),
                        const SizedBox(width: 8),
                        Text(t(locale, 'sign_out')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Update notification banner
              const UpdateNotificationBanner(),

              // Welcome Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Avatar Circle
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getUserDisplayName().substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${t(locale, 'welcome_back')}, ${_getUserDisplayName()}!',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : null,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t(locale, 'dashboard_subtitle'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Statistics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      locale,
                      'completed_tasks',
                      '${completion.completedItems.length}',
                      Icons.task_alt_outlined,
                      onTap: () => _showCompletedTasksScreen(context, locale),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      locale,
                      'application_status',
                      t(
                        locale,
                        _userStatistics['application_status'] ?? 'pending',
                      ),
                      Icons.assignment_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Pending Tasks Section
              if (!completion.registrationCompleted ||
                  !completion.documentsCompleted) ...[
                Text(
                  t(locale, 'pending_tasks'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (!completion.registrationCompleted) ...[
                          ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.home_outlined,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF64B5F6)
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(t(locale, 'dormitory_registration')),
                            subtitle: Text(
                              t(locale, 'complete_registration_first'),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF64B5F6)
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RegistrationScreen(
                                        isEditMode: false,
                                      ),
                                ),
                              );
                            },
                          ),
                          if (!completion.documentsCompleted) const Divider(),
                        ],
                        if (!completion.documentsCompleted) ...[
                          ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.upload_file_outlined,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF64B5F6)
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(t(locale, 'upload_documents')),
                            subtitle: Text(
                              t(locale, 'upload_required_documents'),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF64B5F6)
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DocumentsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String locale,
    String titleKey,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF64B5F6)
                    : Theme.of(context).primaryColor.withOpacity(0.8),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  t(locale, titleKey),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletedTasksScreen(BuildContext context, String locale) {
    final completion = context.read<CompletionNotifier>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(locale, 'completed_tasks'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            if (completion.registrationCompleted)
              _buildCompletedTaskItem(
                context,
                locale,
                'dormitory_registration',
                Icons.home_outlined,
                onEdit: () => _editRegistration(context),
              ),
            if (completion.documentsCompleted)
              _buildCompletedTaskItem(
                context,
                locale,
                'upload_documents',
                Icons.upload_file_outlined,
                onEdit: () => _editDocuments(context),
              ),
            if (!completion.registrationCompleted &&
                !completion.documentsCompleted) ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.pending_actions,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t(locale, 'no_completed_tasks'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF64B5F6)
                      : Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  t(locale, 'close'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedTaskItem(
    BuildContext context,
    String locale,
    String titleKey,
    IconData icon, {
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF64B5F6).withOpacity(0.2)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF64B5F6)
                  : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF64B5F6)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t(locale, titleKey),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : null,
              ),
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              iconSize: 20,
              tooltip: t(locale, 'edit'),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF64B5F6).withOpacity(0.1)
                    : Theme.of(context).primaryColor.withOpacity(0.1),
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF64B5F6)
                    : Theme.of(context).primaryColor,
                minimumSize: const Size(36, 36),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistrationScreen(isEditMode: true),
      ),
    );
  }

  void _editDocuments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DocumentsScreen()),
    );
  }

  Future<void> _checkForUpdates() async {
    final updateService = context.read<UpdateService>();

    try {
      final hasUpdate = await updateService.checkForUpdates();

      if (hasUpdate && mounted) {
        final update = updateService.availableUpdate;
        if (update != null) {
          await showUpdateDialog(context, update);
        }
      } else if (mounted) {
        final locale = context.read<LocaleNotifier>().locale;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(locale, 'no_updates_available')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final locale = context.read<LocaleNotifier>().locale;
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

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}
