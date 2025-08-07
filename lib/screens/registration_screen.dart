import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../notifiers.dart';
import '../services/config_service.dart';
import '../services/localization_service.dart';
import '../services/sanitization_service.dart';
import '../services/validation_service.dart';

String t(String lang, String key) => LocalizationService.t(lang, key);

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Details section
  String? _name,
      _familyName,
      _fatherName,
      _motherName,
      _birthPlace,
      _idCardNumber,
      _issuingAuthority;
  String? _university, _department, _yearOfStudy, _email, _phone, _taxNumber;
  bool? _hasOtherDegree;

  // Parents info
  String? _fatherJob, _motherJob;
  String? _parentAddress,
      _parentCity,
      _parentRegion,
      _parentPostal,
      _parentCountry,
      _parentNumber;

  bool _isLoading = false;
  DateTime? _birthDate;
  int _attemptCount = 0;
  DateTime? _lastAttemptTime;

  Future<void> _registerStudent() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        debugPrint('Starting registration process...');
        debugPrint('Form validation passed, attempting database insert...');
      }

      // Security: Use sanitized data for database insertion
      final studentData = _sanitizeFormData();

      // Security: Final validation before database insertion
      final validationErrors = _validateSanitizedData(studentData);
      if (validationErrors.isNotEmpty) {
        throw Exception('Validation failed: ${validationErrors.join(', ')}');
      }

      if (kDebugMode) {
        debugPrint('Student data to insert: $studentData');
      }

      // Check if Supabase is available by trying to access the client
      try {
        Supabase.instance.client;
      } catch (e) {
        throw Exception(
          'Database not configured. Please set up your Supabase credentials.',
        );
      }

      // First try to test the connection
      if (kDebugMode) {
        debugPrint('Testing database connection...');
      }
      await Supabase.instance.client
          .from('students')
          .select('count')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      if (kDebugMode) {
        debugPrint('Database connection test successful');
      }

      if (kDebugMode) {
        debugPrint('Attempting to insert student data...');
      }
      final response = await Supabase.instance.client
          .from('students')
          .insert(studentData)
          .timeout(const Duration(seconds: 30));
      if (kDebugMode) {
        debugPrint('Database insert successful: $response');
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (kDebugMode) {
        debugPrint('Showing success dialog...');
      }
      showDialog(
        context: context,
        builder: (context) {
          final dialogLocale = context.watch<LocaleNotifier>().locale;
          return AlertDialog(
            title: Text(t(dialogLocale, 'registration_complete')),
            content: Text(t(dialogLocale, 'registration_submitted')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to main screen
                },
                child: Text(t(dialogLocale, 'ok')),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Registration error occurred: $error');
        debugPrint('Error type: ${error.runtimeType}');
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _attemptCount++;
      _lastAttemptTime = DateTime.now();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Security: Rate limiting check
  bool _checkRateLimit() {
    if (_attemptCount >= ConfigService.maxRegistrationAttempts) {
      if (_lastAttemptTime != null) {
        final timeSinceLastAttempt = DateTime.now().difference(
          _lastAttemptTime!,
        );
        return timeSinceLastAttempt < ConfigService.rateLimitWindow;
      }
    }
    return false;
  }

  void _showRateLimitError() {
    final remainingTime =
        ConfigService.rateLimitWindow -
        DateTime.now().difference(_lastAttemptTime!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Too many attempts. Please wait ${remainingTime.inMinutes} minutes before trying again.',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 8),
      ),
    );
  }

  // Security: Sanitize form data
  Map<String, dynamic> _sanitizeFormData() {
    return {
      'name': SanitizationService.sanitizeName(_name),
      'family_name': SanitizationService.sanitizeName(_familyName),
      'father_name': SanitizationService.sanitizeName(_fatherName),
      'mother_name': SanitizationService.sanitizeName(_motherName),
      'birth_date': _birthDate?.toIso8601String(),
      'birth_place': SanitizationService.sanitizeAddress(_birthPlace),
      'id_card_number': SanitizationService.sanitizeAlphanumeric(_idCardNumber),
      'issuing_authority': SanitizationService.sanitizeInstitution(
        _issuingAuthority,
      ),
      'university': SanitizationService.sanitizeInstitution(_university),
      'department': SanitizationService.sanitizeInstitution(_department),
      'year_of_study': _yearOfStudy,
      'has_other_degree': _hasOtherDegree,
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
      'parent_country': SanitizationService.sanitizeAddress(_parentCountry),
      'parent_number': SanitizationService.sanitizeNumeric(_parentNumber),
    };
  }

  // Security: Validate sanitized data
  List<String> _validateSanitizedData(Map<String, dynamic> data) {
    final locale = context.read<LocaleNotifier>().locale;
    final errors = <String>[];

    // Check for required fields after sanitization
    if (data['name'] == null || data['name'].toString().isEmpty) {
      errors.add('Name is required');
    }
    if (data['family_name'] == null || data['family_name'].toString().isEmpty) {
      errors.add('Family name is required');
    }
    if (data['email'] == null || data['email'].toString().isEmpty) {
      errors.add('Email is required');
    }

    // Validate data integrity
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(t(locale, 'student_registration')),
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
                    // Details Section
                    Text(
                      t(locale, 'details'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      locale,
                      'name',
                      (v) => _name = v,
                      required: true,
                    ),
                    _buildTextField(
                      locale,
                      'family_name',
                      (v) => _familyName = v,
                      required: true,
                    ),
                    _buildTextField(
                      locale,
                      'father_name',
                      (v) => _fatherName = v,
                    ),
                    _buildTextField(
                      locale,
                      'mother_name',
                      (v) => _motherName = v,
                    ),
                    _buildBirthDatePicker(locale),
                    _buildTextField(
                      locale,
                      'birth_place',
                      (v) => _birthPlace = v,
                    ),
                    _buildTextField(
                      locale,
                      'id_card_number',
                      (v) => _idCardNumber = v,
                    ),
                    _buildTextField(
                      locale,
                      'issuing_authority',
                      (v) => _issuingAuthority = v,
                    ),
                    _buildTextField(
                      locale,
                      'university',
                      (v) => _university = v,
                    ),
                    _buildTextField(
                      locale,
                      'department',
                      (v) => _department = v,
                    ),
                    _buildTextField(
                      locale,
                      'year_of_study',
                      (v) => _yearOfStudy = v,
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
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      locale,
                      'phone',
                      (v) => _phone = v,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      locale,
                      'tax_number',
                      (v) => _taxNumber = v,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    const Divider(thickness: 1.5, height: 32),

                    // Parents Info Section
                    Text(
                      t(locale, 'parents_info'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      locale,
                      'father_job',
                      (v) => _fatherJob = v,
                    ),
                    _buildTextField(
                      locale,
                      'mother_job',
                      (v) => _motherJob = v,
                    ),
                    const SizedBox(height: 16),

                    // Parents Address Section
                    Text(
                      t(locale, 'parents_address'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      locale,
                      'address',
                      (v) => _parentAddress = v,
                    ),
                    _buildTextField(locale, 'city', (v) => _parentCity = v),
                    _buildTextField(locale, 'region', (v) => _parentRegion = v),
                    _buildTextField(
                      locale,
                      'postal_code',
                      (v) => _parentPostal = v,
                    ),
                    _buildTextField(
                      locale,
                      'country',
                      (v) => _parentCountry = v,
                    ),
                    _buildTextField(locale, 'number', (v) => _parentNumber = v),
                    const SizedBox(height: 32),

                    // Submit Button
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (kDebugMode) {
                                  debugPrint('Register button pressed');
                                }

                                // Security: Check rate limiting
                                if (_checkRateLimit()) {
                                  _showRateLimitError();
                                  return;
                                }

                                if (_formKey.currentState!.validate()) {
                                  if (kDebugMode) {
                                    debugPrint('Form validation passed');
                                  }
                                  _formKey.currentState!.save();
                                  if (kDebugMode) {
                                    debugPrint('Form data saved');
                                  }

                                  // Security: Additional validation on sanitized data
                                  final sanitizedData = _sanitizeFormData();
                                  final validationErrors =
                                      _validateSanitizedData(sanitizedData);

                                  if (validationErrors.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Validation errors: ${validationErrors.join(', ')}',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                    return;
                                  }

                                  if (kDebugMode) {
                                    debugPrint('Security validation passed');
                                    debugPrint('Calling _registerStudent');
                                  }
                                  _registerStudent();
                                } else {
                                  if (kDebugMode) {
                                    debugPrint('Form validation failed');
                                  }
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(t(locale, 'register')),
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
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(labelText: t(locale, key)),
        keyboardType: keyboardType,
        validator: (v) {
          final locale = context.read<LocaleNotifier>().locale;

          // Required field validation
          if (required) {
            final requiredError = ValidationService.validateRequired(
              v,
              key,
              locale,
            );
            if (requiredError != null) return requiredError;
          }

          // Field-specific validation
          if (key == 'name' ||
              key == 'family_name' ||
              key == 'father_name' ||
              key == 'mother_name') {
            return ValidationService.validateName(v, locale);
          } else if (key == 'email') {
            return ValidationService.validateEmail(v, locale);
          } else if (key == 'phone') {
            return ValidationService.validatePhone(v, locale);
          } else if (key == 'tax_number') {
            return ValidationService.validateTaxNumber(v, locale);
          } else if (key == 'id_card_number') {
            return ValidationService.validateIdCard(v, locale);
          } else if (key == 'postal_code') {
            return ValidationService.validatePostalCode(v, locale);
          }

          return null;
        },
        onSaved: (v) {
          // Sanitize input before saving
          String? sanitized;
          if (key == 'name' ||
              key == 'family_name' ||
              key == 'father_name' ||
              key == 'mother_name') {
            sanitized = SanitizationService.sanitizeName(v);
          } else if (key == 'email') {
            sanitized = SanitizationService.sanitizeEmail(v);
          } else if (key == 'phone') {
            sanitized = SanitizationService.sanitizePhone(v);
          } else if (key == 'tax_number' ||
              key == 'postal_code' ||
              key == 'number') {
            sanitized = SanitizationService.sanitizeNumeric(v);
          } else if (key == 'id_card_number') {
            sanitized = SanitizationService.sanitizeAlphanumeric(v);
          } else if (key == 'university' ||
              key == 'department' ||
              key == 'issuing_authority') {
            sanitized = SanitizationService.sanitizeInstitution(v);
          } else if (key == 'address' ||
              key == 'city' ||
              key == 'region' ||
              key == 'country' ||
              key == 'birth_place') {
            sanitized = SanitizationService.sanitizeAddress(v);
          } else {
            sanitized = SanitizationService.sanitizeGeneral(
              v,
              maxLength: ConfigService.maxInputLength,
            );
          }
          onSaved(sanitized);
        },
      ),
    );
  }

  Widget _buildDropdown(String locale, String key, Function(bool?) onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<bool>(
        decoration: InputDecoration(labelText: t(locale, key)),
        items: [
          DropdownMenuItem(value: true, child: Text(t(locale, 'yes'))),
          DropdownMenuItem(value: false, child: Text(t(locale, 'no'))),
        ],
        onChanged: (v) => onSaved(v),
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildBirthDatePicker(String locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              labelText: t(locale, 'birth_date'),
              hintText: t(locale, 'select_birth_date'),
            ),
            validator: (value) {
              if (_birthDate == null) return t(locale, 'required');
              final dateError = ValidationService.validateDateNotFuture(
                _birthDate,
                locale,
              );
              if (dateError != null) return dateError;
              final ageError = ValidationService.validateAge(
                _birthDate,
                16,
                locale,
              );
              if (ageError != null) return ageError;
              return null;
            },
            controller: TextEditingController(
              text: _birthDate == null
                  ? ''
                  : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
            ),
          ),
        ),
      ),
    );
  }
}
