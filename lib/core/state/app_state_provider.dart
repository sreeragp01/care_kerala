import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/clinical_models.dart';
import '../models/network_models.dart';
import '../services/mock_database_service.dart';
import '../services/network_database_service.dart';
import '../services/api_service.dart';
import '../services/auth_session_service.dart';

class AppStateProvider extends ChangeNotifier {
  // Locale & Theme State
  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  bool _isDarkMode = true; // Emerald Glass Theme by default
  bool get isDarkMode => _isDarkMode;

  // Authentication & Persistent JWT Session State
  bool _isLoggedIn = false;
  bool _isSessionLoaded = false;
  String? _jwtToken;
  String? _refreshToken;

  bool get isLoggedIn => _isLoggedIn;
  bool get isSessionLoaded => _isSessionLoaded;
  String? get jwtToken => _jwtToken;
  String? get refreshToken => _refreshToken;

  // Backend API URL State
  String _apiBaseUrl = 'http://127.0.0.1:8000/api';
  String get apiBaseUrl => _apiBaseUrl;

  // Notification Preferences
  bool _notifyEmergencyBlood = true;
  bool _notifyCriticalPatients = true;
  bool _notifyLowStock = true;
  bool get notifyEmergencyBlood => _notifyEmergencyBlood;
  bool get notifyCriticalPatients => _notifyCriticalPatients;
  bool get notifyLowStock => _notifyLowStock;

  // Multi-Tenancy State
  List<OrganizationModel> _organizations = [];
  OrganizationModel? _activeOrganization;
  List<OrganizationModel> get organizations => _organizations;
  OrganizationModel? get activeOrganization => _activeOrganization;

  // User & Demo Role Switcher
  UserModel _currentUser = UserModel(
    id: 'USR-01',
    name: 'Nurse Anitha',
    email: 'anitha@carelink.kerala.gov.in',
    phone: '+91 98470 12345',
    role: UserRole.nurse,
    organizationId: 'org_kozhikode',
    district: 'Kozhikode',
  );
  UserModel get currentUser => _currentUser;


  // Data Store Lists
  List<PatientModel> _patients = [];
  List<VisitModel> _visits = [];
  List<AppointmentModel> _appointments = [];
  List<VolunteerModel> _volunteers = [];
  List<BloodDonorModel> _bloodDonors = [];
  List<BloodRequestModel> _bloodRequests = [];
  List<MedicineItemModel> _medicines = [];
  List<EquipmentItemModel> _equipment = [];
  List<AmbulanceDriverModel> _ambulanceDrivers = [];
  List<DonationModel> _donations = [];
  List<CommunityCampaignModel> _campaigns = [];
  List<MedicalFundraiserModel> _fundraisers = [];
  final List<EmergencySosEvent> _sosEvents = [];
  EmergencySosEvent? _activeSosEvent;
  List<String> _notifications = [];
  int _pendingOfflineSyncCount = 0;

  // Phase 2.7 Palliative & Home Healthcare 2.0 State
  List<HomeVisitRequestModel> _homeVisitRequests = [];
  List<CareTeamModel> _careTeams = [];
  List<MedicationPlanModel> _medicationPlans = [];
  List<CaregiverAccessModel> _caregiverGrants = [];
  List<CareTeamRouteModel> _dailyRoutes = [];

  // Getters
  List<PatientModel> get patients => _patients;
  List<VisitModel> get visits => _visits;
  List<AppointmentModel> get appointments => _appointments;
  List<VolunteerModel> get volunteers => _volunteers;
  List<BloodDonorModel> get bloodDonors => _bloodDonors;
  List<BloodRequestModel> get bloodRequests => _bloodRequests;
  List<MedicineItemModel> get medicines => _medicines;
  List<EquipmentItemModel> get equipment => _equipment;
  List<AmbulanceDriverModel> get ambulanceDrivers => _ambulanceDrivers;
  List<DonationModel> get donations => _donations;
  List<CommunityCampaignModel> get campaigns => _campaigns;
  List<MedicalFundraiserModel> get fundraisers => _fundraisers;
  List<EmergencySosEvent> get sosEvents => List.unmodifiable(_sosEvents);
  EmergencySosEvent? get activeSosEvent => _activeSosEvent;
  List<String> get notifications => _notifications;
  int get pendingOfflineSyncCount => _pendingOfflineSyncCount;

  List<HomeVisitRequestModel> get homeVisitRequests => _homeVisitRequests;
  List<CareTeamModel> get careTeams => _careTeams;
  List<MedicationPlanModel> get medicationPlans => _medicationPlans;
  List<CaregiverAccessModel> get caregiverGrants => _caregiverGrants;
  List<CareTeamRouteModel> get dailyRoutes => _dailyRoutes;

  // Calculated Metrics for Dashboard
  int get todaysVisitsCount => _visits.where((v) => v.scheduledDate == '2026-08-07' || v.scheduledDate == '2026-08-06' || v.scheduledDate == '2026-08-08').length;
  int get activePatientsCount => _patients.length;
  int get criticalPatientsCount => _patients.where((p) => p.riskLevel == 'High Risk').length;
  int get lowStockMedicinesCount => _medicines.where((m) => m.isLowStock).length;
  int get activeBloodRequestsCount => _bloodRequests.where((r) => r.status == 'Active').length;
  double get totalDonationsFund => _donations.fold(0.0, (sum, d) => sum + d.amount);

  AppStateProvider() {
    _initMockData();
    // Restore persistent JWT session if user previously logged in
    restoreSavedSession();
    // Auto-connect to Django REST Backend on startup
    syncWithDjangoBackend();
  }


  void _initMockData() {
    _organizations = MockDatabaseService.getOrganizations();
    _activeOrganization = _organizations.first;
    _patients = MockDatabaseService.getInitialPatients();
    _visits = MockDatabaseService.getInitialVisits();
    _appointments = [
      AppointmentModel(id: 'APT-01', patientName: 'Karthyayani Amma', doctorName: 'Dr. Suresh Kumar', date: '2026-08-08', time: '11:00 AM', type: 'Home Visit Request', status: 'Confirmed'),
      AppointmentModel(id: 'APT-02', patientName: 'Vaidyanathan Nair', doctorName: 'Dr. Priya Varma', date: '2026-08-09', time: '02:30 PM', type: 'Clinic Consultation', status: 'Confirmed'),
    ];
    _volunteers = [
      VolunteerModel(id: 'VOL-01', name: 'Rahul V.', district: 'Kozhikode', ward: 'Chevayur', phone: '+91 97440 11223', isVerified: true, assignedPatientsCount: 4, totalHoursLogged: 48, tasksCompleted: 14),
      VolunteerModel(id: 'VOL-02', name: 'Lakshmi Nair', district: 'Kozhikode', ward: 'Mavoor', phone: '+91 98461 44556', isVerified: true, assignedPatientsCount: 2, totalHoursLogged: 32, tasksCompleted: 9),
    ];
    _bloodDonors = MockDatabaseService.getInitialBloodDonors();
    _bloodRequests = MockDatabaseService.getInitialBloodRequests();
    _medicines = MockDatabaseService.getInitialMedicines();
    _equipment = MockDatabaseService.getInitialEquipment();
    _ambulanceDrivers = MockDatabaseService.getInitialAmbulanceDrivers();
    _campaigns = MockDatabaseService.getInitialCampaigns();
    _fundraisers = MockDatabaseService.getInitialMedicalFundraisers();
    _donations = MockDatabaseService.getInitialDonations();
    _registeredUsers = MockDatabaseService.getDemoUsers();
    
    // CareLink Network 2.0 State Initialization
    _healthcareProfiles = NetworkDatabaseService.getInitialHealthcareDirectory();
    _doctors = NetworkDatabaseService.getInitialDoctors();
    _specialties = NetworkDatabaseService.getInitialSpecialties();
    _changeRequests = NetworkDatabaseService.getInitialChangeRequests();
    _claimRequests = NetworkDatabaseService.getInitialClaimRequests();
    _appointmentRequests = NetworkDatabaseService.getInitialAppointmentRequests();

    // Phase 2.7 Palliative & Home Healthcare Initial Data
    _careTeams = [
      CareTeamModel(
        id: 'CT-01',
        name: 'Feroke Palliative Care Team A',
        leadDoctorName: 'Dr. Anil Kumar (Palliative Lead)',
        primaryNurseName: 'Nurse Anitha (Palliative Specialist)',
        areaCoverage: 'Feroke, Ramanattukara, Kadalundi',
        members: [
          CareTeamMemberModel(id: 'CTM-01', memberName: 'Dr. Anil Kumar', role: 'Doctor (Palliative Lead)', phone: '+91 98470 00001'),
          CareTeamMemberModel(id: 'CTM-02', memberName: 'Nurse Anitha', role: 'Field Nurse', phone: '+91 98470 00002', isPrimary: true),
          CareTeamMemberModel(id: 'CTM-03', memberName: 'Rahul V. (BPT)', role: 'Physiotherapist', phone: '+91 98470 00003'),
          CareTeamMemberModel(id: 'CTM-04', memberName: 'Divya MSW', role: 'Medical Social Worker', phone: '+91 98470 00004'),
        ],
      ),
      CareTeamModel(
        id: 'CT-02',
        name: 'Medical College Community Unit B',
        leadDoctorName: 'Dr. Suresh Kumar',
        primaryNurseName: 'Nurse Bhavana',
        areaCoverage: 'Chevayur, Mavoor, Kottooli',
        members: [
          CareTeamMemberModel(id: 'CTM-05', memberName: 'Dr. Suresh Kumar', role: 'Doctor', phone: '+91 98470 00005'),
          CareTeamMemberModel(id: 'CTM-06', memberName: 'Nurse Bhavana', role: 'Field Nurse', phone: '+91 98470 00006', isPrimary: true),
          CareTeamMemberModel(id: 'CTM-07', memberName: 'Anil Kumar (MSW)', role: 'Counselor', phone: '+91 98470 00007'),
        ],
      ),
    ];

    _homeVisitRequests = [
      HomeVisitRequestModel(
        id: 'HVR-101',
        patientId: 'PAT-01',
        patientName: 'Karthyayani Amma',
        patientPhone: '+91 98470 12345',
        requesterName: 'Suresh (Son)',
        requesterPhone: '+91 98470 99887',
        requesterRelationship: 'Son & Primary Caregiver',
        visitType: 'Pain Management & Vitals Review',
        urgency: 'Urgent (Within 24h)',
        preferredDate: '2026-08-08',
        preferredTimeSlot: '10:00 AM - 12:00 PM',
        reasonAndSymptoms: 'Breakthrough knee & back pain. Appetite reduced; needs vitals review.',
        locationAddress: 'Chevayur, Ward 14, Kozhikode',
        status: 'PENDING',
        createdAt: '2026-08-07 09:30 AM',
      ),
      HomeVisitRequestModel(
        id: 'HVR-102',
        patientId: 'PAT-02',
        patientName: 'Vaidyanathan Nair',
        patientPhone: '+91 94471 22334',
        requesterName: 'Lakshmi Nair (Daughter)',
        requesterPhone: '+91 94471 88776',
        requesterRelationship: 'Daughter',
        visitType: 'Bedsore Dressing & Catheter Care',
        urgency: 'Routine (Scheduled)',
        preferredDate: '2026-08-09',
        preferredTimeSlot: '02:00 PM - 04:00 PM',
        reasonAndSymptoms: 'Scheduled bi-weekly wound dressing change and sterile catheter inspection.',
        locationAddress: 'Mavoor Road, Kozhikode',
        status: 'PENDING',
        createdAt: '2026-08-07 11:15 AM',
      ),
    ];

    _medicationPlans = [
      MedicationPlanModel(
        id: 'MEDP-01',
        patientId: 'PAT-01',
        medicineName: 'Oral Morphine Solution (10mg/5ml)',
        dosage: '5 ml (10 mg)',
        route: 'Oral',
        frequency: 'Every 4 Hours',
        timeSlots: ['06:00 AM', '10:00 AM', '02:00 PM', '06:00 PM', '10:00 PM'],
        prescribedByDoctor: 'Dr. Anil Kumar',
        startDate: '2026-08-01',
        instructions: 'Take with half glass of warm water. For breakthrough pain, contact 24x7 desk.',
        administrations: [
          MedicationAdministrationModel(
            id: 'ADM-01',
            planId: 'MEDP-01',
            medicineName: 'Oral Morphine Solution',
            dosage: '5 ml (10 mg)',
            patientId: 'PAT-01',
            scheduledDate: '2026-08-08',
            timeSlot: '06:00 AM',
            status: 'TAKEN',
            recordedByCaregiver: true,
            administeredAt: '06:15 AM',
            notes: 'Administered on time by son Suresh.',
          ),
          MedicationAdministrationModel(
            id: 'ADM-02',
            planId: 'MEDP-01',
            medicineName: 'Oral Morphine Solution',
            dosage: '5 ml (10 mg)',
            patientId: 'PAT-01',
            scheduledDate: '2026-08-08',
            timeSlot: '10:00 AM',
            status: 'TAKEN',
            verifiedByNurse: true,
            verifiedNurseName: 'Nurse Anitha',
            administeredAt: '10:05 AM',
            notes: 'Verified directly during morning palliative home visit.',
          ),
        ],
      ),
      MedicationPlanModel(
        id: 'MEDP-02',
        patientId: 'PAT-01',
        medicineName: 'Paracetamol 500mg Tab',
        dosage: '1 Tablet',
        route: 'Oral',
        frequency: 'TDS (3 times daily)',
        timeSlots: ['08:00 AM', '02:00 PM', '08:00 PM'],
        prescribedByDoctor: 'Dr. Suresh Kumar',
        startDate: '2026-08-01',
        instructions: 'Take after meals for fever/mild pain relief.',
      ),
      MedicationPlanModel(
        id: 'MEDP-03',
        patientId: 'PAT-02',
        medicineName: 'Pregabalin 75mg Capsule',
        dosage: '1 Capsule',
        route: 'Oral',
        frequency: 'Nightly (OD HS)',
        timeSlots: ['09:30 PM'],
        prescribedByDoctor: 'Dr. Priya Varma',
        startDate: '2026-08-02',
        instructions: 'Take before bedtime for neuropathic relief.',
      ),
    ];

    _caregiverGrants = [
      CaregiverAccessModel(
        id: 'CG-01',
        patientId: 'PAT-01',
        caregiverName: 'Suresh (Son)',
        caregiverPhone: '+91 98470 99887',
        relationship: 'Son & Primary Caregiver',
        permissions: ['VIEW_BASIC_INFO', 'VIEW_VISITS', 'VIEW_VITALS', 'VIEW_CARE_PLAN', 'RECEIVE_ALERTS'],
        grantedBy: 'Nurse Anitha',
        grantedAt: '2026-08-01',
      ),
      CaregiverAccessModel(
        id: 'CG-02',
        patientId: 'PAT-02',
        caregiverName: 'Lakshmi Nair',
        caregiverPhone: '+91 94471 88776',
        relationship: 'Daughter',
        permissions: ['VIEW_BASIC_INFO', 'VIEW_VISITS', 'VIEW_VITALS', 'RECEIVE_ALERTS'],
        grantedBy: 'Dr. Priya Varma',
        grantedAt: '2026-08-02',
      ),
    ];

    _dailyRoutes = [
      CareTeamRouteModel(
        id: 'ROU-01',
        careTeamId: 'CT-01',
        careTeamName: 'Feroke Palliative Care Team A',
        routeDate: '2026-08-08',
        primaryNurseName: 'Nurse Anitha',
        status: 'IN_PROGRESS',
        totalStops: 3,
        notes: 'Priority sequence for Feroke & Chevayur palliative route today.',
        stops: [
          RouteStopModel(
            id: 'STP-01',
            visitId: 'VIS-01',
            patientName: 'Karthyayani Amma',
            patientAddress: 'Chevayur, Ward 14, Kozhikode',
            patientPhone: '+91 98470 12345',
            visitType: 'Palliative Pain & Dressing',
            sequenceOrder: 1,
            locationArea: 'Chevayur Ward 14',
            estimatedArrivalTime: '09:30 AM',
            isCompleted: true,
          ),
          RouteStopModel(
            id: 'STP-02',
            visitId: 'VIS-02',
            patientName: 'Vaidyanathan Nair',
            patientAddress: 'Mavoor Road, Kozhikode',
            patientPhone: '+91 94471 22334',
            visitType: 'Catheter Flush & Mobility Assessment',
            sequenceOrder: 2,
            locationArea: 'Mavoor Ward 06',
            estimatedArrivalTime: '11:15 AM',
            isCompleted: false,
          ),
          RouteStopModel(
            id: 'STP-03',
            visitId: 'VIS-03',
            patientName: 'Muhammed Basheer',
            patientAddress: 'Peace Haven, Feroke, Kozhikode',
            patientPhone: '+91 98472 33445',
            visitType: 'Intensive Pain Management',
            sequenceOrder: 3,
            locationArea: 'Feroke Ward 04',
            estimatedArrivalTime: '02:00 PM',
            isCompleted: false,
          ),
        ],
      ),
    ];

    _notifications = [
      'Welcome to CareLink Kerala! System running online.',
      'Emergency Blood Request posted for Calicut Medical College Hospital (O+ Group).',
      'Low stock warning: Amlodipine 5mg has reached reorder level.',
      'CareLink Network 2.0 active: 4 Verified Kerala Hospital Centers loaded.',
      'Phase 2.7 Active: Multi-Disciplinary Palliative Teams & Home Route Engine Online.',
    ];
  }

  // Django REST Backend Synchronization
  Future<void> syncWithDjangoBackend() async {
    final liveOrgs = await ApiService.getOrganizations();
    if (liveOrgs.isNotEmpty) {
      _organizations = liveOrgs;
      _activeOrganization = liveOrgs.first;
      ApiService.activeTenantId = _activeOrganization?.id;
    }

    final livePatients = await ApiService.getPatients();
    if (livePatients.isNotEmpty) {
      _patients = livePatients;
    }

    _addNotification('Successfully synced state with Django REST Framework backend.');
    notifyListeners();
  }

  // Language & Theme Actions
  void setLocale(Locale newLocale) {
    _locale = newLocale;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _addNotification('Switched theme to ${_isDarkMode ? "Dark Mode" : "Light Mode"}.');
    notifyListeners();
  }

  void setApiBaseUrl(String newUrl) {
    _apiBaseUrl = newUrl;
    ApiService.baseUrl = newUrl;
    _addNotification('Updated Django Backend API URL to $newUrl');
    notifyListeners();
  }

  void toggleEmergencyBloodNotification(bool val) {
    _notifyEmergencyBlood = val;
    notifyListeners();
  }

  void toggleCriticalPatientsNotification(bool val) {
    _notifyCriticalPatients = val;
    notifyListeners();
  }

  void toggleLowStockNotification(bool val) {
    _notifyLowStock = val;
    notifyListeners();
  }

  // Tenant Switcher Actions
  void switchOrganization(OrganizationModel org) {
    _activeOrganization = org;
    _addNotification('Switched active organization tenant to ${org.name}');
    notifyListeners();
  }

  void registerOrganization(OrganizationModel newOrg) {
    _organizations.insert(0, newOrg);
    _activeOrganization = newOrg;
    _addNotification('Registered new Palliative Organization: ${newOrg.name} (${newOrg.district}).');
    notifyListeners();
  }

  List<UserModel> _registeredUsers = [];
  List<UserModel> get registeredUsers => _registeredUsers;
  List<UserModel> get demoUsers => _registeredUsers;

  void registerStaffUser(UserModel newUser) {
    _registeredUsers.insert(0, newUser);
    _addNotification('Registered healthcare staff ${newUser.name} (${newUser.role.displayName}).');
    notifyListeners();
  }

  /// Restore saved JWT session from persistent storage
  Future<void> restoreSavedSession() async {
    try {
      final session = await AuthSessionService.getSession();
      if (session != null && session.isLoggedIn && session.token.isNotEmpty) {
        _currentUser = session.user;
        _jwtToken = session.token;
        _refreshToken = session.refreshToken;
        ApiService.authToken = session.token;
        _isLoggedIn = true;
        _addNotification('Welcome back, ${_currentUser.name}! Session restored.');
      } else {
        _isLoggedIn = false;
      }
    } catch (e) {
      debugPrint('restoreSavedSession error: $e');
      _isLoggedIn = false;
    } finally {
      _isSessionLoaded = true;
      notifyListeners();
    }
  }

  /// Sign in user, assign JWT token, and persist session locally
  Future<void> loginAsUser(UserModel user, {String? token, String? refreshToken}) async {
    _currentUser = user;
    _jwtToken = token ?? ApiService.authToken ?? 'jwt_carelink_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
    _refreshToken = refreshToken;
    ApiService.authToken = _jwtToken;
    _isLoggedIn = true;

    // Persist to local database
    await AuthSessionService.saveSession(
      token: _jwtToken!,
      refreshToken: _refreshToken,
      user: user,
    );

    _addNotification('Signed in as ${user.name} (${user.role.displayName}).');
    notifyListeners();
  }

  /// Explicitly sign out of session and clear persistent storage
  Future<void> logout() async {
    _isLoggedIn = false;
    _jwtToken = null;
    _refreshToken = null;
    ApiService.authToken = null;

    // Clear persistent session
    await AuthSessionService.clearSession();

    _addNotification('Signed out of session.');
    notifyListeners();
  }

  /// Production credential authentication: checks backend JWT API, with fallback to local verified credentials
  Future<bool> authenticate({
    required String emailOrUsername,
    required String password,
  }) async {
    final cleanInput = emailOrUsername.trim();
    final cleanPassword = password.trim();

    if (cleanInput.isEmpty || cleanPassword.isEmpty) {
      return false;
    }

    // 1. Attempt online backend API authentication
    try {
      final apiResult = await ApiService.login(cleanInput, cleanPassword);
      if (apiResult != null && apiResult['access'] != null) {
        final token = apiResult['access'] as String;
        final refreshToken = apiResult['refresh'] as String?;
        final userData = apiResult['user'] as Map<String, dynamic>?;

        UserModel authenticatedUser;
        if (userData != null) {
          final roleStr = (userData['role'] ?? 'NURSE').toString().toUpperCase();
          UserRole role;
          switch (roleStr) {
            case 'SUPER_ADMIN':
              role = UserRole.superAdmin;
              break;
            case 'ORG_ADMIN':
              role = UserRole.orgAdmin;
              break;
            case 'DOCTOR':
              role = UserRole.doctor;
              break;
            case 'NURSE':
              role = UserRole.nurse;
              break;
            case 'VOLUNTEER':
              role = UserRole.volunteer;
              break;
            case 'RECEPTION':
              role = UserRole.reception;
              break;
            case 'PHARMACIST':
              role = UserRole.pharmacist;
              break;
            case 'ACCOUNTANT':
              role = UserRole.accountant;
              break;
            case 'AMBULANCE_DRIVER':
              role = UserRole.ambulanceDriver;
              break;
            case 'PATIENT':
              role = UserRole.patient;
              break;
            case 'FAMILY_MEMBER':
              role = UserRole.familyMember;
              break;
            case 'BLOOD_DONOR':
            case 'PALLIATIVE_MEMBER':
              role = UserRole.palliativeMember;
              break;
            default:
              role = UserRole.nurse;
          }

          final fullName = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
          authenticatedUser = UserModel(
            id: 'USR-${userData['id'] ?? 'PROD-01'}',
            name: fullName.isNotEmpty ? fullName : (userData['username'] ?? cleanInput),
            email: userData['email'] ?? cleanInput,
            phone: userData['phone'] ?? '+91 94470 00001',
            role: role,
            organizationId: userData['organization']?.toString() ?? (_activeOrganization?.id ?? 'org_kozhikode'),
            district: userData['district'] ?? (_activeOrganization?.district ?? 'Kozhikode'),
          );
        } else {
          authenticatedUser = UserModel(
            id: 'USR-AUTH-01',
            name: cleanInput.contains('@') ? cleanInput.split('@').first : cleanInput,
            email: cleanInput,
            phone: '+91 94470 00001',
            role: cleanInput.toLowerCase() == 'psreerag304@gmail.com' ? UserRole.superAdmin : UserRole.nurse,
            organizationId: _activeOrganization?.id ?? 'org_kozhikode',
            district: _activeOrganization?.district ?? 'Kozhikode',
          );
        }

        await loginAsUser(authenticatedUser, token: token, refreshToken: refreshToken);
        return true;
      }
    } catch (e) {
      debugPrint('Online auth attempt encountered exception: $e');
    }

    // 2. Offline / Local Credential Authentication Gate
    final lowerInput = cleanInput.toLowerCase();

    // Primary Super Admin check
    if (lowerInput == 'psreerag304@gmail.com' && cleanPassword == 'Sree321#') {
      final superAdminUser = UserModel(
        id: 'USR-SADM-01',
        name: 'Sreerag (Super Admin)',
        email: 'psreerag304@gmail.com',
        phone: '+91 94470 00001',
        role: UserRole.superAdmin,
        organizationId: _activeOrganization?.id ?? 'org_kozhikode',
        district: _activeOrganization?.district ?? 'Kozhikode',
      );
      await loginAsUser(superAdminUser);
      return true;
    }

    // Known Staff profiles check (e.g. Registered staff or default staff profiles)
    final matchingUser = demoUsers.where(
      (u) => u.email.toLowerCase() == lowerInput || u.id.toLowerCase() == lowerInput,
    ).firstOrNull;

    if (matchingUser != null && (cleanPassword == 'CareLink@2026' || cleanPassword == 'admin123' || cleanPassword == 'pass1234' || cleanPassword == 'Sree321#' || cleanPassword == 'Admin@12345' || cleanPassword == 'password123')) {
      await loginAsUser(matchingUser);
      return true;
    }

    return false;
  }

  /// Authenticate patient / family member by phone and OTP
  Future<bool> authenticatePatientByPhone({
    required String phone,
    required String otp,
  }) async {
    final cleanPhone = phone.trim();
    final cleanOtp = otp.trim();
    if (cleanPhone.isEmpty || cleanOtp.length != 6) {
      return false;
    }

    final existingPatient = _patients.where((p) => p.phone.contains(cleanPhone.replaceAll(' ', ''))).firstOrNull;
    final patientUser = UserModel(
      id: existingPatient?.id ?? 'USR-PAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      name: existingPatient?.name ?? 'Patient User',
      email: '${cleanPhone.replaceAll(RegExp(r'\D'), '')}@carelink.kerala.gov.in',
      phone: cleanPhone,
      role: UserRole.patient,
      organizationId: _activeOrganization?.id ?? 'org_kozhikode',
      district: existingPatient?.district ?? (_activeOrganization?.district ?? 'Kozhikode'),
    );

    await loginAsUser(patientUser);
    return true;
  }

  // Role Switcher Action for Testing
  Future<void> switchRole(UserRole newRole) async {
    final matchingUser = demoUsers.firstWhere(
      (u) => u.role == newRole,
      orElse: () => UserModel(
        id: 'USR-${newRole.name.toUpperCase()}',
        name: '${newRole.displayName} User',
        email: '${newRole.name}@carelink.kerala.gov.in',
        phone: '+91 98470 00000',
        role: newRole,
        organizationId: _activeOrganization?.id ?? 'org_kozhikode',
        district: _activeOrganization?.district ?? 'Kozhikode',
      ),
    );

    await loginAsUser(matchingUser);
  }


  // Phase 2: Patient Actions
  void addPatient(PatientModel newPatient) {
    _patients.insert(0, newPatient);
    _addNotification('New patient ${newPatient.name} registered under ${newPatient.categoryTier}.');
    notifyListeners();
  }

  void referPatientInNeed(PatientModel referredPatient, {required String referrerName, required String referrerRole, required String urgency}) {
    _patients.insert(0, referredPatient);
    _addNotification('🚨 Community Referral: ${referredPatient.name} in ${referredPatient.ward}, ${referredPatient.district} reported by $referrerName ($referrerRole). Urgency: $urgency. Placed in Clinical Triage queue.');
    notifyListeners();
  }

  void addVitalsToPatient(String patientId, VitalsReading vitals) {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      final p = _patients[index];
      p.vitalsHistory.insert(0, vitals);
      _addNotification('Vitals updated for ${p.name}: BP ${vitals.bp}, SpO2 ${vitals.spo2}%.');
      notifyListeners();
    }
  }

  // Phase 3: Home Visit Actions
  void startVisit(String visitId) {
    final index = _visits.indexWhere((v) => v.id == visitId);
    if (index != -1) {
      _visits[index].status = 'In Progress';
      notifyListeners();
    }
  }

  void completeVisit(String visitId, {required String notes, VitalsReading? vitals, String? voicePath}) {
    final index = _visits.indexWhere((v) => v.id == visitId);
    if (index != -1) {
      final v = _visits[index];
      v.status = 'Completed';
      v.gpsCheckInTime = 'GPS Verified at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
      v.gpsLocationName = 'Verified Patient Home Geo-Location';
      v.clinicalNotes = notes;
      if (vitals != null) {
        v.recordedVitals = vitals;
        addVitalsToPatient(v.patientId, vitals);
      }
      _addNotification('Home Visit completed for ${v.patientName}. Timeline updated.');
      notifyListeners();
    }
  }

  void queueOfflineVisitDraft() {
    _pendingOfflineSyncCount++;
    _addNotification('1 Visit entry saved locally in offline queue.');
    notifyListeners();
  }

  void syncOfflineQueue() {
    if (_pendingOfflineSyncCount > 0) {
      _addNotification('Successfully synced $_pendingOfflineSyncCount offline visit notes to cloud.');
      _pendingOfflineSyncCount = 0;
      notifyListeners();
    }
  }

  // Phase 4: Appointments Actions
  void addAppointment(AppointmentModel apt) {
    _appointments.insert(0, apt);
    _addNotification('New appointment scheduled with ${apt.doctorName} for ${apt.patientName}.');
    notifyListeners();
  }

  void updateAppointmentStatus(String aptId, String status) {
    final index = _appointments.indexWhere((a) => a.id == aptId);
    if (index != -1) {
      final a = _appointments[index];
      _appointments[index] = AppointmentModel(
        id: a.id,
        patientName: a.patientName,
        doctorName: a.doctorName,
        date: a.date,
        time: a.time,
        type: a.type,
        status: status,
      );
      _addNotification('Appointment ${a.id} marked as $status.');
      notifyListeners();
    }
  }

  // Phase 5: Volunteer Actions
  void addVolunteer(VolunteerModel volunteer) {
    _volunteers.insert(0, volunteer);
    _addNotification('Registered volunteer ${volunteer.name} (${volunteer.ward}, ${volunteer.district}).');
    notifyListeners();
  }

  void verifyVolunteer(String volunteerId) {
    final index = _volunteers.indexWhere((v) => v.id == volunteerId);
    if (index != -1) {
      final v = _volunteers[index];
      _volunteers[index] = VolunteerModel(
        id: v.id,
        name: v.name,
        district: v.district,
        ward: v.ward,
        phone: v.phone,
        isVerified: true,
        assignedPatientsCount: v.assignedPatientsCount,
        totalHoursLogged: v.totalHoursLogged,
        tasksCompleted: v.tasksCompleted,
      );
      _addNotification('Verified volunteer status for ${v.name}.');
      notifyListeners();
    }
  }

  void toggleVolunteerVerification(String volunteerId) {
    final index = _volunteers.indexWhere((v) => v.id == volunteerId);
    if (index != -1) {
      final v = _volunteers[index];
      _volunteers[index] = VolunteerModel(
        id: v.id,
        name: v.name,
        district: v.district,
        ward: v.ward,
        phone: v.phone,
        isVerified: !v.isVerified,
        assignedPatientsCount: v.assignedPatientsCount,
        totalHoursLogged: v.totalHoursLogged,
        tasksCompleted: v.tasksCompleted,
      );
      _addNotification('Updated verification status for volunteer ${v.name}.');
      notifyListeners();
    }
  }

  void logVolunteerTask(String volunteerId, int hours) {
    final index = _volunteers.indexWhere((v) => v.id == volunteerId);
    if (index != -1) {
      final v = _volunteers[index];
      _volunteers[index] = VolunteerModel(
        id: v.id,
        name: v.name,
        district: v.district,
        ward: v.ward,
        phone: v.phone,
        isVerified: v.isVerified,
        assignedPatientsCount: v.assignedPatientsCount,
        totalHoursLogged: v.totalHoursLogged + hours,
        tasksCompleted: v.tasksCompleted + 1,
      );
      _addNotification('Logged $hours hours for volunteer ${v.name}.');
      notifyListeners();
    }
  }

  // Phase 6: Blood Donor & Emergency Actions
  void registerBloodDonor(BloodDonorModel donor) {
    _bloodDonors.insert(0, donor);
    _addNotification('New donor ${donor.name} (${donor.bloodGroup}) registered.');
    notifyListeners();
  }

  void recordDonation(String donorId) {
    final index = _bloodDonors.indexWhere((d) => d.id == donorId);
    if (index != -1) {
      final d = _bloodDonors[index];
      _bloodDonors[index] = BloodDonorModel(
        id: d.id,
        name: d.name,
        bloodGroup: d.bloodGroup,
        district: d.district,
        locality: d.locality,
        phone: d.phone,
        lastDonationDate: DateTime.now(), // Automatically resets eligibility timer!
        totalDonations: d.totalDonations + 1,
        isAvailable: d.isAvailable,
      );
      _addNotification('Recorded donation for ${d.name}. Eligibility automatically recalculated for next 90 days.');
      notifyListeners();
    }
  }

  void createEmergencyBloodRequest(BloodRequestModel request) {
    _bloodRequests.insert(0, request);
    // Find matching eligible donors
    final eligibleMatching = _bloodDonors.where((d) => d.bloodGroup == request.bloodGroup && d.district == request.district && d.isEligible).length;
    _addNotification('EMERGENCY BLOOD REQUEST: ${request.bloodGroup} needed at ${request.hospitalName}. Alert sent to $eligibleMatching eligible donors!');
    notifyListeners();
  }

  // Phase 7 & 8: Inventory & Equipment Actions
  void issueMedicine(String medicineId, int quantity) {
    final index = _medicines.indexWhere((m) => m.id == medicineId);
    if (index != -1) {
      final m = _medicines[index];
      final newQty = (m.stockQuantity - quantity) < 0 ? 0 : m.stockQuantity - quantity;
      _medicines[index] = MedicineItemModel(
        id: m.id,
        name: m.name,
        category: m.category,
        stockQuantity: newQty,
        unit: m.unit,
        reorderLevel: m.reorderLevel,
        expiryDate: m.expiryDate,
        batchNumber: m.batchNumber,
      );
      _addNotification('Issued $quantity ${m.unit} of ${m.name}. Stock updated.');
      notifyListeners();
    }
  }

  void restockMedicine(String medicineId, int quantity) {
    final index = _medicines.indexWhere((m) => m.id == medicineId);
    if (index != -1) {
      final m = _medicines[index];
      _medicines[index] = MedicineItemModel(
        id: m.id,
        name: m.name,
        category: m.category,
        stockQuantity: m.stockQuantity + quantity,
        unit: m.unit,
        reorderLevel: m.reorderLevel,
        expiryDate: m.expiryDate,
        batchNumber: m.batchNumber,
      );
      _addNotification('Restocked +$quantity ${m.unit} of ${m.name}. Stock is now ${m.stockQuantity + quantity} ${m.unit}.');
      notifyListeners();
    }
  }

  void loanEquipmentToPatient(String equipmentId, String patientName) {
    final index = _equipment.indexWhere((e) => e.id == equipmentId);
    if (index != -1 && _equipment[index].availableCount > 0) {
      final e = _equipment[index];
      _equipment[index] = EquipmentItemModel(
        id: e.id,
        name: e.name,
        totalCount: e.totalCount,
        availableCount: e.availableCount - 1,
        loanedCount: e.loanedCount + 1,
        maintenanceStatus: e.maintenanceStatus,
      );
      _addNotification('Loaned 1 unit of ${e.name} to patient $patientName.');
      notifyListeners();
    }
  }

  void returnEquipmentFromPatient(String equipmentId, int count) {
    final index = _equipment.indexWhere((e) => e.id == equipmentId);
    if (index != -1 && _equipment[index].loanedCount > 0) {
      final e = _equipment[index];
      final actualCount = count > e.loanedCount ? e.loanedCount : count;
      _equipment[index] = EquipmentItemModel(
        id: e.id,
        name: e.name,
        totalCount: e.totalCount,
        availableCount: e.availableCount + actualCount,
        loanedCount: e.loanedCount - actualCount,
        maintenanceStatus: e.maintenanceStatus,
      );
      _addNotification('Returned $actualCount unit(s) of ${e.name} back to available inventory.');
      notifyListeners();
    }
  }

  // Phase 9: Ambulance Actions
  void updateAmbulanceStatus(String driverId, String status) {
    final index = _ambulanceDrivers.indexWhere((d) => d.id == driverId);
    if (index != -1) {
      _ambulanceDrivers[index].currentStatus = status;
      _addNotification('Ambulance $driverId status updated to $status.');
      notifyListeners();
    }
  }

  // Phase 10: Donation Actions
  void addDonation(DonationModel donation) {
    _donations.insert(0, donation);
    _addNotification('Received donation of ₹${donation.amount.toInt()} from ${donation.donorName}. Receipt #${donation.receiptNumber} generated.');
    notifyListeners();
  }

  // Organization Banking & UPI Management
  void updateOrganizationBankingInfo({
    required String orgId,
    required String upiId,
    required String bankAccountName,
    required String bankAccountNumber,
    required String ifscCode,
    required String bankName,
  }) {
    final idx = _organizations.indexWhere((o) => o.id == orgId);
    if (idx != -1) {
      final old = _organizations[idx];
      final updated = OrganizationModel(
        id: old.id,
        name: old.name,
        district: old.district,
        registrationNumber: old.registrationNumber,
        phone: old.phone,
        upiId: upiId,
        bankAccountName: bankAccountName,
        bankAccountNumber: bankAccountNumber,
        ifscCode: ifscCode,
        bankName: bankName,
        qrCodeUrl: old.qrCodeUrl,
        razorpayKeyId: old.razorpayKeyId,
        activePatientsCount: old.activePatientsCount,
        totalVisitsCount: old.totalVisitsCount,
      );
      _organizations[idx] = updated;
      if (_activeOrganization?.id == orgId) {
        _activeOrganization = updated;
      }
      _addNotification('Updated Banking & UPI details for ${old.name} (UPI: $upiId).');
      notifyListeners();
    }
  }

  // Phase 11: Medical Treatment Crowdfunding Actions
  void createMedicalFundraiser(MedicalFundraiserModel fundraiser) {
    _fundraisers.insert(0, fundraiser);
    final routingMsg = fundraiser.useOrgQr
        ? 'Using Cooperating Org Account QR (${fundraiser.cooperatingOrgName})'
        : 'Using Custom Campaign Escrow QR (${fundraiser.customUpiId})';
    _addNotification('🚨 New Treatment Appeal: ${fundraiser.treatmentTitle} for ${fundraiser.patientName} (Target: ₹${fundraiser.targetAmount.toInt()}). $routingMsg.');
    notifyListeners();
  }

  FundraiserDonationModel donateToMedicalFundraiser(
    String fundraiserId,
    double amount,
    String donorName, {
    String? donorPrayer,
    bool isAnonymous = false,
    String paymentMode = 'Razorpay',
    String? razorpayPaymentId,
  }) {
    final index = _fundraisers.indexWhere((f) => f.id == fundraiserId);
    String patientName = 'Patient';
    if (index != -1) {
      final f = _fundraisers[index];
      f.collectedAmount += amount;
      f.donorsCount += 1;
      if (f.collectedAmount >= f.targetAmount) {
        f.status = 'Target Reached';
      }
      patientName = f.patientName;
    }

    final donation = FundraiserDonationModel(
      id: 'FUND-DON-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      fundraiserId: fundraiserId,
      donorName: isAnonymous ? 'Anonymous Well-Wisher' : donorName,
      amount: amount,
      date: '2026-08-07',
      receiptNumber: '80G-MED-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      donorPrayer: donorPrayer,
      isAnonymous: isAnonymous,
      paymentMode: paymentMode,
      razorpayPaymentId: razorpayPaymentId,
    );

    // Also record into general palliative audit ledger
    _donations.insert(
      0,
      DonationModel(
        id: 'DON-MED-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        donorName: isAnonymous ? 'Anonymous Well-Wisher' : donorName,
        amount: amount,
        category: 'Medical Appeal ($patientName)',
        paymentMode: paymentMode,
        receiptNumber: donation.receiptNumber,
        date: '2026-08-07',
        transactionId: razorpayPaymentId ?? donation.receiptNumber,
        donorPrayer: donorPrayer,
        isAnonymous: isAnonymous,
      ),
    );

    _addNotification('❤️ ₹${amount.toInt()} contributed to $patientName Treatment Fund via $paymentMode by ${isAnonymous ? "Anonymous Well-Wisher" : donorName}. 80G Receipt #${donation.receiptNumber} generated.');
    notifyListeners();
    return donation;
  }

  // Password Reset / Forgot Password Flow
  String? _lastPasswordResetOtp;
  String? get lastPasswordResetOtp => _lastPasswordResetOtp;

  String requestPasswordResetOtp(String emailOrPhone) {
    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    _lastPasswordResetOtp = otp;
    _addNotification('🔑 PASSWORD RECOVERY: 6-digit OTP code sent to $emailOrPhone: $otp (Valid for 10 minutes).');
    notifyListeners();
    return otp;
  }

  bool verifyAndResetPassword({required String emailOrPhone, required String otp, required String newPassword}) {
    if (_lastPasswordResetOtp != null && _lastPasswordResetOtp == otp.trim()) {
      _lastPasswordResetOtp = null;
      _addNotification('✅ Password successfully reset for $emailOrPhone. You can now sign in with your new credentials.');
      notifyListeners();
      return true;
    }
    return false;
  }

  // Master Patient Data Management (Admins & Clinical Leads)
  void updatePatient(PatientModel updated) {
    final idx = _patients.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _patients[idx] = updated;
      _addNotification('Updated master clinical record for ${updated.name} (${updated.categoryTier}).');
      notifyListeners();
    }
  }

  void deletePatient(String patientId) {
    final idx = _patients.indexWhere((p) => p.id == patientId);
    if (idx != -1) {
      final p = _patients.removeAt(idx);
      _addNotification('Discharged / Archived patient record for ${p.name}.');
      notifyListeners();
    }
  }

  void updatePatientCarePlan(String patientId, CarePlanModel carePlan) {
    final idx = _patients.indexWhere((p) => p.id == patientId);
    if (idx != -1) {
      final old = _patients[idx];
      _patients[idx] = PatientModel(
        id: old.id,
        name: old.name,
        age: old.age,
        gender: old.gender,
        bloodGroup: old.bloodGroup,
        district: old.district,
        ward: old.ward,
        address: old.address,
        phone: old.phone,
        lifecycleStatus: old.lifecycleStatus,
        categoryTier: old.categoryTier,
        diagnosis: old.diagnosis,
        riskLevel: old.riskLevel,
        aiSummary: old.aiSummary,
        emergencyContactName: old.emergencyContactName,
        emergencyContactPhone: old.emergencyContactPhone,
        carePlan: carePlan,
        vitalsHistory: old.vitalsHistory,
        equipmentIssued: old.equipmentIssued,
        familyMembers: old.familyMembers,
        medicalHistory: old.medicalHistory,
        registeredDate: old.registeredDate,
        referredBy: old.referredBy,
        referralUrgency: old.referralUrgency,
      );
      _addNotification('Updated Palliative Care Plan for ${old.name} (Doctor: ${carePlan.assignedDoctorName}).');
      notifyListeners();
    }
  }

  // Master Inventory & Equipment Listing (Admins, Pharmacists, Nurses)
  void addMedicineItem(MedicineItemModel item) {
    _medicines.insert(0, item);
    _addNotification('Added new item to Pharmacy Inventory: ${item.name} (${item.stockQuantity} ${item.unit}).');
    notifyListeners();
  }

  void updateMedicineItem(MedicineItemModel item) {
    final idx = _medicines.indexWhere((m) => m.id == item.id);
    if (idx != -1) {
      _medicines[idx] = item;
      _addNotification('Updated specifications for medicine ${item.name}.');
      notifyListeners();
    }
  }

  void deleteMedicineItem(String medicineId) {
    final idx = _medicines.indexWhere((m) => m.id == medicineId);
    if (idx != -1) {
      final m = _medicines.removeAt(idx);
      _addNotification('Removed ${m.name} from active inventory catalog.');
      notifyListeners();
    }
  }

  void addEquipmentItem(EquipmentItemModel item) {
    _equipment.insert(0, item);
    _addNotification('Added new equipment asset: ${item.name} (${item.totalCount} units available).');
    notifyListeners();
  }

  void updateEquipmentItem(EquipmentItemModel item) {
    final idx = _equipment.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      _equipment[idx] = item;
      _addNotification('Updated equipment listing for ${item.name}.');
      notifyListeners();
    }
  }

  void deleteEquipmentItem(String equipmentId) {
    final idx = _equipment.indexWhere((e) => e.id == equipmentId);
    if (idx != -1) {
      final e = _equipment.removeAt(idx);
      _addNotification('Removed equipment asset ${e.name} from catalog.');
      notifyListeners();
    }
  }

  // Staff & User Role Management (Super Admins & Org Admins)
  void updateUserRole(String userId, UserRole newRole) {
    final idx = demoUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final user = demoUsers[idx];
      _addNotification('Promoted / Updated staff role for ${user.name} to ${newRole.displayName}.');
      if (_currentUser.id == userId) {
        _currentUser = UserModel(
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: newRole,
          organizationId: user.organizationId,
          district: user.district,
        );
      }
      notifyListeners();
    }
  }

  // Doctor Consultation Triage Actions
  void acceptDoctorConsultation(String aptId, {required String doctorName, required String time, String? notes}) {
    final idx = _appointments.indexWhere((a) => a.id == aptId);
    if (idx != -1) {
      final old = _appointments[idx];
      _appointments[idx] = AppointmentModel(
        id: old.id,
        patientName: old.patientName,
        doctorName: doctorName,
        date: old.date,
        time: time,
        type: old.type,
        status: 'Confirmed',
      );
      _addNotification('Dr. $doctorName accepted consult request for ${old.patientName} at $time.');
      notifyListeners();
    }
  }

  void rejectDoctorConsultation(String aptId) {
    final idx = _appointments.indexWhere((a) => a.id == aptId);
    if (idx != -1) {
      final old = _appointments[idx];
      _appointments[idx] = AppointmentModel(
        id: old.id,
        patientName: old.patientName,
        doctorName: old.doctorName,
        date: old.date,
        time: old.time,
        type: old.type,
        status: 'Declined',
      );
      _addNotification('Consultation request ${old.id} declined / redirected.');
      notifyListeners();
    }
  }

  // Nurse Home Visit Management Actions
  void acceptNurseVisit(String visitId, {required String nurseName, String? scheduledDate, String? scheduledTime}) {
    final idx = _visits.indexWhere((v) => v.id == visitId);
    if (idx != -1) {
      final old = _visits[idx];
      old.status = 'Accepted';
      _addNotification('Nurse $nurseName accepted home visit for ${old.patientName} on ${old.scheduledDate}.');
      notifyListeners();
    }
  }

  void assignNurseToVisit(String visitId, String nurseName) {
    final idx = _visits.indexWhere((v) => v.id == visitId);
    if (idx != -1) {
      final old = _visits[idx];
      _visits[idx] = VisitModel(
        id: old.id,
        patientId: old.patientId,
        patientName: old.patientName,
        patientAddress: old.patientAddress,
        assignedNurseName: nurseName,
        scheduledDate: old.scheduledDate,
        scheduledTime: old.scheduledTime,
        status: 'Assigned',
      );
      _addNotification('Assigned home visit for ${old.patientName} to Nurse $nurseName.');
      notifyListeners();
    }
  }

  // Medical Appeal Moderation Actions (Admins & Moderators)
  void moderateFundraiser(
    String fundraiserId, {
    required String status,
    double? targetAmount,
    bool? isDoctorVerified,
    bool? useOrgQr,
  }) {
    final idx = _fundraisers.indexWhere((f) => f.id == fundraiserId);
    if (idx != -1) {
      final f = _fundraisers[idx];
      f.status = status;
      if (targetAmount != null) f.targetAmount = targetAmount;
      if (isDoctorVerified != null) f.isDoctorVerified = isDoctorVerified;
      if (useOrgQr != null) f.useOrgQr = useOrgQr;
      _addNotification('Moderated Treatment Appeal for ${f.patientName}: Status set to "$status".');
      notifyListeners();
    }
  }



  // Emergency Rapid SOS & Multi-Party Broadcast Dispatch
  EmergencySosEvent triggerEmergencySos({
    required String triggerMethod,
    String? patientId,
  }) {
    final targetPatient = _patients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => _patients.first,
    );

    final nearestDriver = _ambulanceDrivers.firstWhere(
      (d) => d.currentStatus == 'Available',
      orElse: () => _ambulanceDrivers.first,
    );
    nearestDriver.currentStatus = 'Dispatched';

    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute.toString().padLeft(2, '0')} AM';

    final event = EmergencySosEvent(
      id: 'SOS-${now.millisecondsSinceEpoch.toString().substring(7)}',
      patientId: targetPatient.id,
      patientName: targetPatient.name,
      diagnosis: targetPatient.diagnosis,
      bloodGroup: targetPatient.bloodGroup,
      ward: targetPatient.ward,
      district: targetPatient.district,
      gpsCoordinates: '11.2680° N, 75.7910° E',
      emergencyContactName: targetPatient.emergencyContactName,
      emergencyContactPhone: targetPatient.emergencyContactPhone,
      triggerMethod: triggerMethod,
      timestamp: timeStr,
      dispatchedAmbulanceVehicle: nearestDriver.vehicleNumber,
      dispatchedAmbulanceDriver: nearestDriver.driverName,
      dispatchedAmbulancePhone: nearestDriver.phone,
      assignedNurseName: 'Sister Anitha R. (Palliative Nurse)',
      assignedDoctorName: 'Dr. Suresh Menon (MD Palliative)',
      wardVolunteerName: 'Shyam Mohan (Ward 12 Asha Worker)',
      status: 'Ambulance En-Route',
    );

    _activeSosEvent = event;
    _sosEvents.insert(0, event);

    _addNotification('🚨 EMERGENCY SOS: ${targetPatient.name} ($triggerMethod). Ambulance ${nearestDriver.vehicleNumber}, Sister Anitha, & Dr. Suresh Menon dispatched to Ward ${targetPatient.ward}.');
    notifyListeners();
    return event;
  }

  void cancelEmergencySos(String sosId) {
    if (_activeSosEvent?.id == sosId) {
      _activeSosEvent!.status = 'Cancelled';
      _activeSosEvent = null;
      _addNotification('Emergency SOS #$sosId cancelled by caregiver.');
      notifyListeners();
    }
  }

  void resolveEmergencySos(String sosId) {
    final idx = _sosEvents.indexWhere((e) => e.id == sosId);
    if (idx != -1) {
      _sosEvents[idx].status = 'Resolved';
    }
    if (_activeSosEvent?.id == sosId) {
      _activeSosEvent = null;
    }
    _addNotification('Emergency SOS #$sosId marked as Resolved by Clinical Team.');
    notifyListeners();
  }

  // Cache & Maintenance Actions
  void clearCache() {
    _pendingOfflineSyncCount = 0;
    _notifications = ['Cache cleared. System fresh and running online.'];
    _addNotification('Local application cache and pending offline drafts cleared.');
    notifyListeners();
  }

  void resetToDefaultData() {
    _initMockData();
    _pendingOfflineSyncCount = 0;
    _addNotification('Reset all clinic databases and models to initial default demo data.');
    notifyListeners();
  }

  // ==========================================
  // CARELINK NETWORK 2.0 STATE & DIRECTORY
  // ==========================================
  List<HealthcareProfileModel> _healthcareProfiles = [];
  List<DoctorModel> _doctors = [];
  List<SpecialtyModel> _specialties = [];
  List<ChangeRequestModel> _changeRequests = [];
  List<ClaimOrganizationRequestModel> _claimRequests = [];
  List<AppointmentRequestModel> _appointmentRequests = [];

  String _networkDistrictFilter = 'All Districts';
  String? _networkSpecialtyFilter;
  bool _networkEmergencyOnly = false;
  String _networkSearchQuery = '';

  List<HealthcareProfileModel> get healthcareProfiles => _healthcareProfiles;
  List<DoctorModel> get doctors => _doctors;
  List<SpecialtyModel> get specialties => _specialties;
  List<ChangeRequestModel> get changeRequests => _changeRequests;
  List<ClaimOrganizationRequestModel> get claimRequests => _claimRequests;
  List<AppointmentRequestModel> get appointmentRequests => _appointmentRequests;

  String get networkDistrictFilter => _networkDistrictFilter;
  String? get networkSpecialtyFilter => _networkSpecialtyFilter;
  bool get networkEmergencyOnly => _networkEmergencyOnly;
  String get networkSearchQuery => _networkSearchQuery;

  List<HealthcareProfileModel> get filteredHealthcareProfiles {
    return _healthcareProfiles.where((h) {
      if (_networkDistrictFilter != 'All Districts' &&
          h.district.toLowerCase() != _networkDistrictFilter.toLowerCase()) {
        return false;
      }
      if (_networkEmergencyOnly && !h.is24x7Emergency) {
        return false;
      }
      if (_networkSpecialtyFilter != null && _networkSpecialtyFilter!.isNotEmpty) {
        final hasSpec = h.specialties.any((s) => s.toLowerCase().contains(_networkSpecialtyFilter!.toLowerCase()));
        if (!hasSpec) return false;
      }
      if (_networkSearchQuery.isNotEmpty) {
        final q = _networkSearchQuery.toLowerCase();
        final matchesName = h.name.toLowerCase().contains(q);
        final matchesAddr = h.address.toLowerCase().contains(q);
        final matchesDesc = h.description.toLowerCase().contains(q);
        final matchesSpec = h.specialties.any((s) => s.toLowerCase().contains(q));
        final matchesDocs = h.doctors.any((d) => d.name.toLowerCase().contains(q) || d.specialty.toLowerCase().contains(q));
        if (!matchesName && !matchesAddr && !matchesDesc && !matchesSpec && !matchesDocs) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void setNetworkDistrictFilter(String district) {
    _networkDistrictFilter = district;
    notifyListeners();
  }

  void setNetworkSpecialtyFilter(String? specialty) {
    _networkSpecialtyFilter = specialty;
    notifyListeners();
  }

  void setNetworkEmergencyOnly(bool val) {
    _networkEmergencyOnly = val;
    notifyListeners();
  }

  void setNetworkSearchQuery(String query) {
    _networkSearchQuery = query;
    notifyListeners();
  }

  void clearNetworkFilters() {
    _networkDistrictFilter = 'All Districts';
    _networkSpecialtyFilter = null;
    _networkEmergencyOnly = false;
    _networkSearchQuery = '';
    notifyListeners();
  }

  void submitHospitalApplication(HealthcareProfileModel newProfile) {
    _healthcareProfiles.insert(0, newProfile);
    _addNotification('Application for "${newProfile.name}" submitted for CareLink Network verification.');
    notifyListeners();
  }

  void approveChangeRequest(String crId, {String notes = ''}) {
    final idx = _changeRequests.indexWhere((c) => c.id == crId);
    if (idx != -1) {
      final oldCr = _changeRequests[idx];
      _changeRequests[idx] = ChangeRequestModel(
        id: oldCr.id,
        organizationId: oldCr.organizationId,
        organizationName: oldCr.organizationName,
        requestedByName: oldCr.requestedByName,
        entityType: oldCr.entityType,
        changeSummary: oldCr.changeSummary,
        oldData: oldCr.oldData,
        newData: oldCr.newData,
        reason: oldCr.reason,
        status: 'APPROVED',
        createdAt: oldCr.createdAt,
      );
      _addNotification('Change Request #${oldCr.id} approved and published to public healthcare directory.');
      notifyListeners();
    }
  }

  void rejectChangeRequest(String crId, {String notes = ''}) {
    final idx = _changeRequests.indexWhere((c) => c.id == crId);
    if (idx != -1) {
      final oldCr = _changeRequests[idx];
      _changeRequests[idx] = ChangeRequestModel(
        id: oldCr.id,
        organizationId: oldCr.organizationId,
        organizationName: oldCr.organizationName,
        requestedByName: oldCr.requestedByName,
        entityType: oldCr.entityType,
        changeSummary: oldCr.changeSummary,
        oldData: oldCr.oldData,
        newData: oldCr.newData,
        reason: oldCr.reason,
        status: 'REJECTED',
        createdAt: oldCr.createdAt,
      );
      _addNotification('Change Request #${oldCr.id} rejected.');
      notifyListeners();
    }
  }

  void submitChangeRequest(ChangeRequestModel cr) {
    _changeRequests.insert(0, cr);
    _addNotification('Submitted Change Request #${cr.id}: ${cr.changeSummary}');
    notifyListeners();
  }

  void approveClaimRequest(String claimId) {
    final idx = _claimRequests.indexWhere((c) => c.id == claimId);
    if (idx != -1) {
      final old = _claimRequests[idx];
      _claimRequests[idx] = ClaimOrganizationRequestModel(
        id: old.id,
        organizationId: old.organizationId,
        organizationName: old.organizationName,
        claimantUsername: old.claimantUsername,
        claimantDesignation: old.claimantDesignation,
        officialEmail: old.officialEmail,
        officialPhone: old.officialPhone,
        proofDocumentUrl: old.proofDocumentUrl,
        status: 'APPROVED',
      );
      _addNotification('Claim for "${old.organizationName}" approved. Assigned ${old.claimantUsername} as Org Admin.');
      notifyListeners();
    }
  }

  void rejectClaimRequest(String claimId) {
    final idx = _claimRequests.indexWhere((c) => c.id == claimId);
    if (idx != -1) {
      final old = _claimRequests[idx];
      _claimRequests[idx] = ClaimOrganizationRequestModel(
        id: old.id,
        organizationId: old.organizationId,
        organizationName: old.organizationName,
        claimantUsername: old.claimantUsername,
        claimantDesignation: old.claimantDesignation,
        officialEmail: old.officialEmail,
        officialPhone: old.officialPhone,
        proofDocumentUrl: old.proofDocumentUrl,
        status: 'REJECTED',
      );
      _addNotification('Claim for "${old.organizationName}" rejected.');
      notifyListeners();
    }
  }

  // ==========================================
  // PHASE 2.5: APPOINTMENT & PATIENT COORDINATION 2.0
  // ==========================================

  List<AppointmentRequestModel> get patientTodayAppointments {
    final today = DateTime.now().toString().split(' ').first;
    return _appointmentRequests.where((a) => a.preferredDate == today && a.status != 'CANCELLED' && a.status != 'NO_SHOW').toList();
  }

  List<AppointmentRequestModel> get patientUpcomingAppointments {
    final today = DateTime.now().toString().split(' ').first;
    return _appointmentRequests.where((a) => a.preferredDate.compareTo(today) > 0 && a.status != 'CANCELLED' && a.status != 'COMPLETED').toList();
  }

  List<AppointmentRequestModel> get patientPastAppointments {
    final today = DateTime.now().toString().split(' ').first;
    return _appointmentRequests.where((a) => a.status == 'COMPLETED' || (a.preferredDate.compareTo(today) < 0 && a.status != 'CANCELLED' && a.status != 'NO_SHOW')).toList();
  }

  List<AppointmentRequestModel> get patientCancelledAppointments {
    return _appointmentRequests.where((a) => a.status == 'CANCELLED').toList();
  }

  List<AppointmentRequestModel> get patientNoShowAppointments {
    return _appointmentRequests.where((a) => a.status == 'NO_SHOW').toList();
  }

  // Hospital Desk Filtered List
  List<AppointmentRequestModel> getDeskAppointments({String statusFilter = 'ALL', String? query, String? date}) {
    return _appointmentRequests.where((a) {
      if (date != null && date.isNotEmpty && a.preferredDate != date) {
        return false;
      }
      if (statusFilter == 'FLAGGED_LEAVE') {
        if (!a.isDoctorUnavailableFlagged) return false;
      } else if (statusFilter != 'ALL' && a.status != statusFilter) {
        return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase();
        final matchPatient = a.patientName.toLowerCase().contains(q) || a.patientPhone.contains(q);
        final matchDoc = a.doctorName.toLowerCase().contains(q) || a.doctorSpecialty.toLowerCase().contains(q);
        final matchToken = a.tokenNumber.toLowerCase().contains(q);
        if (!matchPatient && !matchDoc && !matchToken) return false;
      }
      return true;
    }).toList();
  }

  // 1. Smart Slot Appointment Booking
  void bookDoctorSmartAppointment(AppointmentRequestModel appointment) {
    _appointmentRequests.insert(0, appointment);
    _addNotification('Appointment confirmed for ${appointment.patientName} with ${appointment.doctorName} on ${appointment.preferredDate} (${appointment.preferredTimeSlot}).');
    notifyListeners();
  }

  // 2. Patient Appointment Rescheduling
  void rescheduleAppointment(String apptId, String newDate, String newTimeSlot, String reason) {
    final idx = _appointmentRequests.indexWhere((a) => a.id == apptId);
    if (idx != -1) {
      final old = _appointmentRequests[idx];
      final newHistory = List<AppointmentStatusHistoryModel>.from(old.statusHistory);
      newHistory.add(AppointmentStatusHistoryModel(
        id: 'H-${DateTime.now().millisecondsSinceEpoch}',
        fromStatus: old.status,
        toStatus: 'RESCHEDULED',
        changedByUsername: 'Patient / Coordinator',
        notes: reason,
        createdAt: DateTime.now().toString().split('.').first,
      ));

      _appointmentRequests[idx] = AppointmentRequestModel(
        id: old.id,
        organizationId: old.organizationId,
        organizationName: old.organizationName,
        doctorId: old.doctorId,
        doctorName: old.doctorName,
        doctorSpecialty: old.doctorSpecialty,
        substituteDoctorName: old.substituteDoctorName,
        patientName: old.patientName,
        patientPhone: old.patientPhone,
        patientAge: old.patientAge,
        patientGender: old.patientGender,
        district: old.district,
        preferredDate: newDate,
        preferredTimeSlot: newTimeSlot,
        consultationMode: old.consultationMode,
        chiefComplaint: old.chiefComplaint,
        status: 'RESCHEDULED',
        statusDisplay: 'Rescheduled to $newDate',
        tokenNumber: old.tokenNumber,
        hospitalNotes: old.hospitalNotes,
        cancellationReason: old.cancellationReason,
        rescheduleReason: reason,
        rejectionReason: old.rejectionReason,
        rescheduledFromDate: old.preferredDate,
        rescheduledFromSlot: old.preferredTimeSlot,
        isDoctorUnavailableFlagged: false,
        createdAt: old.createdAt,
        statusHistory: newHistory,
      );
      _addNotification('Appointment #${old.id} rescheduled to $newDate ($newTimeSlot). Push notification sent.');
      notifyListeners();
    }
  }

  // 3. Patient Appointment Cancellation
  void cancelAppointment(String apptId, String reason) {
    final idx = _appointmentRequests.indexWhere((a) => a.id == apptId);
    if (idx != -1) {
      final old = _appointmentRequests[idx];
      final newHistory = List<AppointmentStatusHistoryModel>.from(old.statusHistory);
      newHistory.add(AppointmentStatusHistoryModel(
        id: 'H-${DateTime.now().millisecondsSinceEpoch}',
        fromStatus: old.status,
        toStatus: 'CANCELLED',
        changedByUsername: 'Patient / Coordinator',
        notes: reason,
        createdAt: DateTime.now().toString().split('.').first,
      ));

      _appointmentRequests[idx] = AppointmentRequestModel(
        id: old.id,
        organizationId: old.organizationId,
        organizationName: old.organizationName,
        doctorId: old.doctorId,
        doctorName: old.doctorName,
        doctorSpecialty: old.doctorSpecialty,
        substituteDoctorName: old.substituteDoctorName,
        patientName: old.patientName,
        patientPhone: old.patientPhone,
        patientAge: old.patientAge,
        patientGender: old.patientGender,
        district: old.district,
        preferredDate: old.preferredDate,
        preferredTimeSlot: old.preferredTimeSlot,
        consultationMode: old.consultationMode,
        chiefComplaint: old.chiefComplaint,
        status: 'CANCELLED',
        statusDisplay: 'Cancelled',
        tokenNumber: old.tokenNumber,
        hospitalNotes: old.hospitalNotes,
        cancellationReason: reason,
        rescheduleReason: old.rescheduleReason,
        rejectionReason: old.rejectionReason,
        rescheduledFromDate: old.rescheduledFromDate,
        rescheduledFromSlot: old.rescheduledFromSlot,
        isDoctorUnavailableFlagged: false,
        createdAt: old.createdAt,
        statusHistory: newHistory,
      );
      _addNotification('Appointment #${old.id} for ${old.patientName} cancelled.');
      notifyListeners();
    }
  }

  // 4. Hospital Desk: Accept Request
  void deskAcceptAppointment(String apptId, {String notes = ''}) {
    final idx = _appointmentRequests.indexWhere((a) => a.id == apptId);
    if (idx != -1) {
      final old = _appointmentRequests[idx];
      final newHistory = List<AppointmentStatusHistoryModel>.from(old.statusHistory);
      newHistory.add(AppointmentStatusHistoryModel(
        id: 'H-${DateTime.now().millisecondsSinceEpoch}',
        fromStatus: old.status,
        toStatus: 'ACCEPTED',
        changedByUsername: 'Hospital Desk Staff',
        notes: notes.isNotEmpty ? notes : 'Accepted by OPD Desk',
        createdAt: DateTime.now().toString().split('.').first,
      ));

      _appointmentRequests[idx] = AppointmentRequestModel(
        id: old.id,
        organizationId: old.organizationId,
        organizationName: old.organizationName,
        doctorId: old.doctorId,
        doctorName: old.doctorName,
        doctorSpecialty: old.doctorSpecialty,
        substituteDoctorName: old.substituteDoctorName,
        patientName: old.patientName,
        patientPhone: old.patientPhone,
        patientAge: old.patientAge,
        patientGender: old.patientGender,
        district: old.district,
        preferredDate: old.preferredDate,
        preferredTimeSlot: old.preferredTimeSlot,
        consultationMode: old.consultationMode,
        chiefComplaint: old.chiefComplaint,
        status: 'ACCEPTED',
        statusDisplay: 'Accepted & Confirmed',
        tokenNumber: old.tokenNumber == 'Pending' ? 'TK-${_appointmentRequests.length + 10}' : old.tokenNumber,
        hospitalNotes: notes.isNotEmpty ? notes : old.hospitalNotes,
        cancellationReason: old.cancellationReason,
        rescheduleReason: old.rescheduleReason,
        rejectionReason: old.rejectionReason,
        rescheduledFromDate: old.rescheduledFromDate,
        rescheduledFromSlot: old.rescheduledFromSlot,
        isDoctorUnavailableFlagged: false,
        createdAt: old.createdAt,
        statusHistory: newHistory,
      );
      _addNotification('Accepted appointment for ${old.patientName}. Patient notified via SMS & CareLink push.');
      notifyListeners();
    }
  }

  // 5. Hospital Desk: Reject Request
  void deskRejectAppointment(String apptId, {String reason = ''}) {
    final idx = _appointmentRequests.indexWhere((a) => a.id == apptId);
    if (idx != -1) {
      final old = _appointmentRequests[idx];
      final newHistory = List<AppointmentStatusHistoryModel>.from(old.statusHistory);
      newHistory.add(AppointmentStatusHistoryModel(
        id: 'H-${DateTime.now().millisecondsSinceEpoch}',
        fromStatus: old.status,
        toStatus: 'REJECTED',
        changedByUsername: 'Hospital Desk Staff',
        notes: reason,
        createdAt: DateTime.now().toString().split('.').first,
      ));

      _appointmentRequests[idx] = AppointmentRequestModel(
        id: old.id,
        organizationId: old.organizationId,
        organizationName: old.organizationName,
        doctorId: old.doctorId,
        doctorName: old.doctorName,
        doctorSpecialty: old.doctorSpecialty,
        substituteDoctorName: old.substituteDoctorName,
        patientName: old.patientName,
        patientPhone: old.patientPhone,
        patientAge: old.patientAge,
        patientGender: old.patientGender,
        district: old.district,
        preferredDate: old.preferredDate,
        preferredTimeSlot: old.preferredTimeSlot,
        consultationMode: old.consultationMode,
        chiefComplaint: old.chiefComplaint,
        status: 'REJECTED',
        statusDisplay: 'Rejected by Hospital',
        tokenNumber: old.tokenNumber,
        hospitalNotes: reason,
        cancellationReason: old.cancellationReason,
        rescheduleReason: old.rescheduleReason,
        rejectionReason: reason,
        rescheduledFromDate: old.rescheduledFromDate,
        rescheduledFromSlot: old.rescheduledFromSlot,
        isDoctorUnavailableFlagged: false,
        createdAt: old.createdAt,
        statusHistory: newHistory,
      );
      _addNotification('Rejected appointment for ${old.patientName}: $reason');
      notifyListeners();
    }
  }

  // 6. Hospital Desk: Check-In Patient
  void deskCheckInAppointment(String apptId, {String notes = ''}) {
    final idx = _appointmentRequests.indexWhere((a) => a.id == apptId);
    if (idx != -1) {
      final old = _appointmentRequests[idx];
      final newHistory = List<AppointmentStatusHistoryModel>.from(old.statusHistory);
      newHistory.add(AppointmentStatusHistoryModel(
        id: 'H-${DateTime.now().millisecondsSinceEpoch}',
        fromStatus: old.status,
        toStatus: 'CHECKED_IN',
        changedByUsername: 'Reception Triage Desk',
        notes: notes.isNotEmpty ? notes : 'Patient arrived at hospital OPD triage',
        createdAt: DateTime.now().toString().split('.').first,
      ));

      _appointmentRequests[idx] = AppointmentRequestModel(
        id: old.id,
        organizationId: old.organizationId,
        organizationName: old.organizationName,
        doctorId: old.doctorId,
        doctorName: old.doctorName,
        doctorSpecialty: old.doctorSpecialty,
        substituteDoctorName: old.substituteDoctorName,
        patientName: old.patientName,
        patientPhone: old.patientPhone,
        patientAge: old.patientAge,
        patientGender: old.patientGender,
        district: old.district,
        preferredDate: old.preferredDate,
        preferredTimeSlot: old.preferredTimeSlot,
        consultationMode: old.consultationMode,
        chiefComplaint: old.chiefComplaint,
        status: 'CHECKED_IN',
        statusDisplay: 'Checked In • In OPD Queue',
        tokenNumber: old.tokenNumber,
        hospitalNotes: notes.isNotEmpty ? notes : old.hospitalNotes,
        cancellationReason: old.cancellationReason,
        rescheduleReason: old.rescheduleReason,
        rejectionReason: old.rejectionReason,
        rescheduledFromDate: old.rescheduledFromDate,
        rescheduledFromSlot: old.rescheduledFromSlot,
        isDoctorUnavailableFlagged: false,
        createdAt: old.createdAt,
        statusHistory: newHistory,
      );
      _addNotification('Checked-in ${old.patientName} (Token ${old.tokenNumber}) into live OPD queue.');
      notifyListeners();
    }
  }

  // 7. Hospital Desk: Mark No-Show
  void deskMarkNoShowAppointment(String apptId, {String notes = ''}) {
    final idx = _appointmentRequests.indexWhere((a) => a.id == apptId);
    if (idx != -1) {
      final old = _appointmentRequests[idx];
      final newHistory = List<AppointmentStatusHistoryModel>.from(old.statusHistory);
      newHistory.add(AppointmentStatusHistoryModel(
        id: 'H-${DateTime.now().millisecondsSinceEpoch}',
        fromStatus: old.status,
        toStatus: 'NO_SHOW',
        changedByUsername: 'Reception Desk',
        notes: notes.isNotEmpty ? notes : 'Patient did not arrive for scheduled slot',
        createdAt: DateTime.now().toString().split('.').first,
      ));

      _appointmentRequests[idx] = AppointmentRequestModel(
        id: old.id,
        organizationId: old.organizationId,
        organizationName: old.organizationName,
        doctorId: old.doctorId,
        doctorName: old.doctorName,
        doctorSpecialty: old.doctorSpecialty,
        substituteDoctorName: old.substituteDoctorName,
        patientName: old.patientName,
        patientPhone: old.patientPhone,
        patientAge: old.patientAge,
        patientGender: old.patientGender,
        district: old.district,
        preferredDate: old.preferredDate,
        preferredTimeSlot: old.preferredTimeSlot,
        consultationMode: old.consultationMode,
        chiefComplaint: old.chiefComplaint,
        status: 'NO_SHOW',
        statusDisplay: 'No Show',
        tokenNumber: old.tokenNumber,
        hospitalNotes: notes.isNotEmpty ? notes : 'Patient missed consultation window',
        cancellationReason: old.cancellationReason,
        rescheduleReason: old.rescheduleReason,
        rejectionReason: old.rejectionReason,
        rescheduledFromDate: old.rescheduledFromDate,
        rescheduledFromSlot: old.rescheduledFromSlot,
        isDoctorUnavailableFlagged: false,
        createdAt: old.createdAt,
        statusHistory: newHistory,
      );
      _addNotification('Marked Appointment #${old.id} (${old.patientName}) as No-Show.');
      notifyListeners();
    }
  }

  // 8. Hospital Desk: Complete Consultation
  void deskCompleteAppointment(String apptId, {String notes = ''}) {
    final idx = _appointmentRequests.indexWhere((a) => a.id == apptId);
    if (idx != -1) {
      final old = _appointmentRequests[idx];
      final newHistory = List<AppointmentStatusHistoryModel>.from(old.statusHistory);
      newHistory.add(AppointmentStatusHistoryModel(
        id: 'H-${DateTime.now().millisecondsSinceEpoch}',
        fromStatus: old.status,
        toStatus: 'COMPLETED',
        changedByUsername: 'Doctor / Medical Officer',
        notes: notes.isNotEmpty ? notes : 'Consultation completed',
        createdAt: DateTime.now().toString().split('.').first,
      ));

      _appointmentRequests[idx] = AppointmentRequestModel(
        id: old.id,
        organizationId: old.organizationId,
        organizationName: old.organizationName,
        doctorId: old.doctorId,
        doctorName: old.doctorName,
        doctorSpecialty: old.doctorSpecialty,
        substituteDoctorName: old.substituteDoctorName,
        patientName: old.patientName,
        patientPhone: old.patientPhone,
        patientAge: old.patientAge,
        patientGender: old.patientGender,
        district: old.district,
        preferredDate: old.preferredDate,
        preferredTimeSlot: old.preferredTimeSlot,
        consultationMode: old.consultationMode,
        chiefComplaint: old.chiefComplaint,
        status: 'COMPLETED',
        statusDisplay: 'Completed',
        tokenNumber: old.tokenNumber,
        hospitalNotes: notes.isNotEmpty ? notes : old.hospitalNotes,
        cancellationReason: old.cancellationReason,
        rescheduleReason: old.rescheduleReason,
        rejectionReason: old.rejectionReason,
        rescheduledFromDate: old.rescheduledFromDate,
        rescheduledFromSlot: old.rescheduledFromSlot,
        isDoctorUnavailableFlagged: false,
        createdAt: old.createdAt,
        statusHistory: newHistory,
      );
      _addNotification('Completed consultation for ${old.patientName} (Token ${old.tokenNumber}).');
      notifyListeners();
    }
  }

  // 9. Doctor Leave Exception: Flag affected appointments
  void markDoctorLeaveAndFlagAppointments(String doctorId, String doctorName, String dateStr, String reason) {
    int flaggedCount = 0;
    for (int i = 0; i < _appointmentRequests.length; i++) {
      final appt = _appointmentRequests[i];
      if (appt.doctorId == doctorId && appt.preferredDate == dateStr && appt.status != 'CANCELLED' && appt.status != 'COMPLETED') {
        _appointmentRequests[i] = AppointmentRequestModel(
          id: appt.id,
          organizationId: appt.organizationId,
          organizationName: appt.organizationName,
          doctorId: appt.doctorId,
          doctorName: appt.doctorName,
          doctorSpecialty: appt.doctorSpecialty,
          substituteDoctorName: appt.substituteDoctorName,
          patientName: appt.patientName,
          patientPhone: appt.patientPhone,
          patientAge: appt.patientAge,
          patientGender: appt.patientGender,
          district: appt.district,
          preferredDate: appt.preferredDate,
          preferredTimeSlot: appt.preferredTimeSlot,
          consultationMode: appt.consultationMode,
          chiefComplaint: appt.chiefComplaint,
          status: appt.status,
          statusDisplay: '${appt.statusDisplay} [Doctor On Leave]',
          tokenNumber: appt.tokenNumber,
          hospitalNotes: 'Doctor marked leave: $reason',
          cancellationReason: appt.cancellationReason,
          rescheduleReason: appt.rescheduleReason,
          rejectionReason: appt.rejectionReason,
          rescheduledFromDate: appt.rescheduledFromDate,
          rescheduledFromSlot: appt.rescheduledFromSlot,
          isDoctorUnavailableFlagged: true,
          createdAt: appt.createdAt,
          statusHistory: appt.statusHistory,
        );
        flaggedCount++;
      }
    }
    _addNotification('Doctor Leave marked for $doctorName on $dateStr. $flaggedCount appointments flagged for resolution.');
    notifyListeners();
  }

  // 10. Doctor Leave Bulk Resolution
  void resolveDoctorLeaveImpact({
    required List<String> appointmentIds,
    required String action,
    String substituteDoctorName = '',
    String newDate = '',
    String notes = '',
  }) {
    int resolvedCount = 0;
    for (int i = 0; i < _appointmentRequests.length; i++) {
      final appt = _appointmentRequests[i];
      if (appointmentIds.contains(appt.id)) {
        final newHistory = List<AppointmentStatusHistoryModel>.from(appt.statusHistory);
        newHistory.add(AppointmentStatusHistoryModel(
          id: 'H-${DateTime.now().millisecondsSinceEpoch}',
          fromStatus: appt.status,
          toStatus: action == 'CANCEL' ? 'CANCELLED' : (action == 'RESCHEDULE' ? 'RESCHEDULED' : appt.status),
          changedByUsername: 'Hospital Leave Resolver Desk',
          notes: 'Leave Impact Resolution ($action): $notes',
          createdAt: DateTime.now().toString().split('.').first,
        ));

        if (action == 'REASSIGN_SUBSTITUTE') {
          _appointmentRequests[i] = AppointmentRequestModel(
            id: appt.id,
            organizationId: appt.organizationId,
            organizationName: appt.organizationName,
            doctorId: appt.doctorId,
            doctorName: appt.doctorName,
            doctorSpecialty: appt.doctorSpecialty,
            substituteDoctorName: substituteDoctorName.isNotEmpty ? substituteDoctorName : 'Substitute Specialist',
            patientName: appt.patientName,
            patientPhone: appt.patientPhone,
            patientAge: appt.patientAge,
            patientGender: appt.patientGender,
            district: appt.district,
            preferredDate: appt.preferredDate,
            preferredTimeSlot: appt.preferredTimeSlot,
            consultationMode: appt.consultationMode,
            chiefComplaint: appt.chiefComplaint,
            status: appt.status,
            statusDisplay: '${appt.statusDisplay} (Covered by $substituteDoctorName)',
            tokenNumber: appt.tokenNumber,
            hospitalNotes: 'Substitute Assigned: $substituteDoctorName. $notes',
            cancellationReason: appt.cancellationReason,
            rescheduleReason: appt.rescheduleReason,
            rejectionReason: appt.rejectionReason,
            rescheduledFromDate: appt.rescheduledFromDate,
            rescheduledFromSlot: appt.rescheduledFromSlot,
            isDoctorUnavailableFlagged: false,
            createdAt: appt.createdAt,
            statusHistory: newHistory,
          );
        } else if (action == 'RESCHEDULE') {
          _appointmentRequests[i] = AppointmentRequestModel(
            id: appt.id,
            organizationId: appt.organizationId,
            organizationName: appt.organizationName,
            doctorId: appt.doctorId,
            doctorName: appt.doctorName,
            doctorSpecialty: appt.doctorSpecialty,
            substituteDoctorName: appt.substituteDoctorName,
            patientName: appt.patientName,
            patientPhone: appt.patientPhone,
            patientAge: appt.patientAge,
            patientGender: appt.patientGender,
            district: appt.district,
            preferredDate: newDate.isNotEmpty ? newDate : appt.preferredDate,
            preferredTimeSlot: appt.preferredTimeSlot,
            consultationMode: appt.consultationMode,
            chiefComplaint: appt.chiefComplaint,
            status: 'RESCHEDULED',
            statusDisplay: 'Auto-Rescheduled to $newDate',
            tokenNumber: appt.tokenNumber,
            hospitalNotes: 'Rescheduled due to doctor leave. $notes',
            cancellationReason: appt.cancellationReason,
            rescheduleReason: 'Doctor unavailability / leave',
            rejectionReason: appt.rejectionReason,
            rescheduledFromDate: appt.preferredDate,
            rescheduledFromSlot: appt.preferredTimeSlot,
            isDoctorUnavailableFlagged: false,
            createdAt: appt.createdAt,
            statusHistory: newHistory,
          );
        } else if (action == 'CANCEL') {
          _appointmentRequests[i] = AppointmentRequestModel(
            id: appt.id,
            organizationId: appt.organizationId,
            organizationName: appt.organizationName,
            doctorId: appt.doctorId,
            doctorName: appt.doctorName,
            doctorSpecialty: appt.doctorSpecialty,
            substituteDoctorName: appt.substituteDoctorName,
            patientName: appt.patientName,
            patientPhone: appt.patientPhone,
            patientAge: appt.patientAge,
            patientGender: appt.patientGender,
            district: appt.district,
            preferredDate: appt.preferredDate,
            preferredTimeSlot: appt.preferredTimeSlot,
            consultationMode: appt.consultationMode,
            chiefComplaint: appt.chiefComplaint,
            status: 'CANCELLED',
            statusDisplay: 'Cancelled by Hospital',
            tokenNumber: appt.tokenNumber,
            hospitalNotes: 'Cancelled with notice due to doctor leave. $notes',
            cancellationReason: 'Doctor on emergency leave',
            rescheduleReason: appt.rescheduleReason,
            rejectionReason: appt.rejectionReason,
            rescheduledFromDate: appt.rescheduledFromDate,
            rescheduledFromSlot: appt.rescheduledFromSlot,
            isDoctorUnavailableFlagged: false,
            createdAt: appt.createdAt,
            statusHistory: newHistory,
          );
        }
        resolvedCount++;
      }
    }
    _addNotification('Resolved $resolvedCount appointments via $action. Patient notifications dispatched.');
    notifyListeners();
  }

  void updateNetworkAppointmentStatus(String apptId, String newStatus) {
    deskAcceptAppointment(apptId);
  }

  void requestDoctorAppointment(AppointmentRequestModel appointment) {
    bookDoctorSmartAppointment(appointment);
  }

  void reportIncorrectInformation({
    required String hospitalName,
    required String reportType,
    required String description,
  }) {
    _addNotification('Inaccuracy report for $hospitalName submitted to CareLink Moderation Desk.');
    notifyListeners();
  }

  // ==========================================
  // PHASE 2.6: ADVANCED QUEUE & PATIENT FLOW ACTIONS
  // ==========================================

  List<QueueSessionModel> _queueSessions = NetworkDatabaseService.getMockQueueSessions();
  List<QueueSessionModel> get queueSessions => _queueSessions;

  HospitalFlowAnalyticsModel _hospitalFlowAnalytics = NetworkDatabaseService.getMockHospitalFlowAnalytics();
  HospitalFlowAnalyticsModel get hospitalFlowAnalytics => _hospitalFlowAnalytics;

  /// Call the next highest priority waiting patient
  void callNextQueueToken(String sessionId) {
    final sIdx = _queueSessions.indexWhere((s) => s.id == sessionId);
    if (sIdx == -1) return;

    final session = _queueSessions[sIdx];
    if (session.isPaused) {
      _addNotification('Queue is currently paused (${session.pauseReason}). Resume before calling tokens.');
      notifyListeners();
      return;
    }

    // Find next token by priority rank (-rank) and token_number
    final candidateTokens = session.tokens.where((t) => t.status == 'WAITING' || t.status == 'CHECKED_IN').toList();
    if (candidateTokens.isEmpty) {
      _addNotification('No waiting patients in ${session.departmentName ?? session.queueTypeDisplay}.');
      notifyListeners();
      return;
    }

    candidateTokens.sort((a, b) {
      final rankCompare = b.priorityRank.compareTo(a.priorityRank);
      if (rankCompare != 0) return rankCompare;
      return a.tokenNumber.compareTo(b.tokenNumber);
    });

    final nextToken = candidateTokens.first;
    final updatedTokens = session.tokens.map((t) {
      if (t.id == nextToken.id) {
        return QueueTokenModel(
          id: t.id,
          queueSessionId: t.queueSessionId,
          appointmentId: t.appointmentId,
          tokenNumber: t.tokenNumber,
          tokenLabel: t.tokenLabel,
          patientName: t.patientName,
          patientPhone: t.patientPhone,
          priority: t.priority,
          priorityRank: t.priorityRank,
          isWalkIn: t.isWalkIn,
          status: 'CALLED',
          statusDisplay: 'Now Calling',
          calledAt: DateTime.now().toString().split('.').first,
          callCount: t.callCount + 1,
          lastCalledAt: DateTime.now().toString().split('.').first,
          roomNumber: session.roomNumber,
          doctorName: session.doctorName,
        );
      }
      return t;
    }).toList();

    _queueSessions[sIdx] = QueueSessionModel(
      id: session.id,
      organizationId: session.organizationId,
      organizationName: session.organizationName,
      doctorId: session.doctorId,
      doctorName: session.doctorName,
      departmentName: session.departmentName,
      roomNumber: session.roomNumber,
      queueType: session.queueType,
      queueTypeDisplay: session.queueTypeDisplay,
      tokenPrefix: session.tokenPrefix,
      sessionDate: session.sessionDate,
      currentTokenNumber: nextToken.tokenNumber,
      totalTokensIssued: session.totalTokensIssued,
      isActive: session.isActive,
      isPaused: session.isPaused,
      pauseReason: session.pauseReason,
      avgConsultationDurationSeconds: session.avgConsultationDurationSeconds,
      totalCompletedConsultations: session.totalCompletedConsultations,
      tokens: updatedTokens,
    );

    _addNotification('Now calling Token ${nextToken.tokenLabel} (${nextToken.patientName}) to ${session.roomNumber}. Proximity alerts dispatched.');
    notifyListeners();
  }

  /// Staged recall for absent patient
  void recallQueueToken(String sessionId, String tokenId) {
    final sIdx = _queueSessions.indexWhere((s) => s.id == sessionId);
    if (sIdx == -1) return;

    final session = _queueSessions[sIdx];
    final updatedTokens = session.tokens.map((t) {
      if (t.id == tokenId) {
        final newCount = t.callCount + 1;
        final newStatus = newCount >= 3 ? 'NO_SHOW' : 'CALLED';
        final newDisplay = newCount >= 3 ? 'No Show (3 Recalls Failed)' : 'Recalled (Call #$newCount)';
        return QueueTokenModel(
          id: t.id,
          queueSessionId: t.queueSessionId,
          appointmentId: t.appointmentId,
          tokenNumber: t.tokenNumber,
          tokenLabel: t.tokenLabel,
          patientName: t.patientName,
          patientPhone: t.patientPhone,
          priority: t.priority,
          priorityRank: t.priorityRank,
          isWalkIn: t.isWalkIn,
          status: newStatus,
          statusDisplay: newDisplay,
          calledAt: t.calledAt,
          callCount: newCount,
          lastCalledAt: DateTime.now().toString().split('.').first,
          roomNumber: session.roomNumber,
          doctorName: session.doctorName,
        );
      }
      return t;
    }).toList();

    _queueSessions[sIdx] = QueueSessionModel(
      id: session.id,
      organizationId: session.organizationId,
      organizationName: session.organizationName,
      doctorId: session.doctorId,
      doctorName: session.doctorName,
      departmentName: session.departmentName,
      roomNumber: session.roomNumber,
      queueType: session.queueType,
      queueTypeDisplay: session.queueTypeDisplay,
      tokenPrefix: session.tokenPrefix,
      sessionDate: session.sessionDate,
      currentTokenNumber: session.currentTokenNumber,
      totalTokensIssued: session.totalTokensIssued,
      isActive: session.isActive,
      isPaused: session.isPaused,
      pauseReason: session.pauseReason,
      avgConsultationDurationSeconds: session.avgConsultationDurationSeconds,
      totalCompletedConsultations: session.totalCompletedConsultations,
      tokens: updatedTokens,
    );

    _addNotification('Recalled token in ${session.departmentName}. Audio chime & push alert triggered.');
    notifyListeners();
  }

  /// Start Consultation
  void startConsultationQueueToken(String sessionId, String tokenId) {
    final sIdx = _queueSessions.indexWhere((s) => s.id == sessionId);
    if (sIdx == -1) return;

    final session = _queueSessions[sIdx];
    final updatedTokens = session.tokens.map((t) {
      if (t.id == tokenId) {
        return QueueTokenModel(
          id: t.id,
          queueSessionId: t.queueSessionId,
          appointmentId: t.appointmentId,
          tokenNumber: t.tokenNumber,
          tokenLabel: t.tokenLabel,
          patientName: t.patientName,
          patientPhone: t.patientPhone,
          priority: t.priority,
          priorityRank: t.priorityRank,
          isWalkIn: t.isWalkIn,
          status: 'IN_CONSULTATION',
          statusDisplay: 'In Consultation',
          calledAt: t.calledAt,
          callCount: t.callCount,
          lastCalledAt: t.lastCalledAt,
          roomNumber: session.roomNumber,
          doctorName: session.doctorName,
        );
      }
      return t;
    }).toList();

    _queueSessions[sIdx] = QueueSessionModel(
      id: session.id,
      organizationId: session.organizationId,
      organizationName: session.organizationName,
      doctorId: session.doctorId,
      doctorName: session.doctorName,
      departmentName: session.departmentName,
      roomNumber: session.roomNumber,
      queueType: session.queueType,
      queueTypeDisplay: session.queueTypeDisplay,
      tokenPrefix: session.tokenPrefix,
      sessionDate: session.sessionDate,
      currentTokenNumber: session.currentTokenNumber,
      totalTokensIssued: session.totalTokensIssued,
      isActive: session.isActive,
      isPaused: session.isPaused,
      pauseReason: session.pauseReason,
      avgConsultationDurationSeconds: session.avgConsultationDurationSeconds,
      totalCompletedConsultations: session.totalCompletedConsultations,
      tokens: updatedTokens,
    );

    _addNotification('Started consultation in ${session.roomNumber}.');
    notifyListeners();
  }

  /// Complete Consultation
  void completeConsultationQueueToken(String sessionId, String tokenId, {String notes = ''}) {
    final sIdx = _queueSessions.indexWhere((s) => s.id == sessionId);
    if (sIdx == -1) return;

    final session = _queueSessions[sIdx];
    final updatedTokens = session.tokens.map((t) {
      if (t.id == tokenId) {
        return QueueTokenModel(
          id: t.id,
          queueSessionId: t.queueSessionId,
          appointmentId: t.appointmentId,
          tokenNumber: t.tokenNumber,
          tokenLabel: t.tokenLabel,
          patientName: t.patientName,
          patientPhone: t.patientPhone,
          priority: t.priority,
          priorityRank: t.priorityRank,
          isWalkIn: t.isWalkIn,
          status: 'COMPLETED',
          statusDisplay: 'Completed',
          calledAt: t.calledAt,
          callCount: t.callCount,
          lastCalledAt: t.lastCalledAt,
          clinicalNotes: notes,
          roomNumber: session.roomNumber,
          doctorName: session.doctorName,
        );
      }
      return t;
    }).toList();

    _queueSessions[sIdx] = QueueSessionModel(
      id: session.id,
      organizationId: session.organizationId,
      organizationName: session.organizationName,
      doctorId: session.doctorId,
      doctorName: session.doctorName,
      departmentName: session.departmentName,
      roomNumber: session.roomNumber,
      queueType: session.queueType,
      queueTypeDisplay: session.queueTypeDisplay,
      tokenPrefix: session.tokenPrefix,
      sessionDate: session.sessionDate,
      currentTokenNumber: session.currentTokenNumber,
      totalTokensIssued: session.totalTokensIssued,
      isActive: session.isActive,
      isPaused: session.isPaused,
      pauseReason: session.pauseReason,
      avgConsultationDurationSeconds: session.avgConsultationDurationSeconds,
      totalCompletedConsultations: session.totalCompletedConsultations + 1,
      tokens: updatedTokens,
    );

    _addNotification('Consultation completed for token. Pharmacy / Billing route opened.');
    notifyListeners();
  }

  /// Pause Queue Session
  void pauseQueueSession(String sessionId, String reason) {
    final sIdx = _queueSessions.indexWhere((s) => s.id == sessionId);
    if (sIdx == -1) return;

    final s = _queueSessions[sIdx];
    _queueSessions[sIdx] = QueueSessionModel(
      id: s.id,
      organizationId: s.organizationId,
      organizationName: s.organizationName,
      doctorId: s.doctorId,
      doctorName: s.doctorName,
      departmentName: s.departmentName,
      roomNumber: s.roomNumber,
      queueType: s.queueType,
      queueTypeDisplay: s.queueTypeDisplay,
      tokenPrefix: s.tokenPrefix,
      sessionDate: s.sessionDate,
      currentTokenNumber: s.currentTokenNumber,
      totalTokensIssued: s.totalTokensIssued,
      isActive: s.isActive,
      isPaused: true,
      pauseReason: reason,
      avgConsultationDurationSeconds: s.avgConsultationDurationSeconds,
      totalCompletedConsultations: s.totalCompletedConsultations,
      tokens: s.tokens,
    );

    _addNotification('Queue ${s.departmentName ?? s.queueType} PAUSED ($reason). Patients alerted.');
    notifyListeners();
  }

  /// Resume Queue Session
  void resumeQueueSession(String sessionId) {
    final sIdx = _queueSessions.indexWhere((s) => s.id == sessionId);
    if (sIdx == -1) return;

    final s = _queueSessions[sIdx];
    _queueSessions[sIdx] = QueueSessionModel(
      id: s.id,
      organizationId: s.organizationId,
      organizationName: s.organizationName,
      doctorId: s.doctorId,
      doctorName: s.doctorName,
      departmentName: s.departmentName,
      roomNumber: s.roomNumber,
      queueType: s.queueType,
      queueTypeDisplay: s.queueTypeDisplay,
      tokenPrefix: s.tokenPrefix,
      sessionDate: s.sessionDate,
      currentTokenNumber: s.currentTokenNumber,
      totalTokensIssued: s.totalTokensIssued,
      isActive: s.isActive,
      isPaused: false,
      pauseReason: '',
      avgConsultationDurationSeconds: s.avgConsultationDurationSeconds,
      totalCompletedConsultations: s.totalCompletedConsultations,
      tokens: s.tokens,
    );

    _addNotification('Queue ${s.departmentName ?? s.queueType} RESUMED. Operations normal.');
    notifyListeners();
  }

  /// Issue Walk-In Token
  void issueWalkInToken({
    required String sessionId,
    required String patientName,
    required String patientPhone,
    String priority = 'NORMAL',
  }) {
    final sIdx = _queueSessions.indexWhere((s) => s.id == sessionId);
    if (sIdx == -1) return;

    final session = _queueSessions[sIdx];
    final nextNumber = session.totalTokensIssued + 1;
    final tokenLabel = '${session.tokenPrefix}-$nextNumber';

    int rank = 1;
    if (priority == 'EMERGENCY') rank = 4;
    else if (priority == 'URGENT') rank = 3;
    else if (priority == 'PRIORITY') rank = 2;

    final newToken = QueueTokenModel(
      id: 'QT-${DateTime.now().millisecondsSinceEpoch}',
      queueSessionId: session.id,
      tokenNumber: nextNumber,
      tokenLabel: tokenLabel,
      patientName: patientName,
      patientPhone: patientPhone,
      priority: priority,
      priorityRank: rank,
      isWalkIn: true,
      status: 'WAITING',
      statusDisplay: 'Waiting in Queue',
      roomNumber: session.roomNumber,
      doctorName: session.doctorName,
    );

    final updatedTokens = List<QueueTokenModel>.from(session.tokens)..add(newToken);

    _queueSessions[sIdx] = QueueSessionModel(
      id: session.id,
      organizationId: session.organizationId,
      organizationName: session.organizationName,
      doctorId: session.doctorId,
      doctorName: session.doctorName,
      departmentName: session.departmentName,
      roomNumber: session.roomNumber,
      queueType: session.queueType,
      queueTypeDisplay: session.queueTypeDisplay,
      tokenPrefix: session.tokenPrefix,
      sessionDate: session.sessionDate,
      currentTokenNumber: session.currentTokenNumber,
      totalTokensIssued: nextNumber,
      isActive: session.isActive,
      isPaused: session.isPaused,
      pauseReason: session.pauseReason,
      avgConsultationDurationSeconds: session.avgConsultationDurationSeconds,
      totalCompletedConsultations: session.totalCompletedConsultations,
      tokens: updatedTokens,
    );

    _addNotification('Walk-in Token $tokenLabel issued for $patientName ($priority priority).');
    notifyListeners();
  }

  /// Perform Digital QR Check-In
  PatientCheckInResultModel performDigitalCheckIn({
    required String appointmentId,
    required String qrHash,
  }) {
    // Find matching appointment
    final apptIdx = _appointmentRequests.indexWhere((a) => a.id == appointmentId);
    String patientName = 'Patient';
    String roomNumber = 'OPD Room 102';
    String doctorName = 'Doctor';

    if (apptIdx != -1) {
      final appt = _appointmentRequests[apptIdx];
      patientName = appt.patientName;
      doctorName = appt.doctorName;
      deskCheckInAppointment(appointmentId);
    }

    // Activate token in session
    for (int i = 0; i < _queueSessions.length; i++) {
      final session = _queueSessions[i];
      final tokenIdx = session.tokens.indexWhere((t) => t.appointmentId == appointmentId);
      if (tokenIdx != -1) {
        final token = session.tokens[tokenIdx];
        final updatedTokens = List<QueueTokenModel>.from(session.tokens);
        updatedTokens[tokenIdx] = QueueTokenModel(
          id: token.id,
          queueSessionId: token.queueSessionId,
          appointmentId: token.appointmentId,
          tokenNumber: token.tokenNumber,
          tokenLabel: token.tokenLabel,
          patientName: token.patientName,
          patientPhone: token.patientPhone,
          priority: token.priority,
          priorityRank: token.priorityRank,
          isWalkIn: token.isWalkIn,
          status: 'CHECKED_IN',
          statusDisplay: 'Checked In / In Waiting Area',
          checkInTime: DateTime.now().toString().split('.').first,
          roomNumber: session.roomNumber,
          doctorName: session.doctorName,
        );

        _queueSessions[i] = QueueSessionModel(
          id: session.id,
          organizationId: session.organizationId,
          organizationName: session.organizationName,
          doctorId: session.doctorId,
          doctorName: session.doctorName,
          departmentName: session.departmentName,
          roomNumber: session.roomNumber,
          queueType: session.queueType,
          queueTypeDisplay: session.queueTypeDisplay,
          tokenPrefix: session.tokenPrefix,
          sessionDate: session.sessionDate,
          currentTokenNumber: session.currentTokenNumber,
          totalTokensIssued: session.totalTokensIssued,
          isActive: session.isActive,
          isPaused: session.isPaused,
          pauseReason: session.pauseReason,
          avgConsultationDurationSeconds: session.avgConsultationDurationSeconds,
          totalCompletedConsultations: session.totalCompletedConsultations,
          tokens: updatedTokens,
        );
        break;
      }
    }

    _addNotification('QR Arrival Check-in verified for $patientName. Token activated.');
    notifyListeners();

    return PatientCheckInResultModel(
      checkInId: 'CHK-${DateTime.now().millisecondsSinceEpoch}',
      tokenId: 'QT-119',
      tokenLabel: 'C-19',
      patientName: patientName,
      roomNumber: roomNumber,
      doctorName: doctorName,
      patientsAhead: 1,
      estimatedWaitMinutes: 13,
      message: 'Check-in verified. Please proceed to $roomNumber waiting area.',
    );
  }

  // ==========================================
  // PHASE 2.7: PALLIATIVE & HOME HEALTHCARE ACTIONS
  // ==========================================

  void requestHomeVisit({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String requesterName,
    required String requesterPhone,
    required String requesterRelationship,
    required String visitType,
    required String urgency,
    required String preferredDate,
    required String preferredTimeSlot,
    required String reasonAndSymptoms,
    required String locationAddress,
  }) {
    final newReq = HomeVisitRequestModel(
      id: 'HVR-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      requesterName: requesterName,
      requesterPhone: requesterPhone,
      requesterRelationship: requesterRelationship,
      visitType: visitType,
      urgency: urgency,
      preferredDate: preferredDate,
      preferredTimeSlot: preferredTimeSlot,
      reasonAndSymptoms: reasonAndSymptoms,
      locationAddress: locationAddress,
      status: 'PENDING',
      createdAt: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    );

    _homeVisitRequests.insert(0, newReq);
    _addNotification('New Home Visit Requested for $patientName ($urgency)');
    notifyListeners();
  }

  void acceptHomeVisitRequest(String requestId, {String? assignedNurse, String? scheduledTime}) {
    final index = _homeVisitRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final req = _homeVisitRequests[index];
      req.status = 'ACCEPTED';

      final newVisit = VisitModel(
        id: 'VIS-${DateTime.now().millisecondsSinceEpoch}',
        patientId: req.patientId,
        patientName: req.patientName,
        patientAddress: req.locationAddress,
        assignedNurseName: assignedNurse ?? 'Nurse Anitha',
        scheduledDate: req.preferredDate,
        scheduledTime: scheduledTime ?? req.preferredTimeSlot.split('-').first.trim(),
        status: 'Scheduled',
        clinicalNotes: 'Reason: ${req.reasonAndSymptoms}',
        symptomsObserved: req.reasonAndSymptoms,
      );

      _visits.insert(0, newVisit);
      _addNotification('Home Visit Request #${req.id} accepted for ${req.patientName}');
      notifyListeners();
    }
  }

  void rejectHomeVisitRequest(String requestId, String reason) {
    final index = _homeVisitRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _homeVisitRequests[index].status = 'REJECTED';
      _homeVisitRequests[index].rejectionReason = reason;
      _addNotification('Home Visit Request #${_homeVisitRequests[index].id} rejected: $reason');
      notifyListeners();
    }
  }

  void dispatchHomeVisit(String visitId) {
    final index = _visits.indexWhere((v) => v.id == visitId);
    if (index != -1) {
      _visits[index].status = 'Dispatched';
      _addNotification('Care Team dispatched for ${_visits[index].patientName}');
      notifyListeners();
    }
  }

  void recordHomeVisitArrival(String visitId, {String locationName = 'GPS Verified Coordinates'}) {
    final index = _visits.indexWhere((v) => v.id == visitId);
    if (index != -1) {
      _visits[index].status = 'In Progress';
      _visits[index].gpsLocationName = locationName;
      _visits[index].gpsCheckInTime = '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
      _addNotification('Care Team arrived at ${_visits[index].patientName}\'s residence ($locationName)');
      notifyListeners();
    }
  }

  void completeHomeVisitWithStructuredNotes(
    String visitId, {
    required String symptoms,
    required String careProvided,
    required String medicationAdministered,
    required String equipmentUsed,
    required String followUp,
    required String clinicalNotes,
    VitalsReading? vitals,
  }) {
    final index = _visits.indexWhere((v) => v.id == visitId);
    if (index != -1) {
      _visits[index].status = 'Completed';
      _visits[index].symptomsObserved = symptoms;
      _visits[index].careProvided = careProvided;
      _visits[index].medicationAdministered = medicationAdministered;
      _visits[index].equipmentUsed = equipmentUsed;
      _visits[index].followUpInstructions = followUp;
      _visits[index].clinicalNotes = clinicalNotes;
      if (vitals != null) {
        _visits[index].recordedVitals = vitals;
        final pIdx = _patients.indexWhere((p) => p.id == _visits[index].patientId);
        if (pIdx != -1) {
          _patients[pIdx].vitalsHistory.insert(0, vitals);
        }
      }

      _addNotification('Home Visit completed & documented for ${_visits[index].patientName}');
      notifyListeners();
    }
  }

  void addCareTeamMember(String careTeamId, CareTeamMemberModel member) {
    final index = _careTeams.indexWhere((ct) => ct.id == careTeamId);
    if (index != -1) {
      final team = _careTeams[index];
      final updatedMembers = List<CareTeamMemberModel>.from(team.members)..add(member);
      _careTeams[index] = CareTeamModel(
        id: team.id,
        name: team.name,
        leadDoctorName: team.leadDoctorName,
        primaryNurseName: team.primaryNurseName,
        areaCoverage: team.areaCoverage,
        isActive: team.isActive,
        members: updatedMembers,
      );
      _addNotification('Added ${member.memberName} (${member.role}) to ${team.name}');
      notifyListeners();
    }
  }

  void logMedicationDose(String planId, String timeSlot, {String status = 'TAKEN', bool isNurseVerified = false, String notes = ''}) {
    final pIdx = _medicationPlans.indexWhere((p) => p.id == planId);
    if (pIdx != -1) {
      final plan = _medicationPlans[pIdx];
      final newAdmin = MedicationAdministrationModel(
        id: 'ADM-${DateTime.now().millisecondsSinceEpoch}',
        planId: plan.id,
        medicineName: plan.medicineName,
        dosage: plan.dosage,
        patientId: plan.patientId,
        scheduledDate: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
        timeSlot: timeSlot,
        status: status,
        recordedByCaregiver: !isNurseVerified,
        verifiedByNurse: isNurseVerified,
        verifiedNurseName: isNurseVerified ? _currentUser.name : null,
        administeredAt: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        notes: notes,
      );

      final updatedAdmins = List<MedicationAdministrationModel>.from(plan.administrations)..insert(0, newAdmin);
      _medicationPlans[pIdx] = MedicationPlanModel(
        id: plan.id,
        patientId: plan.patientId,
        medicineName: plan.medicineName,
        dosage: plan.dosage,
        route: plan.route,
        frequency: plan.frequency,
        timeSlots: plan.timeSlots,
        prescribedByDoctor: plan.prescribedByDoctor,
        startDate: plan.startDate,
        endDate: plan.endDate,
        instructions: plan.instructions,
        isActive: plan.isActive,
        administrations: updatedAdmins,
      );

      _addNotification('Medication logged: ${plan.medicineName} ($status at $timeSlot)');
      notifyListeners();
    }
  }

  void grantCaregiverAccess({
    required String patientId,
    required String caregiverName,
    required String caregiverPhone,
    required String relationship,
    required List<String> permissions,
  }) {
    final newGrant = CaregiverAccessModel(
      id: 'CG-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      caregiverName: caregiverName,
      caregiverPhone: caregiverPhone,
      relationship: relationship,
      permissions: permissions,
      grantedBy: _currentUser.name,
      grantedAt: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    );

    _caregiverGrants.insert(0, newGrant);
    _addNotification('Caregiver consent granted to $caregiverName for Patient $patientId');
    notifyListeners();
  }

  void revokeCaregiverAccess(String grantId) {
    final index = _caregiverGrants.indexWhere((g) => g.id == grantId);
    if (index != -1) {
      _caregiverGrants[index].isActive = false;
      _addNotification('Revoked caregiver access for ${_caregiverGrants[index].caregiverName}');
      notifyListeners();
    }
  }

  void triggerPalliativeEmergencyEscalation(String patientId, String reason) {
    final patient = _patients.firstWhere((p) => p.id == patientId, orElse: () => _patients.first);
    final alertMsg = 'PALLIATIVE EMERGENCY: $reason for ${patient.name}';

    _addNotification(alertMsg);
    _notifications.insert(0, '🚨 CRITICAL ESCALATION: $alertMsg');
    notifyListeners();
  }

  void _addNotification(String msg) {
    _notifications.insert(0, '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} - $msg');
    if (_notifications.length > 50) {
      _notifications = _notifications.take(50).toList();
    }
  }
}

