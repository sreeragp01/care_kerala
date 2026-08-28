import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_kerala/core/models/patient_model.dart';
import 'package:carelink_kerala/core/models/alert_model.dart';
import 'package:carelink_kerala/core/models/clinical_models.dart';



void main() {
  group('Clinical Models Unit Tests', () {
    test('PatientModel serialization and defaults', () {
      final patient = PatientModel(
        id: 'PAT-101',
        name: 'Karthyayani Amma',
        age: 74,
        gender: 'Female',
        bloodGroup: 'O+',
        district: 'Kozhikode',
        ward: 'Ward 14',
        address: 'Chevayur',
        phone: '9847012345',
        lifecycleStatus: 'Active Care',
        categoryTier: 'Category A (Bedridden)',
        diagnosis: 'Osteoarthritis',
        riskLevel: 'Moderate Risk',
        aiSummary: 'Stable',
        emergencyContactName: 'Ramesh',
        emergencyContactPhone: '9847054321',
        vitalsHistory: [],
        equipmentIssued: [],
        familyMembers: [],
        medicalHistory: ['Osteoarthritis'],
        registeredDate: '2026-08-01',
      );

      final json = patient.toJson();
      expect(json['id'], 'PAT-101');


      expect(json['name'], 'Karthyayani Amma');
      expect(json['lifecycle_status'], 'Active Care');
    });

    test('ClinicalAlertModel severity and status parsing', () {
      final alert = ClinicalAlertModel.fromJson({
        'id': 99,
        'patient_name': 'Karthyayani Amma',
        'alert_type': 'VITAL_ABNORMAL',
        'severity': 'CRITICAL',
        'title': 'CRITICAL: Low Oxygen Saturation',
        'message': 'SpO2 88%',
        'status': 'OPEN',
        'created_at': '2026-08-25T10:00:00Z',
      });

      expect(alert.id, '99');
      expect(alert.severity, 'CRITICAL');
      expect(alert.status, 'OPEN');
    });

    test('MedicalFundraiserModel calculations and gratitude template', () {
      final fundraiser = MedicalFundraiserModel(
        id: 'CROWD-TEST-1',
        patientId: 'PAT-T1',
        patientName: 'Test Patient',
        patientAge: 40,
        patientGender: 'Male',
        bloodGroup: 'B+',
        district: 'Kozhikode',
        ward: 'Ward 5',
        hospitalName: 'Govt Medical College',
        doctorName: 'Dr. Suresh Kumar MD',
        treatmentTitle: 'Urgent Renal Transplant',
        category: 'Transplant',
        targetAmount: 1000000.0,
        collectedAmount: 500000.0,
        donorsCount: 150,
        story: 'Urgent transplant appeal',
        medicalEstimateSummary: 'Estimate: 10 Lakhs',
        daysRemaining: 15,
        createdDate: '2026-08-01',
        patientFamilyGratitudeMessage: 'Thank you from the bottom of our hearts! ❤️',
      );

      expect(fundraiser.percentFunded, 0.5);
      expect(fundraiser.remainingAmount, 500000.0);
      expect(fundraiser.isDoctorVerified, true);
      expect(fundraiser.patientFamilyGratitudeMessage, contains('bottom of our hearts'));
    });
  });
}
