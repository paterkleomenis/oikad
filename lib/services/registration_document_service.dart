import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'document_service.dart';

class RegistrationDocumentService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Register student with documents
  static Future<Map<String, dynamic>> registerStudentWithDocuments({
    required Map<String, dynamic> studentData,
    List<Map<String, dynamic>>? documents,
    required Map<String, dynamic> consentData,
  }) async {
    try {
      // Remove any existing id from studentData
      studentData.remove('id');

      // Insert student record (Supabase will generate UUID)
      final studentResponse = await _supabase
          .from('dormitory_students')
          .insert(studentData)
          .select()
          .single();

      final studentId = studentResponse['id'];

      if (kDebugMode) {
        print('Student registered successfully: $studentId');
      }

      // Upload documents if provided
      List<Map<String, dynamic>> uploadResults = [];
      if (documents != null && documents.isNotEmpty) {
        for (final doc in documents) {
          if (doc['file'] != null) {
            final uploadResult = await DocumentService.uploadDocument(
              studentId: studentId,
              categoryKey: doc['categoryKey'],
              file: doc['file'],
              fileBytes: doc['fileBytes'],
            );

            uploadResults.add({
              'category': doc['categoryKey'],
              'result': uploadResult,
            });
          }
        }
      }

      // Documents are uploaded individually, no submission tracking needed

      return {
        'success': true,
        'student_id': studentId,
        'message': 'Registration completed successfully',
        'upload_results': uploadResults,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }

      return {
        'success': false,
        'error': 'registration_error',
        'message': 'Failed to complete registration. Please try again.',
      };
    }
  }

  /// Link uploaded documents to registered student
  static Future<Map<String, dynamic>> linkDocumentsToStudent({
    required String oldUserId,
    required String newStudentId,
  }) async {
    try {
      // Update document records to link to the new student
      await _supabase
          .from('student_documents')
          .update({'student_id': newStudentId})
          .eq('student_id', oldUserId);

      // Update document records
      await _supabase
          .from('student_documents')
          .update({'student_id': newStudentId})
          .eq('student_id', oldUserId);

      return {'success': true, 'message': 'Documents linked successfully'};
    } catch (e) {
      if (kDebugMode) {
        print('Document linking error: $e');
      }

      return {
        'success': false,
        'error': 'linking_error',
        'message': 'Failed to link documents to registration',
      };
    }
  }

  /// Get student documents with thumbnails for verification
  static Future<List<Map<String, dynamic>>> getStudentDocumentsWithThumbnails(
    String studentId,
  ) async {
    try {
      final documents = await _supabase
          .from('student_documents')
          .select('''
            *,
            category:document_categories(*)
          ''')
          .eq('student_id', studentId)
          .order('uploaded_at', ascending: false);

      return List<Map<String, dynamic>>.from(documents);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching student documents: $e');
      }
      return [];
    }
  }

  /// Get registration summary with document status
  static Future<Map<String, dynamic>> getRegistrationSummary(
    String studentId,
  ) async {
    try {
      // Get student info
      final student = await _supabase
          .from('dormitory_students')
          .select('*')
          .eq('id', studentId)
          .single();

      // Get document summary
      final documents = await getStudentDocumentsWithThumbnails(studentId);

      // Get document categories for completion check
      final categories = await DocumentService.getDocumentCategories();
      final requiredCategories = categories
          .where((cat) => cat['is_required'] == true)
          .toList();

      // Check completion status
      final uploadedCategoryKeys = documents
          .map((doc) => doc['category']['category_key'])
          .toSet();
      final requiredCategoryKeys = requiredCategories
          .map((cat) => cat['category_key'])
          .toSet();
      final missingCategories = requiredCategoryKeys.difference(
        uploadedCategoryKeys,
      );

      return {
        'student': student,
        'documents': documents,
        'required_categories': requiredCategories,
        'uploaded_categories': uploadedCategoryKeys.toList(),
        'missing_categories': missingCategories.toList(),
        'is_complete': missingCategories.isEmpty,
        'completion_percentage': requiredCategories.isEmpty
            ? 100
            : ((uploadedCategoryKeys.length / requiredCategories.length) * 100)
                  .round(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting registration summary: $e');
      }

      return {
        'error': 'Failed to get registration summary',
        'is_complete': false,
        'completion_percentage': 0,
      };
    }
  }

  /// Generate verification token for document upload session
  static String generateVerificationToken({
    required Map<String, dynamic> verificationData,
  }) {
    try {
      // Create deterministic hash from verification data
      final dataString = json.encode(verificationData);
      final bytes = utf8.encode(dataString + DateTime.now().toString());
      final digest = sha256.convert(bytes);

      return digest.toString().substring(0, 32); // First 32 characters
    } catch (e) {
      if (kDebugMode) {
        print('Error generating verification token: $e');
      }
      // Fallback to timestamp-based token
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// Create verification session for linking documents to registration
  static Future<Map<String, dynamic>> createVerificationSession({
    required Map<String, dynamic> verificationData,
    required List<PlatformFile> uploadedFiles,
  }) async {
    try {
      final token = generateVerificationToken(
        verificationData: verificationData,
      );

      // Store verification data in database for later matching
      await _supabase.from('document_verification_sessions').insert({
        'verification_token': token,
        'partial_name': verificationData['partial_name'],
        'partial_family_name': verificationData['partial_family_name'],
        'partial_email': verificationData['partial_email'],
        'partial_phone': verificationData['partial_phone'],
        'partial_id_card': verificationData['partial_id_card'],
        'partial_birth_date': verificationData['partial_birth_date'],
        'status': 'pending_registration',
        'metadata': json.encode({
          'uploaded_files_count': uploadedFiles.length,
          'verification_method': 'partial_data_match',
        }),
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'verification_token': token,
        'message': 'Verification session created',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error creating verification session: $e');
      }

      return {
        'success': false,
        'error': 'verification_session_error',
        'message': 'Failed to create verification session',
      };
    }
  }

  /// Verify and link documents using verification token
  static Future<Map<String, dynamic>> verifyAndLinkDocuments({
    required String verificationToken,
    required String studentId,
  }) async {
    try {
      // Get verification session
      final verificationSession = await _supabase
          .from('document_verification_sessions')
          .select('*')
          .eq('verification_token', verificationToken)
          .maybeSingle();

      if (verificationSession == null) {
        return {
          'success': false,
          'error': 'invalid_token',
          'message': 'Invalid or expired verification token',
        };
      }

      // Update document ownership
      await _supabase
          .from('student_documents')
          .update({'student_id': studentId})
          .eq('verification_token', verificationToken);

      // Update document ownership
      await _supabase
          .from('student_documents')
          .update({'student_id': studentId})
          .eq('verification_token', verificationToken);

      // Mark verification session as used
      await _supabase
          .from('document_verification_sessions')
          .update({
            'linked_at': DateTime.now().toIso8601String(),
            'linked_student_id': studentId,
            'status': 'completed',
          })
          .eq('verification_token', verificationToken);

      return {
        'success': true,
        'message': 'Documents linked successfully to registration',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying and linking documents: $e');
      }

      return {
        'success': false,
        'error': 'verification_error',
        'message': 'Failed to verify and link documents',
      };
    }
  }

  /// Get pending verification sessions
  static Future<List<Map<String, dynamic>>>
  getPendingVerificationSessions() async {
    try {
      final sessions = await _supabase
          .from('document_verification_sessions')
          .select('*')
          .eq('status', 'pending_registration')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(sessions);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching pending verification sessions: $e');
      }
      return [];
    }
  }

  /// Check if student has completed their registration
  static Future<bool> isRegistrationComplete(String studentId) async {
    try {
      // Get student record
      final student = await _supabase
          .from('dormitory_students')
          .select('application_status')
          .eq('id', studentId)
          .maybeSingle();

      if (student == null) return false;

      // Check if application is submitted or further along
      final status = student['application_status'] as String?;
      return status != null &&
          status != 'draft' &&
          ['submitted', 'under_review', 'approved'].contains(status);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking registration completion: $e');
      }
      return false;
    }
  }

  /// Get student by auth user ID
  static Future<Map<String, dynamic>?> getStudentByAuthUserId(
    String authUserId,
  ) async {
    try {
      final student = await _supabase
          .from('dormitory_students')
          .select('*')
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      return student;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching student by auth user ID: $e');
      }
      return null;
    }
  }

  /// Update registration status
  static Future<Map<String, dynamic>> updateRegistrationStatus({
    required String studentId,
    required String status,
    String? notes,
  }) async {
    try {
      final updateData = {
        'application_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _supabase
          .from('dormitory_students')
          .update(updateData)
          .eq('id', studentId);

      return {
        'success': true,
        'message': 'Registration status updated successfully',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error updating registration status: $e');
      }

      return {
        'success': false,
        'error': 'update_error',
        'message': 'Failed to update registration status',
      };
    }
  }
}
