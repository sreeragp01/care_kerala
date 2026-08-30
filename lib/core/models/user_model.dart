enum UserRole {
  superAdmin,
  orgAdmin,
  doctor,
  nurse,
  volunteer,
  reception,
  pharmacist,
  accountant,
  ambulanceDriver,
  patient,
  familyMember,
  palliativeMember,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.orgAdmin:
        return 'Organization Admin';
      case UserRole.doctor:
        return 'Palliative Doctor';
      case UserRole.nurse:
        return 'Community Nurse';
      case UserRole.volunteer:
        return 'Palliative Volunteer';
      case UserRole.reception:
        return 'Receptionist';
      case UserRole.pharmacist:
        return 'Pharmacist';
      case UserRole.accountant:
        return 'Accountant';
      case UserRole.ambulanceDriver:
        return 'Ambulance Driver';
      case UserRole.patient:
        return 'Patient';
      case UserRole.familyMember:
        return 'Family Member';
      case UserRole.palliativeMember:
        return 'Palliative Member';
    }
  }

  bool get isPatientOrFamily => this == UserRole.patient || this == UserRole.familyMember;
  bool get isClinicalStaff => this == UserRole.doctor || this == UserRole.nurse;
  bool get isAdmin => this == UserRole.superAdmin || this == UserRole.orgAdmin;
  bool get isVolunteer => this == UserRole.volunteer;
  bool get isAmbulanceDriver => this == UserRole.ambulanceDriver;
  bool get isPalliativeMember => this == UserRole.palliativeMember;

  bool get canAccessClinicalRecords => isAdmin || isClinicalStaff || isVolunteer || this == UserRole.reception;
  bool get canReferPatients => true; // All roles (Palliative Members, Family, Community) can refer patients in need
  bool get canAccessBloodDirectory => true; // Universal access across all roles
  bool get canManageInventory => isAdmin || this == UserRole.pharmacist || this == UserRole.nurse;
  bool get canDispatchAmbulance => isAdmin || isAmbulanceDriver || isClinicalStaff;
  bool get canConfigureBackend => isAdmin;
  bool get canSwitchRolesInSettings => isAdmin;
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String organizationId;
  final String district;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.organizationId,
    required this.district,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.name,
    'organization_id': organizationId,
    'district': district,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? 'USR-01',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.nurse,
      ),
      organizationId: json['organization_id'] ?? 'org_kozhikode',
      district: json['district'] ?? 'Kozhikode',
    );
  }
}


class OrganizationModel {
  final String id;
  final String name;
  final String district;
  final String registrationNumber;
  final String phone;
  final String upiId;
  final String bankAccountName;
  final String bankAccountNumber;
  final String ifscCode;
  final String bankName;
  final String qrCodeUrl;
  final String razorpayKeyId;
  final int activePatientsCount;
  final int totalVisitsCount;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.district,
    required this.registrationNumber,
    required this.phone,
    this.upiId = '',
    this.bankAccountName = '',
    this.bankAccountNumber = '',
    this.ifscCode = '',
    this.bankName = '',
    this.qrCodeUrl = '',
    this.razorpayKeyId = 'rzp_test_CareLinkKerala2026',
    required this.activePatientsCount,
    required this.totalVisitsCount,
  });

  /// Generates standard UPI QR Intent payload for payment apps (GPay, PhonePe, Paytm, BHIM)
  String generateUpiString({double? amount, String? note}) {
    final vpa = upiId.isNotEmpty ? upiId : 'carelinkkerala@sbi';
    final pn = Uri.encodeComponent(name);
    final tn = Uri.encodeComponent(note ?? 'Palliative Care Donation');
    var upi = 'upi://pay?pa=$vpa&pn=$pn&tn=$tn&cu=INR';
    if (amount != null && amount > 0) {
      upi += '&am=${amount.toStringAsFixed(2)}';
    }
    return upi;
  }
}

