class VitalsReading {
  final String date;
  final String bp; // e.g. "120/80"
  final int pulse;
  final int spo2; // e.g. 98%
  final double temperature; // e.g. 98.6 F
  final int painScale; // 0-10
  final int respiratoryRate;
  final String recordedBy;

  VitalsReading({
    required this.date,
    required this.bp,
    required this.pulse,
    required this.spo2,
    this.temperature = 98.6,
    required this.painScale,
    this.respiratoryRate = 16,
    required this.recordedBy,
  });
}

class CarePlanModel {
  final String primaryNurseName;
  final String assignedDoctorName;
  final String careGoals;
  final String dietaryInstructions;
  final String emergencyEscalationNotes;
  final int reviewFrequencyDays;
  final String lastReviewedDate;

  CarePlanModel({
    required this.primaryNurseName,
    required this.assignedDoctorName,
    required this.careGoals,
    this.dietaryInstructions = '',
    this.emergencyEscalationNotes = '',
    this.reviewFrequencyDays = 14,
    required this.lastReviewedDate,
  });
}

class EquipmentIssued {
  final String equipmentName;
  final String issuedDate;
  final String serialNumber;
  final String status; // Active, Returned

  EquipmentIssued({
    required this.equipmentName,
    required this.issuedDate,
    required this.serialNumber,
    required this.status,
  });
}

class FamilyMemberContact {
  final String name;
  final String relation;
  final String phone;

  FamilyMemberContact({
    required this.name,
    required this.relation,
    required this.phone,
  });
}

class PatientModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String bloodGroup;
  final String district;
  final String ward;
  final String address;
  final String phone;
  final String lifecycleStatus; // Registration, Active Care, Follow-up, Discharged
  final String categoryTier; // Category A, B, C, D
  final String diagnosis;
  final String riskLevel; // High, Moderate, Low
  final String aiSummary;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final CarePlanModel? carePlan;
  final List<VitalsReading> vitalsHistory;
  final List<EquipmentIssued> equipmentIssued;
  final List<FamilyMemberContact> familyMembers;
  final List<String> medicalHistory;
  final String registeredDate;
  final String? referredBy;
  final String? referralUrgency;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.district,
    required this.ward,
    required this.address,
    required this.phone,
    this.lifecycleStatus = 'Active Care',
    required this.categoryTier,
    required this.diagnosis,
    required this.riskLevel,
    required this.aiSummary,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    this.carePlan,
    required this.vitalsHistory,
    required this.equipmentIssued,
    required this.familyMembers,
    required this.medicalHistory,
    required this.registeredDate,
    this.referredBy,
    this.referralUrgency,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'blood_group': bloodGroup,
      'district': district,
      'ward': ward,
      'address': address,
      'phone': phone,
      'lifecycle_status': lifecycleStatus,
      'category_tier': categoryTier,
      'diagnosis': diagnosis,
      'risk_level': riskLevel,
      'registered_date': registeredDate,
      'referred_by': referredBy,
      'referral_urgency': referralUrgency,
    };
  }
}


