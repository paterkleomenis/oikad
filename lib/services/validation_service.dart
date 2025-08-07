import 'localization_service.dart';

class ValidationService {
  static String? validateRequired(
    String? value,
    String fieldName,
    String locale,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '${LocalizationService.t(locale, fieldName)} ${LocalizationService.t(locale, 'required').toLowerCase()}';
    }
    return null;
  }

  static String? validateEmail(String? value, String locale) {
    if (value == null || value.trim().isEmpty) return null;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return _getValidationMessage('invalid_email', locale);
    }
    return null;
  }

  static String? validatePhone(String? value, String locale) {
    if (value == null || value.trim().isEmpty) return null;

    // Support both Greek and international phone formats
    final phoneRegex = RegExp(
      r'^(\+30|0030|30)?[2-9]\d{8,9}$|^\+?[\d\s\-\(\)]{10,15}$',
    );
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return _getValidationMessage('invalid_phone', locale);
    }
    return null;
  }

  static String? validateTaxNumber(String? value, String locale) {
    if (value == null || value.trim().isEmpty) return null;

    // Greek AFM validation (9 digits) - simplified validation
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanValue.length != 9) {
      return _getValidationMessage('invalid_afm_length', locale);
    }

    // Simple validation - just check if it's 9 digits
    return null;
  }

  static String? validateIdCard(String? value, String locale) {
    if (value == null || value.trim().isEmpty) return null;

    // More flexible ID card validation - accept various formats
    final cleanValue = value.toUpperCase().replaceAll(' ', '');

    // Allow various ID formats: letters + numbers (minimum 6 characters)
    if (cleanValue.length < 6) {
      return _getValidationMessage('invalid_id_card', locale);
    }

    return null;
  }

  static String? validatePostalCode(String? value, String locale) {
    if (value == null || value.trim().isEmpty) return null;

    // Greek postal code: 5 digits
    final postalRegex = RegExp(r'^\d{5}$');
    if (!postalRegex.hasMatch(value.trim())) {
      return _getValidationMessage('invalid_postal_code', locale);
    }
    return null;
  }

  static String? validateName(String? value, String locale) {
    if (value == null || value.trim().isEmpty) return null;

    // Check length first
    if (value.trim().length < 2) {
      return _getValidationMessage('name_too_short', locale);
    }

    // Check for invalid characters (numbers and most special characters)
    if (value.contains(RegExp(r'[0-9!@#$%^&*()_+={}|;<>?/\\`~]'))) {
      return _getValidationMessage('invalid_name', locale);
    }

    return null;
  }

  static String? validateMinLength(
    String? value,
    int minLength,
    String locale,
  ) {
    if (value == null || value.trim().isEmpty) return null;

    if (value.trim().length < minLength) {
      return _getValidationMessage(
        'min_length',
        locale,
      ).replaceAll('{length}', minLength.toString());
    }
    return null;
  }

  static String? validateMaxLength(
    String? value,
    int maxLength,
    String locale,
  ) {
    if (value == null || value.trim().isEmpty) return null;

    if (value.trim().length > maxLength) {
      return _getValidationMessage(
        'max_length',
        locale,
      ).replaceAll('{length}', maxLength.toString());
    }
    return null;
  }

  static String? validateDateNotFuture(DateTime? date, String locale) {
    if (date == null) return null;

    if (date.isAfter(DateTime.now())) {
      return _getValidationMessage('date_future', locale);
    }
    return null;
  }

  static String? validateAge(DateTime? birthDate, int minAge, String locale) {
    if (birthDate == null) return null;

    final now = DateTime.now();
    final age = now.year - birthDate.year;

    if (age < minAge ||
        (age == minAge && now.month < birthDate.month) ||
        (age == minAge &&
            now.month == birthDate.month &&
            now.day < birthDate.day)) {
      return _getValidationMessage(
        'min_age',
        locale,
      ).replaceAll('{age}', minAge.toString());
    }
    return null;
  }

  static String _getValidationMessage(String key, String locale) {
    final messages = {
      'en': {
        'invalid_email': 'Please enter a valid email address',
        'invalid_phone': 'Please enter a valid phone number',
        'invalid_afm_length': 'Tax number must be exactly 9 digits',
        'invalid_afm': 'Invalid tax number format',
        'invalid_id_card': 'ID card must be at least 6 characters',
        'invalid_postal_code': 'Postal code must be 5 digits',
        'invalid_name': 'Name should only contain letters',
        'name_too_short': 'Name must be at least 2 characters',
        'min_length': 'Minimum length is {length} characters',
        'max_length': 'Maximum length is {length} characters',
        'date_future': 'Date cannot be in the future',
        'min_age': 'Minimum age is {age} years',
      },
      'el': {
        'invalid_email': 'Παρακαλώ εισάγετε έγκυρη διεύθυνση email',
        'invalid_phone': 'Παρακαλώ εισάγετε έγκυρο αριθμό τηλεφώνου',
        'invalid_afm_length': 'Το ΑΦΜ πρέπει να έχει ακριβώς 9 ψηφία',
        'invalid_afm': 'Μη έγκυρη μορφή ΑΦΜ',
        'invalid_id_card':
            'Η ταυτότητα πρέπει να έχει τουλάχιστον 6 χαρακτήρες',
        'invalid_postal_code': 'Ο ταχυδρομικός κώδικας πρέπει να έχει 5 ψηφία',
        'invalid_name': 'Το όνομα πρέπει να περιέχει μόνο γράμματα',
        'name_too_short': 'Το όνομα πρέπει να έχει τουλάχιστον 2 χαρακτήρες',
        'min_length': 'Ελάχιστο μήκος {length} χαρακτήρες',
        'max_length': 'Μέγιστο μήκος {length} χαρακτήρες',
        'date_future': 'Η ημερομηνία δεν μπορεί να είναι στο μέλλον',
        'min_age': 'Ελάχιστη ηλικία {age} έτη',
      },
    };

    return messages[locale]?[key] ?? messages['en']![key]!;
  }

  // Utility method to combine multiple validators
  static String? Function(String?) combineValidators(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
