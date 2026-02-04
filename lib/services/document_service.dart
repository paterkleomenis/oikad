import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'image_processing_service.dart';

class DocumentService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'student-documents';

  /// Upload a document file to Supabase storage and save metadata to database
  static Future<Map<String, dynamic>> uploadDocument({
    required String studentId,
    required String categoryKey,
    required PlatformFile file,
    Uint8List? fileBytes,
    bool enableCompression = true,
    bool generateThumbnail = false, // This parameter is ignored now
  }) async {
    try {
      // Validate file
      if (file.size > 50 * 1024 * 1024) {
        throw Exception('File size exceeds 50 MB limit');
      }

      // Get file extension
      final fileExtension = file.extension ?? 'unknown';

      // Get category configuration
      final categoryConfig = await getDocumentCategoryConfig(categoryKey);
      final maxSizeMb = categoryConfig['max_size_mb'] ?? 50;

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
        // Compress/optimize images (PDFs currently return original bytes)
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
      final filePath = 'documents/$studentId/$uniqueFileName';

      // Upload main file ONLY - no thumbnails
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
      // Look up category ID
      final category = await _supabase
          .from('document_categories')
          .select('id')
          .eq('category_key', categoryKey)
          .single();

      if (kDebugMode) {
        print('Found category for $categoryKey: ${category['id']}');
      }

      // Save document metadata to database WITHOUT any thumbnail data
      final documentData = {
        'student_id': studentId,
        'category_id': category['id'],
        'file_name': uniqueFileName,
        'original_file_name': file.name,
        'file_path': filePath,
        'file_size_bytes': finalSize,
        'file_type': fileExtension,
        'mime_type': 'application/octet-stream',
        'compressed_size_bytes': finalSize,
        'compression_ratio': compressionRatio,
        'metadata': <String, dynamic>{},
      };

      if (kDebugMode) {
        print('Inserting document data: $documentData');
      }

      // Simple insert without trying to return data
      await _supabase.from('student_documents').insert(documentData);

      if (kDebugMode) {
        print('Document inserted successfully for category: $categoryKey');
      }

      return {
        'success': true,
        'document_id': null,
        'signed_url': signedUrl,
        'file_path': filePath,
        'compression_ratio': compressionRatio,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Document upload error: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to upload document: ${e.toString()}',
      };
    }
  }

  /// Get document categories from database
  static Future<List<Map<String, dynamic>>> getDocumentCategories() async {
    try {
      final categories = await _supabase
          .from('document_categories')
          .select('*')
          .order('id', ascending: true);

      return List<Map<String, dynamic>>.from(categories);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching document categories: $e');
      }
      return [];
    }
  }

  /// Get configuration for a specific document category
  static Future<Map<String, dynamic>> getDocumentCategoryConfig(
    String categoryKey,
  ) async {
    try {
      final category = await _supabase
          .from('document_categories')
          .select('*')
          .eq('category_key', categoryKey)
          .maybeSingle();

      if (category != null) {
        return category;
      } else {
        // Return default configuration
        return {
          'category_key': categoryKey,
          'max_size_mb': 50,
          'allowed_types': ['pdf', 'jpg', 'jpeg', 'png'],
          'is_required': false,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching category config for $categoryKey: $e');
      }
      // Return default configuration
      return {
        'category_key': categoryKey,
        'max_size_mb': 50,
        'allowed_types': ['pdf', 'jpg', 'jpeg', 'png'],
        'is_required': false,
      };
    }
  }

  /// Get document submission for a student
  static Future<Map<String, dynamic>?> getDocumentSubmission(
    String studentId,
  ) async {
    try {
      final documents = await _supabase
          .from('student_documents')
          .select('*')
          .eq('student_id', studentId)
          .limit(1)
          .maybeSingle();

      return documents;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching student documents: $e');
      }
      return null;
    }
  }

  /// Get documents for a student
  static Future<List<Map<String, dynamic>>> getStudentDocuments(
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

  /// Get thumbnail URL for a document (deprecated - use getThumbnailByPath instead)
  static Future<String> getThumbnailUrl(String filePath) async {
    try {
      final thumbnailBytes = await getThumbnailByPath(filePath);
      if (thumbnailBytes != null) {
        // Return a data URL for the thumbnail
        return 'data:image/jpeg;base64,${base64Encode(thumbnailBytes)}';
      }
      return '';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting thumbnail URL: $e');
      }
      return '';
    }
  }

  /// Delete a document from storage and database
  static Future<Map<String, dynamic>> deleteDocument(String documentId) async {
    try {
      // Get document info first
      final document = await _supabase
          .from('student_documents')
          .select('file_path')
          .eq('id', documentId)
          .single();

      // Delete file from storage
      if (document['file_path'] != null) {
        await _supabase.storage.from(_bucketName).remove([
          document['file_path'],
        ]);
      }

      // No need to delete thumbnails - they're generated on-demand

      // Delete document record from database
      await _supabase.from('student_documents').delete().eq('id', documentId);

      return {'success': true, 'message': 'Document deleted successfully'};
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting document: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to delete document: ${e.toString()}',
      };
    }
  }

  /// Update document metadata
  static Future<Map<String, dynamic>> updateDocumentMetadata({
    required String documentId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = {
        'updated_at': DateTime.now().toIso8601String(),
        if (metadata != null) ...metadata,
      };

      await _supabase
          .from('student_documents')
          .update(updateData)
          .eq('id', documentId);

      return {
        'success': true,
        'message': 'Document metadata updated successfully',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error updating document metadata: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to update document: ${e.toString()}',
      };
    }
  }

  /// Get document statistics for a student
  static Future<Map<String, dynamic>> getDocumentStatistics(
    String studentId,
  ) async {
    try {
      final documents = await _supabase
          .from('student_documents')
          .select('file_size, category_key')
          .eq('student_id', studentId);

      final totalDocuments = documents.length;
      final totalSizeBytes = documents.fold<int>(
        0,
        (sum, doc) => sum + (doc['file_size'] as int? ?? 0),
      );

      final categoryCount = <String, int>{};
      for (final doc in documents) {
        final category = doc['category_key'] as String?;
        if (category != null) {
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }
      }

      return {
        'total_documents': totalDocuments,
        'total_size_bytes': totalSizeBytes,
        'total_size_mb': (totalSizeBytes / (1024 * 1024)).toStringAsFixed(2),
        'category_breakdown': categoryCount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting document statistics: $e');
      }
      return {
        'total_documents': 0,
        'total_size_bytes': 0,
        'total_size_mb': '0.00',
        'category_breakdown': <String, int>{},
      };
    }
  }

  /// Generate thumbnail from stored document for display purposes only
  static Future<Uint8List?> generateThumbnailFromUrl(String fileUrl) async {
    try {
      // Download the file
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Create a temporary PlatformFile for thumbnail generation
        final tempFile = PlatformFile(
          name: 'temp.jpg',
          size: bytes.length,
          bytes: bytes,
        );

        // Generate thumbnail
        final thumbnailResult = await ImageProcessingService.generateThumbnail(
          file: tempFile,
          thumbnailSize: 200,
          quality: 70,
        );

        if (thumbnailResult['success']) {
          return thumbnailResult['thumbnail_bytes'] as Uint8List;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating thumbnail: $e');
      }
      return null;
    }
  }

  /// Get thumbnail for a document (generates on-demand)
  static Future<Uint8List?> getDocumentThumbnail(String documentId) async {
    try {
      // Get document info
      final document = await _supabase
          .from('student_documents')
          .select('file_path')
          .eq('id', documentId)
          .single();

      if (document['file_path'] != null) {
        final fileUrl = await _supabase.storage
            .from(_bucketName)
            .createSignedUrl(document['file_path'], 3600);

        return await generateThumbnailFromUrl(fileUrl);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting document thumbnail: $e');
      }
      return null;
    }
  }

  /// Get thumbnail for a document by file path
  static Future<Uint8List?> getThumbnailByPath(String filePath) async {
    try {
      final fileUrl = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(filePath, 3600);

      return await generateThumbnailFromUrl(fileUrl);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting thumbnail by path: $e');
      }
      return null;
    }
  }

  /// Check if a file is an image that can have thumbnails
  static bool canGenerateThumbnail(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }
}
