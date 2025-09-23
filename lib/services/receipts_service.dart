import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReceiptsService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String bucketName = 'student-receipts';
  static const String receiptsFolder = 'receipts';

  /// Get all receipts for a student
  static Future<List<Map<String, dynamic>>> getStudentReceipts(
    String studentId, {
    int? month,
    int? year,
  }) async {
    try {
      var query = _supabase
          .from('student_receipts')
          .select('*')
          .eq('student_id', studentId);

      // Apply filters if provided
      if (month != null) {
        query = query.eq('concerns_month', month);
      }
      if (year != null) {
        query = query.eq('concerns_year', year);
      }

      final receipts = await query.order('uploaded_at', ascending: false);

      return List<Map<String, dynamic>>.from(receipts);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching student receipts: $e');
      }
      return [];
    }
  }

  /// Get available years for receipts
  static Future<List<int>> getAvailableYears(String studentId) async {
    try {
      final response = await _supabase
          .from('student_receipts')
          .select('concerns_year')
          .eq('student_id', studentId)
          .not('concerns_year', 'is', null);

      final years = response
          .map((receipt) => receipt['concerns_year'] as int?)
          .where((year) => year != null)
          .cast<int>()
          .toSet()
          .toList();

      years.sort((a, b) => b.compareTo(a)); // Descending order
      return years;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching available years: $e');
      }
      return [];
    }
  }

  /// Get available months for receipts in a specific year
  static Future<List<int>> getAvailableMonths(
    String studentId,
    int year,
  ) async {
    try {
      final response = await _supabase
          .from('student_receipts')
          .select('concerns_month')
          .eq('student_id', studentId)
          .eq('concerns_year', year)
          .not('concerns_month', 'is', null);

      final months = response
          .map((receipt) => receipt['concerns_month'] as int?)
          .where((month) => month != null)
          .cast<int>()
          .toSet()
          .toList();

      months.sort(); // Ascending order (1-12)
      return months;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching available months: $e');
      }
      return [];
    }
  }

  /// Download receipt file
  static Future<Uint8List?> downloadReceipt(String filePath) async {
    try {
      final bytes = await _supabase.storage.from(bucketName).download(filePath);

      return bytes;
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading receipt: $e');
      }
      return null;
    }
  }

  /// Get receipt statistics for a student
  static Future<Map<String, dynamic>> getReceiptStatistics(
    String studentId,
  ) async {
    try {
      final receipts = await _supabase
          .from('student_receipts')
          .select('file_size_bytes, concerns_year')
          .eq('student_id', studentId);

      final totalCount = receipts.length;
      final totalSize = receipts.fold<int>(
        0,
        (sum, receipt) => sum + (receipt['file_size_bytes'] as int? ?? 0),
      );

      final currentYear = DateTime.now().year;
      final currentYearCount = receipts
          .where((receipt) => receipt['concerns_year'] == currentYear)
          .length;

      return {
        'total_count': totalCount,
        'total_size_bytes': totalSize,
        'current_year_count': currentYearCount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting receipt statistics: $e');
      }
      return {'total_count': 0, 'total_size_bytes': 0, 'current_year_count': 0};
    }
  }

  /// Get month name from month number
  static String getMonthName(int month, String locale) {
    switch (locale) {
      case 'el':
        const months = [
          'Ιανουάριος',
          'Φεβρουάριος',
          'Μάρτιος',
          'Απρίλιος',
          'Μάιος',
          'Ιούνιος',
          'Ιούλιος',
          'Αύγουστος',
          'Σεπτέμβριος',
          'Οκτώβριος',
          'Νοέμβριος',
          'Δεκέμβριος',
        ];
        return months[month - 1];
      default:
        const months = [
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
        return months[month - 1];
    }
  }

  /// Format file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
