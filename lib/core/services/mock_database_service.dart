import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/clinical_models.dart';

class MockDatabaseService {
  static List<OrganizationModel> getOrganizations() {
    return [
      OrganizationModel(
        id: 'org_kozhikode',
        name: 'Kozhikode Palliative Care Society',
        district: 'Kozhikode',
        registrationNumber: 'KZD/NGO/2012/482',
        phone: '+91 495 272 1000',
        upiId: 'kozhikodepalliative@sbi',
        bankAccountName: 'Kozhikode Palliative Care Society Main A/C',
        bankAccountNumber: '389201948201',
        ifscCode: 'SBIN0001234',
        bankName: 'State Bank of India (Calicut Main Branch)',
        razorpayKeyId: 'rzp_test_CareLinkKozhikode',
        activePatientsCount: 142,
        totalVisitsCount: 1840,
      ),
      OrganizationModel(
        id: 'org_ernakulam',
        name: 'Ernakulam Care Trust',
        district: 'Ernakulam',
        registrationNumber: 'EKM/NGO/2015/921',
        phone: '+91 484 234 5678',
        upiId: 'ernakulamcare@hdfcbank',
        bankAccountName: 'Ernakulam Care Trust Primary Escrow',
        bankAccountNumber: '50100482910394',
        ifscCode: 'HDFC0000456',
        bankName: 'HDFC Bank (Edappally Branch)',
        razorpayKeyId: 'rzp_test_CareLinkErnakulam',
        activePatientsCount: 98,
        totalVisitsCount: 1210,
      ),
      OrganizationModel(
        id: 'org_wayanad',
        name: 'Wayanad Tribal Health Initiative',
        district: 'Wayanad',
        registrationNumber: 'WYD/NGO/2018/104',
        phone: '+91 493 620 4400',
        upiId: 'wayanadtribalcare@icici',
        bankAccountName: 'Wayanad Tribal Palliative Initiative Fund',
        bankAccountNumber: '002305001289',
        ifscCode: 'ICIC0000023',
        bankName: 'ICICI Bank (Kalpetta Branch)',
        razorpayKeyId: 'rzp_test_CareLinkWayanad',
        activePatientsCount: 65,
        totalVisitsCount: 790,
      ),
    ];
  }


  static List<PatientModel> getInitialPatients() {
    return [
      PatientModel(
        id: 'PAT-101',
        name: 'Karthyayani Amma',
        age: 74,
        gender: 'Female',
        bloodGroup: 'O+',
        district: 'Kozhikode',
        ward: 'Ward 14 - Chevayur',
        address: 'House No 42, Green Valley Lane, Chevayur, Kozhikode',
        phone: '+91 94471 23456',
        categoryTier: 'Category A (Bedridden)',
        diagnosis: 'Advanced Osteoarthritis & Palliative Care Support',
        riskLevel: 'High Risk',
        aiSummary: 'Patient requires bi-weekly pain management monitoring and wound dressing. Mobility restricted. Next BP check required.',
        emergencyContactName: 'Ramesh (Son)',
        emergencyContactPhone: '+91 98470 11223',
        vitalsHistory: [
          VitalsReading(date: '2026-08-05', bp: '130/85', pulse: 76, spo2: 97, painScale: 4, recordedBy: 'Nurse Anitha'),
          VitalsReading(date: '2026-08-01', bp: '138/90', pulse: 82, spo2: 95, painScale: 6, recordedBy: 'Nurse Anitha'),
        ],
        equipmentIssued: [
          EquipmentIssued(equipmentName: 'Air Mattress', issuedDate: '2026-06-10', serialNumber: 'EQ-AM-402', status: 'Active'),
          EquipmentIssued(equipmentName: 'Wheelchair', issuedDate: '2026-07-01', serialNumber: 'EQ-WC-118', status: 'Active'),
        ],
        familyMembers: [
          FamilyMemberContact(name: 'Ramesh Kumar', relation: 'Son', phone: '+91 98470 11223'),
          FamilyMemberContact(name: 'Suma Ramesh', relation: 'Daughter-in-law', phone: '+91 98470 44556'),
        ],
        medicalHistory: [
          'Diagnosed with Osteoarthritis in 2021',
          'Hypertension under medication since 2019',
          'Allergic to Sulfa drugs',
        ],
        registeredDate: '2024-03-15',
      ),
      PatientModel(
        id: 'PAT-102',
        name: 'Vaidyanathan Nair',
        age: 68,
        gender: 'Male',
        bloodGroup: 'B+',
        district: 'Kozhikode',
        ward: 'Ward 08 - Medical College',
        address: 'Souparnika, Near Primary Health Centre, Medical College PO',
        phone: '+91 94462 88990',
        categoryTier: 'Category B (Semi-mobile)',
        diagnosis: 'Post-Stroke Rehabilitation & Hypertension',
        riskLevel: 'Moderate Risk',
        aiSummary: 'Right-side weakness recovering. Regular physiotherapy recommended. Vitals stable.',
        emergencyContactName: 'Meenakshi (Wife)',
        emergencyContactPhone: '+91 94462 88991',
        vitalsHistory: [
          VitalsReading(date: '2026-08-04', bp: '124/80', pulse: 72, spo2: 98, painScale: 2, recordedBy: 'Nurse Anitha'),
        ],
        equipmentIssued: [
          EquipmentIssued(equipmentName: 'Walker Frame', issuedDate: '2026-05-12', serialNumber: 'EQ-WF-091', status: 'Active'),
        ],
        familyMembers: [
          FamilyMemberContact(name: 'Meenakshi Nair', relation: 'Wife', phone: '+91 94462 88991'),
        ],
        medicalHistory: [
          'Ischemic stroke in January 2025',
          'Type 2 Diabetes Mellitus',
        ],
        registeredDate: '2025-01-20',
      ),
      PatientModel(
        id: 'PAT-103',
        name: 'Fathima Beevi',
        age: 81,
        gender: 'Female',
        bloodGroup: 'AB+',
        district: 'Ernakulam',
        ward: 'Ward 03 - Edappally',
        address: 'Mukkath House, Near Changampuzha Park, Edappally',
        phone: '+91 98461 55443',
        categoryTier: 'Category A (Bedridden)',
        diagnosis: 'Stage 4 Lung Carcinoma (Palliative Support)',
        riskLevel: 'High Risk',
        aiSummary: 'On palliative pain protocol. Requires continuous oxygen concentrator monitoring.',
        emergencyContactName: 'Siddique (Son)',
        emergencyContactPhone: '+91 98461 99887',
        vitalsHistory: [
          VitalsReading(date: '2026-08-06', bp: '110/70', pulse: 88, spo2: 94, painScale: 7, recordedBy: 'Nurse Sini'),
        ],
        equipmentIssued: [
          EquipmentIssued(equipmentName: 'Oxygen Concentrator 5L', issuedDate: '2026-04-01', serialNumber: 'EQ-OC-501', status: 'Active'),
          EquipmentIssued(equipmentName: 'Suction Machine', issuedDate: '2026-04-05', serialNumber: 'EQ-SM-204', status: 'Active'),
        ],
        familyMembers: [
          FamilyMemberContact(name: 'Siddique Mukkath', relation: 'Son', phone: '+91 98461 99887'),
        ],
        medicalHistory: [
          'Diagnosed late 2024',
          'Morphine oral solution prescribed',
        ],
        registeredDate: '2025-02-10',
      ),
      PatientModel(
        id: 'PAT-REF-104',
        name: 'Sreedharan Pillai',
        age: 79,
        gender: 'Male',
        bloodGroup: 'O+',
        district: 'Kozhikode',
        ward: 'Ward 12 - Mavoor Road',
        address: 'Pillai House, Near Mavoor Junction, Kozhikode',
        phone: '+91 94470 33445',
        categoryTier: 'Pending Clinical Triage',
        diagnosis: 'Severe Chronic Arthritis & Hip Fracture (Bedridden at home)',
        riskLevel: 'Triage Required',
        aiSummary: 'Community nomination reported by Deepak M. (Blood Donor). Patient bedridden with high pain score and living alone. Urgent home visit triage recommended.',
        emergencyContactName: 'Biju (Neighbor)',
        emergencyContactPhone: '+91 94470 33446',
        vitalsHistory: [],
        equipmentIssued: [],
        familyMembers: [],
        medicalHistory: ['Reported through CareLink Community Patient Referral Portal.'],
        registeredDate: '2026-08-07',
        referredBy: 'Deepak M. (Blood Donor)',
        referralUrgency: 'Urgent',
      ),
    ];
  }

  static List<VisitModel> getInitialVisits() {
    return [
      VisitModel(
        id: 'VIS-201',
        patientId: 'PAT-101',
        patientName: 'Karthyayani Amma',
        patientAddress: 'Chevayur, Kozhikode',
        assignedNurseName: 'Nurse Anitha',
        scheduledDate: '2026-08-07',
        scheduledTime: '10:00 AM',
        status: 'Scheduled',
      ),
      VisitModel(
        id: 'VIS-202',
        patientId: 'PAT-102',
        patientName: 'Vaidyanathan Nair',
        patientAddress: 'Medical College, Kozhikode',
        assignedNurseName: 'Nurse Anitha',
        scheduledDate: '2026-08-07',
        scheduledTime: '11:30 AM',
        status: 'Scheduled',
      ),
      VisitModel(
        id: 'VIS-203',
        patientId: 'PAT-103',
        patientName: 'Fathima Beevi',
        patientAddress: 'Edappally, Ernakulam',
        assignedNurseName: 'Nurse Sini',
        scheduledDate: '2026-08-06',
        scheduledTime: '02:00 PM',
        status: 'Completed',
        gpsCheckInTime: '02:05 PM',
        gpsLocationName: 'Edappally, Ernakulam (10.0261° N, 76.3125° E)',
        recordedVitals: VitalsReading(date: '2026-08-06', bp: '110/70', pulse: 88, spo2: 94, painScale: 7, recordedBy: 'Nurse Sini'),
        clinicalNotes: 'Administered oral pain medication as directed. Oxygen concentrator flow rate verified at 2L/min.',
      ),
    ];
  }

  static List<BloodDonorModel> getInitialBloodDonors() {
    return [
      BloodDonorModel(
        id: 'DON-301',
        name: 'Arjun Das',
        bloodGroup: 'O+',
        district: 'Kozhikode',
        locality: 'Chevayur',
        phone: '+91 97451 11223',
        lastDonationDate: DateTime.now().subtract(const Duration(days: 110)),
        totalDonations: 8,
        isAvailable: true,
      ),
      BloodDonorModel(
        id: 'DON-302',
        name: 'Dr. Priya Varma',
        bloodGroup: 'B+',
        district: 'Kozhikode',
        locality: 'Calicut City',
        phone: '+91 98472 33445',
        lastDonationDate: DateTime.now().subtract(const Duration(days: 45)),
        totalDonations: 12,
        isAvailable: true,
      ),
      BloodDonorModel(
        id: 'DON-303',
        name: 'Muhammed Nishad',
        bloodGroup: 'O-',
        district: 'Ernakulam',
        locality: 'Kaloor',
        phone: '+91 99460 77889',
        lastDonationDate: DateTime.now().subtract(const Duration(days: 130)),
        totalDonations: 5,
        isAvailable: true,
      ),
      BloodDonorModel(
        id: 'DON-304',
        name: 'Sneha Mohan',
        bloodGroup: 'AB+',
        district: 'Kozhikode',
        locality: 'Mavoor',
        phone: '+91 94473 99001',
        lastDonationDate: DateTime.now().subtract(const Duration(days: 100)),
        totalDonations: 4,
        isAvailable: true,
      ),
    ];
  }

  static List<BloodRequestModel> getInitialBloodRequests() {
    return [
      BloodRequestModel(
        id: 'REQ-401',
        patientName: 'Karthyayani Amma',
        bloodGroup: 'O+',
        hospitalName: 'Calicut Medical College Hospital',
        district: 'Kozhikode',
        unitsNeeded: 2,
        urgency: 'Emergency',
        requestedDate: '2026-08-06',
      ),
    ];
  }

  static List<MedicineItemModel> getInitialMedicines() {
    return [
      MedicineItemModel(id: 'MED-01', name: 'Morphine Oral Sol. 10mg/5ml', category: 'Analgesics', stockQuantity: 45, unit: 'bottles', reorderLevel: 20, expiryDate: '2027-04-30', batchNumber: 'BAT-MRP-901'),
      MedicineItemModel(id: 'MED-02', name: 'Paracetamol 500mg', category: 'Analgesics', stockQuantity: 350, unit: 'tablets', reorderLevel: 100, expiryDate: '2028-01-15', batchNumber: 'BAT-PCM-332'),
      MedicineItemModel(id: 'MED-03', name: 'Amlodipine 5mg', category: 'Antihypertensives', stockQuantity: 12, unit: 'strips', reorderLevel: 25, expiryDate: '2026-11-20', batchNumber: 'BAT-AML-110'),
      MedicineItemModel(id: 'MED-04', name: 'Metformin 500mg', category: 'Antidiabetics', stockQuantity: 180, unit: 'tablets', reorderLevel: 50, expiryDate: '2027-09-10', batchNumber: 'BAT-MET-774'),
    ];
  }

  static List<EquipmentItemModel> getInitialEquipment() {
    return [
      EquipmentItemModel(id: 'EQ-01', name: 'Oxygen Concentrator (5L)', totalCount: 15, availableCount: 3, loanedCount: 12, maintenanceStatus: 'Good'),
      EquipmentItemModel(id: 'EQ-02', name: 'Hospital Bed (Manual 2-Cut)', totalCount: 20, availableCount: 4, loanedCount: 16, maintenanceStatus: 'Good'),
      EquipmentItemModel(id: 'EQ-03', name: 'Air Mattress with Pump', totalCount: 30, availableCount: 8, loanedCount: 22, maintenanceStatus: 'Good'),
      EquipmentItemModel(id: 'EQ-04', name: 'Wheelchair (Folding)', totalCount: 25, availableCount: 6, loanedCount: 19, maintenanceStatus: 'Servicing Required'),
    ];
  }

  static List<AmbulanceDriverModel> getInitialAmbulanceDrivers() {
    return [
      AmbulanceDriverModel(id: 'AMB-01', driverName: 'Sujith Kumar', vehicleNumber: 'KL-11-BV-4091', phone: '+91 94470 12345', district: 'Kozhikode', currentStatus: 'Available'),
      AmbulanceDriverModel(id: 'AMB-02', driverName: 'Rahim K.', vehicleNumber: 'KL-07-CD-8820', phone: '+91 98460 54321', district: 'Ernakulam', currentStatus: 'Available'),
    ];
  }

  static List<CommunityCampaignModel> getInitialCampaigns() {
    return [
      CommunityCampaignModel(
        id: 'CAMP-01',
        title: 'Pain Relief & Chemotherapy Comfort for Karthyayani Amma',
        subtitle: 'Supporting bedridden elder with daily morphine, wound dressings & home nurse visits',
        description: 'Karthyayani Amma (72y, Chevayur) is battling advanced cancer. Her family requires regular home care medical consumables, catheter supplies, and pain medications.',
        beneficiaryName: 'Karthyayani Amma & Ramesh (Son)',
        beneficiaryRelation: 'Mother & Caregiver Son',
        locality: 'Chevayur, Ward 14',
        district: 'Kozhikode',
        category: 'Patient Support',
        urgency: 'High Priority',
        supportersCount: 28,
        patientFamilyGratitudeTemplate:
            'With folded hands and tearful gratitude from Karthyayani Amma and our family in Chevayur. Your compassion provides our mother with pain-free nights and necessary medicines. May God bless you and your family abundantly! ❤️',
      ),
      CommunityCampaignModel(
        id: 'CAMP-02',
        title: 'Free Community Oxygen & Water Bed Depots',
        subtitle: 'Maintaining 20+ portable oxygen concentrators and air mattresses for bedridden elders across Kozhikode',
        description: 'Our palliative equipment pool provides zero-cost loans of medical oxygen concentrators, hospital beds, and ripple mattresses to low-income families.',
        beneficiaryName: 'Community Palliative Equipment Depot',
        beneficiaryRelation: 'Community Equipment Pool',
        locality: 'Medical College Ward',
        district: 'Kozhikode',
        category: 'Equipment Aid',
        urgency: 'Ongoing Support',
        supportersCount: 45,
        patientFamilyGratitudeTemplate:
            'Heartfelt gratitude from the Palliative Care Team and all beneficiary families. Your support keeps vital oxygen flowing for elders in need across our district! 🙏',
      ),
      CommunityCampaignModel(
        id: 'CAMP-03',
        title: 'Monthly Free Morphine & Wound Care Medicine Fund',
        subtitle: 'Procuring essential analgesics and sterile dressing kits for 150+ home-care patients',
        description: 'Ensures no palliative patient in our panchayat is left in severe physical distress due to inability to afford daily pain medications.',
        beneficiaryName: 'Malabar Palliative Care Society',
        beneficiaryRelation: 'Community Society Care Unit',
        locality: 'District Palliative Center',
        district: 'Kozhikode',
        category: 'Medicine Pool',
        urgency: 'Ongoing Support',
        supportersCount: 62,
        patientFamilyGratitudeTemplate:
            'Thank you for standing by the suffering and vulnerable. Your generous contribution brings dignity, comfort, and healing to our patients every day. ❤️',
      ),
    ];
  }

  static List<DonationModel> getInitialDonations() {
    return [
      DonationModel(
        id: 'DON-901',
        donorName: 'Malabar Palliative Supporters',
        amount: 50000.0,
        category: 'General Palliative Fund',
        paymentMode: 'Razorpay',
        receiptNumber: 'REC-2026-0811',
        date: '2026-08-01',
        transactionId: 'pay_rzp_984102',
        razorpayPaymentId: 'pay_rzp_984102',
        isVerified: true,
      ),
      DonationModel(
        id: 'DON-902',
        donorName: 'Dr. K. S. Menon',
        amount: 25000.0,
        category: 'Equipment Fund',
        paymentMode: 'UPI_QR',
        receiptNumber: 'REC-2026-0812',
        date: '2026-08-03',
        transactionId: 'UPI-REF-889104',
        isVerified: true,
      ),
      DonationModel(
        id: 'DON-903',
        donorName: 'Anil Kumar V.',
        amount: 5000.0,
        category: 'Medicine Support',
        paymentMode: 'Razorpay',
        receiptNumber: 'REC-2026-0813',
        date: '2026-08-05',
        transactionId: 'pay_rzp_774129',
        razorpayPaymentId: 'pay_rzp_774129',
        isVerified: true,
      ),
    ];
  }


  static List<UserModel> getDemoUsers() {
    return [
      UserModel(
        id: 'USR-PAT-01',
        name: 'Karthyayani Amma',
        email: 'patient@carelink.kerala.gov.in',
        phone: '+91 94471 23456',
        role: UserRole.patient,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
      UserModel(
        id: 'USR-FAM-01',
        name: 'Ramesh Kumar (Son & Caregiver)',
        email: 'caregiver@carelink.kerala.gov.in',
        phone: '+91 98470 11223',
        role: UserRole.familyMember,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
      UserModel(
        id: 'USR-NUR-01',
        name: 'Sr. Anitha Kumari',
        email: 'anitha@carelink.kerala.gov.in',
        phone: '+91 98470 12345',
        role: UserRole.nurse,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
      UserModel(
        id: 'USR-DOC-01',
        name: 'Dr. Suresh Kumar MD',
        email: 'suresh@carelink.kerala.gov.in',
        phone: '+91 94470 88990',
        role: UserRole.doctor,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
      UserModel(
        id: 'USR-VOL-01',
        name: 'Arjun Das (ASHA / Volunteer)',
        email: 'arjun@carelink.kerala.gov.in',
        phone: '+91 97440 11223',
        role: UserRole.volunteer,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
      UserModel(
        id: 'USR-AMB-01',
        name: 'Sujith Kumar (Ambulance Driver)',
        email: 'sujith@carelink.kerala.gov.in',
        phone: '+91 94470 12345',
        role: UserRole.ambulanceDriver,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
      UserModel(
        id: 'USR-PHARM-01',
        name: 'Manoj Kumar (Pharmacist)',
        email: 'pharmacy@carelink.kerala.gov.in',
        phone: '+91 98460 77112',
        role: UserRole.pharmacist,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
      UserModel(
        id: 'USR-ADM-01',
        name: 'Dr. K. S. Menon (District Admin)',
        email: 'admin@carelink.kerala.gov.in',
        phone: '+91 94470 55667',
        role: UserRole.orgAdmin,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
      UserModel(
        id: 'USR-SADM-01',
        name: 'Super Admin',
        email: 'psreerag304@gmail.com',
        phone: '+91 94470 00001',
        role: UserRole.superAdmin,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
      UserModel(
        id: 'USR-REC-01',
        name: 'Kavya Nair (Hospital Reception Desk)',
        email: 'reception@carelink.kerala.gov.in',
        phone: '+91 98472 88119',
        role: UserRole.reception,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
      UserModel(
        id: 'USR-ACC-01',
        name: 'Shalini K. (Hospital Accountant)',
        email: 'accounts@carelink.kerala.gov.in',
        phone: '+91 98473 44556',
        role: UserRole.accountant,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
      UserModel(
        id: 'USR-ADM-EKM',
        name: 'Dr. Radhakrishnan (Ernakulam Admin)',
        email: 'admin.ekm@carelink.kerala.gov.in',
        phone: '+91 98460 22334',
        role: UserRole.orgAdmin,
        organizationId: 'org_ernakulam',
        district: 'Ernakulam',
      ),
      UserModel(
        id: 'USR-ADM-WYD',
        name: 'Dr. Vineeth Mathew (Wayanad Admin)',
        email: 'admin.wyd@carelink.kerala.gov.in',
        phone: '+91 98475 99001',
        role: UserRole.orgAdmin,
        organizationId: 'org_wayanad',
        district: 'Wayanad',
      ),
      UserModel(
        id: 'USR-PAT-02',
        name: 'Muhammed Basheer',
        email: 'basheer@carelink.kerala.gov.in',
        phone: '+91 98472 33445',
        role: UserRole.patient,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
      UserModel(
        id: 'USR-MEM-01',
        name: 'Deepak M. (Palliative Member & O+ Donor)',
        email: 'member@carelink.kerala.gov.in',
        phone: '+91 98471 22334',
        role: UserRole.palliativeMember,
        organizationId: 'org_kozhikode',
        district: 'Kozhikode',
      ),
    ];
  }

  static List<MedicalFundraiserModel> getInitialMedicalFundraisers() {
    return [
      MedicalFundraiserModel(
        id: 'CROWD-101',
        patientId: 'PAT-ADITHYAN-01',
        patientName: 'Master Adithyan',
        patientAge: 8,
        patientGender: 'Male',
        bloodGroup: 'O+',
        district: 'Kozhikode',
        ward: 'Ward 08 - Chevayur',
        hospitalName: 'Govt. Medical College Hospital, Calicut',
        doctorName: 'Dr. Suresh Kumar MD (Pediatric Cardiac Unit)',
        treatmentTitle: 'Complex Pediatric Open-Heart Surgery & Valve Reconstruction',
        category: 'Pediatric Cardiac',
        targetAmount: 1200000.0,
        collectedAmount: 780000.0,
        donorsCount: 412,
        story:
            '8-year-old Adithyan from Kozhikode was diagnosed with critical congenital heart valve anomaly requiring urgent surgical reconstruction. His father, a daily-wage laborer, has exhausted all family savings for pre-surgical ICU care. The hospital medical board has scheduled surgery for this month.',
        medicalEstimateSummary: 'Govt. Medical College Estimate: ₹12,00,000 (Surgery, Valve Prosthesis & 14-day Post-Op PICU)',
        isDoctorVerified: true,
        daysRemaining: 14,
        createdDate: '2026-07-25',
        status: 'Active',
        cooperatingOrgId: 'org_kozhikode',
        cooperatingOrgName: 'Kozhikode Palliative Care Society',
        useOrgQr: true,
        patientFamilyGratitudeMessage:
            'Dear Well-Wisher, with tears of gratitude from Adithyan’s parents and family in Chevayur. Your compassion gives our little 8-year-old boy a second chance at life and a healthy heart. May God bless you and your loved ones with lifelong health and happiness! ❤️',
      ),
      MedicalFundraiserModel(
        id: 'CROWD-102',
        patientId: 'PAT-103',
        patientName: 'Fathima Beevi',
        patientAge: 81,
        patientGender: 'Female',
        bloodGroup: 'AB+',
        district: 'Ernakulam',
        ward: 'Ward 03 - Edappally',
        hospitalName: 'Ernakulam General Hospital & Palliative Oncology Wing',
        doctorName: 'Dr. Priya Varma MD (Medical Oncology)',
        treatmentTitle: 'Advanced Oncology Immunotherapy & Continuous Oxygen Care',
        category: 'Oncology',
        targetAmount: 500000.0,
        collectedAmount: 320000.0,
        donorsCount: 185,
        story:
            'Fathima Beevi (81y) is battling Stage 4 Lung Carcinoma and requires non-invasive bi-level positive airway pressure support, targeted palliative pain therapy, and round-the-clock nursing care consumables at home.',
        medicalEstimateSummary: 'Hospital Estimate: ₹5,00,000 (Targeted Pain Protocols, Oxygen Support & Home Nursing consumables)',
        isDoctorVerified: true,
        daysRemaining: 21,
        createdDate: '2026-08-01',
        status: 'Active',
        cooperatingOrgId: 'org_ernakulam',
        cooperatingOrgName: 'Ernakulam Care Trust',
        useOrgQr: true,
        patientFamilyGratitudeMessage:
            'Dear Kind Supporter, with folded hands from Fathima Beevi and our entire family in Edappally. Your kind contribution ensures mother receives dignified pain relief and necessary medical support. We keep you in our daily prayers! 🙏',
      ),
      MedicalFundraiserModel(
        id: 'CROWD-103',
        patientId: 'PAT-REF-104',
        patientName: 'Sreedharan Pillai',
        patientAge: 79,
        patientGender: 'Male',
        bloodGroup: 'O+',
        district: 'Kozhikode',
        ward: 'Ward 12 - Mavoor Road',
        hospitalName: 'Beach General Hospital, Kozhikode',
        doctorName: 'Dr. Ramesh Chandran (Orthopedic Surgery)',
        treatmentTitle: 'Emergency Hip Hemiarthroplasty & Post-Fracture Mobility Rehabilitation',
        category: 'Orthopedic Surgery',
        targetAmount: 350000.0,
        collectedAmount: 195000.0,
        donorsCount: 94,
        story:
            'Sreedharan Pillai (79y, living alone) suffered a severe comminuted femoral neck fracture after a domestic fall. He is currently completely bedridden in high distress. Urgent surgery is required to restore basic mobility and prevent fatal bedsores.',
        medicalEstimateSummary: 'Orthopedic Board Estimate: ₹3,50,000 (Titanium Bipolar Prosthesis, Surgery & Physiotherapy)',
        isDoctorVerified: true,
        daysRemaining: 9,
        createdDate: '2026-08-03',
        status: 'Active',
        cooperatingOrgId: 'org_kozhikode',
        cooperatingOrgName: 'Kozhikode Palliative Care Society',
        useOrgQr: false,
        customUpiId: 'sreedharan.care.fund@sbi',
        patientFamilyGratitudeMessage:
            'With deep respect and folded hands from Sreedharan Pillai and our community care unit. Your support is helping an elderly father stand back on his feet and escape a lifetime of bedridden pain. Thank you so much! ❤️',
      ),
    ];
  }
}

