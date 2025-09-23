import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../notifiers.dart';

import '../services/localization_service.dart';
import '../services/sanitization_service.dart';
import '../services/validation_service.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

String t(String lang, String key) => LocalizationService.t(lang, key);

class RegistrationScreen extends StatefulWidget {
  final bool isEditMode;

  const RegistrationScreen({super.key, this.isEditMode = false});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String? _name;
  String? _familyName;
  String? _fatherName;
  String? _motherName;
  String? _birthPlace;
  String? _idCardNumber;
  String? _issuingAuthority;
  String? _university;
  String? _department;
  int? _yearOfStudy;
  String? _email;
  String? _phone;
  String? _taxNumber;
  bool? _hasOtherDegree;
  String? _fatherJob;
  String? _motherJob;
  String? _parentAddress;
  String? _parentCity;
  String? _parentRegion;
  String? _parentPostal;
  String? _parentCountry;
  String? _parentNumber;

  bool _isLoading = false;
  bool _isLoadingData = false;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    if (!AuthService.isAuthenticated) {
      return;
    }

    setState(() {
      _isLoadingData = true;
    });

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
          _isLoading = false;
        });
        return;
      }

      final existing = await Supabase.instance.client
          .from('dormitory_students')
          .select()
          .eq('id', currentUserId)
          .maybeSingle();

      if (existing != null && mounted) {
        setState(() {
          _name = existing['name'];
          _familyName = existing['family_name'];
          _fatherName = existing['father_name'];
          _motherName = existing['mother_name'];
          _birthPlace = existing['birth_place'];
          _idCardNumber = existing['id_card_number'];
          _issuingAuthority = existing['issuing_authority'];
          _university = existing['university'];
          _department = existing['department'];
          _yearOfStudy = existing['year_of_study'];
          _email = existing['email'];
          _phone = existing['phone'];
          _taxNumber = existing['tax_number'];
          _hasOtherDegree = existing['has_other_degree'];
          _fatherJob = existing['father_job'];
          _motherJob = existing['mother_job'];
          _parentAddress = existing['parent_address'];
          _parentCity = existing['parent_city'];
          _parentRegion = existing['parent_region'];
          _parentPostal = existing['parent_postal'];
          _parentCountry = existing['parent_country'];
          _parentNumber = existing['parent_phone'];

          if (existing['birth_date'] != null) {
            _birthDate = DateTime.parse(existing['birth_date']);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading existing registration data: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _registerStudent() async {
    if (!mounted) return;

    if (!AuthService.isAuthenticated) {
      final locale = context.read<LocaleNotifier>().locale;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(locale, 'please_login_first')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final studentData = _sanitizeFormData();
      final validationErrors = _validateSanitizedData(studentData);

      if (validationErrors.isNotEmpty) {
        throw Exception('Validation failed: ${validationErrors.join(', ')}');
      }

      studentData['id'] = AuthService.currentUserId;

      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) {
        throw Exception('User session expired. Please sign in again.');
      }

      final existing = await Supabase.instance.client
          .from('dormitory_students')
          .select('id')
          .eq('id', currentUserId)
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('dormitory_students')
            .update({
              ...studentData,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', currentUserId)
            .timeout(const Duration(seconds: 30));
      } else {
        await Supabase.instance.client
            .from('dormitory_students')
            .insert(studentData)
            .timeout(const Duration(seconds: 30));
      }

      if (!mounted) return;

      if (_isCompleteSubmission()) {
        context.read<CompletionNotifier>().markRegistrationCompleted();
      }

      setState(() {
        _isLoading = false;
      });

      final locale = context.read<LocaleNotifier>().locale;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(locale, 'registration_saved_successfully')),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final locale = context.read<LocaleNotifier>().locale;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t(locale, 'registration_failed')}: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  bool _isCompleteSubmission() {
    return _name?.trim().isNotEmpty == true &&
        _familyName?.trim().isNotEmpty == true &&
        _birthDate != null &&
        _birthPlace?.trim().isNotEmpty == true &&
        _phone?.trim().isNotEmpty == true &&
        _email?.trim().isNotEmpty == true;
  }

  Map<String, dynamic> _sanitizeFormData() {
    return {
      'name': SanitizationService.sanitizeName(_name),
      'family_name': SanitizationService.sanitizeName(_familyName),
      'father_name': SanitizationService.sanitizeName(_fatherName),
      'mother_name': SanitizationService.sanitizeName(_motherName),
      'birth_date': _birthDate?.toIso8601String().split('T')[0],
      'birth_place': SanitizationService.sanitizeAddress(_birthPlace),
      'id_card_number': SanitizationService.sanitizeAlphanumeric(_idCardNumber),
      'issuing_authority': SanitizationService.sanitizeInstitution(
        _issuingAuthority,
      ),
      'university': SanitizationService.sanitizeInstitution(_university),
      'department': SanitizationService.sanitizeInstitution(_department),
      'year_of_study': _yearOfStudy,
      'has_other_degree': _hasOtherDegree ?? false,
      'email': SanitizationService.sanitizeEmail(_email),
      'phone': SanitizationService.sanitizePhone(_phone),
      'tax_number': SanitizationService.sanitizeNumeric(_taxNumber),
      'father_job': SanitizationService.sanitizeGeneral(
        _fatherJob,
        maxLength: 100,
      ),
      'mother_job': SanitizationService.sanitizeGeneral(
        _motherJob,
        maxLength: 100,
      ),
      'parent_address': SanitizationService.sanitizeAddress(_parentAddress),
      'parent_city': SanitizationService.sanitizeAddress(_parentCity),
      'parent_region': SanitizationService.sanitizeAddress(_parentRegion),
      'parent_postal': SanitizationService.sanitizeNumeric(_parentPostal),
      'parent_country':
          SanitizationService.sanitizeAddress(_parentCountry) ?? 'Greece',
      'parent_phone': SanitizationService.sanitizeNumeric(_parentNumber),
      'application_status': _isCompleteSubmission() ? 'submitted' : 'draft',
      'terms_accepted': true,
      'privacy_policy_accepted': true,
      'data_processing_consent': true,
      'consent_date': DateTime.now().toIso8601String(),
    };
  }

  List<String> _validateSanitizedData(Map<String, dynamic> data) {
    final locale = context.read<LocaleNotifier>().locale;
    final errors = <String>[];

    if (data['name'] == null || data['name'].toString().isEmpty) {
      errors.add('Name is required');
    }
    if (data['family_name'] == null || data['family_name'].toString().isEmpty) {
      errors.add('Family name is required');
    }
    if (data['birth_date'] == null || data['birth_date'].toString().isEmpty) {
      errors.add('Birth date is required');
    }
    if (data['birth_place'] == null || data['birth_place'].toString().isEmpty) {
      errors.add('Birth place is required');
    }
    if (data['phone'] == null || data['phone'].toString().isEmpty) {
      errors.add('Phone is required');
    }
    if (data['email'] == null || data['email'].toString().isEmpty) {
      errors.add('Email is required');
    }

    if (data['email'] != null) {
      final emailError = ValidationService.validateEmail(data['email'], locale);
      if (emailError != null) errors.add(emailError);
    }

    if (data['phone'] != null) {
      final phoneError = ValidationService.validatePhone(data['phone'], locale);
      if (phoneError != null) errors.add(phoneError);
    }

    if (data['tax_number'] != null) {
      final taxError = ValidationService.validateTaxNumber(
        data['tax_number'],
        locale,
      );
      if (taxError != null) errors.add(taxError);
    }

    return errors;
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
        title: Text(t(locale, 'dormitory_registration')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(locale, 'details'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      locale,
                      'name',
                      (v) => _name = v,
                      initialValue: _name,
                      required: true,
                    ),
                    _buildTextField(
                      locale,
                      'family_name',
                      (v) => _familyName = v,
                      initialValue: _familyName,
                      required: true,
                    ),
                    _buildTextField(
                      locale,
                      'father_name',
                      (v) => _fatherName = v,
                      initialValue: _fatherName,
                    ),
                    _buildTextField(
                      locale,
                      'mother_name',
                      (v) => _motherName = v,
                      initialValue: _motherName,
                    ),
                    _buildBirthDatePicker(locale),
                    _buildTextField(
                      locale,
                      'birth_place',
                      (v) => _birthPlace = v,
                      initialValue: _birthPlace,
                      required: true,
                    ),
                    _buildTextField(
                      locale,
                      'id_card_number',
                      (v) => _idCardNumber = v,
                      initialValue: _idCardNumber,
                    ),
                    _buildTextField(
                      locale,
                      'issuing_authority',
                      (v) => _issuingAuthority = v,
                      initialValue: _issuingAuthority,
                    ),
                    _buildTextField(
                      locale,
                      'university',
                      (v) => _university = v,
                      initialValue: _university,
                    ),
                    _buildTextField(
                      locale,
                      'department',
                      (v) => _department = v,
                      initialValue: _department,
                    ),
                    _buildTextField(
                      locale,
                      'year_of_study',
                      (v) => _yearOfStudy = int.tryParse(v ?? ''),
                      initialValue: _yearOfStudy?.toString(),
                      keyboardType: TextInputType.number,
                    ),
                    _buildDropdown(
                      locale,
                      'has_other_degree',
                      (v) => _hasOtherDegree = v,
                    ),
                    _buildTextField(
                      locale,
                      'email',
                      (v) => _email = v,
                      initialValue: _email,
                      keyboardType: TextInputType.emailAddress,
                      required: true,
                    ),
                    _buildTextField(
                      locale,
                      'phone',
                      (v) => _phone = v,
                      initialValue: _phone,
                      keyboardType: TextInputType.phone,
                      required: true,
                    ),
                    _buildTextField(
                      locale,
                      'tax_number',
                      (v) => _taxNumber = v,
                      initialValue: _taxNumber,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 24),
                    const Divider(thickness: 1.5, height: 24),

                    Text(
                      t(locale, 'parents_info'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      locale,
                      'father_job',
                      (v) => _fatherJob = v,
                      initialValue: _fatherJob,
                    ),
                    _buildTextField(
                      locale,
                      'mother_job',
                      (v) => _motherJob = v,
                      initialValue: _motherJob,
                    ),

                    const SizedBox(height: 12),
                    Text(
                      t(locale, 'parents_address'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      locale,
                      'address',
                      (v) => _parentAddress = v,
                      initialValue: _parentAddress,
                    ),
                    _buildTextField(
                      locale,
                      'city',
                      (v) => _parentCity = v,
                      initialValue: _parentCity,
                    ),
                    _buildTextField(
                      locale,
                      'region',
                      (v) => _parentRegion = v,
                      initialValue: _parentRegion,
                    ),
                    _buildTextField(
                      locale,
                      'postal_code',
                      (v) => _parentPostal = v,
                      initialValue: _parentPostal,
                    ),
                    _buildTextField(
                      locale,
                      'country',
                      (v) => _parentCountry = v,
                      initialValue: _parentCountry,
                    ),
                    _buildTextField(
                      locale,
                      'number',
                      (v) => _parentNumber = v,
                      initialValue: _parentNumber,
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  _registerStudent();
                                }
                              },
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
      ),
    );
  }

  Widget _buildTextField(
    String locale,
    String key,
    Function(String?) onSaved, {
    String? initialValue,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    // Get localized field labels
    String getFieldLabel(String key) {
      final locale = context.read<LocaleNotifier>().locale;
      return t(locale, key);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: required
              ? '${getFieldLabel(key)} (${t(locale, 'required')})'
              : getFieldLabel(key),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : null,
          ),
        ),
        keyboardType: keyboardType,
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            final locale = context.read<LocaleNotifier>().locale;
            return '${getFieldLabel(key)} ${t(locale, 'required')}';
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdown(String locale, String key, Function(bool?) onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<bool>(
        decoration: InputDecoration(
          labelText: t(locale, 'has_other_degree'),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : null,
          ),
        ),
        initialValue: _hasOtherDegree,
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
        onChanged: (v) => setState(() => _hasOtherDegree = v),
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildBirthDatePicker(String locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _birthDate ?? DateTime(2000, 1, 1),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              _birthDate = picked;
            });
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            decoration: InputDecoration(
              labelText:
                  '${t(locale, 'birth_date')} (${t(locale, 'required')})',
              hintText: t(locale, 'select_birth_date'),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : null,
              ),
            ),
            controller: TextEditingController(
              text: _birthDate == null
                  ? ''
                  : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
            ),
            validator: (value) {
              if (_birthDate == null) {
                return '${t(locale, 'birth_date')} ${t(locale, 'required')}';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}
