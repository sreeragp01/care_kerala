import 'patient_model.dart';

class VisitModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientAddress;
  final String assignedNurseName;
  final String scheduledDate;
  final String scheduledTime;
  String status; // Scheduled, Assigned, Accepted, In Progress, Completed, Doctor Review, Closed
  String? gpsCheckInTime;
  String? gpsLocationName;
  VitalsReading? recordedVitals;
  String? clinicalNotes;
  String? symptomsObserved;
  String? assessmentNotes;
  String? careProvided;
  String? medicationAdministered;
  String? equipmentUsed;
  String? followUpInstructions;
  String? nextVisitDate;
  String? doctorReviewNotes;
  bool doctorSignedOff;
  String? doctorSignoffTimestamp;
  String? voiceRecordingPath;
  List<String> photos;
  bool isSyncedOffline;

  VisitModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAddress,
    required this.assignedNurseName,
    required this.scheduledDate,
    required this.scheduledTime,
    this.status = 'Scheduled',
    this.gpsCheckInTime,
    this.gpsLocationName,
    this.recordedVitals,
    this.clinicalNotes,
    this.symptomsObserved,
    this.assessmentNotes,
    this.careProvided,
    this.medicationAdministered,
    this.equipmentUsed,
    this.followUpInstructions,
    this.nextVisitDate,
    this.doctorReviewNotes,
    this.doctorSignedOff = false,
    this.doctorSignoffTimestamp,
    this.voiceRecordingPath,
    this.photos = const [],
    this.isSyncedOffline = true,
  });
}


class AppointmentModel {
  final String id;
  final String patientName;
  final String doctorName;
  final String date;
  final String time;
  final String type; // Clinic Consultation, Tele-Palliative, Home Visit Request
  final String status; // Confirmed, Pending, Completed

  AppointmentModel({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
  });
}

class VolunteerModel {
  final String id;
  final String name;
  final String district;
  final String ward;
  final String phone;
  final bool isVerified;
  final int assignedPatientsCount;
  final int totalHoursLogged;
  final int tasksCompleted;

  VolunteerModel({
    required this.id,
    required this.name,
    required this.district,
    required this.ward,
    required this.phone,
    required this.isVerified,
    required this.assignedPatientsCount,
    required this.totalHoursLogged,
    required this.tasksCompleted,
  });
}

class BloodDonorModel {
  final String id;
  final String name;
  final String bloodGroup;
  final String district;
  final String locality;
  final String phone;
  final DateTime lastDonationDate;
  final int totalDonations;
  final bool isAvailable;

  BloodDonorModel({
    required this.id,
    required this.name,
    required this.bloodGroup,
    required this.district,
    required this.locality,
    required this.phone,
    required this.lastDonationDate,
    required this.totalDonations,
    required this.isAvailable,
  });

  // Automatically calculate eligibility based on 90 days donation interval
  bool get isEligible {
    if (!isAvailable) return false;
    final days = DateTime.now().difference(lastDonationDate).inDays;
    return days >= 90;
  }

  int get daysRemaining {
    final days = DateTime.now().difference(lastDonationDate).inDays;
    if (days >= 90) return 0;
    return 90 - days;
  }
}

class BloodRequestModel {
  final String id;
  final String patientName;
  final String bloodGroup;
  final String hospitalName;
  final String district;
  final int unitsNeeded;
  final String urgency; // Emergency, Urgent, Normal
  final String requestedDate;
  String status; // Active, Fulfilled

  BloodRequestModel({
    required this.id,
    required this.patientName,
    required this.bloodGroup,
    required this.hospitalName,
    required this.district,
    required this.unitsNeeded,
    required this.urgency,
    required this.requestedDate,
    this.status = 'Active',
  });
}

class MedicineItemModel {
  final String id;
  final String name;
  final String category;
  final int stockQuantity;
  final String unit; // tablets, bottles, ampoules
  final int reorderLevel;
  final String expiryDate;
  final String batchNumber;

  MedicineItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.stockQuantity,
    required this.unit,
    required this.reorderLevel,
    required this.expiryDate,
    required this.batchNumber,
  });

  bool get isLowStock => stockQuantity <= reorderLevel;
}

class EquipmentItemModel {
  final String id;
  final String name;
  final int totalCount;
  final int availableCount;
  final int loanedCount;
  final String maintenanceStatus; // Good, Servicing Required

  EquipmentItemModel({
    required this.id,
    required this.name,
    required this.totalCount,
    required this.availableCount,
    required this.loanedCount,
    required this.maintenanceStatus,
  });
}

class AmbulanceDriverModel {
  final String id;
  final String driverName;
  final String vehicleNumber;
  final String phone;
  final String district;
  String currentStatus; // Available, Dispatched, On Duty

  AmbulanceDriverModel({
    required this.id,
    required this.driverName,
    required this.vehicleNumber,
    required this.phone,
    required this.district,
    this.currentStatus = 'Available',
  });
}

class CommunityCampaignModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String beneficiaryName;
  final String beneficiaryRelation;
  final String locality;
  final String district;
  final String category; // Patient Support, Medicine Pool, Equipment Aid, Chemotherapy Care
  final String urgency; // High Priority, Urgent Care, Ongoing Support
  int supportersCount;
  final String patientFamilyGratitudeTemplate;
  final bool isVerified;

  CommunityCampaignModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.beneficiaryName,
    required this.beneficiaryRelation,
    required this.locality,
    required this.district,
    required this.category,
    required this.urgency,
    this.supportersCount = 0,
    required this.patientFamilyGratitudeTemplate,
    this.isVerified = true,
  });
}

class DonationModel {
  final String id;
  final String donorName;
  final double amount;
  final String category; // General Palliative Fund, Equipment Fund, Medicine Support, Treatment Appeal
  final String paymentMode; // Razorpay, UPI_QR, Bank Transfer, Cash
  final String receiptNumber;
  final String date;
  final String? transactionId;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final bool isVerified;
  final String? donorPrayer;
  final bool isAnonymous;

  DonationModel({
    required this.id,
    required this.donorName,
    required this.amount,
    required this.category,
    required this.paymentMode,
    required this.receiptNumber,
    required this.date,
    this.transactionId,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.isVerified = true,
    this.donorPrayer,
    this.isAnonymous = false,
  });
}

class MedicalFundraiserModel {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String bloodGroup;
  final String district;
  final String ward;
  final String hospitalName;
  final String doctorName;
  final String treatmentTitle;
  final String category; // Surgery, Oncology, Pediatric, Transplant, Rehabilitation
  double targetAmount;
  double collectedAmount;
  int donorsCount;
  String story;
  final String medicalEstimateSummary;
  bool isDoctorVerified;
  final int daysRemaining;
  final String createdDate;
  String status; // Active, Target Reached, Completed
  final String patientFamilyGratitudeMessage;

  // Multi-Org & QR Routing System
  final String cooperatingOrgId;
  final String cooperatingOrgName;
  bool useOrgQr; // If true, routes to cooperating organization's verified QR; if false, uses custom campaign QR
  final String? customUpiId;
  final String? customQrUrl;

  MedicalFundraiserModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.bloodGroup,
    required this.district,
    required this.ward,
    required this.hospitalName,
    required this.doctorName,
    required this.treatmentTitle,
    required this.category,
    required this.targetAmount,
    this.collectedAmount = 0.0,
    this.donorsCount = 0,
    required this.story,
    required this.medicalEstimateSummary,
    this.isDoctorVerified = true,
    required this.daysRemaining,
    required this.createdDate,
    this.status = 'Active',
    required this.patientFamilyGratitudeMessage,
    this.cooperatingOrgId = 'org_kozhikode',
    this.cooperatingOrgName = 'Kozhikode Palliative Care Society',
    this.useOrgQr = true,
    this.customUpiId,
    this.customQrUrl,
  });

  double get percentFunded {
    if (targetAmount <= 0) return 0.0;
    final pct = (collectedAmount / targetAmount);
    return pct > 1.0 ? 1.0 : pct;
  }

  double get remainingAmount {
    final rem = targetAmount - collectedAmount;
    return rem < 0 ? 0.0 : rem;
  }

  /// Resolves the active UPI VPA string for this fundraiser
  String getActiveUpiVpa(String orgUpiId) {
    if (!useOrgQr && customUpiId != null && customUpiId!.isNotEmpty) {
      return customUpiId!;
    }
    return orgUpiId.isNotEmpty ? orgUpiId : 'carelinkkerala@sbi';
  }

  /// Generates the UPI QR string for scanning via GPay / PhonePe / Paytm / BHIM
  String generateUpiPayload({required String orgUpiId, double? amount}) {
    final vpa = getActiveUpiVpa(orgUpiId);
    final payeeName = useOrgQr ? cooperatingOrgName : '$patientName Treatment Fund';
    final pn = Uri.encodeComponent(payeeName);
    final tn = Uri.encodeComponent('Medical Support: $treatmentTitle ($patientName)');
    var upi = 'upi://pay?pa=$vpa&pn=$pn&tn=$tn&cu=INR';
    if (amount != null && amount > 0) {
      upi += '&am=${amount.toStringAsFixed(2)}';
    }
    return upi;
  }
}

class FundraiserDonationModel {
  final String id;
  final String fundraiserId;
  final String donorName;
  final double amount;
  final String date;
  final String receiptNumber;
  final String? donorPrayer;
  final bool isAnonymous;
  final String paymentMode; // Razorpay, UPI_QR, Bank Transfer
  final String? razorpayPaymentId;

  FundraiserDonationModel({
    required this.id,
    required this.fundraiserId,
    required this.donorName,
    required this.amount,
    required this.date,
    required this.receiptNumber,
    this.donorPrayer,
    this.isAnonymous = false,
    this.paymentMode = 'Razorpay',
    this.razorpayPaymentId,
  });
}


class EmergencySosEvent {
  final String id;
  final String patientId;
  final String patientName;
  final String diagnosis;
  final String bloodGroup;
  final String ward;
  final String district;
  final String gpsCoordinates;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String triggerMethod;
  final String timestamp;
  final String dispatchedAmbulanceVehicle;
  final String dispatchedAmbulanceDriver;
  final String dispatchedAmbulancePhone;
  final String assignedNurseName;
  final String assignedDoctorName;
  final String wardVolunteerName;
  String status; // "Broadcasting", "Ambulance En-Route", "Resolved", "Cancelled"

  EmergencySosEvent({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.diagnosis,
    required this.bloodGroup,
    required this.ward,
    required this.district,
    required this.gpsCoordinates,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.triggerMethod,
    required this.timestamp,
    required this.dispatchedAmbulanceVehicle,
    required this.dispatchedAmbulanceDriver,
    required this.dispatchedAmbulancePhone,
    required this.assignedNurseName,
    required this.assignedDoctorName,
    required this.wardVolunteerName,
    this.status = 'Ambulance En-Route',
  });
}

class HomeVisitRequestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String requesterName;
  final String requesterPhone;
  final String requesterRelationship;
  final String visitType;
  final String urgency;
  final String preferredDate;
  final String preferredTimeSlot;
  final String reasonAndSymptoms;
  final String locationAddress;
  String status;
  String? rejectionReason;
  final String createdAt;

  HomeVisitRequestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.requesterName,
    required this.requesterPhone,
    required this.requesterRelationship,
    required this.visitType,
    required this.urgency,
    required this.preferredDate,
    required this.preferredTimeSlot,
    required this.reasonAndSymptoms,
    required this.locationAddress,
    this.status = 'PENDING',
    this.rejectionReason,
    required this.createdAt,
  });
}

class CareTeamMemberModel {
  final String id;
  final String? userId;
  final String? username;
  final String memberName;
  final String role;
  final String phone;
  final bool isPrimary;

  CareTeamMemberModel({
    required this.id,
    this.userId,
    this.username,
    required this.memberName,
    required this.role,
    required this.phone,
    this.isPrimary = false,
  });
}

class CareTeamModel {
  final String id;
  final String name;
  final String leadDoctorName;
  final String primaryNurseName;
  final String areaCoverage;
  final bool isActive;
  final List<CareTeamMemberModel> members;

  CareTeamModel({
    required this.id,
    required this.name,
    required this.leadDoctorName,
    required this.primaryNurseName,
    required this.areaCoverage,
    this.isActive = true,
    this.members = const [],
  });
}

class PatientCareGoalModel {
  final String id;
  final String patientId;
  final String category;
  final String description;
  final String targetDate;
  bool isAchieved;
  String? notes;

  PatientCareGoalModel({
    required this.id,
    required this.patientId,
    required this.category,
    required this.description,
    required this.targetDate,
    this.isAchieved = false,
    this.notes,
  });
}

class CaregiverAccessModel {
  final String id;
  final String patientId;
  final String caregiverName;
  final String caregiverPhone;
  final String relationship;
  final List<String> permissions;
  bool isActive;
  final String grantedBy;
  final String grantedAt;

  CaregiverAccessModel({
    required this.id,
    required this.patientId,
    required this.caregiverName,
    required this.caregiverPhone,
    required this.relationship,
    required this.permissions,
    this.isActive = true,
    required this.grantedBy,
    required this.grantedAt,
  });

  bool hasPermission(String perm) => permissions.contains(perm);
}

class MedicationAdministrationModel {
  final String id;
  final String planId;
  final String medicineName;
  final String dosage;
  final String patientId;
  final String scheduledDate;
  final String timeSlot;
  String status;
  final bool recordedByCaregiver;
  final bool verifiedByNurse;
  final String? verifiedNurseName;
  final String administeredAt;
  final String notes;

  MedicationAdministrationModel({
    required this.id,
    required this.planId,
    required this.medicineName,
    required this.dosage,
    required this.patientId,
    required this.scheduledDate,
    required this.timeSlot,
    required this.status,
    this.recordedByCaregiver = true,
    this.verifiedByNurse = false,
    this.verifiedNurseName,
    required this.administeredAt,
    this.notes = '',
  });
}

class MedicationPlanModel {
  final String id;
  final String patientId;
  final String medicineName;
  final String dosage;
  final String route;
  final String frequency;
  final List<String> timeSlots;
  final String prescribedByDoctor;
  final String startDate;
  final String? endDate;
  final String instructions;
  final bool isActive;
  final List<MedicationAdministrationModel> administrations;

  MedicationPlanModel({
    required this.id,
    required this.patientId,
    required this.medicineName,
    required this.dosage,
    required this.route,
    required this.frequency,
    required this.timeSlots,
    required this.prescribedByDoctor,
    required this.startDate,
    this.endDate,
    required this.instructions,
    this.isActive = true,
    this.administrations = const [],
  });
}

class RouteStopModel {
  final String id;
  final String visitId;
  final String patientName;
  final String patientAddress;
  final String patientPhone;
  final String visitType;
  final int sequenceOrder;
  final String locationArea;
  final String estimatedArrivalTime;
  bool isCompleted;

  RouteStopModel({
    required this.id,
    required this.visitId,
    required this.patientName,
    required this.patientAddress,
    required this.patientPhone,
    required this.visitType,
    required this.sequenceOrder,
    required this.locationArea,
    required this.estimatedArrivalTime,
    this.isCompleted = false,
  });
}

class CareTeamRouteModel {
  final String id;
  final String careTeamId;
  final String careTeamName;
  final String routeDate;
  final String primaryNurseName;
  String status;
  final int totalStops;
  final String notes;
  final List<RouteStopModel> stops;

  CareTeamRouteModel({
    required this.id,
    required this.careTeamId,
    required this.careTeamName,
    required this.routeDate,
    required this.primaryNurseName,
    this.status = 'PLANNED',
    required this.totalStops,
    this.notes = '',
    this.stops = const [],
  });
}

