import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';

class LocaleNotifier extends ChangeNotifier {
  String _locale = 'en';
  String get locale => _locale;

  LocaleNotifier() {
    _loadLocale();
  }

  void toggleLocale() {
    _locale = _locale == 'en' ? 'el' : 'en';
    _saveLocale();
    notifyListeners();
  }

  void setLocale(String locale) {
    if (_locale != locale) {
      _locale = locale;
      _saveLocale();
      notifyListeners();
    }
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString('locale') ?? 'en';
    notifyListeners();
  }

  Future<void> _saveLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', _locale);
  }
}

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _loadTheme();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveTheme();
      notifyListeners();
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_mode') ?? 'system';
    switch (themeString) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    String themeString;
    switch (_themeMode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      default:
        themeString = 'system';
    }
    await prefs.setString('theme_mode', themeString);
  }
}

class CompletionNotifier extends ChangeNotifier {
  bool _registrationCompleted = false;
  bool _documentsCompleted = false;
  final List<String> _completedItems = [];
  String? _lastUserId;

  bool get registrationCompleted => _registrationCompleted;
  bool get documentsCompleted => _documentsCompleted;
  List<String> get completedItems => List.unmodifiable(_completedItems);

  // Convenience getters for pending tasks
  bool get hasRegistrationPending => !_registrationCompleted;
  bool get hasDocumentsPending => !_documentsCompleted;
  bool get hasPendingTasks => hasRegistrationPending || hasDocumentsPending;
  int get pendingTasksCount =>
      (hasRegistrationPending ? 1 : 0) + (hasDocumentsPending ? 1 : 0);

  List<String> get pendingTasks {
    final pending = <String>[];
    if (hasRegistrationPending) {
      pending.add('Dormitory Registration');
    }
    if (hasDocumentsPending) {
      pending.add('Document Upload');
    }
    return pending;
  }

  CompletionNotifier() {
    _loadCompletionState();
  }

  void markRegistrationCompleted() {
    if (!_registrationCompleted) {
      _registrationCompleted = true;
      _addCompletedItem('Dormitory Registration');
      _saveCompletionState();
      notifyListeners();
    }
  }

  void unmarkRegistrationCompleted() {
    if (_registrationCompleted) {
      _registrationCompleted = false;
      _completedItems.removeWhere((item) => item == 'Dormitory Registration');
      _saveCompletionState();
      notifyListeners();
    }
  }

  void markDocumentsCompleted() {
    if (!_documentsCompleted) {
      _documentsCompleted = true;
      _addCompletedItem('Document Upload');
      _saveCompletionState();
      notifyListeners();
    }
  }

  void _addCompletedItem(String item) {
    if (!_completedItems.contains(item)) {
      _completedItems.add(item);
    }
  }

  Future<void> _loadCompletionState() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = AuthService.currentUserId;

    // Check if user has changed since last load
    if (_lastUserId != null && _lastUserId != currentUserId) {
      // User changed, reset completion state
      _registrationCompleted = false;
      _documentsCompleted = false;
      _completedItems.clear();
    }
    _lastUserId = currentUserId;

    // Check actual completion status from database instead of just stored flags
    await _checkActualCompletionStatus();

    // If database check fails, fall back to stored preferences tied to current user
    if (!_registrationCompleted && !_documentsCompleted) {
      if (currentUserId != null) {
        _registrationCompleted =
            prefs.getBool('registration_completed_$currentUserId') ?? false;
        _documentsCompleted =
            prefs.getBool('documents_completed_$currentUserId') ?? false;
      }
    }

    // Rebuild completed items list based on actual completion flags
    _completedItems.clear();
    if (_registrationCompleted) {
      _completedItems.add('Dormitory Registration');
    }
    if (_documentsCompleted) {
      _completedItems.add('Document Upload');
    }

    notifyListeners();
  }

  Future<void> _saveCompletionState() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = AuthService.currentUserId;
    if (currentUserId != null) {
      await prefs.setBool(
        'registration_completed_$currentUserId',
        _registrationCompleted,
      );
      await prefs.setBool(
        'documents_completed_$currentUserId',
        _documentsCompleted,
      );
      await prefs.setStringList(
        'completed_items_$currentUserId',
        _completedItems,
      );
    }
  }

  void resetCompletion() {
    _registrationCompleted = false;
    _documentsCompleted = false;
    _completedItems.clear();
    _lastUserId = AuthService.currentUserId;
    _saveCompletionState();
    notifyListeners();
  }

  // Clear completion state for current user (useful when user logs out or switches accounts)
  Future<void> clearCompletionForCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = AuthService.currentUserId;
    if (currentUserId != null) {
      await prefs.remove('registration_completed_$currentUserId');
      await prefs.remove('documents_completed_$currentUserId');
      await prefs.remove('completed_items_$currentUserId');
    }
    resetCompletion();
  }

  // Check actual completion status from database
  Future<void> _checkActualCompletionStatus() async {
    try {
      // Check if user is authenticated first
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      // Check registration completion by verifying if submitted registration exists
      final registrationResult = await Supabase.instance.client
          .from('dormitory_students')
          .select('application_status')
          .eq('auth_user_id', currentUserId)
          .maybeSingle();

      if (registrationResult != null) {
        final status = registrationResult['application_status'] as String?;
        _registrationCompleted = status != null && status != 'draft';
      } else {
        _registrationCompleted = false;
      }

      // Check documents completion by verifying if document submission exists
      final documentsResult = await Supabase.instance.client
          .from('document_submissions')
          .select('id')
          .eq('student_id', currentUserId)
          .maybeSingle();

      _documentsCompleted = documentsResult != null;

      // Save the updated status
      await _saveCompletionState();
    } catch (e) {
      // If database check fails, keep existing state
      if (kDebugMode) {
        debugPrint('Error checking completion status from database: $e');
      }
    }
  }

  // Method to refresh completion status and check for user changes
  Future<void> refreshCompletionStatus() async {
    final currentUserId = AuthService.currentUserId;

    // Check if user has changed since last load
    if (_lastUserId != null && _lastUserId != currentUserId) {
      // User changed, reset completion state
      _registrationCompleted = false;
      _documentsCompleted = false;
      _completedItems.clear();
    }
    _lastUserId = currentUserId;

    await _checkActualCompletionStatus();
    notifyListeners();
  }
}
