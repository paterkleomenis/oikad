import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'localization_service.dart';

class ErrorService {
  static void showError(
    BuildContext context,
    String message, {
    String? locale,
  }) {
    final currentLocale = locale ?? 'en';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: LocalizationService.t(currentLocale, 'dismiss'),
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? locale,
  }) {
    final currentLocale = locale ?? 'en';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: LocalizationService.t(currentLocale, 'dismiss'),
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static String getErrorMessage(dynamic error, {String locale = 'en'}) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505':
          return _getLocalizedError('duplicate_entry', locale);
        case '42501':
          return _getLocalizedError('insufficient_privileges', locale);
        case '08006':
          return _getLocalizedError('connection_error', locale);
        default:
          return _getLocalizedError(
            'database_error',
            locale,
            details: error.message,
          );
      }
    }

    if (error is AuthException) {
      switch (error.statusCode) {
        case '400':
          return _getLocalizedError('invalid_credentials', locale);
        case '422':
          return _getLocalizedError('validation_error', locale);
        default:
          return _getLocalizedError(
            'auth_error',
            locale,
            details: error.message,
          );
      }
    }

    if (error is FormatException) {
      return _getLocalizedError('invalid_format', locale);
    }

    // Generic error handling
    return _getLocalizedError(
      'unexpected_error',
      locale,
      details: error.toString(),
    );
  }

  static String _getLocalizedError(
    String errorKey,
    String locale, {
    String? details,
  }) {
    final errorMessages = {
      'en': {
        'duplicate_entry': 'This record already exists',
        'insufficient_privileges':
            'You do not have permission to perform this action',
        'connection_error':
            'Unable to connect to the server. Please check your internet connection',
        'database_error': 'Database error occurred',
        'invalid_credentials': 'Invalid email or password',
        'validation_error': 'Please check your input and try again',
        'auth_error': 'Authentication error occurred',
        'invalid_format': 'Invalid data format',
        'unexpected_error': 'An unexpected error occurred',
        'network_error': 'Network error. Please try again',
        'timeout_error': 'Request timed out. Please try again',
      },
      'el': {
        'duplicate_entry': 'Αυτή η εγγραφή υπάρχει ήδη',
        'insufficient_privileges':
            'Δεν έχετε δικαίωμα να εκτελέσετε αυτή την ενέργεια',
        'connection_error':
            'Αδυναμία σύνδεσης με τον διακομιστή. Ελέγξτε τη σύνδεσή σας στο διαδίκτυο',
        'database_error': 'Προέκυψε σφάλμα βάσης δεδομένων',
        'invalid_credentials': 'Μη έγκυρο email ή κωδικός πρόσβασης',
        'validation_error': 'Ελέγξτε τα στοιχεία σας και δοκιμάστε ξανά',
        'auth_error': 'Προέκυψε σφάλμα επαλήθευσης',
        'invalid_format': 'Μη έγκυρη μορφή δεδομένων',
        'unexpected_error': 'Προέκυψε απροσδόκητο σφάλμα',
        'network_error': 'Σφάλμα δικτύου. Δοκιμάστε ξανά',
        'timeout_error': 'Η αίτηση έληξε. Δοκιμάστε ξανά',
      },
    };

    final message =
        errorMessages[locale]?[errorKey] ?? errorMessages['en']![errorKey]!;

    if (details != null && details.isNotEmpty) {
      return '$message: $details';
    }

    return message;
  }

  static void handleAsyncError(dynamic error, StackTrace stackTrace) {
    // Log error for debugging
    debugPrint('Async Error: $error');
    debugPrint('Stack Trace: $stackTrace');

    // In production, you might want to send this to a crash reporting service
    // like Firebase Crashlytics or Sentry
  }

  static bool isNetworkError(dynamic error) {
    return error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('ClientException');
  }
}
