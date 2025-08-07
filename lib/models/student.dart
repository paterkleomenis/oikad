class Student {
  final String? id;
  final String? name;
  final String? familyName;
  final String? fatherName;
  final String? motherName;
  final DateTime? birthDate;
  final String? birthPlace;
  final String? idCardNumber;
  final String? issuingAuthority;
  final String? university;
  final String? department;
  final String? yearOfStudy;
  final bool? hasOtherDegree;
  final String? email;
  final String? phone;
  final String? taxNumber;
  final String? fatherJob;
  final String? motherJob;
  final String? parentAddress;
  final String? parentCity;
  final String? parentRegion;
  final String? parentPostal;
  final String? parentCountry;
  final String? parentNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Student({
    this.id,
    this.name,
    this.familyName,
    this.fatherName,
    this.motherName,
    this.birthDate,
    this.birthPlace,
    this.idCardNumber,
    this.issuingAuthority,
    this.university,
    this.department,
    this.yearOfStudy,
    this.hasOtherDegree,
    this.email,
    this.phone,
    this.taxNumber,
    this.fatherJob,
    this.motherJob,
    this.parentAddress,
    this.parentCity,
    this.parentRegion,
    this.parentPostal,
    this.parentCountry,
    this.parentNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id']?.toString(),
      name: map['name']?.toString(),
      familyName: map['family_name']?.toString(),
      fatherName: map['father_name']?.toString(),
      motherName: map['mother_name']?.toString(),
      birthDate: map['birth_date'] != null
          ? DateTime.tryParse(map['birth_date'].toString())
          : null,
      birthPlace: map['birth_place']?.toString(),
      idCardNumber: map['id_card_number']?.toString(),
      issuingAuthority: map['issuing_authority']?.toString(),
      university: map['university']?.toString(),
      department: map['department']?.toString(),
      yearOfStudy: map['year_of_study']?.toString(),
      hasOtherDegree: map['has_other_degree'] as bool?,
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      taxNumber: map['tax_number']?.toString(),
      fatherJob: map['father_job']?.toString(),
      motherJob: map['mother_job']?.toString(),
      parentAddress: map['parent_address']?.toString(),
      parentCity: map['parent_city']?.toString(),
      parentRegion: map['parent_region']?.toString(),
      parentPostal: map['parent_postal']?.toString(),
      parentCountry: map['parent_country']?.toString(),
      parentNumber: map['parent_number']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (familyName != null) 'family_name': familyName,
      if (fatherName != null) 'father_name': fatherName,
      if (motherName != null) 'mother_name': motherName,
      if (birthDate != null) 'birth_date': birthDate!.toIso8601String(),
      if (birthPlace != null) 'birth_place': birthPlace,
      if (idCardNumber != null) 'id_card_number': idCardNumber,
      if (issuingAuthority != null) 'issuing_authority': issuingAuthority,
      if (university != null) 'university': university,
      if (department != null) 'department': department,
      if (yearOfStudy != null) 'year_of_study': yearOfStudy,
      if (hasOtherDegree != null) 'has_other_degree': hasOtherDegree,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (taxNumber != null) 'tax_number': taxNumber,
      if (fatherJob != null) 'father_job': fatherJob,
      if (motherJob != null) 'mother_job': motherJob,
      if (parentAddress != null) 'parent_address': parentAddress,
      if (parentCity != null) 'parent_city': parentCity,
      if (parentRegion != null) 'parent_region': parentRegion,
      if (parentPostal != null) 'parent_postal': parentPostal,
      if (parentCountry != null) 'parent_country': parentCountry,
      if (parentNumber != null) 'parent_number': parentNumber,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Student copyWith({
    String? id,
    String? name,
    String? familyName,
    String? fatherName,
    String? motherName,
    DateTime? birthDate,
    String? birthPlace,
    String? idCardNumber,
    String? issuingAuthority,
    String? university,
    String? department,
    String? yearOfStudy,
    bool? hasOtherDegree,
    String? email,
    String? phone,
    String? taxNumber,
    String? fatherJob,
    String? motherJob,
    String? parentAddress,
    String? parentCity,
    String? parentRegion,
    String? parentPostal,
    String? parentCountry,
    String? parentNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      familyName: familyName ?? this.familyName,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      birthDate: birthDate ?? this.birthDate,
      birthPlace: birthPlace ?? this.birthPlace,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      university: university ?? this.university,
      department: department ?? this.department,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      hasOtherDegree: hasOtherDegree ?? this.hasOtherDegree,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      taxNumber: taxNumber ?? this.taxNumber,
      fatherJob: fatherJob ?? this.fatherJob,
      motherJob: motherJob ?? this.motherJob,
      parentAddress: parentAddress ?? this.parentAddress,
      parentCity: parentCity ?? this.parentCity,
      parentRegion: parentRegion ?? this.parentRegion,
      parentPostal: parentPostal ?? this.parentPostal,
      parentCountry: parentCountry ?? this.parentCountry,
      parentNumber: parentNumber ?? this.parentNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Student{'
        'id: $id, '
        'name: $name, '
        'familyName: $familyName, '
        'email: $email, '
        'university: $university, '
        'department: $department'
        '}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods
  String get fullName {
    final parts = <String>[];
    if (name?.isNotEmpty == true) parts.add(name!);
    if (familyName?.isNotEmpty == true) parts.add(familyName!);
    return parts.join(' ');
  }

  String get fullParentAddress {
    final parts = <String>[];
    if (parentAddress?.isNotEmpty == true) parts.add(parentAddress!);
    if (parentNumber?.isNotEmpty == true) parts.add(parentNumber!);
    if (parentCity?.isNotEmpty == true) parts.add(parentCity!);
    if (parentRegion?.isNotEmpty == true) parts.add(parentRegion!);
    if (parentPostal?.isNotEmpty == true) parts.add(parentPostal!);
    if (parentCountry?.isNotEmpty == true) parts.add(parentCountry!);
    return parts.join(', ');
  }

  bool get isComplete {
    return name?.isNotEmpty == true &&
        familyName?.isNotEmpty == true &&
        email?.isNotEmpty == true &&
        university?.isNotEmpty == true;
  }

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }
}
