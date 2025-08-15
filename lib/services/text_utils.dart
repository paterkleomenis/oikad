import 'dart:convert';

class TextUtils {
  /// Converts text with underscores to readable format
  /// Example: "hello_world_test" -> "Hello World Test"
  static String formatText(String text) {
    if (text.isEmpty) return text;

    return text
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  /// Converts camelCase to readable format
  /// Example: "helloWorldTest" -> "Hello World Test"
  static String formatCamelCase(String text) {
    if (text.isEmpty) return text;

    return text
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .trim()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  /// Converts any text to title case
  /// Example: "hello world" -> "Hello World"
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;

    return text
        .toLowerCase()
        .split(' ')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  /// Truncates text with ellipsis
  static String truncate(
    String text,
    int maxLength, {
    String ellipsis = '...',
  }) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Removes all underscores and replaces with spaces
  static String removeUnderscores(String text) {
    return text.replaceAll('_', ' ');
  }

  /// Formats file names to be more readable
  /// Example: "ID_Card_Front.jpg" -> "ID Card Front"
  static String formatFileName(String fileName) {
    // Remove file extension
    String nameWithoutExtension = fileName.split('.').first;

    // Replace underscores with spaces and format
    return formatText(nameWithoutExtension);
  }

  /// Formats status text
  /// Example: "under_review" -> "Under Review"
  static String formatStatus(String status) {
    return formatText(status);
  }

  /// Validates and formats email
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Email is required';

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates and formats phone number
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) return null; // Optional field

    // Remove all non-digit characters
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    return null;
  }

  /// Formats phone number for display
  static String formatPhoneDisplay(String phone) {
    // Remove all non-digit characters
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length == 10) {
      // Format as (XXX) XXX-XXXX
      return '(${cleanPhone.substring(0, 3)}) ${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
    } else if (cleanPhone.length == 11 && cleanPhone.startsWith('1')) {
      // Format as +1 (XXX) XXX-XXXX
      return '+1 (${cleanPhone.substring(1, 4)}) ${cleanPhone.substring(4, 7)}-${cleanPhone.substring(7)}';
    }

    return phone; // Return original if can't format
  }

  /// Capitalizes first letter of each word
  static String capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Converts text to URL-friendly slug
  static String toSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Formats file size in bytes to human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Formats date to readable string
  static String formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Formats date and time to readable string
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Gets relative time string (e.g., "2 days ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Extracts initials from full name
  static String getInitials(String fullName) {
    List<String> names = fullName.trim().split(' ');
    if (names.isEmpty) return '';

    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    }

    return '${names.first.substring(0, 1)}${names.last.substring(0, 1)}'
        .toUpperCase();
  }

  /// Generates a random color based on text
  static int generateColorFromText(String text) {
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Convert to hex color
    String hex = (hash & 0x00FFFFFF).toRadixString(16).padLeft(6, '0');
    return int.parse('FF$hex', radix: 16);
  }

  /// Escapes HTML characters
  static String escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Unescapes HTML characters
  static String unescapeHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  /// Checks if string is a valid URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Extracts numbers from text
  static List<int> extractNumbers(String text) {
    final regex = RegExp(r'\d+');
    return regex
        .allMatches(text)
        .map((match) => int.tryParse(match.group(0)!) ?? 0)
        .toList();
  }

  /// Masks sensitive information (like credit card numbers)
  static String maskSensitive(
    String text, {
    int visibleChars = 4,
    String maskChar = '*',
  }) {
    if (text.length <= visibleChars) return text;

    final visiblePart = text.substring(text.length - visibleChars);
    final maskedPart = maskChar * (text.length - visibleChars);

    return maskedPart + visiblePart;
  }

  /// Converts string to base64
  static String toBase64(String text) {
    return base64Encode(utf8.encode(text));
  }

  /// Converts base64 to string
  static String fromBase64(String base64Text) {
    try {
      return utf8.decode(base64Decode(base64Text));
    } catch (e) {
      return '';
    }
  }
}
