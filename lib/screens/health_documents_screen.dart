import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../notifiers.dart';
import '../services/localization_service.dart';
import '../services/health_service.dart';
import '../services/auth_service.dart';
import '../services/image_processing_service.dart';
import '../services/text_utils.dart';
import 'welcome_screen.dart';

class HealthDocumentsScreen extends StatefulWidget {
  const HealthDocumentsScreen({super.key});

  @override
  State<HealthDocumentsScreen> createState() => _HealthDocumentsScreenState();
}

class _HealthDocumentsScreenState extends State<HealthDocumentsScreen> {
  // File uploads
  PlatformFile? _healthForm;
  PlatformFile? _vaccinationCard;
  PlatformFile? _medicalDiagnosis;
  PlatformFile? _otherMedical;

  bool _isLoading = false;
  bool _isLoadingData = true;

  String t(String locale, String key) => LocalizationService.t(locale, key);

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
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

  Future<void> _loadExistingDocuments() async {
    if (!AuthService.isAuthenticated) {
      setState(() {
        _isLoadingData = false;
      });
      return;
    }

    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      final studentId = currentUserId;

      // Load existing documents
      final existingDocuments = await HealthService.getStudentDocuments(
        studentId,
      );

      // Create a map of category keys to document info
      final documentMap = <String, Map<String, dynamic>>{};
      for (final doc in existingDocuments) {
        final category = doc['category'] as Map<String, dynamic>?;
        if (category != null) {
          final categoryKey = category['category_key'] as String?;
          if (categoryKey != null) {
            documentMap[categoryKey] = doc;
          }
        }
      }

      // Restore UI state
      setState(() {
        if (documentMap.containsKey('health_form')) {
          final doc = documentMap['health_form']!;
          _healthForm = PlatformFile(
            name: doc['original_file_name'] ?? 'health_form',
            size: doc['file_size_bytes'] ?? 0,
            path: doc['file_path'],
          );
        }

        if (documentMap.containsKey('vaccination_card')) {
          final doc = documentMap['vaccination_card']!;
          _vaccinationCard = PlatformFile(
            name: doc['original_file_name'] ?? 'vaccination_card',
            size: doc['file_size_bytes'] ?? 0,
            path: doc['file_path'],
          );
        }

        if (documentMap.containsKey('medical_diagnosis')) {
          final doc = documentMap['medical_diagnosis']!;
          _medicalDiagnosis = PlatformFile(
            name: doc['original_file_name'] ?? 'medical_diagnosis',
            size: doc['file_size_bytes'] ?? 0,
            path: doc['file_path'],
          );
        }

        if (documentMap.containsKey('other_medical')) {
          final doc = documentMap['other_medical']!;
          _otherMedical = PlatformFile(
            name: doc['original_file_name'] ?? 'other_medical',
            size: doc['file_size_bytes'] ?? 0,
            path: doc['file_path'],
          );
        }
      });

      if (mounted) {
        context.read<CompletionNotifier>().refreshCompletionStatus();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading existing health documents: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
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
            case 'health_form':
              _healthForm = file;
              break;
            case 'vaccination_card':
              _vaccinationCard = file;
              break;
            case 'medical_diagnosis':
              _medicalDiagnosis = file;
              break;
            case 'other_medical':
              _otherMedical = file;
              break;
          }
        });
      }
    } catch (e) {
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

  Future<void> _saveDocuments() async {
    final locale = context.read<LocaleNotifier>().locale;

    // Validate required fields
    if (_healthForm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(locale, 'health_form_required')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (!AuthService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) return;

      // Upload health form
      if (_healthForm != null && _healthForm!.bytes != null) {
        await HealthService.uploadDocument(
          studentId: currentUserId,
          categoryKey: 'health_form',
          file: _healthForm!,
        );
      }

      // Upload vaccination card
      if (_vaccinationCard != null && _vaccinationCard!.bytes != null) {
        await HealthService.uploadDocument(
          studentId: currentUserId,
          categoryKey: 'vaccination_card',
          file: _vaccinationCard!,
        );
      }

      // Upload medical diagnosis
      if (_medicalDiagnosis != null && _medicalDiagnosis!.bytes != null) {
        await HealthService.uploadDocument(
          studentId: currentUserId,
          categoryKey: 'medical_diagnosis',
          file: _medicalDiagnosis!,
        );
      }

      // Upload other medical
      if (_otherMedical != null && _otherMedical!.bytes != null) {
        await HealthService.uploadDocument(
          studentId: currentUserId,
          categoryKey: 'other_medical',
          file: _otherMedical!,
        );
      }

      // Mark as completed
      if (mounted) {
        context.read<CompletionNotifier>().markHealthCompleted();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(locale, 'documents_saved')),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    PlatformFile? currentFile, {
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
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
        title: Text(t(locale, 'health_documents')),
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
                  Text(
                    t(locale, 'upload_health_documents'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(locale, 'upload_health_documents_subtitle'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildFileUpload(
                    locale,
                    t(locale, 'health_form'),
                    'health_form',
                    _healthForm,
                    required: true,
                  ),
                  const SizedBox(height: 16),

                  _buildFileUpload(
                    locale,
                    t(locale, 'vaccination_card'),
                    'vaccination_card',
                    _vaccinationCard,
                  ),
                  const SizedBox(height: 16),

                  _buildFileUpload(
                    locale,
                    t(locale, 'medical_diagnosis'),
                    'medical_diagnosis',
                    _medicalDiagnosis,
                  ),
                  const SizedBox(height: 16),

                  _buildFileUpload(
                    locale,
                    t(locale, 'other_medical'),
                    'other_medical',
                    _otherMedical,
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveDocuments,
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
