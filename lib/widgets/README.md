# Document Thumbnail System

This directory contains widgets for displaying document thumbnails that are generated on-demand without storing them in the database.

## Overview

The new thumbnail system:
- ✅ **Generates thumbnails on-demand** when needed for display
- ✅ **Doesn't store thumbnails** in Supabase Storage (saves space)
- ✅ **Caches thumbnails in memory** for better performance
- ✅ **Shows appropriate file icons** for non-image files
- ✅ **Handles loading and error states** gracefully

## Widgets Available

### 1. `DocumentThumbnail`
Main widget for displaying document thumbnails with full customization options.

### 2. `SimpleDocumentThumbnail`
Quick thumbnail widget for list items and simple displays.

### 3. `DocumentThumbnailWithOverlay`
Thumbnail with shadow and overlay effects, good for cards and detailed views.

## Usage Examples

### Basic Usage in a List

```dart
import 'package:oikad/widgets/document_thumbnail.dart';

// In your widget build method:
ListView.builder(
  itemCount: documents.length,
  itemBuilder: (context, index) {
    final doc = documents[index];
    return ListTile(
      leading: SimpleDocumentThumbnail(
        documentId: doc['id'],
        fileName: doc['original_file_name'],
        size: 40,
      ),
      title: Text(doc['original_file_name']),
      subtitle: Text('${(doc['file_size_bytes'] / 1024).round()} KB'),
    );
  },
)
```

### Custom Thumbnail with Border

```dart
DocumentThumbnail(
  documentId: documentId,
  fileName: fileName,
  width: 80,
  height: 80,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Colors.blue, width: 2),
  placeholder: Container(
    color: Colors.grey.shade200,
    child: const Icon(Icons.downloading),
  ),
)
```

### Thumbnail Grid View

```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  ),
  itemCount: documents.length,
  itemBuilder: (context, index) {
    final doc = documents[index];
    return DocumentThumbnailWithOverlay(
      documentId: doc['id'],
      fileName: doc['original_file_name'],
      size: 100,
      onTap: () => _viewDocument(doc),
    );
  },
)
```

### Admin Dashboard View

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        DocumentThumbnail(
          filePath: document['file_path'],
          fileName: document['original_file_name'],
          width: 60,
          height: 60,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document['original_file_name'],
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Uploaded: ${document['uploaded_at']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  ),
)
```

## Migration from Old System

If you were previously using stored thumbnails, here's how to migrate:

### Before (with stored thumbnails):
```dart
// Old way - using stored thumbnail_path
Image.network(
  supabase.storage.from('student-documents').getPublicUrl(thumbnailPath),
  width: 40,
  height: 40,
)
```

### After (with on-demand thumbnails):
```dart
// New way - generates thumbnail on-demand
SimpleDocumentThumbnail(
  documentId: documentId,
  fileName: fileName,
  size: 40,
)
```

## Database Cleanup

After implementing the new system, run this SQL script to clean up:

```sql
-- Remove thumbnail storage columns (run in Supabase SQL Editor)
ALTER TABLE student_documents DROP COLUMN IF EXISTS thumbnail_path;
ALTER TABLE student_documents DROP COLUMN IF EXISTS thumbnail_size_bytes;

-- Optional: Delete existing thumbnail files from storage
-- DELETE FROM storage.objects WHERE bucket_id = 'student-documents' AND name LIKE '%thumbnail%';
```

## Performance Tips

1. **Use SimpleDocumentThumbnail for lists** - it's optimized for small sizes
2. **Avoid generating thumbnails for large lists** - implement pagination
3. **The widget automatically caches thumbnails** in memory during the session
4. **Non-image files show appropriate icons** instead of generating thumbnails

## File Type Support

### Image Files (Generate Thumbnails):
- JPG, JPEG, PNG, GIF, BMP, WEBP

### Non-Image Files (Show Icons):
- PDF → Red PDF icon
- DOC/DOCX → Blue document icon  
- Other → Gray file icon

## Error Handling

The thumbnail widgets handle these scenarios gracefully:
- **Network errors** → Shows file icon
- **Invalid image data** → Shows file icon  
- **Missing files** → Shows file icon
- **Loading state** → Shows loading spinner

## Customization Options

All widgets support:
- Custom width/height
- Border radius and borders
- Custom placeholder widgets
- Custom error widgets
- Different BoxFit options
- Loading indicators

This system provides better performance, saves storage space, and maintains a clean user experience!