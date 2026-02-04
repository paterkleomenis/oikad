import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

class ImageProcessingService {
  /// Compress an image file to reduce size
  static Future<Map<String, dynamic>> compressImage({
    required PlatformFile file,
    int quality = 75,
    int maxWidth = 1920,
    int maxHeight = 1920,
  }) async {
    try {
      if (!isImageFile(file)) {
        return {
          'success': false,
          'error': 'File is not an image',
          'message': 'Only image files can be compressed',
        };
      }

      final originalSize = file.size;
      final bytes = file.bytes;

      if (bytes == null) {
        return {
          'success': false,
          'error': 'File bytes not available',
          'message': 'Cannot access file data for compression',
        };
      }

      if (kDebugMode) {
        print('Compressing image: ${file.name}');
        print('Original size: $originalSize bytes');
      }

      // Use flutter_image_compress for compression
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      final compressedSize = compressedBytes.length;
      final compressionRatio =
          ((originalSize - compressedSize) / originalSize * 100)
              .toStringAsFixed(1);

      if (kDebugMode) {
        print('Compressed size: $compressedSize bytes');
        print('Compression ratio: $compressionRatio%');
      }

      return {
        'success': true,
        'compressed_bytes': compressedBytes,
        'original_size': originalSize,
        'compressed_size': compressedSize,
        'compression_ratio': compressionRatio,
        'file_name': _getCompressedFileName(file.name),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Image compression error: $e');
      }

      // Fallback to original file if compression fails
      return {
        'success': true,
        'compressed_bytes': file.bytes,
        'original_size': file.size,
        'compressed_size': file.size,
        'compression_ratio': '0.0',
        'file_name': file.name,
        'message': 'Compression failed, using original file: ${e.toString()}',
      };
    }
  }

  /// Generate thumbnail from image
  static Future<Map<String, dynamic>> generateThumbnail({
    required PlatformFile file,
    int thumbnailSize = 200,
    int quality = 70,
  }) async {
    try {
      if (!isImageFile(file)) {
        return {
          'success': false,
          'error': 'File is not an image',
          'message': 'Only image files can have thumbnails generated',
        };
      }

      final bytes = file.bytes;

      if (bytes == null) {
        return {
          'success': false,
          'error': 'File bytes not available',
          'message': 'Cannot access file data for thumbnail generation',
        };
      }

      if (kDebugMode) {
        print('Generating thumbnail for: ${file.name}');
        print('Target size: ${thumbnailSize}px');
      }

      // Decode the image
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        return {
          'success': false,
          'error': 'Invalid image format',
          'message': 'Cannot decode image for thumbnail generation',
        };
      }

      // Resize the image to create thumbnail
      final thumbnail = img.copyResize(
        originalImage,
        width: thumbnailSize,
        height: thumbnailSize,
        interpolation: img.Interpolation.cubic,
      );

      // Encode the thumbnail as JPEG
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: quality);

      if (kDebugMode) {
        print('Thumbnail generated: ${thumbnailBytes.length} bytes');
      }

      return {
        'success': true,
        'thumbnail_bytes': Uint8List.fromList(thumbnailBytes),
        'thumbnail_size': thumbnailBytes.length,
        'file_name': _getThumbnailFileName(file.name),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Thumbnail generation error: $e');
      }

      // Fallback: use compressed version of original as thumbnail
      try {
        final compressedResult = await compressImage(
          file: file,
          quality: quality,
          maxWidth: thumbnailSize,
          maxHeight: thumbnailSize,
        );

        if (compressedResult['success']) {
          return {
            'success': true,
            'thumbnail_bytes': compressedResult['compressed_bytes'],
            'thumbnail_size': compressedResult['compressed_size'],
            'file_name': _getThumbnailFileName(file.name),
            'message': 'Generated thumbnail using compression fallback',
          };
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('Thumbnail fallback error: $fallbackError');
        }
      }

      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to generate thumbnail: ${e.toString()}',
      };
    }
  }

  /// Check if file is an image
  static bool isImageFile(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  /// Check if file is a PDF
  static bool isPdfFile(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    return extension == 'pdf';
  }

  /// Get compressed file name
  static String _getCompressedFileName(String originalName) {
    final nameWithoutExt = _getFileNameWithoutExtension(originalName);
    return '${nameWithoutExt}_compressed.jpg';
  }

  /// Get thumbnail file name
  static String _getThumbnailFileName(String originalName) {
    final nameWithoutExt = _getFileNameWithoutExtension(originalName);
    return '${nameWithoutExt}_thumb.jpg';
  }

  /// Get file name without extension
  static String _getFileNameWithoutExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    return lastDot != -1 ? fileName.substring(0, lastDot) : fileName;
  }

  /// Compress PDF (placeholder for future implementation)
  static Future<Map<String, dynamic>> compressPdf(PlatformFile file) async {
    try {
      if (!isPdfFile(file)) {
        return {
          'success': false,
          'error': 'File is not a PDF',
          'message': 'Only PDF files can be compressed with this method',
        };
      }

      // For now, return original file
      // TODO: Implement PDF compression using a suitable package
      return {
        'success': true,
        'compressed_bytes': file.bytes,
        'original_size': file.size,
        'compressed_size': file.size,
        'compression_ratio': '0.0',
        'file_name': file.name,
        'message':
            'PDF compression not implemented yet - returning original file',
      };
    } catch (e) {
      if (kDebugMode) {
        print('PDF compression error: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to process PDF: ${e.toString()}',
      };
    }
  }

  /// Get optimized file size for upload
  static Future<Map<String, dynamic>> optimizeForUpload(
    PlatformFile file,
  ) async {
    try {
      if (isImageFile(file)) {
        // Compress images
        return await compressImage(
          file: file,
          quality: 75,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } else if (isPdfFile(file)) {
        // For PDFs, just return the original for now
        return await compressPdf(file);
      } else {
        // For other files, return as is
        return {
          'success': true,
          'compressed_bytes': file.bytes,
          'original_size': file.size,
          'compressed_size': file.size,
          'compression_ratio': '0.0',
          'file_name': file.name,
          'message': 'File type does not require compression',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('File optimization error: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to optimize file: ${e.toString()}',
      };
    }
  }

  /// Validate file for upload
  static Map<String, dynamic> validateFileForUpload(PlatformFile file) {
    const maxSizeInBytes = 50 * 1024 * 1024; // 50MB
    const allowedExtensions = [
      'jpg',
      'jpeg',
      'png',
      'pdf',
      'gif',
      'bmp',
      'webp',
    ];

    final extension = file.extension?.toLowerCase();

    if (extension == null || !allowedExtensions.contains(extension)) {
      return {
        'valid': false,
        'error': 'Invalid file type',
        'message':
            'Only image files (JPG, PNG, GIF, BMP, WebP) and PDF files are allowed',
      };
    }

    if (file.size > maxSizeInBytes) {
      return {
        'valid': false,
        'error': 'File too large',
        'message': 'File size must be less than 50MB',
      };
    }

    return {'valid': true, 'message': 'File is valid for upload'};
  }
}
