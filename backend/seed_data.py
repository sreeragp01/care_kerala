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
from apps.network.models import (
    Specialty, HealthcareService, Facility, HealthcareProfile,
    OrganizationType, OwnershipType, VerificationStatus, OrganizationLifecycleStatus,
    Doctor, DoctorAffiliation, DoctorSchedule, ConsultationMode,
    AppointmentRequest, AppointmentStatus, AppointmentStatusHistory,
    QueueSession, QueueToken, QueueStatus, PriorityTriage
)

def seed():
    print("=======================================================")
    print("Seeding CareLink Kerala Multi-Role & Network Database")
    print("=======================================================")

    # 1. Organizations
    org1, _ = Organization.objects.get_or_create(
        registration_number='KZD/HOSP/2012/482',
        defaults={
            'name': 'Calicut Medical Center & Palliative Institute',
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
        registration_number='EKM/HOSP/2015/921',
        defaults={
            'name': 'Ernakulam General Hospital & Specialty Clinic',
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

    org3, _ = Organization.objects.get_or_create(
        registration_number='WYD/HOSP/2018/311',
        defaults={
            'name': 'Wayanad Community & Tribal Health Center',
            'district': 'Wayanad',
            'phone': '+91 4936 202 334',
            'upi_id': 'wayanadtribal@canarabank',
            'bank_account_name': 'Wayanad Tribal Health Escrow',
            'bank_account_number': '109283746501',
            'ifsc_code': 'CNRB0001829',
            'bank_name': 'Canara Bank (Kalpetta Branch)',
            'razorpay_account_id': 'acc_wyd_tribal_03',
            'active_patients_count': 64,
            'total_visits_count': 620,
        }
    )

    # 2. Healthcare Specialties Catalog
    spec_cardio, _ = Specialty.objects.get_or_create(name='Cardiology', defaults={'description': 'Heart & Vascular Care', 'icon_name': 'favorite'})
    spec_pall, _ = Specialty.objects.get_or_create(name='Palliative & Pain Medicine', defaults={'description': 'Supportive, Pain & Hospice Care', 'icon_name': 'volunteer_activism'})
    spec_onco, _ = Specialty.objects.get_or_create(name='Medical & Surgical Oncology', defaults={'description': 'Cancer Care, Chemotherapy & Immunotherapy', 'icon_name': 'biotech'})
    spec_neuro, _ = Specialty.objects.get_or_create(name='Neurology & Neurosurgery', defaults={'description': 'Brain, Nerve & Spine Care', 'icon_name': 'psychology'})
    spec_ortho, _ = Specialty.objects.get_or_create(name='Orthopedics & Joint Care', defaults={'description': 'Bone, Joint & Trauma Surgery', 'icon_name': 'accessibility'})
    spec_ped, _ = Specialty.objects.get_or_create(name='Pediatrics & Neonatology', defaults={'description': 'Child & Infant Healthcare', 'icon_name': 'child_care'})
    spec_gen, _ = Specialty.objects.get_or_create(name='General Medicine', defaults={'description': 'Adult Primary Care & Fevers', 'icon_name': 'health_and_safety'})
    spec_emerg, _ = Specialty.objects.get_or_create(name='Emergency & Critical Care', defaults={'description': '24x7 Emergency & Trauma Care', 'icon_name': 'emergency'})

    # 3. Healthcare Services & Facilities
    srv_emg, _ = HealthcareService.objects.get_or_create(name='24x7 Emergency Casualty & Trauma', defaults={'category': 'Emergency Care'})
    srv_icu, _ = HealthcareService.objects.get_or_create(name='Critical Care ICU & CCU Beds', defaults={'category': 'Inpatient Care'})
    srv_dial, _ = HealthcareService.objects.get_or_create(name='Dialysis Center & Renal Support', defaults={'category': 'Dialysis'})
    srv_home, _ = HealthcareService.objects.get_or_create(name='Home Palliative Care Outreach', defaults={'category': 'Community Outreach'})
    srv_pharm, _ = HealthcareService.objects.get_or_create(name='24x7 Verified In-House Pharmacy', defaults={'category': 'Pharmacy'})
    srv_amb, _ = HealthcareService.objects.get_or_create(name='Advanced Life Support (ALS) Ambulance', defaults={'category': 'Emergency Transport'})

    fac_wc, _ = Facility.objects.get_or_create(name='Wheelchair Ramp & Elevator Accessible')
    fac_o2, _ = Facility.objects.get_or_create(name='Central Piped Oxygen Supply')
    fac_gen, _ = Facility.objects.get_or_create(name='100% 24x7 Generator Power Backup')
    fac_park, _ = Facility.objects.get_or_create(name='Free Patient & Ambulance Parking')

    # 4. Healthcare Profiles
    prof1, _ = HealthcareProfile.objects.get_or_create(
        organization=org1,
        defaults={
            'organization_type': OrganizationType.HOSPITAL,
            'ownership_type': OwnershipType.TRUST,
            'verification_status': VerificationStatus.VERIFIED,
            'address': 'Mavoor Road, Medical College Junction, West Hill',
            'district': 'Kozhikode',
            'pincode': '673001',
            'phone': '+91 495 272 1000',
            'emergency_phone': '+91 495 272 1099',
            'email': 'admin@cmccalicut.org',
            'website': 'https://cmccalicut.org',
            'is_24x7_emergency': True,
            'trauma_care_available': True,
            'ambulance_available': True,
            'total_beds': 250,
            'icu_beds': 30,
            'description': 'Premier multispecialty hospital and community palliative hub in North Malabar offering cardiology, oncology, palliative care, and trauma management.',
            'profile_completeness_score': 95,
            'lifecycle_status': OrganizationLifecycleStatus.PUBLISHED,
            'is_published': True,
        }
    )
    prof1.specialties.set([spec_cardio, spec_pall, spec_onco, spec_gen, spec_emerg])
    prof1.services.set([srv_emg, srv_icu, srv_dial, srv_home, srv_pharm, srv_amb])
    prof1.facilities.set([fac_wc, fac_o2, fac_gen, fac_park])

    prof2, _ = HealthcareProfile.objects.get_or_create(
        organization=org2,
        defaults={
            'organization_type': OrganizationType.HOSPITAL,
            'ownership_type': OwnershipType.GOVERNMENT,
            'verification_status': VerificationStatus.VERIFIED,
            'address': 'Hospital Road, Marine Drive, Kochi',
            'district': 'Ernakulam',
            'pincode': '682011',
            'phone': '+91 484 234 5678',
            'emergency_phone': '+91 484 234 5699',
            'email': 'superintendent@ekmgenhosp.kerala.gov.in',
            'website': 'https://ekmgenhosp.health.kerala.gov.in',
            'is_24x7_emergency': True,
            'trauma_care_available': True,
            'ambulance_available': True,
            'total_beds': 450,
            'icu_beds': 45,
            'description': 'Leading tertiary government hospital in Central Kerala featuring advanced oncology wing, pediatric cardiology, and comprehensive outpatient clinics.',
            'profile_completeness_score': 90,
            'lifecycle_status': OrganizationLifecycleStatus.PUBLISHED,
            'is_published': True,
        }
    )
    prof2.specialties.set([spec_onco, spec_ped, spec_gen, spec_emerg, spec_ortho])

    prof3, _ = HealthcareProfile.objects.get_or_create(
        organization=org3,
        defaults={
            'organization_type': OrganizationType.PALLIATIVE_CARE_CENTER,
            'ownership_type': OwnershipType.TRUST,
            'verification_status': VerificationStatus.VERIFIED,
            'address': 'Main Road, Meppadi, Kalpetta',
            'district': 'Wayanad',
            'pincode': '673577',
            'phone': '+91 4936 202 334',
            'emergency_phone': '+91 4936 202 399',
            'email': 'care@wayanadtribalhealth.org',
            'is_24x7_emergency': True,
            'ambulance_available': True,
            'total_beds': 60,
            'icu_beds': 8,
            'description': 'Dedicated tribal community healthcare center and palliative hospice providing free medical outreach, snakebite triage, and palliative elder support.',
            'profile_completeness_score': 88,
            'lifecycle_status': OrganizationLifecycleStatus.PUBLISHED,
            'is_published': True,
        }
    )
    prof3.specialties.set([spec_pall, spec_gen, spec_emerg])

    # 5. User Accounts for EVERY Role
    users_to_seed = [
        # Super Admin
        ('psreerag304@gmail.com', 'Sreerag', 'Admin', UserRole.SUPER_ADMIN, org1, 'Kozhikode', '+91 94470 00001', True, True),
        # Hospital Admins (orgAdmin)
        ('admin_calicut', 'Dr. K. S.', 'Menon', UserRole.ORG_ADMIN, org1, 'Kozhikode', '+91 94470 55667', True, False),
        ('admin_ekm', 'Dr. C.', 'Radhakrishnan', UserRole.ORG_ADMIN, org2, 'Ernakulam', '+91 98460 22334', True, False),
        ('admin_wyd', 'Dr. Vineeth', 'Mathew', UserRole.ORG_ADMIN, org3, 'Wayanad', '+91 98475 99001', True, False),
        # Doctors
        ('suresh', 'Dr. Suresh', 'Kumar', UserRole.DOCTOR, org1, 'Kozhikode', '+91 94470 88990', False, False),
        ('dr_priya', 'Dr. Priya', 'Varma', UserRole.DOCTOR, org1, 'Kozhikode', '+91 98472 33445', False, False),
        ('dr_anil', 'Dr. Anil', 'Kumar', UserRole.DOCTOR, org1, 'Kozhikode', '+91 94470 19820', False, False),
        ('dr_sunitha', 'Dr. Sunitha', 'Menon', UserRole.DOCTOR, org2, 'Ernakulam', '+91 98461 44556', False, False),
        # Nurses
        ('anitha', 'Sr. Anitha', 'Kumar', UserRole.NURSE, org1, 'Kozhikode', '+91 98470 12345', False, False),
        ('nurse_saramma', 'Sr. Saramma', 'Joseph', UserRole.NURSE, org2, 'Ernakulam', '+91 98462 77889', False, False),
        # Reception / Token Desk Staff
        ('reception_calicut', 'Kavya', 'Nair', UserRole.RECEPTION, org1, 'Kozhikode', '+91 98472 88119', False, False),
        ('reception_ekm', 'Naveen', 'Prasad', UserRole.RECEPTION, org2, 'Ernakulam', '+91 98463 11220', False, False),
        # Moderator
        ('moderator_kerala', 'Rahul', 'Menon', UserRole.MODERATOR, org1, 'Kozhikode', '+91 94471 66778', False, False),
        # Pharmacist
        ('pharmacy_cmc', 'Manoj', 'Kumar', UserRole.PHARMACIST, org1, 'Kozhikode', '+91 98460 77112', False, False),
        # Accountant
        ('accountant_cmc', 'Shalini', 'K.', UserRole.ACCOUNTANT, org1, 'Kozhikode', '+91 98473 44556', False, False),
        # Ambulance Driver
        ('driver_sujith', 'Sujith', 'Kumar', UserRole.AMBULANCE_DRIVER, org1, 'Kozhikode', '+91 94470 12345', False, False),
        # Volunteer
        ('arjun', 'Arjun', 'Das', UserRole.VOLUNTEER, org1, 'Kozhikode', '+91 97440 11223', False, False),
        # Patients
        ('patient_karthyayani', 'Karthyayani', 'Amma', UserRole.PATIENT, org1, 'Kozhikode', '+91 94471 23456', False, False),
        ('patient_basheer', 'Muhammed', 'Basheer', UserRole.PATIENT, org1, 'Kozhikode', '+91 98472 33445', False, False),
        # Family Member / Caregiver
        ('caregiver_ramesh', 'Ramesh', 'Kumar', UserRole.FAMILY_MEMBER, org1, 'Kozhikode', '+91 98470 11223', False, False),
        # Palliative Member / Blood Donor
        ('donor_deepak', 'Deepak', 'M.', UserRole.BLOOD_DONOR, org1, 'Kozhikode', '+91 98471 22334', False, False),
    ]

    for uname, fname, lname, role, org, dist, phone, is_stf, is_sup in users_to_seed:
        u, _ = User.objects.get_or_create(
            username=uname,
            defaults={
                'email': f'{uname}@carelink.kerala.gov.in' if '@' not in uname else uname,
                'first_name': fname,
                'last_name': lname,
                'role': role,
                'organization': org,
                'district': dist,
                'phone': phone,
                'is_staff': is_stf,
                'is_superuser': is_sup,
            }
        )
        if uname == 'psreerag304@gmail.com':
            u.set_password(os.getenv('SUPERADMIN_PASSWORD', 'Sree321#'))
        else:
            u.set_password('pass1234')
        u.role = role
        u.save()

    # 6. Doctors, Affiliations, Schedules
    doc_suresh, _ = Doctor.objects.get_or_create(
        name='Suresh Kumar MD',
        defaults={
            'qualification': 'MD, DNB (Palliative Medicine), FPCM',
            'primary_specialty': spec_pall,
            'sub_specialties': 'Pain Management, Geriatric Palliative Care',
            'experience_years': 18,
            'languages': 'Malayalam, English, Hindi',
            'registration_number': 'TCMC-24891',
            'is_reg_verified': True,
            'biography': 'Senior palliative consultant with 18+ years leading home palliative teams across North Kerala.',
        }
    )

    doc_priya, _ = Doctor.objects.get_or_create(
        name='Priya Varma MD',
        defaults={
            'qualification': 'MD (Internal Medicine), DM (Medical Oncology)',
            'primary_specialty': spec_onco,
            'sub_specialties': 'Solid Tumors, Chemotherapy & Immunotherapy',
            'experience_years': 14,
            'languages': 'Malayalam, English',
            'registration_number': 'TCMC-31045',
            'is_reg_verified': True,
            'biography': 'Specialist medical oncologist dedicated to affordable cancer protocols and patient navigation.',
        }
    )

    doc_anil, _ = Doctor.objects.get_or_create(
        name='Anil Kumar DM',
        defaults={
            'qualification': 'MD, DM (Cardiology), FACC',
            'primary_specialty': spec_cardio,
            'sub_specialties': 'Interventional Cardiology, Heart Failure',
            'experience_years': 16,
            'languages': 'Malayalam, English, Tamil',
            'registration_number': 'TCMC-19820',
            'is_reg_verified': True,
            'biography': 'Chief cardiologist with expertise in coronary angiography, acute coronary syndromes, and hypertension.',
        }
    )

    doc_sunitha, _ = Doctor.objects.get_or_create(
        name='Sunitha Menon MD',
        defaults={
            'qualification': 'MBBS, MD (Pediatrics)',
            'primary_specialty': spec_ped,
            'sub_specialties': 'Pediatric Pulmonology & Neonatology',
            'experience_years': 11,
            'languages': 'Malayalam, English',
            'registration_number': 'TCMC-40112',
            'is_reg_verified': True,
            'biography': 'Compassionate pediatrician focusing on developmental milestones and pediatric asthma care.',
        }
    )

    # Affiliations
    aff_suresh, _ = DoctorAffiliation.objects.get_or_create(
        doctor=doc_suresh, organization=org1,
        defaults={'designation': 'Director of Palliative Medicine', 'consultation_mode': ConsultationMode.ALL, 'consultation_fee': 0.00}
    )
    aff_priya, _ = DoctorAffiliation.objects.get_or_create(
        doctor=doc_priya, organization=org1,
        defaults={'designation': 'Senior Consultant Oncologist', 'consultation_mode': ConsultationMode.IN_PERSON, 'consultation_fee': 400.00}
    )
    aff_anil, _ = DoctorAffiliation.objects.get_or_create(
        doctor=doc_anil, organization=org1,
        defaults={'designation': 'Head of Cardiology', 'consultation_mode': ConsultationMode.IN_PERSON, 'consultation_fee': 500.00}
    )
    aff_sunitha, _ = DoctorAffiliation.objects.get_or_create(
        doctor=doc_sunitha, organization=org2,
        defaults={'designation': 'Consultant Pediatrician', 'consultation_mode': ConsultationMode.IN_PERSON, 'consultation_fee': 350.00}
    )

    # Schedules
    DoctorSchedule.objects.get_or_create(
        affiliation=aff_suresh, day_of_week='Monday',
        defaults={'start_time': '09:00:00', 'end_time': '13:00:00', 'location_room': 'OPD Room 101', 'consultation_type': 'Palliative Clinic', 'slot_duration_minutes': 20, 'max_tokens': 25}
    )
    DoctorSchedule.objects.get_or_create(
        affiliation=aff_suresh, day_of_week='Wednesday',
        defaults={'start_time': '09:00:00', 'end_time': '13:00:00', 'location_room': 'OPD Room 101', 'consultation_type': 'Symptom Triage', 'slot_duration_minutes': 20, 'max_tokens': 25}
    )
    DoctorSchedule.objects.get_or_create(
        affiliation=aff_priya, day_of_week='Tuesday',
        defaults={'start_time': '10:00:00', 'end_time': '14:00:00', 'location_room': 'Oncology Suite 204', 'consultation_type': 'Oncology OPD', 'slot_duration_minutes': 20, 'max_tokens': 20}
    )
    DoctorSchedule.objects.get_or_create(
        affiliation=aff_priya, day_of_week='Thursday',
        defaults={'start_time': '10:00:00', 'end_time': '14:00:00', 'location_room': 'Oncology Suite 204', 'consultation_type': 'Chemotherapy Review', 'slot_duration_minutes': 20, 'max_tokens': 20}
    )
    DoctorSchedule.objects.get_or_create(
        affiliation=aff_anil, day_of_week='Monday',
        defaults={'start_time': '16:00:00', 'end_time': '19:00:00', 'location_room': 'Cardiology Lab C-1', 'consultation_type': 'Cardiac Consultation', 'slot_duration_minutes': 20, 'max_tokens': 25}
    )
    DoctorSchedule.objects.get_or_create(
        affiliation=aff_anil, day_of_week='Wednesday',
        defaults={'start_time': '16:00:00', 'end_time': '19:00:00', 'location_room': 'Cardiology Lab C-1', 'consultation_type': 'Post-Op Review', 'slot_duration_minutes': 20, 'max_tokens': 25}
    )

    # 7. Patients
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
            'name': 'Muhammed Basheer',
            'age': 68,
            'gender': 'Male',
            'blood_group': 'B+',
            'district': 'Kozhikode',
            'ward': 'Ward 08 - Medical College',
            'address': 'Souparnika, Near Primary Health Centre, Medical College PO',
            'phone': '+91 98472 33445',
            'category_tier': 'Category B (Semi-mobile)',
            'diagnosis': 'Post-Myocardial Infarction & Hypertension',
            'risk_level': 'Moderate Risk',
            'ai_summary': 'Cardiac recovery following angioplasty. Needs routine ECG and medication review.',
            'emergency_contact_name': 'Amina (Wife)',
            'emergency_contact_phone': '+91 98472 33446',
        }
    )

    VitalsReading.objects.get_or_create(patient=p1, recorded_date=date.today(), defaults={'bp': '130/85', 'pulse': 76, 'spo2': 97, 'pain_scale': 4, 'recorded_by': 'Sr. Anitha Kumar'})
    EquipmentIssued.objects.get_or_create(patient=p1, serial_number='EQ-AM-402', defaults={'equipment_name': 'Air Mattress', 'issued_date': date.today() - timedelta(days=60), 'status': 'Active'})
    FamilyMemberContact.objects.get_or_create(patient=p1, name='Ramesh Kumar', defaults={'relation': 'Son', 'phone': '+91 98470 11223'})

    # 8. Appointments Across Lifecycle Stages
    today = date.today()
    tomorrow = today + timedelta(days=1)
    yesterday = today - timedelta(days=1)

    # 1. REQUESTED (Pending desk intake)
    AppointmentRequest.objects.get_or_create(
        organization=org1, doctor=doc_anil, patient_name='Muhammed Basheer',
        preferred_date=tomorrow,
        defaults={
            'affiliation': aff_anil,
            'patient_phone': '+91 98472 33445',
            'patient_age': 68,
            'patient_gender': 'Male',
            'district': 'Kozhikode',
            'preferred_time_slot': '04:00 PM - 04:20 PM',
            'consultation_mode': ConsultationMode.IN_PERSON,
            'chief_complaint': 'Mild exertion breathlessness and post-angioplasty routine checkup.',
            'status': AppointmentStatus.REQUESTED,
            'token_number': 'C-16',
        }
    )

    # 2. CONFIRMED (Desk approved, token issued)
    AppointmentRequest.objects.get_or_create(
        organization=org1, doctor=doc_suresh, patient_name='A. Narayanan',
        preferred_date=today,
        defaults={
            'affiliation': aff_suresh,
            'patient_phone': '+91 98765 43210',
            'patient_age': 71,
            'patient_gender': 'Male',
            'district': 'Kozhikode',
            'preferred_time_slot': '09:00 AM - 09:20 AM',
            'consultation_mode': ConsultationMode.IN_PERSON,
            'chief_complaint': 'Chronic back pain and mobility difficulty.',
            'status': AppointmentStatus.CONFIRMED,
            'token_number': 'A-01',
            'hospital_notes': 'Slot verified by Desk Officer Kavya Nair.',
        }
    )

    # 3. CHECKED_IN (Patient arrived, in waiting room)
    AppointmentRequest.objects.get_or_create(
        organization=org1, doctor=doc_anil, patient_name='Fatima Zahra',
        preferred_date=today,
        defaults={
            'affiliation': aff_anil,
            'patient_phone': '+91 98765 43211',
            'patient_age': 54,
            'patient_gender': 'Female',
            'district': 'Kozhikode',
            'preferred_time_slot': '04:20 PM - 04:40 PM',
            'consultation_mode': ConsultationMode.IN_PERSON,
            'chief_complaint': 'Follow-up on blood pressure regulation.',
            'status': AppointmentStatus.CHECKED_IN,
            'token_number': 'C-19',
            'hospital_notes': 'Arrived at reception 15 mins early. Queued in Room 102.',
        }
    )

    # 4. IN_CONSULTATION (Currently inside doctor room)
    AppointmentRequest.objects.get_or_create(
        organization=org1, doctor=doc_anil, patient_name='Rahul Narayanan',
        preferred_date=today,
        defaults={
            'affiliation': aff_anil,
            'patient_phone': '+91 98765 43212',
            'patient_age': 49,
            'patient_gender': 'Male',
            'district': 'Kozhikode',
            'preferred_time_slot': '04:00 PM - 04:20 PM',
            'consultation_mode': ConsultationMode.IN_PERSON,
            'chief_complaint': 'ECG review and chest tightness assessment.',
            'status': AppointmentStatus.IN_CONSULTATION,
            'token_number': 'C-18',
        }
    )

    # 5. COMPLETED (Consultation done, Rx printed)
    apt_comp, _ = AppointmentRequest.objects.get_or_create(
        organization=org1, doctor=doc_suresh, patient_name='Karthyayani Amma',
        preferred_date=yesterday,
        defaults={
            'affiliation': aff_suresh,
            'patient_phone': '+91 94471 23456',
            'patient_age': 74,
            'patient_gender': 'Female',
            'district': 'Kozhikode',
            'preferred_time_slot': '11:00 AM - 11:20 AM',
            'consultation_mode': ConsultationMode.IN_PERSON,
            'chief_complaint': 'Severe knee pain and immobility',
            'status': AppointmentStatus.COMPLETED,
            'token_number': 'A-09',
            'hospital_notes': 'Prescribed Gabapentin 300mg and advised gentle home physiotherapy.',
        }
    )

    # 6. CANCELLED (Patient cancel with valid reason)
    AppointmentRequest.objects.get_or_create(
        organization=org1, doctor=doc_priya, patient_name='George Joseph',
        preferred_date=yesterday,
        defaults={
            'affiliation': aff_priya,
            'patient_phone': '+91 94470 11999',
            'patient_age': 61,
            'patient_gender': 'Male',
            'district': 'Kozhikode',
            'preferred_time_slot': '11:00 AM - 11:20 AM',
            'consultation_mode': ConsultationMode.IN_PERSON,
            'chief_complaint': 'Routine oncology CBC check.',
            'status': AppointmentStatus.CANCELLED,
            'token_number': 'B-03',
            'cancellation_reason': 'Patient had travel constraints due to heavy rain in Wayanad ghats.',
        }
    )

    # 7. NO_SHOW
    AppointmentRequest.objects.get_or_create(
        organization=org1, doctor=doc_priya, patient_name='Raveendran Master',
        preferred_date=yesterday,
        defaults={
            'affiliation': aff_priya,
            'patient_phone': '+91 98471 00223',
            'patient_age': 79,
            'patient_gender': 'Male',
            'district': 'Kozhikode',
            'preferred_time_slot': '10:40 AM - 11:00 AM',
            'consultation_mode': ConsultationMode.IN_PERSON,
            'chief_complaint': 'Post-op oncology dressing review.',
            'status': AppointmentStatus.NO_SHOW,
            'token_number': 'B-02',
            'hospital_notes': 'Patient did not report to reception.',
        }
    )

    # 9. Live Queue Sessions & Tokens
    qs_cardio, _ = QueueSession.objects.get_or_create(
        organization=org1, doctor=doc_anil, session_date=today,
        defaults={
            'department_name': 'Cardiology OPD',
            'room_number': 'OPD Room 102 (Block A)',
            'queue_type': 'OPD',
            'queue_type_display': 'Cardiology Consultation',
            'token_prefix': 'C',
            'start_time': '16:00:00',
            'end_time': '19:00:00',
            'max_capacity': 25,
            'avg_consultation_minutes': 13,
            'is_active': True,
        }
    )

    QueueToken.objects.get_or_create(
        session=qs_cardio, token_number=18,
        defaults={'token_label': 'C-18', 'patient_name': 'Rahul Narayanan', 'patient_phone': '+91 98765 43212', 'priority': PriorityTriage.NORMAL, 'status': QueueStatus.IN_CONSULTATION, 'is_walk_in': False}
    )
    QueueToken.objects.get_or_create(
        session=qs_cardio, token_number=19,
        defaults={'token_label': 'C-19', 'patient_name': 'Fatima Zahra', 'patient_phone': '+91 98765 43211', 'priority': PriorityTriage.NORMAL, 'status': QueueStatus.CHECKED_IN, 'is_walk_in': False}
    )
    QueueToken.objects.get_or_create(
        session=qs_cardio, token_number=20,
        defaults={'token_label': 'C-20', 'patient_name': 'Muhammed Basheer', 'patient_phone': '+91 98472 33445', 'priority': PriorityTriage.PRIORITY, 'status': QueueStatus.WAITING, 'is_walk_in': False}
    )
    QueueToken.objects.get_or_create(
        session=qs_cardio, token_number=21,
        defaults={'token_label': 'C-21', 'patient_name': 'Unnikrishnan Nair', 'patient_phone': '+91 94471 99002', 'priority': PriorityTriage.NORMAL, 'status': QueueStatus.WAITING, 'is_walk_in': True}
    )

    # 10. Blood Donors & Fundraisers
    BloodDonor.objects.get_or_create(
        name='Deepak M.',
        defaults={
            'organization': org1,
            'blood_group': 'O+',
            'district': 'Kozhikode',
            'locality': 'Chevayur',
            'phone': '+91 98471 22334',
            'last_donation_date': today - timedelta(days=40),
            'total_donations': 10,
            'is_available': True,
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

    print("=======================================================")
    print("Database seeding completed successfully!")
    print(f"Hospitals: {HealthcareProfile.objects.count()} verified institutions")
    print(f"Users: {User.objects.count()} multi-role user accounts")
    print(f"Doctors: {Doctor.objects.count()} doctors with active OPD timetables")
    print(f"Appointments: {AppointmentRequest.objects.count()} appointments across all lifecycle states")
    print(f"Live Queues: {QueueSession.objects.count()} active OPD queue sessions with tokens")
    print("=======================================================")

if __name__ == '__main__':
    seed()
