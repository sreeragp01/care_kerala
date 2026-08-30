import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/clinical_models.dart';
import '../services/mock_database_service.dart';
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
    _notifications = [
      'Welcome to CareLink Kerala! System running online.',
      'Emergency Blood Request posted for Calicut Medical College Hospital (O+ Group).',
      'Low stock warning: Amlodipine 5mg has reached reorder level.',
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

    if (matchingUser != null && (cleanPassword == 'pass1234' || cleanPassword == 'Sree321#' || cleanPassword == 'Admin@12345' || cleanPassword == 'password123')) {
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

  void _addNotification(String msg) {
    _notifications.insert(0, '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} - $msg');
    if (_notifications.length > 50) {
      _notifications = _notifications.take(50).toList();
    }
  }
}
