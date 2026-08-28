import os
import django
from datetime import date, timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.patients.models import Patient, VitalsReading, EquipmentIssued, FamilyMemberContact
from apps.visits.models import HomeVisit
from apps.blood_donors.models import BloodDonor, BloodRequest
from apps.inventory.models import MedicineItem, EquipmentItem
from apps.finance.models import Donation, MedicalFundraiser

def seed():
    print("Seeding CareLink Kerala Django database...")

    # 1. Organizations
    org1, _ = Organization.objects.get_or_create(
        registration_number='KZD/NGO/2012/482',
        defaults={
            'name': 'Kozhikode Palliative Care Society',
            'district': 'Kozhikode',
            'phone': '+91 495 272 1000',
            'upi_id': 'kozhikodepalliative@sbi',
            'bank_account_name': 'Kozhikode Palliative Care Society Main A/C',
            'bank_account_number': '389201948201',
            'ifsc_code': 'SBIN0001234',
            'bank_name': 'State Bank of India (Calicut Main Branch)',
            'razorpay_account_id': 'acc_kzd_palliative_01',
            'active_patients_count': 142,
            'total_visits_count': 1840,
        }
    )

    org2, _ = Organization.objects.get_or_create(
        registration_number='EKM/NGO/2015/921',
        defaults={
            'name': 'Ernakulam Care Trust',
            'district': 'Ernakulam',
            'phone': '+91 484 234 5678',
            'upi_id': 'ernakulamcare@hdfcbank',
            'bank_account_name': 'Ernakulam Care Trust Primary Escrow',
            'bank_account_number': '50100482910394',
            'ifsc_code': 'HDFC0000456',
            'bank_name': 'HDFC Bank (Edappally Branch)',
            'razorpay_account_id': 'acc_ekm_care_02',
            'active_patients_count': 98,
            'total_visits_count': 1210,
        }
    )


    # 2. Users
    if not User.objects.filter(username='admin').exists():
        User.objects.create_superuser('admin', 'admin@carelink.kerala.gov.in', 'admin123', role=UserRole.SUPER_ADMIN, organization=org1, district='Kozhikode')

    nurse, _ = User.objects.get_or_create(
        username='anitha',
        defaults={
            'email': 'anitha@carelink.kerala.gov.in',
            'first_name': 'Anitha',
            'last_name': 'Kumar',
            'role': UserRole.NURSE,
            'organization': org1,
            'district': 'Kozhikode',
            'phone': '+91 98470 12345',
        }
    )
    nurse.set_password('pass1234')
    nurse.save()

    doctor, _ = User.objects.get_or_create(
        username='suresh',
        defaults={
            'email': 'suresh@carelink.kerala.gov.in',
            'first_name': 'Dr. Suresh',
            'last_name': 'Kumar',
            'role': UserRole.DOCTOR,
            'organization': org1,
            'district': 'Kozhikode',
            'phone': '+91 94470 99887',
        }
    )
    doctor.set_password('pass1234')
    doctor.save()

    # 3. Patients
    p1, _ = Patient.objects.get_or_create(
        patient_id_code='PAT-101',
        defaults={
            'organization': org1,
            'name': 'Karthyayani Amma',
            'age': 74,
            'gender': 'Female',
            'blood_group': 'O+',
            'district': 'Kozhikode',
            'ward': 'Ward 14 - Chevayur',
            'address': 'House No 42, Green Valley Lane, Chevayur, Kozhikode',
            'phone': '+91 94471 23456',
            'category_tier': 'Category A (Bedridden)',
            'diagnosis': 'Advanced Osteoarthritis & Palliative Care Support',
            'risk_level': 'High Risk',
            'ai_summary': 'Requires bi-weekly pain management and wound dressing. Next BP check required.',
            'emergency_contact_name': 'Ramesh (Son)',
            'emergency_contact_phone': '+91 98470 11223',
        }
    )

    p2, _ = Patient.objects.get_or_create(
        patient_id_code='PAT-102',
        defaults={
            'organization': org1,
            'name': 'Vaidyanathan Nair',
            'age': 68,
            'gender': 'Male',
            'blood_group': 'B+',
            'district': 'Kozhikode',
            'ward': 'Ward 08 - Medical College',
            'address': 'Souparnika, Near Primary Health Centre, Medical College PO',
            'phone': '+91 94462 88990',
            'category_tier': 'Category B (Semi-mobile)',
            'diagnosis': 'Post-Stroke Rehabilitation & Hypertension',
            'risk_level': 'Moderate Risk',
            'ai_summary': 'Right-side weakness recovering. Regular physiotherapy recommended.',
            'emergency_contact_name': 'Meenakshi (Wife)',
            'emergency_contact_phone': '+91 94462 88991',
        }
    )

    VitalsReading.objects.get_or_create(patient=p1, recorded_date='2026-08-05', defaults={'bp': '130/85', 'pulse': 76, 'spo2': 97, 'pain_scale': 4, 'recorded_by': 'Nurse Anitha'})
    EquipmentIssued.objects.get_or_create(patient=p1, serial_number='EQ-AM-402', defaults={'equipment_name': 'Air Mattress', 'issued_date': '2026-06-10', 'status': 'Active'})
    FamilyMemberContact.objects.get_or_create(patient=p1, name='Ramesh Kumar', defaults={'relation': 'Son', 'phone': '+91 98470 11223'})

    # 4. Home Visits
    HomeVisit.objects.get_or_create(
        patient=p1,
        scheduled_date='2026-08-07',
        defaults={
            'organization': org1,
            'assigned_nurse_name': 'Nurse Anitha',
            'scheduled_time': '10:00 AM',
            'status': 'Scheduled',
        }
    )

    # 5. Blood Donors
    BloodDonor.objects.get_or_create(
        name='Arjun Das',
        defaults={
            'organization': org1,
            'blood_group': 'O+',
            'district': 'Kozhikode',
            'locality': 'Chevayur',
            'phone': '+91 97451 11223',
            'last_donation_date': date.today() - timedelta(days=110),
            'total_donations': 8,
            'is_available': True,
        }
    )

    BloodDonor.objects.get_or_create(
        name='Dr. Priya Varma',
        defaults={
            'organization': org1,
            'blood_group': 'B+',
            'district': 'Kozhikode',
            'locality': 'Calicut City',
            'phone': '+91 98472 33445',
            'last_donation_date': date.today() - timedelta(days=45),
            'total_donations': 12,
            'is_available': True,
        }
    )

    BloodRequest.objects.get_or_create(
        patient_name='Karthyayani Amma',
        defaults={
            'organization': org1,
            'blood_group': 'O+',
            'hospital_name': 'Calicut Medical College Hospital',
            'district': 'Kozhikode',
            'units_needed': 2,
            'urgency': 'Emergency',
        }
    )

    # 6. Inventory
    MedicineItem.objects.get_or_create(
        batch_number='BAT-MRP-901',
        defaults={
            'organization': org1,
            'name': 'Morphine Oral Sol. 10mg/5ml',
            'category': 'Analgesics',
            'stock_quantity': 45,
            'unit': 'bottles',
            'reorder_level': 20,
            'expiry_date': '2027-04-30',
        }
    )

    EquipmentItem.objects.get_or_create(
        name='Oxygen Concentrator (5L)',
        defaults={
            'organization': org1,
            'total_count': 15,
            'available_count': 3,
            'loaned_count': 12,
            'maintenance_status': 'Good',
        }
    )

    # 7. Finance
    Donation.objects.get_or_create(
        receipt_number='REC-2026-0811',
        defaults={
            'organization': org1,
            'donor_name': 'Malabar Palliative Supporters',
            'amount': 50000.0,
            'category': 'General Palliative Fund',
            'payment_mode': 'Razorpay',
            'razorpay_payment_id': 'pay_demo_982410',
            'is_verified': True,
        }
    )

    MedicalFundraiser.objects.get_or_create(
        treatment_title='Complex Pediatric Open-Heart Surgery & Valve Reconstruction',
        defaults={
            'cooperating_organization': org1,
            'patient_name': 'Master Adithyan',
            'patient_age': 8,
            'patient_gender': 'Male',
            'blood_group': 'O+',
            'district': 'Kozhikode',
            'ward': 'Ward 08 - Chevayur',
            'hospital_name': 'Govt. Medical College Hospital, Calicut',
            'doctor_name': 'Dr. Suresh Kumar MD (Pediatric Cardiac Unit)',
            'category': 'Pediatric Cardiac',
            'target_amount': 1200000.0,
            'collected_amount': 780000.0,
            'donors_count': 412,
            'story': '8-year-old Adithyan from Kozhikode was diagnosed with critical congenital heart valve anomaly requiring urgent surgical reconstruction.',
            'medical_estimate_summary': 'Govt. Medical College Estimate: ₹12,00,000 (Surgery, Valve Prosthesis & PICU)',
            'is_doctor_verified': True,
            'days_remaining': 14,
            'status': 'Active',
            'patient_family_gratitude_message': 'Dear Well-Wisher, with tears of gratitude from Adithyan’s parents. Your support saves our little boy’s life! ❤️',
            'use_org_qr': True,
            'custom_upi_id': '',
        }
    )

    MedicalFundraiser.objects.get_or_create(
        treatment_title='Advanced Oncology Immunotherapy & Continuous Oxygen Care',
        defaults={
            'cooperating_organization': org2,
            'patient_name': 'Fathima Beevi',
            'patient_age': 81,
            'patient_gender': 'Female',
            'blood_group': 'AB+',
            'district': 'Ernakulam',
            'ward': 'Ward 03 - Edappally',
            'hospital_name': 'Ernakulam General Hospital & Palliative Oncology Wing',
            'doctor_name': 'Dr. Priya Varma MD (Medical Oncology)',
            'category': 'Oncology',
            'target_amount': 500000.0,
            'collected_amount': 320000.0,
            'donors_count': 185,
            'story': 'Fathima Beevi (81y) is battling Stage 4 Lung Carcinoma and requires palliative pain therapy and continuous oxygen care.',
            'medical_estimate_summary': 'Hospital Estimate: ₹5,00,000 (Targeted Pain Protocols & Oxygen consumables)',
            'is_doctor_verified': True,
            'days_remaining': 21,
            'status': 'Active',
            'patient_family_gratitude_message': 'Dear Kind Supporter, folded hands from Fathima Beevi and family. We keep you in our prayers! 🙏',
            'use_org_qr': True,
            'custom_upi_id': '',
        }
    )

    print("Database seeding completed successfully!")

if __name__ == '__main__':
    seed()

