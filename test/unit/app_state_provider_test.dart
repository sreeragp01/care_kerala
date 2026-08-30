import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_kerala/core/state/app_state_provider.dart';
import 'package:carelink_kerala/core/models/clinical_models.dart';
import 'package:carelink_kerala/core/models/user_model.dart';
import 'package:carelink_kerala/core/models/patient_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppStateProvider Enhanced State & Settings Tests', () {
    late AppStateProvider state;

    setUp(() {
      state = AppStateProvider();
    });

    test('Dark Mode Toggling', () {
      expect(state.isDarkMode, isTrue);
      state.toggleDarkMode();
      expect(state.isDarkMode, isFalse);
      state.toggleDarkMode();
      expect(state.isDarkMode, isTrue);
    });




    test('API Base URL Configuration', () {
      expect(state.apiBaseUrl, contains('127.0.0.1:8000'));
      state.setApiBaseUrl('https://carelink.kerala.gov.in/api');
      expect(state.apiBaseUrl, 'https://carelink.kerala.gov.in/api');
    });

    test('Notification Preferences Toggling', () {
      expect(state.notifyEmergencyBlood, isTrue);
      state.toggleEmergencyBloodNotification(false);
      expect(state.notifyEmergencyBlood, isFalse);

      expect(state.notifyCriticalPatients, isTrue);
      state.toggleCriticalPatientsNotification(false);
      expect(state.notifyCriticalPatients, isFalse);

      expect(state.notifyLowStock, isTrue);
      state.toggleLowStockNotification(false);
      expect(state.notifyLowStock, isFalse);
    });

    test('Appointments Management', () {
      final initialCount = state.appointments.length;
      final newApt = AppointmentModel(
        id: 'APT-TEST-1',
        patientName: 'Test Patient',
        doctorName: 'Dr. Test',
        date: '2026-08-15',
        time: '11:00 AM',
        type: 'Home Consultation',
        status: 'Confirmed',
      );

      state.addAppointment(newApt);
      expect(state.appointments.length, initialCount + 1);

      state.updateAppointmentStatus('APT-TEST-1', 'Completed');
      final updated = state.appointments.firstWhere((a) => a.id == 'APT-TEST-1');
      expect(updated.status, 'Completed');
    });

    test('Volunteer Registration and Verification', () {
      final initialCount = state.volunteers.length;
      final newVol = VolunteerModel(
        id: 'VOL-TEST-1',
        name: 'Arjun Das',
        phone: '+91 94471 99999',
        ward: 'Ward 5',
        district: 'Kozhikode',
        assignedPatientsCount: 0,
        totalHoursLogged: 0,
        tasksCompleted: 0,
        isVerified: false,
      );

      state.addVolunteer(newVol);
      expect(state.volunteers.length, initialCount + 1);

      state.toggleVolunteerVerification('VOL-TEST-1');
      expect(state.volunteers.firstWhere((v) => v.id == 'VOL-TEST-1').isVerified, isTrue);
    });

    test('Medicine Restocking', () {
      final med = state.medicines.first;
      final initialQty = med.stockQuantity;

      state.restockMedicine(med.id, 50);
      final updatedMed = state.medicines.firstWhere((m) => m.id == med.id);
      expect(updatedMed.stockQuantity, initialQty + 50);
    });

    test('Equipment Loan and Return', () {
      final eq = state.equipment.firstWhere((e) => e.availableCount > 0);
      final initialAvailable = eq.availableCount;
      final initialLoaned = eq.loanedCount;

      state.loanEquipmentToPatient(eq.id, 'Test Patient');
      var updatedEq = state.equipment.firstWhere((e) => e.id == eq.id);
      expect(updatedEq.availableCount, initialAvailable - 1);
      expect(updatedEq.loanedCount, initialLoaned + 1);

      state.returnEquipmentFromPatient(eq.id, 1);
      updatedEq = state.equipment.firstWhere((e) => e.id == eq.id);
      expect(updatedEq.availableCount, initialAvailable);
      expect(updatedEq.loanedCount, initialLoaned);
    });

    test('Role-Based Access Control (RBAC) Permissions', () {
      expect(UserRole.patient.isPatientOrFamily, isTrue);
      expect(UserRole.patient.canAccessClinicalRecords, isFalse);
      expect(UserRole.patient.canConfigureBackend, isFalse);
      expect(UserRole.patient.canSwitchRolesInSettings, isFalse);

      expect(UserRole.nurse.isClinicalStaff, isTrue);
      expect(UserRole.nurse.canAccessClinicalRecords, isTrue);
      expect(UserRole.nurse.canConfigureBackend, isFalse);

      expect(UserRole.orgAdmin.isAdmin, isTrue);
      expect(UserRole.orgAdmin.canConfigureBackend, isTrue);
      expect(UserRole.orgAdmin.canSwitchRolesInSettings, isTrue);
      expect(UserRole.orgAdmin.canManageInventory, isTrue);

      expect(UserRole.doctor.isClinicalStaff, isTrue);
      expect(UserRole.doctor.canAccessClinicalRecords, isTrue);

      expect(UserRole.ambulanceDriver.isAmbulanceDriver, isTrue);
      expect(UserRole.ambulanceDriver.canDispatchAmbulance, isTrue);

      expect(UserRole.palliativeMember.isPalliativeMember, isTrue);
      expect(UserRole.palliativeMember.canAccessClinicalRecords, isFalse);

      // Universal Capabilities
      for (final role in UserRole.values) {
        expect(role.canReferPatients, isTrue);
        expect(role.canAccessBloodDirectory, isTrue);
      }
    });

    test('Community Patient Referral Flow', () {
      final initialCount = state.patients.length;
      final refPatient = PatientModel(
        id: 'PAT-REF-TEST',
        name: 'Govindan Kutty',
        age: 82,
        gender: 'Male',
        bloodGroup: 'A+',
        district: 'Kozhikode',
        ward: 'Ward 4',
        address: 'Kutty House, Chevayur',
        phone: '+91 94470 00112',
        categoryTier: 'Pending Clinical Triage',
        diagnosis: 'Bedridden elderly with chronic joint immobility',
        riskLevel: 'Moderate Risk',
        aiSummary: 'Referred by neighbor.',
        emergencyContactName: 'Daughter',
        emergencyContactPhone: '+91 94470 00113',
        vitalsHistory: [],
        equipmentIssued: [],
        familyMembers: [],
        medicalHistory: [],
        registeredDate: '2026-08-07',
        referredBy: 'Deepak M. (Palliative Member)',
        referralUrgency: 'Urgent',
      );

      state.referPatientInNeed(
        refPatient,
        referrerName: 'Deepak M.',
        referrerRole: 'Palliative Member',
        urgency: 'Urgent',
      );

      expect(state.patients.length, initialCount + 1);
      final added = state.patients.firstWhere((p) => p.id == 'PAT-REF-TEST');
      expect(added.referredBy, 'Deepak M. (Palliative Member)');
      expect(added.referralUrgency, 'Urgent');
      expect(state.notifications.first, contains('Community Referral'));
    });

    test('Palliative Fund Donations & Balance Calculation', () {
      final initialCount = state.donations.length;
      final initialTotal = state.totalDonationsFund;

      final donation = DonationModel(
        id: 'DON-TEST-1',
        donorName: 'Test Supporter',
        amount: 2500.0,
        category: 'General Palliative Fund',
        paymentMode: 'UPI',
        receiptNumber: 'REC-TEST-99',
        date: '2026-08-07',
      );

      state.addDonation(donation);

      expect(state.donations.length, initialCount + 1);
      expect(state.totalDonationsFund, initialTotal + 2500.0);
      expect(state.notifications.first, contains('Received donation'));
    });

    test('Medical Treatment Crowdfunding Flow & Automated Gratitude Dispatch', () {
      final fundraiser = state.fundraisers.first;
      final initialRaised = fundraiser.collectedAmount;
      final initialDonors = fundraiser.donorsCount;

      final donation = state.donateToMedicalFundraiser(
        fundraiser.id,
        5000.0,
        'Deepak M. (Palliative Member)',
        donorPrayer: 'Prayers for successful surgery and quick recovery! ❤️',
        isAnonymous: false,
      );

      expect(fundraiser.collectedAmount, initialRaised + 5000.0);
      expect(fundraiser.donorsCount, initialDonors + 1);
      expect(donation.donorName, 'Deepak M. (Palliative Member)');
      expect(donation.amount, 5000.0);
      expect(donation.donorPrayer, contains('successful surgery'));
      expect(state.notifications.first, contains('Treatment Fund'));
    });

    test('Persistent JWT Login, Auto-Session Restore and Logout Flow', () async {
      final testDoctor = UserModel(
        id: 'DOC-PERSIST-99',
        name: 'Dr. Hariharan MD',
        email: 'hariharan@carelink.kerala.gov.in',
        phone: '+91 94470 55555',
        role: UserRole.doctor,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      );

      // 1. Log in user with JWT token
      await state.loginAsUser(testDoctor, token: 'jwt_mock_access_token_12345');
      expect(state.isLoggedIn, isTrue);
      expect(state.currentUser.id, 'DOC-PERSIST-99');
      expect(state.currentUser.name, 'Dr. Hariharan MD');
      expect(state.jwtToken, 'jwt_mock_access_token_12345');

      // 2. Simulate new app launch & restore session
      final newState = AppStateProvider();
      await newState.restoreSavedSession();
      expect(newState.isLoggedIn, isTrue);
      expect(newState.currentUser.id, 'DOC-PERSIST-99');
      expect(newState.currentUser.name, 'Dr. Hariharan MD');
      expect(newState.jwtToken, 'jwt_mock_access_token_12345');

      // 3. Explicit Logout clears the session
      await newState.logout();
      expect(newState.isLoggedIn, isFalse);
      expect(newState.jwtToken, isNull);

      // 4. Subsequent launch after logout remains logged out
      final afterLogoutState = AppStateProvider();
      await afterLogoutState.restoreSavedSession();
      expect(afterLogoutState.isLoggedIn, isFalse);
    });
  });
}

