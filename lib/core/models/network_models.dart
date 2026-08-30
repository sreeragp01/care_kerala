class SpecialtyModel {
  final String id;
  final String name;
  final String category;
  final String iconName;
  final String description;

  const SpecialtyModel({
    required this.id,
    required this.name,
    this.category = 'Clinical Specialty',
    this.iconName = 'medical_services',
    this.description = '',
  });

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Clinical Specialty',
      iconName: json['icon_name'] ?? 'medical_services',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'icon_name': iconName,
    'description': description,
  };
}

class DepartmentModel {
  final String id;
  final String organizationId;
  final String name;
  final String headOfDepartment;
  final String phoneExtension;
  final String floorLocation;

  const DepartmentModel({
    required this.id,
    required this.organizationId,
    required this.name,
    this.headOfDepartment = '',
    this.phoneExtension = '',
    this.floorLocation = '',
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization']?.toString() ?? '',
      name: json['name'] ?? '',
      headOfDepartment: json['head_of_department'] ?? '',
      phoneExtension: json['phone_extension'] ?? '',
      floorLocation: json['floor_location'] ?? '',
    );
  }
}

class HealthcareServiceModel {
  final String id;
  final String name;
  final String category;
  final String iconName;
  final String description;

  const HealthcareServiceModel({
    required this.id,
    required this.name,
    this.category = 'Clinical Service',
    this.iconName = 'local_hospital',
    this.description = '',
  });

  factory HealthcareServiceModel.fromJson(Map<String, dynamic> json) {
    return HealthcareServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Clinical Service',
      iconName: json['icon_name'] ?? 'local_hospital',
      description: json['description'] ?? '',
    );
  }
}

class FacilityModel {
  final String id;
  final String name;
  final String iconName;
  final String description;

  const FacilityModel({
    required this.id,
    required this.name,
    this.iconName = 'check_circle',
    this.description = '',
  });

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      iconName: json['icon_name'] ?? 'check_circle',
      description: json['description'] ?? '',
    );
  }
}

class DoctorScheduleModel {
  final String id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String consultationType;
  final String locationRoom;
  final int maxTokens;
  final bool appointmentRequired;
  final String status;
  final String lastVerifiedText;

  const DoctorScheduleModel({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.consultationType = 'General OPD',
    this.locationRoom = 'OPD Room 101',
    this.maxTokens = 30,
    this.appointmentRequired = true,
    this.status = 'ACTIVE',
    this.lastVerifiedText = 'Verified recently',
  });

  factory DoctorScheduleModel.fromJson(Map<String, dynamic> json) {
    return DoctorScheduleModel(
      id: json['id']?.toString() ?? '',
      dayOfWeek: json['day_name'] ?? (json['day_of_week'] ?? 'Monday'),
      startTime: json['start_time'] ?? '09:00 AM',
      endTime: json['end_time'] ?? '01:00 PM',
      consultationType: json['consultation_type'] ?? 'General OPD',
      locationRoom: json['location_room'] ?? 'OPD Room 101',
      maxTokens: json['max_tokens'] ?? 30,
      appointmentRequired: json['appointment_required'] ?? true,
      status: json['status'] ?? 'ACTIVE',
      lastVerifiedText: json['last_verified_at'] != null ? 'Verified recently' : 'Verified recently',
    );
  }
}

class DoctorModel {
  final String id;
  final String name;
  final String qualification;
  final String specialty;
  final String designation;
  final String organizationId;
  final String organizationName;
  final String district;
  final int experienceYears;
  final String languages;
  final String registrationNumber;
  final bool isRegVerified;
  final String consultationMode;
  final double consultationFee;
  final String biography;
  final bool isCareLinkVerified;
  final List<DoctorScheduleModel> schedules;
  final String profilePhotoUrl;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.qualification,
    required this.specialty,
    this.designation = 'Senior Consultant',
    this.organizationId = 'org_kozhikode',
    this.organizationName = 'Calicut Medical Center',
    this.district = 'Kozhikode',
    this.experienceYears = 10,
    this.languages = 'Malayalam, English',
    this.registrationNumber = 'TCMC-XXXXX',
    this.isRegVerified = true,
    this.consultationMode = 'In-Person Hospital OPD',
    this.consultationFee = 0.00,
    this.biography = '',
    this.isCareLinkVerified = true,
    this.schedules = const [],
    this.profilePhotoUrl = '',
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    List<DoctorScheduleModel> parsedSchedules = [];
    if (json['schedules'] != null && json['schedules'] is List) {
      parsedSchedules = (json['schedules'] as List)
          .map((s) => DoctorScheduleModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return DoctorModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      qualification: json['qualification'] ?? '',
      specialty: json['specialty'] ?? (json['primary_specialty_name'] ?? 'General Medicine'),
      designation: json['designation'] ?? 'Specialist Consultant',
      organizationId: json['organization_id'] ?? 'org_kozhikode',
      organizationName: json['organization_name'] ?? 'CareLink Network Hospital',
      district: json['district'] ?? 'Kozhikode',
      experienceYears: json['experience_years'] ?? 8,
      languages: json['languages'] ?? 'Malayalam, English',
      registrationNumber: json['registration_number'] ?? 'TCMC Verified',
      isRegVerified: json['is_reg_verified'] ?? true,
      consultationMode: json['consultation_mode'] ?? 'In-Person Hospital OPD',
      consultationFee: (json['consultation_fee'] != null) ? double.tryParse(json['consultation_fee'].toString()) ?? 0.0 : 0.0,
      biography: json['biography'] ?? '',
      isCareLinkVerified: json['is_verified'] ?? true,
      schedules: parsedSchedules,
      profilePhotoUrl: json['profile_photo_url'] ?? '',
    );
  }
}

class HealthcareProfileModel {
  final String id;
  final String organizationId;
  final String name;
  final String organizationType;
  final String ownershipType;
  final String verificationStatus;
  final bool isCareLinkVerified;
  final String district;
  final String address;
  final String pincode;
  final double latitude;
  final double longitude;
  final String phone;
  final String emergencyPhone;
  final bool is24x7Emergency;
  final bool ambulanceAvailable;
  final int totalBeds;
  final int icuBeds;
  final String description;
  final int profileCompletenessScore;
  final String lastVerifiedDate;
  final List<String> specialties;
  final List<String> services;
  final List<String> facilities;
  final List<DoctorModel> doctors;

  const HealthcareProfileModel({
    required this.id,
    required this.organizationId,
    required this.name,
    this.organizationType = 'Hospital',
    this.ownershipType = 'Trust / Non-Profit',
    this.verificationStatus = 'VERIFIED',
    this.isCareLinkVerified = true,
    this.district = 'Kozhikode',
    this.address = '',
    this.pincode = '673001',
    this.latitude = 11.2588,
    this.longitude = 75.7804,
    this.phone = '',
    this.emergencyPhone = '',
    this.is24x7Emergency = false,
    this.ambulanceAvailable = false,
    this.totalBeds = 0,
    this.icuBeds = 0,
    this.description = '',
    this.profileCompletenessScore = 90,
    this.lastVerifiedDate = '31 Aug 2026',
    this.specialties = const [],
    this.services = const [],
    this.facilities = const [],
    this.doctors = const [],
  });

  factory HealthcareProfileModel.fromJson(Map<String, dynamic> json) {
    List<DoctorModel> docList = [];
    if (json['doctors'] != null && json['doctors'] is List) {
      docList = (json['doctors'] as List)
          .map((d) => DoctorModel.fromJson(d as Map<String, dynamic>))
          .toList();
    }

    List<String> specList = [];
    if (json['specialties'] != null && json['specialties'] is List) {
      specList = (json['specialties'] as List)
          .map((s) => s is Map ? (s['name']?.toString() ?? '') : s.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    List<String> srvList = [];
    if (json['services'] != null && json['services'] is List) {
      srvList = (json['services'] as List)
          .map((s) => s is Map ? (s['name']?.toString() ?? '') : s.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    List<String> facList = [];
    if (json['facilities'] != null && json['facilities'] is List) {
      facList = (json['facilities'] as List)
          .map((f) => f is Map ? (f['name']?.toString() ?? '') : f.toString())
          .where((f) => f.isNotEmpty)
          .toList();
    }

    return HealthcareProfileModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization']?.toString() ?? (json['organization_id']?.toString() ?? ''),
      name: json['organization_name'] ?? (json['name'] ?? 'Healthcare Center'),
      organizationType: json['organization_type_display'] ?? (json['organization_type'] ?? 'Hospital'),
      ownershipType: json['ownership_type_display'] ?? (json['ownership_type'] ?? 'Trust'),
      verificationStatus: json['verification_status'] ?? 'VERIFIED',
      isCareLinkVerified: (json['verification_status'] == 'VERIFIED'),
      district: json['district'] ?? (json['organization_district'] ?? 'Kozhikode'),
      address: json['address'] ?? '',
      pincode: json['pincode'] ?? '673001',
      latitude: (json['latitude'] != null) ? double.tryParse(json['latitude'].toString()) ?? 11.2588 : 11.2588,
      longitude: (json['longitude'] != null) ? double.tryParse(json['longitude'].toString()) ?? 75.7804 : 75.7804,
      phone: json['phone'] ?? (json['organization_phone'] ?? ''),
      emergencyPhone: json['emergency_phone'] ?? '',
      is24x7Emergency: json['is_24x7_emergency'] ?? false,
      ambulanceAvailable: json['ambulance_available'] ?? false,
      totalBeds: json['total_beds'] ?? 0,
      icuBeds: json['icu_beds'] ?? 0,
      description: json['description'] ?? '',
      profileCompletenessScore: json['profile_completeness_score'] ?? 85,
      lastVerifiedDate: 'Recently verified',
      specialties: specList,
      services: srvList,
      facilities: facList,
      doctors: docList,
    );
  }
}

class ChangeRequestModel {
  final String id;
  final String organizationId;
  final String organizationName;
  final String requestedByName;
  final String entityType;
  final String changeSummary;
  final Map<String, dynamic> oldData;
  final Map<String, dynamic> newData;
  final String reason;
  final String status;
  final String createdAt;

  const ChangeRequestModel({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.requestedByName,
    required this.entityType,
    required this.changeSummary,
    this.oldData = const {},
    this.newData = const {},
    this.reason = '',
    this.status = 'PENDING',
    this.createdAt = 'Today',
  });

  factory ChangeRequestModel.fromJson(Map<String, dynamic> json) {
    return ChangeRequestModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization']?.toString() ?? '',
      organizationName: json['organization_name'] ?? 'Healthcare Unit',
      requestedByName: json['requested_by_name'] ?? 'Moderator',
      entityType: json['entity_type_display'] ?? (json['entity_type'] ?? 'Schedule Update'),
      changeSummary: json['change_summary'] ?? '',
      oldData: (json['old_data'] is Map) ? Map<String, dynamic>.from(json['old_data']) : {},
      newData: (json['new_data'] is Map) ? Map<String, dynamic>.from(json['new_data']) : {},
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] != null ? json['created_at'].toString().split('T').first : 'Today',
    );
  }
}

class AppointmentRequestModel {
  final String id;
  final String patientName;
  final String patientPhone;
  final int patientAge;
  final String patientGender;
  final String district;
  final String doctorName;
  final String doctorSpecialty;
  final String preferredDate;
  final String preferredTimeSlot;
  final String consultationMode;
  final String chiefComplaint;
  final String status;
  final String tokenNumber;

  const AppointmentRequestModel({
    required this.id,
    required this.patientName,
    required this.patientPhone,
    this.patientAge = 45,
    this.patientGender = 'Male',
    this.district = 'Kozhikode',
    required this.doctorName,
    required this.doctorSpecialty,
    required this.preferredDate,
    this.preferredTimeSlot = 'Morning (09:00 AM - 01:00 PM)',
    this.consultationMode = 'In-Person Hospital OPD',
    this.chiefComplaint = '',
    this.status = 'REQUESTED',
    this.tokenNumber = 'TK-01',
  });

  factory AppointmentRequestModel.fromJson(Map<String, dynamic> json) {
    return AppointmentRequestModel(
      id: json['id']?.toString() ?? '',
      patientName: json['patient_name'] ?? '',
      patientPhone: json['patient_phone'] ?? '',
      patientAge: json['patient_age'] ?? 45,
      patientGender: json['patient_gender'] ?? 'Male',
      district: json['district'] ?? 'Kozhikode',
      doctorName: json['doctor_name'] ?? 'Doctor Specialist',
      doctorSpecialty: json['doctor_specialty'] ?? 'Palliative Care',
      preferredDate: json['preferred_date'] ?? '',
      preferredTimeSlot: json['preferred_time_slot'] ?? 'Morning (09:00 AM - 01:00 PM)',
      consultationMode: json['consultation_mode'] ?? 'In-Person Hospital OPD',
      chiefComplaint: json['chief_complaint'] ?? '',
      status: json['status'] ?? 'REQUESTED',
      tokenNumber: json['token_number'] ?? 'TK-01',
    );
  }
}
