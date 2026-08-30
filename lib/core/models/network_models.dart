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
  final String dataFreshnessTier;
  final String dataFreshnessLabel;
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
    this.dataFreshnessTier = 'CURRENT',
    this.dataFreshnessLabel = 'Verified & Active 🟢',
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

    final tier = json['data_freshness_tier'] ?? 'CURRENT';
    final label = json['data_freshness_label'] ?? (tier == 'CURRENT' ? 'Verified & Active 🟢' : 'Review Recommended 🟡');

    return HealthcareProfileModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization']?.toString() ?? (json['organization_id']?.toString() ?? ''),
      name: json['organization_name'] ?? (json['name'] ?? 'Healthcare Center'),
      organizationType: json['organization_type_display'] ?? (json['organization_type'] ?? 'Hospital'),
      ownershipType: json['ownership_type_display'] ?? (json['ownership_type'] ?? 'Trust'),
      verificationStatus: json['verification_status'] ?? 'VERIFIED',
      isCareLinkVerified: (json['verification_status'] == 'VERIFIED'),
      dataFreshnessTier: tier,
      dataFreshnessLabel: label,
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

class ClaimOrganizationRequestModel {
  final String id;
  final String organizationId;
  final String organizationName;
  final String claimantUsername;
  final String claimantDesignation;
  final String officialEmail;
  final String officialPhone;
  final String proofDocumentUrl;
  final String status;

  const ClaimOrganizationRequestModel({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.claimantUsername,
    this.claimantDesignation = 'Authorized Officer',
    this.officialEmail = '',
    this.officialPhone = '',
    this.proofDocumentUrl = '',
    this.status = 'PENDING',
  });

  factory ClaimOrganizationRequestModel.fromJson(Map<String, dynamic> json) {
    return ClaimOrganizationRequestModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization']?.toString() ?? '',
      organizationName: json['organization_name'] ?? 'Healthcare Institution',
      claimantUsername: json['claimant_username'] ?? 'User',
      claimantDesignation: json['claimant_designation'] ?? 'Authorized Officer',
      officialEmail: json['official_email'] ?? '',
      officialPhone: json['official_phone'] ?? '',
      proofDocumentUrl: json['proof_document_url'] ?? '',
      status: json['status'] ?? 'PENDING',
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

class HealthcareProspectModel {
  final String id;
  final String name;
  final String district;
  final String organizationType;
  final String ownershipType;
  final String contactPerson;
  final String contactDesignation;
  final String contactPhone;
  final String contactEmail;
  final String status;
  final String statusDisplay;
  final String internalNotes;
  final String createdByUsername;
  final String createdAt;

  const HealthcareProspectModel({
    required this.id,
    required this.name,
    required this.district,
    this.organizationType = 'Hospital',
    this.ownershipType = 'Private',
    required this.contactPerson,
    this.contactDesignation = 'Medical Superintendent',
    required this.contactPhone,
    required this.contactEmail,
    this.status = 'CONTACTED',
    this.statusDisplay = 'Contacted',
    this.internalNotes = '',
    this.createdByUsername = 'admin',
    this.createdAt = '',
  });

  factory HealthcareProspectModel.fromJson(Map<String, dynamic> json) {
    return HealthcareProspectModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      district: json['district'] ?? 'Kozhikode',
      organizationType: json['organization_type'] ?? 'Hospital',
      ownershipType: json['ownership_type'] ?? 'Private',
      contactPerson: json['contact_person'] ?? '',
      contactDesignation: json['contact_designation'] ?? 'Medical Superintendent',
      contactPhone: json['contact_phone'] ?? '',
      contactEmail: json['contact_email'] ?? '',
      status: json['status'] ?? 'CONTACTED',
      statusDisplay: json['status_display'] ?? json['status'] ?? 'Contacted',
      internalNotes: json['internal_notes'] ?? '',
      createdByUsername: json['created_by_username'] ?? 'admin',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class OrganizationInvitationModel {
  final String id;
  final String organizationId;
  final String organizationName;
  final String recipientName;
  final String recipientEmail;
  final String recipientPhone;
  final String recipientDesignation;
  final String token;
  final String status;
  final String statusDisplay;
  final String expiresAt;

  const OrganizationInvitationModel({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.recipientName,
    required this.recipientEmail,
    this.recipientPhone = '',
    this.recipientDesignation = 'Hospital Administrator',
    required this.token,
    this.status = 'PENDING',
    this.statusDisplay = 'Pending Activation',
    this.expiresAt = '',
  });

  factory OrganizationInvitationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationInvitationModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization']?.toString() ?? '',
      organizationName: json['organization_name'] ?? 'Healthcare Facility',
      recipientName: json['recipient_name'] ?? '',
      recipientEmail: json['recipient_email'] ?? '',
      recipientPhone: json['recipient_phone'] ?? '',
      recipientDesignation: json['recipient_designation'] ?? 'Hospital Administrator',
      token: json['token'] ?? '',
      status: json['status'] ?? 'PENDING',
      statusDisplay: json['status_display'] ?? 'Pending',
      expiresAt: json['expires_at'] ?? '',
    );
  }
}

class OrganizationMembershipModel {
  final String id;
  final String userId;
  final String username;
  final String email;
  final String fullName;
  final String organizationId;
  final String organizationName;
  final String role;
  final String roleDisplay;
  final String status;
  final String statusDisplay;
  final String departmentName;
  final String designation;
  final String medicalRegistrationNumber;
  final String approvedByUsername;
  final String joinedAt;

  const OrganizationMembershipModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    this.fullName = '',
    required this.organizationId,
    required this.organizationName,
    required this.role,
    this.roleDisplay = 'Staff',
    required this.status,
    this.statusDisplay = 'Active',
    this.departmentName = '',
    this.designation = '',
    this.medicalRegistrationNumber = '',
    this.approvedByUsername = '',
    this.joinedAt = '',
  });

  factory OrganizationMembershipModel.fromJson(Map<String, dynamic> json) {
    return OrganizationMembershipModel(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['username'] ?? '',
      organizationId: json['organization']?.toString() ?? '',
      organizationName: json['organization_name'] ?? '',
      role: json['role'] ?? 'STAFF',
      roleDisplay: json['role_display'] ?? json['role'] ?? 'Staff',
      status: json['status'] ?? 'ACTIVE',
      statusDisplay: json['status_display'] ?? json['status'] ?? 'Active',
      departmentName: json['department_name'] ?? '',
      designation: json['designation'] ?? '',
      medicalRegistrationNumber: json['medical_registration_number'] ?? '',
      approvedByUsername: json['approved_by_username'] ?? '',
      joinedAt: json['joined_at'] ?? json['created_at'] ?? '',
    );
  }
}

class HospitalTeamInvitationModel {
  final String id;
  final String organizationName;
  final String recipientName;
  final String recipientEmail;
  final String recipientPhone;
  final String role;
  final String roleDisplay;
  final String departmentName;
  final String designation;
  final String token;
  final String status;
  final String expiresAt;

  const HospitalTeamInvitationModel({
    required this.id,
    required this.organizationName,
    required this.recipientName,
    required this.recipientEmail,
    this.recipientPhone = '',
    required this.role,
    this.roleDisplay = 'Staff',
    this.departmentName = '',
    this.designation = '',
    required this.token,
    this.status = 'PENDING',
    this.expiresAt = '',
  });

  factory HospitalTeamInvitationModel.fromJson(Map<String, dynamic> json) {
    return HospitalTeamInvitationModel(
      id: json['id']?.toString() ?? '',
      organizationName: json['organization_name'] ?? '',
      recipientName: json['recipient_name'] ?? '',
      recipientEmail: json['recipient_email'] ?? '',
      recipientPhone: json['recipient_phone'] ?? '',
      role: json['role'] ?? 'STAFF',
      roleDisplay: json['role_display'] ?? json['role'] ?? 'Staff',
      departmentName: json['department_name'] ?? '',
      designation: json['designation'] ?? '',
      token: json['token'] ?? '',
      status: json['status'] ?? 'PENDING',
      expiresAt: json['expires_at'] ?? '',
    );
  }
}

class DoctorAvailabilityModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String organizationId;
  final String date;
  final String status;
  final String statusDisplay;
  final String reason;

  const DoctorAvailabilityModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.organizationId,
    required this.date,
    required this.status,
    this.statusDisplay = 'Available on Duty',
    this.reason = '',
  });

  factory DoctorAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilityModel(
      id: json['id']?.toString() ?? '',
      doctorId: json['doctor']?.toString() ?? json['doctor_id']?.toString() ?? '',
      doctorName: json['doctor_name'] ?? '',
      organizationId: json['organization']?.toString() ?? json['organization_id']?.toString() ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'AVAILABLE',
      statusDisplay: json['status_display'] ?? json['status'] ?? 'Available',
      reason: json['reason'] ?? '',
    );
  }
}

class QueueTokenModel {
  final String id;
  final int tokenNumber;
  final String tokenLabel;
  final String patientName;
  final String patientPhone;
  final String status;
  final String statusDisplay;
  final String calledAt;
  final String consultationStartedAt;
  final String completedAt;
  final String clinicalNotes;

  const QueueTokenModel({
    required this.id,
    required this.tokenNumber,
    required this.tokenLabel,
    required this.patientName,
    required this.patientPhone,
    required this.status,
    this.statusDisplay = 'Waiting',
    this.calledAt = '',
    this.consultationStartedAt = '',
    this.completedAt = '',
    this.clinicalNotes = '',
  });

  factory QueueTokenModel.fromJson(Map<String, dynamic> json) {
    return QueueTokenModel(
      id: json['id']?.toString() ?? '',
      tokenNumber: json['token_number'] ?? 0,
      tokenLabel: json['token_label'] ?? 'A-01',
      patientName: json['patient_name'] ?? '',
      patientPhone: json['patient_phone'] ?? '',
      status: json['status'] ?? 'WAITING',
      statusDisplay: json['status_display'] ?? json['status'] ?? 'Waiting',
      calledAt: json['called_at'] ?? '',
      consultationStartedAt: json['consultation_started_at'] ?? '',
      completedAt: json['completed_at'] ?? '',
      clinicalNotes: json['clinical_notes'] ?? '',
    );
  }
}

class QueueSessionModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String departmentName;
  final String roomNumber;
  final int currentTokenNumber;
  final int totalTokensIssued;
  final bool isActive;
  final List<QueueTokenModel> tokens;

  const QueueSessionModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    this.departmentName = 'General OPD',
    this.roomNumber = 'Room 102',
    this.currentTokenNumber = 0,
    this.totalTokensIssued = 0,
    this.isActive = true,
    this.tokens = const [],
  });

  factory QueueSessionModel.fromJson(Map<String, dynamic> json) {
    List<QueueTokenModel> parsedTokens = [];
    if (json['tokens'] != null && json['tokens'] is List) {
      parsedTokens = (json['tokens'] as List)
          .map((t) => QueueTokenModel.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return QueueSessionModel(
      id: json['id']?.toString() ?? '',
      doctorId: json['doctor']?.toString() ?? '',
      doctorName: json['doctor_name'] ?? '',
      departmentName: json['department_name'] ?? 'General OPD',
      roomNumber: json['room_number'] ?? 'Room 102',
      currentTokenNumber: json['current_token_number'] ?? 0,
      totalTokensIssued: json['total_tokens_issued'] ?? 0,
      isActive: json['is_active'] ?? true,
      tokens: parsedTokens,
    );
  }
}

class LiveQueueTrackerModel {
  final String tokenId;
  final String tokenLabel;
  final int tokenNumber;
  final String tokenStatus;
  final String tokenStatusDisplay;
  final int currentTokenNumber;
  final String currentTokenLabel;
  final int patientsAhead;
  final int estimatedWaitMinutes;
  final String doctorName;
  final String doctorSpecialty;
  final String roomNumber;
  final String organizationName;
  final String emergencyPhone;
  final String sessionDate;

  const LiveQueueTrackerModel({
    required this.tokenId,
    required this.tokenLabel,
    required this.tokenNumber,
    required this.tokenStatus,
    this.tokenStatusDisplay = 'Waiting in Queue',
    this.currentTokenNumber = 0,
    this.currentTokenLabel = 'Not Started',
    this.patientsAhead = 0,
    this.estimatedWaitMinutes = 0,
    required this.doctorName,
    this.doctorSpecialty = 'General Medicine',
    this.roomNumber = 'Room 102',
    required this.organizationName,
    this.emergencyPhone = '',
    this.sessionDate = '',
  });

  factory LiveQueueTrackerModel.fromJson(Map<String, dynamic> json) {
    return LiveQueueTrackerModel(
      tokenId: json['token_id']?.toString() ?? '',
      tokenLabel: json['token_label'] ?? 'A-01',
      tokenNumber: json['token_number'] ?? 1,
      tokenStatus: json['token_status'] ?? 'WAITING',
      tokenStatusDisplay: json['token_status_display'] ?? json['token_status'] ?? 'Waiting',
      currentTokenNumber: json['current_token_number'] ?? 0,
      currentTokenLabel: json['current_token_label'] ?? 'Not Started',
      patientsAhead: json['patients_ahead'] ?? 0,
      estimatedWaitMinutes: json['estimated_wait_minutes'] ?? 0,
      doctorName: json['doctor_name'] ?? 'Doctor',
      doctorSpecialty: json['doctor_specialty'] ?? 'General Medicine',
      roomNumber: json['room_number'] ?? 'OPD Room',
      organizationName: json['organization_name'] ?? 'Hospital',
      emergencyPhone: json['emergency_phone'] ?? '',
      sessionDate: json['session_date'] ?? '',
    );
  }
}


