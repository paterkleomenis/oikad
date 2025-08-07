import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import '../services/error_service.dart';

class RegistrationProvider extends ChangeNotifier {
  final StudentService _studentService = StudentService();

  bool _isLoading = false;
  String? _error;
  Student? _currentStudent;
  Map<String, String> _validationErrors = {};

  // Form data
  String? _name;
  String? _familyName;
  String? _fatherName;
  String? _motherName;
  DateTime? _birthDate;
  String? _birthPlace;
  String? _idCardNumber;
  String? _issuingAuthority;
  String? _university;
  String? _department;
  String? _yearOfStudy;
  bool? _hasOtherDegree;
  String? _email;
  String? _phone;
  String? _taxNumber;
  String? _fatherJob;
  String? _motherJob;
  String? _parentAddress;
  String? _parentCity;
  String? _parentRegion;
  String? _parentPostal;
  String? _parentCountry;
  String? _parentNumber;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Student? get currentStudent => _currentStudent;
  Map<String, String> get validationErrors => _validationErrors;
  bool get hasValidationErrors => _validationErrors.isNotEmpty;

  // Form data getters
  String? get name => _name;
  String? get familyName => _familyName;
  String? get fatherName => _fatherName;
  String? get motherName => _motherName;
  DateTime? get birthDate => _birthDate;
  String? get birthPlace => _birthPlace;
  String? get idCardNumber => _idCardNumber;
  String? get issuingAuthority => _issuingAuthority;
  String? get university => _university;
  String? get department => _department;
  String? get yearOfStudy => _yearOfStudy;
  bool? get hasOtherDegree => _hasOtherDegree;
  String? get email => _email;
  String? get phone => _phone;
  String? get taxNumber => _taxNumber;
  String? get fatherJob => _fatherJob;
  String? get motherJob => _motherJob;
  String? get parentAddress => _parentAddress;
  String? get parentCity => _parentCity;
  String? get parentRegion => _parentRegion;
  String? get parentPostal => _parentPostal;
  String? get parentCountry => _parentCountry;
  String? get parentNumber => _parentNumber;

  // Progress tracking
  double get formProgress {
    int filledFields = 0;
    int totalFields = 24; // Total number of fields

    if (_name?.isNotEmpty == true) filledFields++;
    if (_familyName?.isNotEmpty == true) filledFields++;
    if (_fatherName?.isNotEmpty == true) filledFields++;
    if (_motherName?.isNotEmpty == true) filledFields++;
    if (_birthDate != null) filledFields++;
    if (_birthPlace?.isNotEmpty == true) filledFields++;
    if (_idCardNumber?.isNotEmpty == true) filledFields++;
    if (_issuingAuthority?.isNotEmpty == true) filledFields++;
    if (_university?.isNotEmpty == true) filledFields++;
    if (_department?.isNotEmpty == true) filledFields++;
    if (_yearOfStudy?.isNotEmpty == true) filledFields++;
    if (_hasOtherDegree != null) filledFields++;
    if (_email?.isNotEmpty == true) filledFields++;
    if (_phone?.isNotEmpty == true) filledFields++;
    if (_taxNumber?.isNotEmpty == true) filledFields++;
    if (_fatherJob?.isNotEmpty == true) filledFields++;
    if (_motherJob?.isNotEmpty == true) filledFields++;
    if (_parentAddress?.isNotEmpty == true) filledFields++;
    if (_parentCity?.isNotEmpty == true) filledFields++;
    if (_parentRegion?.isNotEmpty == true) filledFields++;
    if (_parentPostal?.isNotEmpty == true) filledFields++;
    if (_parentCountry?.isNotEmpty == true) filledFields++;
    if (_parentNumber?.isNotEmpty == true) filledFields++;

    return filledFields / totalFields;
  }

  bool get isBasicInfoComplete {
    return _name?.isNotEmpty == true &&
        _familyName?.isNotEmpty == true &&
        _email?.isNotEmpty == true &&
        _birthDate != null;
  }

  // Setters with validation
  void setName(String? value) {
    final trimmed = value?.trim();
    if (_name != trimmed) {
      _name = trimmed;
      _removeValidationError('name');
      notifyListeners();
    }
  }

  void setFamilyName(String? value) {
    final trimmed = value?.trim();
    if (_familyName != trimmed) {
      _familyName = trimmed;
      _removeValidationError('family_name');
      notifyListeners();
    }
  }

  void setFatherName(String? value) {
    final trimmed = value?.trim();
    if (_fatherName != trimmed) {
      _fatherName = trimmed;
      _removeValidationError('father_name');
      notifyListeners();
    }
  }

  void setMotherName(String? value) {
    final trimmed = value?.trim();
    if (_motherName != trimmed) {
      _motherName = trimmed;
      _removeValidationError('mother_name');
      notifyListeners();
    }
  }

  void setBirthDate(DateTime? value) {
    if (_birthDate != value) {
      _birthDate = value;
      _removeValidationError('birth_date');
      notifyListeners();
    }
  }

  void setBirthPlace(String? value) {
    final trimmed = value?.trim();
    if (_birthPlace != trimmed) {
      _birthPlace = trimmed;
      _removeValidationError('birth_place');
      notifyListeners();
    }
  }

  void setIdCardNumber(String? value) {
    final processed = value?.trim().toUpperCase();
    if (_idCardNumber != processed) {
      _idCardNumber = processed;
      _removeValidationError('id_card_number');
      notifyListeners();
    }
  }

  void setIssuingAuthority(String? value) {
    final trimmed = value?.trim();
    if (_issuingAuthority != trimmed) {
      _issuingAuthority = trimmed;
      _removeValidationError('issuing_authority');
      notifyListeners();
    }
  }

  void setUniversity(String? value) {
    final trimmed = value?.trim();
    if (_university != trimmed) {
      _university = trimmed;
      _removeValidationError('university');
      notifyListeners();
    }
  }

  void setDepartment(String? value) {
    final trimmed = value?.trim();
    if (_department != trimmed) {
      _department = trimmed;
      _removeValidationError('department');
      notifyListeners();
    }
  }

  void setYearOfStudy(String? value) {
    final trimmed = value?.trim();
    if (_yearOfStudy != trimmed) {
      _yearOfStudy = trimmed;
      _removeValidationError('year_of_study');
      notifyListeners();
    }
  }

  void setHasOtherDegree(bool? value) {
    if (_hasOtherDegree != value) {
      _hasOtherDegree = value;
      _removeValidationError('has_other_degree');
      notifyListeners();
    }
  }

  void setEmail(String? value) {
    final processed = value?.trim().toLowerCase();
    if (_email != processed) {
      _email = processed;
      _removeValidationError('email');
      notifyListeners();
    }
  }

  void setPhone(String? value) {
    final trimmed = value?.trim();
    if (_phone != trimmed) {
      _phone = trimmed;
      _removeValidationError('phone');
      notifyListeners();
    }
  }

  void setTaxNumber(String? value) {
    final trimmed = value?.trim();
    if (_taxNumber != trimmed) {
      _taxNumber = trimmed;
      _removeValidationError('tax_number');
      notifyListeners();
    }
  }

  void setFatherJob(String? value) {
    final trimmed = value?.trim();
    if (_fatherJob != trimmed) {
      _fatherJob = trimmed;
      _removeValidationError('father_job');
      notifyListeners();
    }
  }

  void setMotherJob(String? value) {
    final trimmed = value?.trim();
    if (_motherJob != trimmed) {
      _motherJob = trimmed;
      _removeValidationError('mother_job');
      notifyListeners();
    }
  }

  void setParentAddress(String? value) {
    final trimmed = value?.trim();
    if (_parentAddress != trimmed) {
      _parentAddress = trimmed;
      _removeValidationError('parent_address');
      notifyListeners();
    }
  }

  void setParentCity(String? value) {
    final trimmed = value?.trim();
    if (_parentCity != trimmed) {
      _parentCity = trimmed;
      _removeValidationError('parent_city');
      notifyListeners();
    }
  }

  void setParentRegion(String? value) {
    final trimmed = value?.trim();
    if (_parentRegion != trimmed) {
      _parentRegion = trimmed;
      _removeValidationError('parent_region');
      notifyListeners();
    }
  }

  void setParentPostal(String? value) {
    final trimmed = value?.trim();
    if (_parentPostal != trimmed) {
      _parentPostal = trimmed;
      _removeValidationError('parent_postal');
      notifyListeners();
    }
  }

  void setParentCountry(String? value) {
    final trimmed = value?.trim();
    if (_parentCountry != trimmed) {
      _parentCountry = trimmed;
      _removeValidationError('parent_country');
      notifyListeners();
    }
  }

  void setParentNumber(String? value) {
    final trimmed = value?.trim();
    if (_parentNumber != trimmed) {
      _parentNumber = trimmed;
      _removeValidationError('parent_number');
      notifyListeners();
    }
  }

  void _removeValidationError(String field) {
    if (_validationErrors.containsKey(field)) {
      _validationErrors.remove(field);
    }
  }

  void addValidationError(String field, String message) {
    _validationErrors[field] = message;
    notifyListeners();
  }

  void clearValidationErrors() {
    _validationErrors.clear();
    notifyListeners();
  }

  Student _createStudentFromFormData() {
    return Student(
      name: _name,
      familyName: _familyName,
      fatherName: _fatherName,
      motherName: _motherName,
      birthDate: _birthDate,
      birthPlace: _birthPlace,
      idCardNumber: _idCardNumber,
      issuingAuthority: _issuingAuthority,
      university: _university,
      department: _department,
      yearOfStudy: _yearOfStudy,
      hasOtherDegree: _hasOtherDegree,
      email: _email,
      phone: _phone,
      taxNumber: _taxNumber,
      fatherJob: _fatherJob,
      motherJob: _motherJob,
      parentAddress: _parentAddress,
      parentCity: _parentCity,
      parentRegion: _parentRegion,
      parentPostal: _parentPostal,
      parentCountry: _parentCountry,
      parentNumber: _parentNumber,
    );
  }

  Future<bool> validateAndRegisterStudent() async {
    clearValidationErrors();
    _setLoading(true);

    try {
      final student = _createStudentFromFormData();

      // Validate student data on server
      final serverValidationErrors = await _studentService.validateStudentData(
        student,
      );

      if (serverValidationErrors.isNotEmpty) {
        _validationErrors.addAll(serverValidationErrors);
        _setLoading(false);
        return false;
      }

      // Register student
      final studentId = await _studentService.registerStudentComplete(student);

      // Update current student with the returned ID
      _currentStudent = student.copyWith(id: studentId);

      _setLoading(false);
      return true;
    } catch (error) {
      _error = ErrorService.getErrorMessage(error);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerStudent() async {
    _setLoading(true);

    try {
      final student = _createStudentFromFormData();
      final studentId = await _studentService.registerStudentComplete(student);

      _currentStudent = student.copyWith(id: studentId);
      _setLoading(false);
      return true;
    } catch (error) {
      _error = ErrorService.getErrorMessage(error);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      return await _studentService.emailExists(email);
    } catch (error) {
      return false;
    }
  }

  Future<bool> checkTaxNumberExists(String taxNumber) async {
    try {
      return await _studentService.taxNumberExists(taxNumber);
    } catch (error) {
      return false;
    }
  }

  Future<bool> checkIdCardExists(String idCard) async {
    try {
      return await _studentService.idCardExists(idCard);
    } catch (error) {
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetForm() {
    _name = null;
    _familyName = null;
    _fatherName = null;
    _motherName = null;
    _birthDate = null;
    _birthPlace = null;
    _idCardNumber = null;
    _issuingAuthority = null;
    _university = null;
    _department = null;
    _yearOfStudy = null;
    _hasOtherDegree = null;
    _email = null;
    _phone = null;
    _taxNumber = null;
    _fatherJob = null;
    _motherJob = null;
    _parentAddress = null;
    _parentCity = null;
    _parentRegion = null;
    _parentPostal = null;
    _parentCountry = null;
    _parentNumber = null;
    _currentStudent = null;
    _error = null;
    _validationErrors.clear();
    notifyListeners();
  }

  void loadStudent(Student student) {
    _name = student.name;
    _familyName = student.familyName;
    _fatherName = student.fatherName;
    _motherName = student.motherName;
    _birthDate = student.birthDate;
    _birthPlace = student.birthPlace;
    _idCardNumber = student.idCardNumber;
    _issuingAuthority = student.issuingAuthority;
    _university = student.university;
    _department = student.department;
    _yearOfStudy = student.yearOfStudy;
    _hasOtherDegree = student.hasOtherDegree;
    _email = student.email;
    _phone = student.phone;
    _taxNumber = student.taxNumber;
    _fatherJob = student.fatherJob;
    _motherJob = student.motherJob;
    _parentAddress = student.parentAddress;
    _parentCity = student.parentCity;
    _parentRegion = student.parentRegion;
    _parentPostal = student.parentPostal;
    _parentCountry = student.parentCountry;
    _parentNumber = student.parentNumber;
    _currentStudent = student;
    notifyListeners();
  }

  @override
  void dispose() {
    resetForm();
    super.dispose();
  }
}
