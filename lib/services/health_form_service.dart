import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Υγειονομικά στοιχεία φοιτητή (ηλεκτρονική φόρμα stoixia.docx).
class HealthFormService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  static const List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  /// Σταθερή λίστα παθήσεων (οι 5 γνωστές από το docx + συμπλήρωση).
  static const List<String> conditionOptions = [
    'lactose', // Ευαισθησία στη λακτόζη
    'enzymes', // Έλλειψη ενζύμων
    'diabetes', // Διαβήτης
    'asthma', // Άσθμα
    'heart', // Καρδιακή πάθηση
    'epilepsy', // Επιληψία
    'allergy', // Αλλεργίες
    'other', // Άλλο
  ];

  static Future<Map<String, dynamic>?> getForm(String studentId) async {
    try {
      final row = await _supabase
          .from('student_health_forms')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();
      return row;
    } catch (e) {
      if (kDebugMode) print('Error loading health form: $e');
      return null;
    }
  }

  static Future<void> saveForm(
    String studentId,
    Map<String, dynamic> data,
  ) async {
    final payload = Map<String, dynamic>.from(data)
      ..['student_id'] = studentId
      ..['updated_at'] = DateTime.now().toIso8601String();

    final existing = await getForm(studentId);
    if (existing == null) {
      await _supabase.from('student_health_forms').insert(payload);
    } else {
      await _supabase
          .from('student_health_forms')
          .update(payload)
          .eq('student_id', studentId);
    }
  }
}
