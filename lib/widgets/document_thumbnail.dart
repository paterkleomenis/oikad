import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../services/document_service.dart';

/// Widget for displaying thumbnails of uploaded documents
/// Generates thumbnails on-demand without storing them
class DocumentThumbnail extends StatefulWidget {
  final String? documentId;
  final String? filePath;
  final String? fileName;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final BoxBorder? border;

  const DocumentThumbnail({
    Key? key,
    this.documentId,
    this.filePath,
    this.fileName,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.border,
  }) : assert(
         documentId != null || filePath != null,
         'Either documentId or filePath must be provided',
       ),
       super(key: key);

  @override
  State<DocumentThumbnail> createState() => _DocumentThumbnailState();
}

class _DocumentThumbnailState extends State<DocumentThumbnail> {
  Uint8List? _thumbnailBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(DocumentThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentId != widget.documentId ||
        oldWidget.filePath != widget.filePath) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _thumbnailBytes = null;
    });

    try {
      // Check if it's an image file that can have thumbnails
      final fileName = widget.fileName ?? '';
      if (!DocumentService.canGenerateThumbnail(fileName)) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        return;
      }

      Uint8List? thumbnailBytes;

      if (widget.documentId != null) {
        thumbnailBytes = await DocumentService.getDocumentThumbnail(
          widget.documentId!,
        );
      } else if (widget.filePath != null) {
        thumbnailBytes = await DocumentService.getThumbnailByPath(
          widget.filePath!,
        );
      }

      if (mounted) {
        setState(() {
          _thumbnailBytes = thumbnailBytes;
          _isLoading = false;
          _hasError = thumbnailBytes == null;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading thumbnail: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Widget _buildFileIcon() {
    final fileName = widget.fileName ?? '';
    final extension = fileName.toLowerCase().split('.').last;

    IconData iconData;
    Color iconColor;

    switch (extension) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        iconData = Icons.image;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Icon(iconData, size: widget.width * 0.6, color: iconColor);
  }

  Widget _buildContent() {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: widget.borderRadius,
              border: widget.border,
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
    }

    if (_hasError || _thumbnailBytes == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: widget.borderRadius,
              border: widget.border,
            ),
            child: Center(child: _buildFileIcon()),
          );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: widget.border,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Image.memory(
          _thumbnailBytes!,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade100,
              child: Center(child: _buildFileIcon()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }
}

/// Simple document thumbnail for list items
class SimpleDocumentThumbnail extends StatelessWidget {
  final String? documentId;
  final String? filePath;
  final String? fileName;
  final double size;

  const SimpleDocumentThumbnail({
    Key? key,
    this.documentId,
    this.filePath,
    this.fileName,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DocumentThumbnail(
      documentId: documentId,
      filePath: filePath,
      fileName: fileName,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.grey.shade300),
    );
  }
}

/// Document thumbnail with loading indicator overlay
class DocumentThumbnailWithOverlay extends StatelessWidget {
  final String? documentId;
  final String? filePath;
  final String? fileName;
  final double size;
  final VoidCallback? onTap;

  const DocumentThumbnailWithOverlay({
    Key? key,
    this.documentId,
    this.filePath,
    this.fileName,
    this.size = 80,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DocumentThumbnail(
          documentId: documentId,
          filePath: filePath,
          fileName: fileName,
          width: size,
          height: size,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
