import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

import 'image_processing_service.dart';

class HealthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'health-documents';

  /// Upload a health document file to Supabase storage and save metadata to database
  static Future<Map<String, dynamic>> uploadDocument({
    required String studentId,
    required String categoryKey,
    required PlatformFile file,
    Uint8List? fileBytes,
    bool enableCompression = true,
  }) async {
    try {
      // Validate file
      if (file.size > 50 * 1024 * 1024) {
        throw Exception('File size exceeds 50 MB limit');
      }

      // Get file extension
      final fileExtension = file.extension ?? 'unknown';

      // Get category configuration
      final categoryConfig = await getCategoryConfig(categoryKey);
      final maxSizeMb = categoryConfig['max_file_size_mb'] ?? 50;

      if (file.size > maxSizeMb * 1024 * 1024) {
        throw Exception('File size exceeds category limit of $maxSizeMb MB');
      }

      // Process file based on type
      Uint8List finalBytes;
      int finalSize = file.size;
      double compressionRatio = 0.0;

      // Get file bytes
      final originalBytes = fileBytes ?? file.bytes;
      if (originalBytes == null) {
        throw Exception('Could not read file data');
      }

      if (enableCompression) {
        final compressionResult =
            await ImageProcessingService.optimizeForUpload(file);

        if (compressionResult['success']) {
          finalBytes = compressionResult['compressed_bytes'];
          finalSize = compressionResult['compressed_size'];
          final ratioValue = compressionResult['compression_ratio'];
          if (ratioValue != null) {
            compressionRatio = double.parse(ratioValue.toString());
          }

          if (kDebugMode) {
            print('File optimized: $compressionRatio% reduction');
          }
        } else {
          // Use original if compression fails
          finalBytes = originalBytes;
        }
      } else {
        // Use original file for non-images or when compression disabled
        finalBytes = originalBytes;
      }

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName =
          '${studentId}_${categoryKey}_$timestamp.$fileExtension';
      final filePath = '$studentId/$uniqueFileName';

      // Upload main file
      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            finalBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get a signed URL (bucket should be private)
      final signedUrl = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(filePath, 3600);

      // Get category info
      final category = await _supabase
          .from('health_document_categories')
          .select('id')
          .eq('category_key', categoryKey)
          .single();

      if (kDebugMode) {
        print('Found category for $categoryKey: ${category['id']}');
      }

      // Save document metadata to database
      final documentData = {
        'student_id': studentId,
        'category_id': category['id'],
        'file_name': uniqueFileName,
        'original_file_name': file.name,
        'file_path': filePath,
        'file_size_bytes': finalSize,
        'file_type': fileExtension,
        'mime_type': 'application/octet-stream', // Could be better detected
        'metadata': <String, dynamic>{},
      };

      if (kDebugMode) {
        print('Inserting health document data: $documentData');
      }

      await _supabase.from('student_health_documents').insert(documentData);

      if (kDebugMode) {
        print(
          'Health document inserted successfully for category: $categoryKey',
        );
      }

      return {'success': true, 'signed_url': signedUrl, 'file_path': filePath};
    } catch (e) {
      if (kDebugMode) {
        print('Health document upload error: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to upload document: ${e.toString()}',
      };
    }
  }

  /// Get health document categories from database
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final categories = await _supabase
          .from('health_document_categories')
          .select('*')
          .order('id', ascending: true);

      return List<Map<String, dynamic>>.from(categories);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching health categories: $e');
      }
      return [];
    }
  }

  /// Get configuration for a specific category
  static Future<Map<String, dynamic>> getCategoryConfig(
    String categoryKey,
  ) async {
    try {
      final category = await _supabase
          .from('health_document_categories')
          .select('*')
          .eq('category_key', categoryKey)
          .maybeSingle();

      if (category != null) {
        return category;
      } else {
        return {
          'category_key': categoryKey,
          'max_file_size_mb': 50,
          'is_required': false,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching category config for $categoryKey: $e');
      }
      return {
        'category_key': categoryKey,
        'max_file_size_mb': 50,
        'is_required': false,
      };
    }
  }

  /// Get health documents for a student
  static Future<List<Map<String, dynamic>>> getStudentDocuments(
    String studentId,
  ) async {
    try {
      final documents = await _supabase
          .from('student_health_documents')
          .select('''
            *,
            category:health_document_categories(*)
          ''')
          .eq('student_id', studentId)
          .order('uploaded_at', ascending: false);

      return List<Map<String, dynamic>>.from(documents);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching student health documents: $e');
      }
      return [];
    }
  }

  /// Delete a health document
  static Future<Map<String, dynamic>> deleteDocument(String documentId) async {
    try {
      final document = await _supabase
          .from('student_health_documents')
          .select('file_path')
          .eq('id', documentId)
          .single();

      if (document['file_path'] != null) {
        await _supabase.storage.from(_bucketName).remove([
          document['file_path'],
        ]);
      }

      await _supabase
          .from('student_health_documents')
          .delete()
          .eq('id', documentId);

      return {'success': true, 'message': 'Document deleted successfully'};
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting health document: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to delete document: ${e.toString()}',
      };
    }
  }
}
