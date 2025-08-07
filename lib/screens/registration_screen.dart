import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../notifiers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/validation_service.dart';
import '../services/sanitization_service.dart';
import '../services/config_service.dart';

// Localization map and t() function (should match your main.dart)
const Map<String, Map<String, String>> localizedStrings = {
  'en': {
    'register': 'Register',
    'student_registration': 'Student Registration',
    'details': 'Details',
    'parents_info': 'Parents Info',
    'parents_address': "Parents' Address",
    'name': 'Name',
    'family_name': 'Family Name',
    'father_name': "Father's Name",
    'mother_name': "Mother's Name",
    'birth_date': 'Birth Date (dd/mm/yyyy)',
    'birth_place': 'Place of Birth',
    'id_card_number': 'ID Card Number',
    'issuing_authority': 'Issuing Authority',
    'university': 'University',
    'department': 'Department of Study',
    'year_of_study': 'Year of Study',
    'has_other_degree': 'Having any other degree?',
    'yes': 'Yes',
    'no': 'No',
    'email': 'Email',
    'phone': 'Phone Number',
    'tax_number': 'Tax Number (AFM)',
    'father_job': "Father's Job",
    'mother_job': "Mother's Job",
    'address': 'Address',
    'city': 'City',
    'region': 'Region',
    'postal_code': 'Postal Code',
    'country': 'Country',
    'number': 'Number',
    'required': 'Required',
    'select_birth_date': 'Select your birth date',
    'registration_complete': 'Registration Complete',
    'registration_submitted': 'Your registration has been submitted.',
    'ok': 'OK',
  },
  'el': {
    'register': 'Εγγραφή',
    'student_registration': 'Εγγραφή Φοιτητή',
    'details': 'Στοιχεία',
    'parents_info': 'Στοιχεία Γονέων',
    'parents_address': 'Διεύθυνση Γονέων',
    'name': 'Όνομα',
    'family_name': 'Επώνυμο',
    'father_name': 'Όνομα Πατέρα',
    'mother_name': 'Όνομα Μητέρας',
    'birth_date': 'Ημερομηνία Γέννησης (ηη/μμ/εεεε)',
    'birth_place': 'Τόπος Γέννησης',
    'id_card_number': 'Αριθμός Ταυτότητας',
    'issuing_authority': 'Αρχή Έκδοσης',
    'university': 'Πανεπιστήμιο',
    'department': 'Τμήμα Σπουδών',
    'year_of_study': 'Έτος Σπουδών',
    'has_other_degree': 'Διαθέτετε άλλο πτυχίο;',
    'yes': 'Ναι',
    'no': 'Όχι',
    'email': 'Email',
    'phone': 'Τηλέφωνο',
    'tax_number': 'ΑΦΜ',
    'father_job': 'Επάγγελμα Πατέρα',
    'mother_job': 'Επάγγελμα Μητέρας',
    'address': 'Διεύθυνση',
    'city': 'Πόλη',
    'region': 'Περιοχή',
    'postal_code': 'Τ.Κ.',
    'country': 'Χώρα',
    'number': 'Αριθμός',
    'required': 'Υποχρεωτικό',
    'select_birth_date': 'Επιλέξτε ημερομηνία γέννησης',
    'registration_complete': 'Η εγγραφή ολοκληρώθηκε',
    'registration_submitted': 'Η εγγραφή σας υποβλήθηκε.',
    'ok': 'OK',
  },
};
String t(String lang, String key) => localizedStrings[lang]?[key] ?? key;

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
      print('DEBUG: Starting registration process...');
      print('DEBUG: Form validation passed, attempting database insert...');

      // Security: Use sanitized data for database insertion
      final studentData = _sanitizeFormData();

      // Security: Final validation before database insertion
      final validationErrors = _validateSanitizedData(studentData);
      if (validationErrors.isNotEmpty) {
        throw Exception('Validation failed: ${validationErrors.join(', ')}');
      }

      print('DEBUG: Student data to insert: $studentData');

      // First try to test the connection
      print('DEBUG: Testing database connection...');
      await Supabase.instance.client
          .from('students')
          .select('count')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      print('DEBUG: Database connection test successful');

      print('DEBUG: Attempting to insert student data...');
      final response = await Supabase.instance.client
          .from('students')
          .insert(studentData)
          .timeout(const Duration(seconds: 30));
      print('DEBUG: Database insert successful: $response');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      print('DEBUG: Showing success dialog...');
      showDialog(
        context: context,
        builder: (context) {
          final locale = context.watch<LocaleNotifier>().locale;
          return AlertDialog(
            title: Text(t(locale, 'registration_complete')),
            content: Text(t(locale, 'registration_submitted')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to main screen
                },
                child: Text(t(locale, 'ok')),
              ),
            ],
          );
        },
      );
    } catch (error) {
      print('DEBUG: Registration error occurred: $error');
      print('DEBUG: Error type: ${error.runtimeType}');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _attemptCount++;
      _lastAttemptTime = DateTime.now();

      String errorMessage = 'Registration failed: ';

      if (error.toString().contains('522')) {
        errorMessage +=
            'Server connection error. Please try again or check your internet connection.';
      } else if (error.toString().contains('401')) {
        errorMessage += 'Authentication error. Please contact support.';
      } else if (error.toString().contains('404')) {
        errorMessage += 'Service not found. Please contact support.';
      } else if (error.toString().contains('TimeoutException')) {
        errorMessage +=
            'Connection timeout (${ConfigService.longTimeout.inSeconds}s). Your internet may be slow. Please try again with a better connection, or contact support if this persists.';
      } else if (error.toString().contains('Validation failed')) {
        errorMessage +=
            'Invalid data format. Please check your entries and try again.';
      } else {
        errorMessage += 'Unexpected error occurred. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                _registerStudent();
              }
            },
          ),
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
    final locale = context.read<LocaleNotifier>().locale;
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
    final themeMode = context.watch<ThemeNotifier>().themeMode;

    final theme = ThemeData(
      brightness: themeMode == ThemeMode.dark
          ? Brightness.dark
          : Brightness.light,
      colorSchemeSeed: Colors.teal,
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme.copyWith(brightness: Brightness.dark),
      themeMode: themeMode,
      locale: Locale(locale),
      supportedLocales: const [Locale('en'), Locale('el')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          title: Text(t(locale, 'student_registration')),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: SingleChildScrollView(
            key: ValueKey(locale + themeMode.toString()),
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
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          style: Theme.of(context).textTheme.titleLarge!,
                          child: Text(t(locale, 'details')),
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
                        Divider(thickness: 1.5, height: 32),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          style: Theme.of(context).textTheme.titleLarge!,
                          child: Text(t(locale, 'details')),
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
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          style: Theme.of(context).textTheme.titleLarge!,
                          child: Text(t(locale, 'details')),
                        ),
                        _buildTextField(
                          locale,
                          'address',
                          (v) => _parentAddress = v,
                        ),
                        _buildTextField(locale, 'city', (v) => _parentCity = v),
                        _buildTextField(
                          locale,
                          'region',
                          (v) => _parentRegion = v,
                        ),
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
                        _buildTextField(
                          locale,
                          'number',
                          (v) => _parentNumber = v,
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      print('DEBUG: Register button pressed');

                                      // Security: Check rate limiting
                                      if (_checkRateLimit()) {
                                        _showRateLimitError();
                                        return;
                                      }

                                      if (_formKey.currentState!.validate()) {
                                        print('DEBUG: Form validation passed');
                                        _formKey.currentState!.save();
                                        print('DEBUG: Form data saved');

                                        // Security: Additional validation on sanitized data
                                        final sanitizedData =
                                            _sanitizeFormData();
                                        final validationErrors =
                                            _validateSanitizedData(
                                              sanitizedData,
                                            );

                                        if (validationErrors.isNotEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Validation errors: ${validationErrors.join(', ')}',
                                              ),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(
                                                seconds: 5,
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        print(
                                          'DEBUG: Security validation passed',
                                        );
                                        print(
                                          'DEBUG: Calling _registerStudent',
                                        );
                                        _registerStudent();
                                      } else {
                                        print('DEBUG: Form validation failed');
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(t(locale, 'register')),
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
