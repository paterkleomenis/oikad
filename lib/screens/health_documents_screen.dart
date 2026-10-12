import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../notifiers.dart';
import '../services/localization_service.dart';
import '../services/health_service.dart';
import '../services/health_form_service.dart';
import '../services/auth_service.dart';
import '../services/image_processing_service.dart';
import '../services/text_utils.dart';
import 'welcome_screen.dart';

class HealthDocumentsScreen extends StatefulWidget {
  final bool isViewOnly;
  const HealthDocumentsScreen({super.key, this.isViewOnly = false});

  @override
  State<HealthDocumentsScreen> createState() => _HealthDocumentsScreenState();
}

class _HealthDocumentsScreenState extends State<HealthDocumentsScreen> {
  final _formKey = GlobalKey<FormState>();

  // File uploads
  PlatformFile? _healthForm;
  PlatformFile? _vaccinationCard;
  PlatformFile? _medicalDiagnosis;
  PlatformFile? _otherMedical;

  bool _isLoading = false;
  bool _isLoadingData = true;

  // --- Υγειονομικά στοιχεία (stoixia.docx) ---
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _surgeriesCtrl = TextEditingController();
  final _illnessDetailsCtrl = TextEditingController();
  final _medicationCtrl = TextEditingController();
  final _dietDetailsCtrl = TextEditingController();
  final _conditionsDetailsCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();

  DateTime? _birthDate;
  DateTime? _hepatitisDate;
  DateTime? _tetanusDate;
  DateTime? _meningitisDate;
  String? _bloodType;
  bool? _hepatitisCovered;
  bool? _tetanusCovered;
  bool? _meningitisCovered;
  bool? _seriousIllness;
  bool? _specialDiet;
  Set<String> _conditions = {};
  bool _healthConsent = false;

  bool get _isViewOnly => widget.isViewOnly;

  String t(String locale, String key) => LocalizationService.t(locale, key);

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadExistingDocuments();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _motherNameCtrl.dispose();
    _surgeriesCtrl.dispose();
    _illnessDetailsCtrl.dispose();
    _medicationCtrl.dispose();
    _dietDetailsCtrl.dispose();
    _conditionsDetailsCtrl.dispose();
    _observationsCtrl.dispose();
    super.dispose();
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

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
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

      // Load health questionnaire form
      final form = await HealthFormService.getForm(studentId);

      // Prefill names from registration if form is empty
      Map<String, dynamic>? registration;
      try {
        registration = await Supabase.instance.client
            .from('dormitory_students')
            .select('name, family_name, father_name, mother_name, birth_date')
            .eq('id', studentId)
            .maybeSingle();
      } catch (_) {}

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

        if (form != null) {
          _firstNameCtrl.text = (form['first_name'] ?? '').toString();
          _lastNameCtrl.text = (form['last_name'] ?? '').toString();
          _fatherNameCtrl.text = (form['father_name'] ?? '').toString();
          _motherNameCtrl.text = (form['mother_name'] ?? '').toString();
          _birthDate = _parseDate(form['birth_date']);
          _bloodType = form['blood_type']?.toString();
          _surgeriesCtrl.text = (form['recent_surgeries'] ?? '').toString();
          _hepatitisCovered = form['hepatitis_covered'] as bool?;
          _hepatitisDate = _parseDate(form['hepatitis_date']);
          _tetanusCovered = form['tetanus_covered'] as bool?;
          _tetanusDate = _parseDate(form['tetanus_date']);
          _meningitisCovered = form['meningitis_covered'] as bool?;
          _meningitisDate = _parseDate(form['meningitis_date']);
          _seriousIllness = form['serious_illness'] as bool?;
          _illnessDetailsCtrl.text =
              (form['serious_illness_details'] ?? '').toString();
          _medicationCtrl.text = (form['medication'] ?? '').toString();
          _specialDiet = form['special_diet'] as bool?;
          _dietDetailsCtrl.text =
              (form['special_diet_details'] ?? '').toString();
          final conds = form['conditions'];
          if (conds is List) {
            _conditions = conds.map((e) => e.toString()).toSet();
          }
          _conditionsDetailsCtrl.text =
              (form['conditions_details'] ?? '').toString();
          _observationsCtrl.text =
              (form['other_observations'] ?? '').toString();
          _healthConsent = (form['consent_accepted'] as bool?) ?? false;
        } else if (registration != null) {
          if (_firstNameCtrl.text.isEmpty) {
            _firstNameCtrl.text =
                (registration['name'] ?? '').toString().toUpperCase();
          }
          if (_lastNameCtrl.text.isEmpty) {
            _lastNameCtrl.text =
                (registration['family_name'] ?? '').toString().toUpperCase();
          }
          if (_fatherNameCtrl.text.isEmpty) {
            _fatherNameCtrl.text =
                (registration['father_name'] ?? '').toString().toUpperCase();
          }
          if (_motherNameCtrl.text.isEmpty) {
            _motherNameCtrl.text =
                (registration['mother_name'] ?? '').toString().toUpperCase();
          }
          _birthDate ??= _parseDate(registration['birth_date']);
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
    if (_isViewOnly) return;
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

  bool _validateHealthForm(String locale) {
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        _fatherNameCtrl.text.trim().isEmpty ||
        _motherNameCtrl.text.trim().isEmpty ||
        _birthDate == null ||
        _bloodType == null ||
        _hepatitisCovered == null ||
        _tetanusCovered == null ||
        _meningitisCovered == null ||
        _seriousIllness == null ||
        _specialDiet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(locale, 'health_questionnaire_subtitle')),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    if (!_healthConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(locale, 'health_consent_required')),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveDocuments() async {
    if (_isViewOnly) return;
    final locale = context.read<LocaleNotifier>().locale;

    if (!_validateHealthForm(locale)) return;

    // Validate required file
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

      // Save questionnaire first
      await HealthFormService.saveForm(currentUserId, {
        'first_name': _firstNameCtrl.text.trim().toUpperCase(),
        'last_name': _lastNameCtrl.text.trim().toUpperCase(),
        'father_name': _fatherNameCtrl.text.trim().toUpperCase(),
        'mother_name': _motherNameCtrl.text.trim().toUpperCase(),
        'birth_date': _birthDate!.toIso8601String().split('T')[0],
        'blood_type': _bloodType,
        'recent_surgeries': _surgeriesCtrl.text.trim().isEmpty
            ? null
            : _surgeriesCtrl.text.trim(),
        'hepatitis_covered': _hepatitisCovered,
        'hepatitis_date': _hepatitisDate?.toIso8601String().split('T')[0],
        'tetanus_covered': _tetanusCovered,
        'tetanus_date': _tetanusDate?.toIso8601String().split('T')[0],
        'meningitis_covered': _meningitisCovered,
        'meningitis_date': _meningitisDate?.toIso8601String().split('T')[0],
        'serious_illness': _seriousIllness,
        'serious_illness_details': _illnessDetailsCtrl.text.trim().isEmpty
            ? null
            : _illnessDetailsCtrl.text.trim(),
        'medication': _medicationCtrl.text.trim().isEmpty
            ? null
            : _medicationCtrl.text.trim(),
        'special_diet': _specialDiet,
        'special_diet_details': _dietDetailsCtrl.text.trim().isEmpty
            ? null
            : _dietDetailsCtrl.text.trim(),
        'conditions': _conditions.toList(),
        'conditions_details': _conditionsDetailsCtrl.text.trim().isEmpty
            ? null
            : _conditionsDetailsCtrl.text.trim(),
        'other_observations': _observationsCtrl.text.trim().isEmpty
            ? null
            : _observationsCtrl.text.trim(),
        'consent_accepted': true,
        'consent_date': DateTime.now().toIso8601String(),
      });

      // Upload health form file
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
              const Text(
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
                onPressed: _isViewOnly ? null : () => _pickFile(fileType),
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
                child: const Text(
                  'Choose File',
                  style: TextStyle(fontWeight: FontWeight.w600),
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

  Widget _qText(
    String locale,
    String labelKey,
    TextEditingController ctrl, {
    bool required = false,
    int maxLines = 1,
    bool upperCase = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: ctrl,
        enabled: !_isViewOnly,
        readOnly: _isViewOnly,
        maxLines: maxLines,
        textCapitalization:
            upperCase ? TextCapitalization.characters : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: required
              ? '${t(locale, labelKey)} (${t(locale, 'required')})'
              : t(locale, labelKey),
        ),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return '${t(locale, labelKey)} ${t(locale, 'required')}';
          }
          return null;
        },
        onChanged: upperCase
            ? (v) {
                final u = v.toUpperCase();
                if (u != v) {
                  ctrl.value = ctrl.value.copyWith(
                    text: u,
                    selection: TextSelection.collapsed(offset: u.length),
                  );
                }
              }
            : null,
      ),
    );
  }

  Widget _qDate(
    String locale,
    String labelKey,
    DateTime? value,
    void Function(DateTime?) onPick, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: _isViewOnly
            ? null
            : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: value ?? DateTime(2000, 1, 1),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                onPick(picked);
              },
        child: AbsorbPointer(
          child: TextFormField(
            enabled: !_isViewOnly,
            decoration: InputDecoration(
              labelText: required
                  ? '${t(locale, labelKey)} (${t(locale, 'required')})'
                  : t(locale, labelKey),
              hintText: t(locale, 'health_select_date'),
              suffixIcon: const Icon(Icons.calendar_today, size: 20),
            ),
            controller: TextEditingController(
              text: value == null
                  ? ''
                  : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}',
            ),
            validator: (v) {
              if (required && value == null) {
                return '${t(locale, labelKey)} ${t(locale, 'required')}';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _qBool(
    String locale,
    String labelKey,
    bool? value,
    void Function(bool?) onChanged, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<bool>(
        decoration: InputDecoration(
          labelText: required
              ? '${t(locale, labelKey)} (${t(locale, 'required')})'
              : t(locale, labelKey),
        ),
        initialValue: value,
        items: [
          DropdownMenuItem(
            value: true,
            child: Text(
              t(locale, 'yes'),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : null,
              ),
            ),
          ),
          DropdownMenuItem(
            value: false,
            child: Text(
              t(locale, 'no'),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : null,
              ),
            ),
          ),
        ],
        onChanged: _isViewOnly ? null : onChanged,
        validator: (v) {
          if (required && v == null) {
            return '${t(locale, labelKey)} ${t(locale, 'required')}';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildQuestionnaire(String locale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t(locale, 'health_questionnaire'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t(locale, 'health_questionnaire_subtitle'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              _qText(locale, 'health_first_name', _firstNameCtrl,
                  required: true, upperCase: true),
              _qText(locale, 'health_last_name', _lastNameCtrl,
                  required: true, upperCase: true),
              _qText(locale, 'health_father_name', _fatherNameCtrl,
                  required: true, upperCase: true),
              _qText(locale, 'health_mother_name', _motherNameCtrl,
                  required: true, upperCase: true),
              _qDate(locale, 'health_birth_date', _birthDate,
                  (v) => setState(() => _birthDate = v),
                  required: true),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText:
                        '${t(locale, 'health_blood_type')} (${t(locale, 'required')})',
                  ),
                  initialValue:
                      HealthFormService.bloodTypes.contains(_bloodType)
                      ? _bloodType
                      : null,
                  items: HealthFormService.bloodTypes
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: _isViewOnly
                      ? null
                      : (v) => setState(() => _bloodType = v),
                  validator: (v) => v == null
                      ? '${t(locale, 'health_blood_type')} ${t(locale, 'required')}'
                      : null,
                ),
              ),
              _qText(locale, 'health_recent_surgeries', _surgeriesCtrl,
                  maxLines: 3),
              _qBool(locale, 'health_hepatitis_covered', _hepatitisCovered,
                  (v) => setState(() => _hepatitisCovered = v),
                  required: true),
              _qDate(locale, 'health_hepatitis_date', _hepatitisDate,
                  (v) => setState(() => _hepatitisDate = v)),
              _qBool(locale, 'health_tetanus_covered', _tetanusCovered,
                  (v) => setState(() => _tetanusCovered = v),
                  required: true),
              _qDate(locale, 'health_tetanus_date', _tetanusDate,
                  (v) => setState(() => _tetanusDate = v)),
              _qBool(locale, 'health_meningitis_covered', _meningitisCovered,
                  (v) => setState(() => _meningitisCovered = v),
                  required: true),
              _qDate(locale, 'health_meningitis_date', _meningitisDate,
                  (v) => setState(() => _meningitisDate = v)),
              _qBool(locale, 'health_serious_illness', _seriousIllness,
                  (v) => setState(() => _seriousIllness = v),
                  required: true),
              _qText(locale, 'health_serious_illness_details',
                  _illnessDetailsCtrl,
                  maxLines: 2),
              _qText(locale, 'health_medication', _medicationCtrl, maxLines: 3),
              _qBool(locale, 'health_special_diet', _specialDiet,
                  (v) => setState(() => _specialDiet = v),
                  required: true),
              _qText(locale, 'health_special_diet_details', _dietDetailsCtrl,
                  maxLines: 2),
              const SizedBox(height: 12),
              Text(
                '${t(locale, 'health_conditions')} (${t(locale, 'optional')})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : null,
                ),
              ),
              ...HealthFormService.conditionOptions.map(
                (key) => CheckboxListTile(
                  value: _conditions.contains(key),
                  onChanged: _isViewOnly
                      ? null
                      : (v) => setState(() {
                          if (v == true) {
                            _conditions.add(key);
                          } else {
                            _conditions.remove(key);
                          }
                        }),
                  title: Text(t(locale, 'health_condition_$key')),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              _qText(locale, 'health_conditions_details',
                  _conditionsDetailsCtrl,
                  maxLines: 3),
              _qText(locale, 'health_other_observations', _observationsCtrl,
                  maxLines: 3),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _healthConsent,
                    onChanged: _isViewOnly
                        ? null
                        : (v) =>
                              setState(() => _healthConsent = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        '${t(locale, 'health_consent_text')} *',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : null,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          child: Column(
            children: [
              if (_isViewOnly)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t(locale, 'view_only_message'),
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildQuestionnaire(locale),
              const SizedBox(height: 16),
              Card(
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
                      if (!_isViewOnly)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveDocuments,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
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
            ],
          ),
        ),
      ),
    );
  }
}
