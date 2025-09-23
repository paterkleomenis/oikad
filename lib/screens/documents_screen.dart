import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../notifiers.dart';
import '../services/localization_service.dart';
import '../services/document_service.dart';
import '../services/auth_service.dart';
import '../services/image_processing_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/debug_config.dart';
import '../services/text_utils.dart';
import 'welcome_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  // Document type selection
  String? _selectedDocumentType; // 'id' or 'passport'

  // File uploads
  PlatformFile? _studentPhoto;
  PlatformFile? _idFrontPhoto;
  PlatformFile? _passportPhoto;
  PlatformFile? _idBackPhoto;
  PlatformFile? _medicalCertificateFile;

  // Consent
  bool _consentAccepted = false;

  bool _isLoading = false;
  bool _isLoadingData = true;

  String t(String locale, String key) => LocalizationService.t(locale, key);

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _initializeData();
    _loadExistingDocuments();
  }

  Future<void> _checkAuthentication() async {
    if (!AuthService.isAuthenticated) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  Future<void> _initializeData() async {
    try {
      final categories = await DocumentService.getDocumentCategories();
      if (kDebugMode) {
        debugPrint('Loaded ${categories.length} document categories');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing documents screen: $e');
      }
    }
  }

  Future<void> _loadExistingDocuments() async {
    if (!AuthService.isAuthenticated) {
      setState(() {
        _isLoadingData = false;
      });
      return;
    }

    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User session expired. Please sign in again.'),
            ),
          );
          // AuthWrapper will automatically handle navigation when user becomes unauthenticated
        }
        setState(() {
          _isLoadingData = false;
        });
        return;
      }

      final studentId = currentUserId;

      // Load existing document submission
      final submission = await DocumentService.getDocumentSubmission(studentId);
      if (submission != null) {
        setState(() {
          _consentAccepted = submission['consent_accepted'] ?? false;
        });
      }

      // Debug: Check available categories
      if (kDebugMode) {
        final categories = await Supabase.instance.client
            .from('document_categories')
            .select('id, category_key');
        print('DEBUG: Available categories:');
        for (final cat in categories) {
          print('  - ${cat['category_key']}: ID ${cat['id']}');
        }
      }

      // Debug: Check all documents in database for this student
      if (kDebugMode) {
        final allDocs = await Supabase.instance.client
            .from('student_documents')
            .select('*')
            .eq('student_id', studentId);
        print('DEBUG: Found ${allDocs.length} total documents in database:');
        for (final doc in allDocs) {
          print(
            '  - File: ${doc['original_file_name']}, Category ID: ${doc['category_id']}, Path: ${doc['file_path']}',
          );
        }
      }

      // Load existing documents
      final existingDocuments = await DocumentService.getStudentDocuments(
        studentId,
      );

      if (kDebugMode) {
        print(
          'Loaded ${existingDocuments.length} existing documents with category join:',
        );
        for (final doc in existingDocuments) {
          print(
            'Document: ${doc['original_file_name']}, Category: ${doc['category']}',
          );
        }
      }

      // Create a map of category keys to document info for easier lookup
      final documentMap = <String, Map<String, dynamic>>{};
      for (final doc in existingDocuments) {
        final category = doc['category'] as Map<String, dynamic>?;
        if (category != null) {
          final categoryKey = category['category_key'] as String?;
          if (categoryKey != null) {
            documentMap[categoryKey] = doc;
            if (kDebugMode) {
              print(
                'Added to documentMap: $categoryKey -> ${doc['original_file_name']}',
              );
            }
          }
        }
      }

      // Restore UI state based on existing documents
      setState(() {
        // Check which documents exist and create placeholder PlatformFiles
        if (documentMap.containsKey('student_photo')) {
          final doc = documentMap['student_photo']!;
          _studentPhoto = PlatformFile(
            name: doc['original_file_name'] ?? 'student_photo',
            size: doc['file_size_bytes'] ?? 0,
            path: doc['file_path'],
          );
        }

        if (documentMap.containsKey('id_front')) {
          final doc = documentMap['id_front']!;
          _idFrontPhoto = PlatformFile(
            name: doc['original_file_name'] ?? 'id_front',
            size: doc['file_size_bytes'] ?? 0,
            path: doc['file_path'],
          );
          _selectedDocumentType = 'id';
        }

        if (documentMap.containsKey('id_back')) {
          final doc = documentMap['id_back']!;
          _idBackPhoto = PlatformFile(
            name: doc['original_file_name'] ?? 'id_back',
            size: doc['file_size_bytes'] ?? 0,
            path: doc['file_path'],
          );
          _selectedDocumentType = 'id';
        }

        if (documentMap.containsKey('passport')) {
          final doc = documentMap['passport']!;
          _passportPhoto = PlatformFile(
            name: doc['original_file_name'] ?? 'passport',
            size: doc['file_size_bytes'] ?? 0,
            path: doc['file_path'],
          );
          _selectedDocumentType = 'passport';
        }

        if (documentMap.containsKey('medical_certificate')) {
          final doc = documentMap['medical_certificate']!;
          _medicalCertificateFile = PlatformFile(
            name: doc['original_file_name'] ?? 'medical_certificate',
            size: doc['file_size_bytes'] ?? 0,
            path: doc['file_path'],
          );
        }
      });

      // Refresh completion status after loading documents
      if (mounted) {
        context.read<CompletionNotifier>().refreshCompletionStatus();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading existing documents: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final locale = context.read<LocaleNotifier>().locale;
    final url = t(locale, 'privacy_policy_link');

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error launching privacy policy URL: $e');
      }
    }
  }

  Future<void> _pickFile(String fileType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file
        final validation = ImageProcessingService.validateFileForUpload(file);
        if (!validation['valid']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(validation['message']),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        setState(() {
          switch (fileType) {
            case 'student_photo':
              _studentPhoto = file;
              break;
            case 'id_front':
              _idFrontPhoto = file;
              break;
            case 'passport':
              _passportPhoto = file;
              break;
            case 'id_back':
              _idBackPhoto = file;
              break;
            case 'medical_certificate':
              _medicalCertificateFile = file;
              break;
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking file: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveDocuments({bool isDraft = false}) async {
    final locale = context.read<LocaleNotifier>().locale;

    // For non-draft submissions, validate all required fields
    if (!isDraft) {
      if (!_consentAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(locale, 'consent_required')),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if student photo is uploaded
      if (_studentPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(locale, 'student_photo_required')),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if identity document is uploaded
      bool hasIdentityDocument = false;
      if (_selectedDocumentType == 'id') {
        hasIdentityDocument = _idFrontPhoto != null && _idBackPhoto != null;
        if (!hasIdentityDocument) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(locale, 'id_documents_required')),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      } else if (_selectedDocumentType == 'passport') {
        hasIdentityDocument = _passportPhoto != null;
        if (!hasIdentityDocument) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(locale, 'passport_required')),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      } else {
        // No document type selected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(locale, 'document_type_required')),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if medical certificate is uploaded
      if (_medicalCertificateFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(locale, 'medical_certificate_required')),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (!AuthService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User session expired. Please sign in again.');
      }

      final studentId = currentUserId;

      List<Map<String, dynamic>> uploadedFiles = [];

      // Upload student photo (only if it's a new file, not an existing one)
      if (_studentPhoto != null && _studentPhoto!.bytes != null) {
        final result = await DocumentService.uploadDocument(
          studentId: studentId,
          categoryKey: 'student_photo',
          file: _studentPhoto!,
        );
        uploadedFiles.add(result);
      }

      // Upload ID front photo (only if it's a new file, not an existing one)
      if (_idFrontPhoto != null && _idFrontPhoto!.bytes != null) {
        final result = await DocumentService.uploadDocument(
          studentId: studentId,
          categoryKey: 'id_front',
          file: _idFrontPhoto!,
        );
        uploadedFiles.add(result);
      }

      // Upload passport photo (only if it's a new file, not an existing one)
      if (_passportPhoto != null && _passportPhoto!.bytes != null) {
        final result = await DocumentService.uploadDocument(
          studentId: studentId,
          categoryKey: 'passport',
          file: _passportPhoto!,
        );
        uploadedFiles.add(result);
      }

      // Upload ID back photo (only if it's a new file, not an existing one)
      if (_idBackPhoto != null && _idBackPhoto!.bytes != null) {
        final result = await DocumentService.uploadDocument(
          studentId: studentId,
          categoryKey: 'id_back',
          file: _idBackPhoto!,
        );
        uploadedFiles.add(result);
      }

      // Upload medical certificate (only if it's a new file, not an existing one)
      if (_medicalCertificateFile != null &&
          _medicalCertificateFile!.bytes != null) {
        final result = await DocumentService.uploadDocument(
          studentId: studentId,
          categoryKey: 'medical_certificate',
          file: _medicalCertificateFile!,
        );
        uploadedFiles.add(result);
      }

      // Get category IDs for selected documents
      List<int> selectedCategoryIds = [];
      final categories = await DocumentService.getDocumentCategories();

      for (final category in categories) {
        final categoryKey = category['category_key'];
        bool isSelected = false;

        switch (categoryKey) {
          case 'student_photo':
            isSelected = _studentPhoto != null;
            break;
          case 'id_front':
          case 'passport':
          case 'id_back':
            isSelected = true; // Always allow upload
            break;
          case 'medical_certificate':
            isSelected = true; // Always allow upload
            break;
          case 'health_card':
            isSelected = true; // Always allow upload
            break;
        }

        if (isSelected) {
          selectedCategoryIds.add(category['id']);
        }
      }

      // Documents are already uploaded individually via uploadDocument method
      // No need for separate submission tracking

      // Only mark documents as completed if this is a submission (not draft) and we have essential documents
      if (mounted && !isDraft && _isDocumentsComplete()) {
        DebugConfig.debugLog(
          'Documents are complete, marking as completed. isDraft=$isDraft, isComplete=${_isDocumentsComplete()}',
          tag: 'DocumentsScreen',
        );
        context.read<CompletionNotifier>().markDocumentsCompleted();
      } else {
        DebugConfig.debugLog(
          'Documents not marked as completed. mounted=$mounted, isDraft=$isDraft, isComplete=${_isDocumentsComplete()}',
          tag: 'DocumentsScreen',
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(locale, 'documents_saved')),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to main screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving documents: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Check if documents are complete enough to be marked as completed
  bool _isDocumentsComplete() {
    // Check if we have at least the essential documents
    bool hasIdentityDocument = false;

    if (_selectedDocumentType == 'id') {
      hasIdentityDocument = _idFrontPhoto != null && _idBackPhoto != null;
    } else if (_selectedDocumentType == 'passport') {
      hasIdentityDocument = _passportPhoto != null;
    }

    final isComplete =
        _studentPhoto != null &&
        hasIdentityDocument &&
        _medicalCertificateFile != null &&
        _consentAccepted;
    DebugConfig.debugLog(
      'Document completion check: studentPhoto=${_studentPhoto != null}, hasIdentityDocument=$hasIdentityDocument, medicalCertificate=${_medicalCertificateFile != null}, consentAccepted=$_consentAccepted, isComplete=$isComplete',
      tag: 'DocumentsScreen',
    );
    return isComplete;
  }

  Widget _buildThumbnailPreview(PlatformFile? file) {
    if (file == null) return const SizedBox.shrink();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: file.bytes != null && ImageProcessingService.isImageFile(file)
            ? Image.memory(
                file.bytes!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image, size: 20);
                },
              )
            : file.path != null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    ImageProcessingService.isImageFile(file)
                        ? Icons.image
                        : ImageProcessingService.isPdfFile(file)
                        ? Icons.picture_as_pdf
                        : Icons.insert_drive_file,
                    size: 20,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey.shade600,
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
                ],
              )
            : Icon(
                ImageProcessingService.isPdfFile(file)
                    ? Icons.picture_as_pdf
                    : Icons.insert_drive_file,
                size: 20,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey.shade600,
              ),
      ),
    );
  }

  Widget _buildFileUpload(
    String locale,
    String label,
    String fileType,
    PlatformFile? currentFile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () => _pickFile(fileType),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF64B5F6)
                      : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Choose File',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentFile != null
                      ? TextUtils.formatFileName(currentFile.name)
                      : t(locale, 'no_file_selected'),
                  style: TextStyle(
                    color: currentFile != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildThumbnailPreview(currentFile),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;

    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: t(locale, 'back'),
        ),
        title: Text(t(locale, 'document_upload')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Uploads Section
                  Text(
                    t(locale, 'upload_documents'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildFileUpload(
                    locale,
                    t(locale, 'student_photo'),
                    'student_photo',
                    _studentPhoto,
                  ),
                  const SizedBox(height: 24),

                  // Document Type Selection
                  Text(
                    t(locale, 'select_identity_document'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Radio buttons for document type
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDocumentType = 'id';
                            _passportPhoto = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedDocumentType == 'id'
                                        ? (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF64B5F6)
                                              : Theme.of(context).primaryColor)
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: _selectedDocumentType == 'id'
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFF64B5F6)
                                                : Theme.of(
                                                    context,
                                                  ).primaryColor,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  t(locale, 'id_card_front_back'),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDocumentType = 'passport';
                            _idFrontPhoto = null;
                            _idBackPhoto = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedDocumentType == 'passport'
                                        ? (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF64B5F6)
                                              : Theme.of(context).primaryColor)
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: _selectedDocumentType == 'passport'
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFF64B5F6)
                                                : Theme.of(
                                                    context,
                                                  ).primaryColor,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  t(locale, 'passport_document'),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ID Card uploads (only show if ID is selected)
                  if (_selectedDocumentType == 'id') ...[
                    _buildFileUpload(
                      locale,
                      t(locale, 'id_front'),
                      'id_front',
                      _idFrontPhoto,
                    ),
                    const SizedBox(height: 12),
                    _buildFileUpload(
                      locale,
                      t(locale, 'id_back'),
                      'id_back',
                      _idBackPhoto,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Passport upload (only show if passport is selected)
                  if (_selectedDocumentType == 'passport') ...[
                    _buildFileUpload(
                      locale,
                      t(locale, 'passport_photo'),
                      'passport',
                      _passportPhoto,
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildFileUpload(
                    locale,
                    t(locale, 'medical_certificate'),
                    'medical_certificate',
                    _medicalCertificateFile,
                  ),

                  const SizedBox(height: 24),

                  // Consent Section
                  Text(
                    t(locale, 'consent_accepted'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _consentAccepted,
                        onChanged: (value) {
                          setState(() {
                            _consentAccepted = value ?? false;
                          });
                        },
                        activeColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF64B5F6)
                            : Theme.of(context).primaryColor,
                        checkColor: Colors.white,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white70
                                          : null,
                                    ),
                                children: [
                                  TextSpan(
                                    text: locale == 'el'
                                        ? 'Δηλώνω ότι έχω διαβάσει και αποδέχομαι τους όρους και προϋποθέσεις για την υποβολή εγγράφων και την επεξεργασία δεδομένων.'
                                        : 'I declare that I have read and accept the terms and conditions for document submission and data processing.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _launchPrivacyPolicy,
                              child: Text(
                                'Νόμος 4624/2019 (GDPR) - Κλικ εδώ για περισσότερες πληροφορίες',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF64B5F6)
                                      : Theme.of(context).primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _saveDocuments(isDraft: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF64B5F6)
                            : Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              t(locale, 'submit'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
