class SanitizationService {
  /// Sanitizes text input by removing potentially harmful characters
  /// and normalizing whitespace
  static String? sanitizeText(String? input) {
    if (input == null) return null;

    // Remove null bytes and control characters
    String sanitized = input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // Remove common injection patterns
    sanitized = sanitized.replaceAll(RegExp(r'[<>"\x27\x00]'), '');

    // Normalize whitespace
    sanitized = sanitized.trim().replaceAll(RegExp(r'\s+'), ' ');

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitizes name fields (allows letters, spaces, apostrophes, hyphens)
  static String? sanitizeName(String? input) {
    if (input == null) return null;

    // Keep only letters, spaces, apostrophes, and hyphens (for names like O'Connor, Smith-Jones)
    String sanitized = input.replaceAll(
      RegExp(
        r'[^a-zA-ZάβγδεζηθικλμνξοπρστυφχψωΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΐΰέόίώήύ\s\x27\-]',
      ),
      '',
    );

    // Normalize whitespace
    sanitized = sanitized.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Remove multiple consecutive apostrophes or hyphens
    sanitized = sanitized.replaceAll(RegExp(r'[\x27\-]{2,}'), '');

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitizes email addresses
  static String? sanitizeEmail(String? input) {
    if (input == null) return null;

    // Convert to lowercase and trim
    String sanitized = input.toLowerCase().trim();

    // Remove any characters that aren't valid in email addresses
    sanitized = sanitized.replaceAll(RegExp(r'[^a-z0-9@\.\-_]'), '');

    // Remove multiple consecutive dots or @ symbols
    sanitized = sanitized.replaceAll(RegExp(r'\.{2,}'), '.');
    sanitized = sanitized.replaceAll(RegExp(r'@{2,}'), '@');

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitizes phone numbers (keeps only digits, +, -, (, ), spaces)
  static String? sanitizePhone(String? input) {
    if (input == null) return null;

    // Keep only digits and common phone formatting characters
    String sanitized = input.replaceAll(RegExp(r'[^\d\+\-\(\)\s]'), '');

    // Normalize whitespace
    sanitized = sanitized.trim().replaceAll(RegExp(r'\s+'), ' ');

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitizes numeric fields (tax numbers, postal codes, etc.)
  static String? sanitizeNumeric(String? input) {
    if (input == null) return null;

    // Keep only digits
    String sanitized = input.replaceAll(RegExp(r'[^\d]'), '');

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitizes alphanumeric fields (ID card numbers, etc.)
  static String? sanitizeAlphanumeric(String? input) {
    if (input == null) return null;

    // Keep only letters and numbers (both English and Greek)
    String sanitized = input.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ]'),
      '',
    );

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitizes address fields
  static String? sanitizeAddress(String? input) {
    if (input == null) return null;

    // Allow letters, numbers, spaces, common punctuation for addresses
    String sanitized = input.replaceAll(
      RegExp(
        r'[^a-zA-Z0-9άβγδεζηθικλμνξοπρστυφχψωΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΐΰέόίώήύ\s\.\,\-\/\#]',
      ),
      '',
    );

    // Normalize whitespace
    sanitized = sanitized.trim().replaceAll(RegExp(r'\s+'), ' ');

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Comprehensive sanitization for general text fields
  static String? sanitizeGeneral(String? input, {int? maxLength}) {
    if (input == null) return null;

    String sanitized = sanitizeText(input) ?? '';

    // Apply max length if specified
    if (maxLength != null && sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Sanitizes university/institution names
  static String? sanitizeInstitution(String? input) {
    if (input == null) return null;

    // Allow letters, numbers, spaces, and common punctuation for institution names
    String sanitized = input.replaceAll(
      RegExp(
        r'[^a-zA-Z0-9άβγδεζηθικλμνξοπρστυφχψωΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΐΰέόίώήύ\s\.\-\x27&]',
      ),
      '',
    );

    // Normalize whitespace
    sanitized = sanitized.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Remove multiple consecutive punctuation
    sanitized = sanitized.replaceAll(RegExp(r'[\.\-\x27&]{2,}'), '');

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Prevents XSS by encoding HTML entities
  static String escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Removes SQL injection patterns (basic protection)
  static String? sanitizeSql(String? input) {
    if (input == null) return null;

    // Remove common SQL injection patterns
    String sanitized = input.replaceAll(RegExp(r'[;\x27\x22\\]'), '');
    sanitized = sanitized.replaceAll(
      RegExp(
        r'\b(DROP|DELETE|INSERT|UPDATE|SELECT|UNION|ALTER|CREATE)\b',
        caseSensitive: false,
      ),
      '',
    );

    return sanitized.trim().isEmpty ? null : sanitized;
  }

  /// Validates file upload extensions (if needed for future features)
  static bool isAllowedFileExtension(
    String filename,
    List<String> allowedExtensions,
  ) {
    final extension = filename.toLowerCase().split('.').last;
    return allowedExtensions.contains(extension);
  }

  /// Security headers for sensitive data
  static Map<String, String> getSecurityHeaders() {
    return {
      'Content-Security-Policy': "default-src 'self'",
      'X-Frame-Options': 'DENY',
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
    };
  }
}
