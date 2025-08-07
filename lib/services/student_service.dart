import '../models/student.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'students';

  /// Register a new student with complete information
  Future<String> registerStudentComplete(Student student) async {
    try {
      final response = await _client
          .from(_tableName)
          .insert(student.toMap())
          .select('id')
          .single();
      return response['id'].toString();
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Register a student with basic information (legacy method)
  Future<void> registerStudent(String name, String university) async {
    try {
      await _client.from(_tableName).insert({
        'name': name,
        'university': university,
      });
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Fetch all students
  Future<List<Student>> fetchStudents({
    int? limit,
    int? offset,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .order(orderBy ?? 'created_at', ascending: ascending)
          .limit(limit ?? 50)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 50) - 1);

      return (data as List).map((item) => Student.fromMap(item)).toList();
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Fetch a student by ID
  Future<Student?> fetchStudentById(String id) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      return data != null ? Student.fromMap(data) : null;
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Search students by name or email
  Future<List<Student>> searchStudents(String query) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .or(
            'name.ilike.%$query%,family_name.ilike.%$query%,email.ilike.%$query%',
          );

      return (data as List).map((item) => Student.fromMap(item)).toList();
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Update a student's information
  Future<void> updateStudent(String id, Student student) async {
    try {
      await _client.from(_tableName).update(student.toMap()).eq('id', id);
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Delete a student
  Future<void> deleteStudent(String id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Check if email already exists
  Future<bool> emailExists(String email) async {
    try {
      final data = await _client
          .from(_tableName)
          .select('id')
          .eq('email', email)
          .maybeSingle();

      return data != null;
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Check if tax number already exists
  Future<bool> taxNumberExists(String taxNumber) async {
    try {
      final data = await _client
          .from(_tableName)
          .select('id')
          .eq('tax_number', taxNumber)
          .maybeSingle();

      return data != null;
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Check if ID card number already exists
  Future<bool> idCardExists(String idCardNumber) async {
    try {
      final data = await _client
          .from(_tableName)
          .select('id')
          .eq('id_card_number', idCardNumber)
          .maybeSingle();

      return data != null;
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Get statistics about students
  Future<Map<String, dynamic>> getStudentStatistics() async {
    try {
      final allData = await _client
          .from(_tableName)
          .select('university, department');

      final universities = Set<String>.from(
        (allData as List)
            .where((item) => item['university'] != null)
            .map((item) => item['university'].toString()),
      );

      final departments = Set<String>.from(
        (allData as List)
            .where((item) => item['department'] != null)
            .map((item) => item['department'].toString()),
      );

      return {
        'totalStudents': allData.length,
        'totalUniversities': universities.length,
        'totalDepartments': departments.length,
        'universities': universities.toList(),
        'departments': departments.toList(),
      };
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Fetch students by university
  Future<List<Student>> fetchStudentsByUniversity(String university) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .eq('university', university)
          .order('family_name');

      return (data as List).map((item) => Student.fromMap(item)).toList();
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Fetch students by department
  Future<List<Student>> fetchStudentsByDepartment(String department) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .eq('department', department)
          .order('family_name');

      return (data as List).map((item) => Student.fromMap(item)).toList();
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Validate student data before registration
  Future<Map<String, String>> validateStudentData(Student student) async {
    final errors = <String, String>{};

    // Check for duplicate email
    if (student.email?.isNotEmpty == true) {
      final emailExistsResult = await emailExists(student.email!);
      if (emailExistsResult) {
        errors['email'] = 'This email is already registered';
      }
    }

    // Check for duplicate tax number
    if (student.taxNumber?.isNotEmpty == true) {
      final taxNumberExistsResult = await taxNumberExists(student.taxNumber!);
      if (taxNumberExistsResult) {
        errors['tax_number'] = 'This tax number is already registered';
      }
    }

    // Check for duplicate ID card
    if (student.idCardNumber?.isNotEmpty == true) {
      final idCardExistsResult = await idCardExists(student.idCardNumber!);
      if (idCardExistsResult) {
        errors['id_card_number'] = 'This ID card number is already registered';
      }
    }

    return errors;
  }

  /// Handle errors and convert them to user-friendly messages
  Exception _handleError(dynamic error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505': // Unique constraint violation
          if (error.message.contains('email')) {
            return Exception('Email address is already registered');
          } else if (error.message.contains('tax_number')) {
            return Exception('Tax number is already registered');
          } else if (error.message.contains('id_card_number')) {
            return Exception('ID card number is already registered');
          }
          return Exception('This information is already registered');
        case '23502': // Not null constraint violation
          return Exception('Required field is missing');
        case '23514': // Check constraint violation
          return Exception('Invalid data format');
        default:
          return Exception('Database error: ${error.message}');
      }
    }

    if (error is AuthException) {
      return Exception('Authentication error: ${error.message}');
    }

    return Exception('Unexpected error occurred: ${error.toString()}');
  }

  /// Stream students for real-time updates
  Stream<List<Student>> streamStudents() {
    return _client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => Student.fromMap(item)).toList());
  }

  /// Batch operations
  Future<void> batchInsertStudents(List<Student> students) async {
    try {
      final studentMaps = students.map((student) => student.toMap()).toList();
      await _client.from(_tableName).insert(studentMaps);
    } catch (error) {
      throw _handleError(error);
    }
  }

  /// Export students data
  Future<List<Map<String, dynamic>>> exportStudentsData({
    String? university,
    String? department,
  }) async {
    try {
      var query = _client.from(_tableName).select();

      if (university != null) {
        query = query.eq('university', university);
      }

      if (department != null) {
        query = query.eq('department', department);
      }

      final data = await query.order('family_name');
      return List<Map<String, dynamic>>.from(data);
    } catch (error) {
      throw _handleError(error);
    }
  }
}
