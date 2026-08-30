import os
import sys
import django

# Setup utf-8 encoding for Windows console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

# Setup Django environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.utils import timezone
from apps.organizations.models import Organization, OrganizationStatus
from apps.authentication.models import User, UserRole
from apps.network.models import (
    Specialty,
    Department,
    HealthcareService,
    Facility,
    HealthcareProfile,
    OrganizationType,
    OwnershipType,
    VerificationStatus,
    Doctor,
    DoctorAffiliation,
    DoctorSchedule,
    DayOfWeek,
    ScheduleStatus,
    ChangeRequest,
    ChangeRequestEntityType,
    ChangeRequestStatus,
    AppointmentRequest,
    AppointmentStatus,
)

def seed_network():
    print("🌱 Seeding CareLink Network 2.0 (Verified Kerala Healthcare Ecosystem)...")

    # 1. Specialties Taxonomy
    specialties_data = [
        ('Cardiology', 'Heart & Vascular Care', 'favorite'),
        ('Neurology & Neurosurgery', 'Brain & Spine Care', 'psychology'),
        ('Medical & Surgical Oncology', 'Cancer Care & Chemotherapy', 'biotech'),
        ('Palliative & Pain Medicine', 'Home & Hospice Supportive Care', 'volunteer_activism'),
        ('Orthopedics & Joint Replacement', 'Bone & Joint Surgery', 'accessibility'),
        ('Pediatrics & Neonatology', 'Child & Infant Healthcare', 'child_care'),
        ('Nephrology & Urology', 'Kidney & Dialysis Care', 'water_drop'),
        ('General & Internal Medicine', 'Adult Primary Care', 'health_and_safety'),
        ('Pulmonology & Respiratory Care', 'Chest & Lung Diseases', 'air'),
        ('Emergency & Trauma Medicine', '24x7 Critical Care', 'emergency'),
    ]
    specialty_objs = {}
    for name, desc, icon in specialties_data:
        spec, _ = Specialty.objects.get_or_create(
            name=name,
            defaults={'description': desc, 'icon_name': icon}
        )
        specialty_objs[name] = spec
    print(f"✅ Created {len(specialty_objs)} Kerala Medical Specialties.")

    # 2. Services & Facilities Catalog
    services_data = [
        ('24x7 Emergency & Trauma Care', 'emergency'),
        ('Intensive Care Unit (ICU / CCU / NICU)', 'monitor_heart'),
        ('Dialysis Unit', 'water_drop'),
        ('Blood Bank & Component Separation', 'bloodtype'),
        ('24x7 In-House Pharmacy', 'medication'),
        ('Diagnostic MRI, CT & Ultrasound Imaging', 'scanner'),
        ('Palliative Home Care Fleet', 'local_hospital'),
        ('Ambulance & Mobile ICU Services', 'airport_shuttle'),
        ('Day-Care Chemotherapy Wing', 'healing'),
        ('Physiotherapy & Stroke Rehabilitation', 'fitness_center'),
    ]
    service_objs = []
    for s_name, s_icon in services_data:
        srv, _ = HealthcareService.objects.get_or_create(name=s_name, defaults={'icon_name': s_icon})
        service_objs.append(srv)

    facilities_data = [
        ('Wheelchair & Stretcher Accessible', 'accessible'),
        ('Centralized Medical Oxygen Supply', 'air'),
        ('Jan Aushadhi / Free Medicine Counter', 'local_pharmacy'),
        ('24x7 Power Backup & Generator', 'power'),
        ('Ample Visitor Parking', 'local_parking'),
        ('Patient Bystander Dormitory & Canteen', 'restaurant'),
    ]
    facility_objs = []
    for f_name, f_icon in facilities_data:
        fac, _ = Facility.objects.get_or_create(name=f_name, defaults={'icon_name': f_icon})
        facility_objs.append(fac)
    print(f"✅ Created {len(service_objs)} Services & {len(facility_objs)} Facilities.")

    # 3. Organizations & Healthcare Profiles
    orgs_data = [
        {
            'name': 'Calicut Medical Center & Palliative Institute',
            'district': 'Kozhikode',
            'reg_no': 'KZD/HOSP/2012/104',
            'phone': '+91 495 272 1000',
            'emergency_phone': '+91 495 272 1999',
            'type': OrganizationType.HOSPITAL,
            'ownership': OwnershipType.TRUST,
            'address': 'Mavoor Road Junction, Medical College PO, Kozhikode, Kerala 673008',
            'lat': 11.2721,
            'lng': 75.8342,
            'beds': 450,
            'icu_beds': 45,
            'emergency': True,
            'ambulance': True,
            'desc': 'NABH accredited multispecialty hospital with dedicated 50-bed palliative oncology and community home care wing.'
        },
        {
            'name': 'Ernakulam Care Palliative Trust & Specialty Clinic',
            'district': 'Ernakulam',
            'reg_no': 'EKM/CLINIC/2015/921',
            'phone': '+91 484 234 5678',
            'emergency_phone': '+91 484 234 5999',
            'type': OrganizationType.PALLIATIVE_CARE_CENTER,
            'ownership': OwnershipType.TRUST,
            'address': 'Near Changampuzha Park, Edappally, Kochi, Kerala 682024',
            'lat': 10.0261,
            'lng': 76.3125,
            'beds': 60,
            'icu_beds': 8,
            'emergency': True,
            'ambulance': True,
            'desc': 'Community-led palliative care center providing zero-cost home care, pain management, and free oxygen concentrator loans.'
        },
        {
            'name': 'Wayanad Tribal Health Mission & Hospital',
            'district': 'Wayanad',
            'reg_no': 'WYD/HOSP/2018/330',
            'phone': '+91 493 620 4400',
            'emergency_phone': '+91 493 620 4911',
            'type': OrganizationType.HOSPITAL,
            'ownership': OwnershipType.MISSION,
            'address': 'Main Highway, Kalpetta, Wayanad, Kerala 673121',
            'lat': 11.6050,
            'lng': 76.0830,
            'beds': 120,
            'icu_beds': 12,
            'emergency': True,
            'ambulance': True,
            'desc': 'Serving highland and tribal communities with mobile clinic vans, dialysis units, and maternal care.'
        },
        {
            'name': 'Thiruvananthapuram Institute of Palliative Sciences',
            'district': 'Thiruvananthapuram',
            'reg_no': 'TVM/INST/2014/512',
            'phone': '+91 471 244 8800',
            'emergency_phone': '+91 471 244 8899',
            'type': OrganizationType.HOSPITAL,
            'ownership': OwnershipType.TRUST,
            'address': 'Medical College Campus, Thiruvananthapuram, Kerala 695011',
            'lat': 8.5241,
            'lng': 76.9366,
            'beds': 200,
            'icu_beds': 25,
            'emergency': True,
            'ambulance': True,
            'desc': 'WHO demonstration center for pain relief and community hospice care across South Kerala.'
        },
    ]

    created_profiles = []
    for o_info in orgs_data:
        org, _ = Organization.objects.get_or_create(
            registration_number=o_info['reg_no'],
            defaults={
                'name': o_info['name'],
                'district': o_info['district'],
                'phone': o_info['phone'],
                'status': OrganizationStatus.ACTIVE
            }
        )

        profile, _ = HealthcareProfile.objects.get_or_create(
            organization=org,
            defaults={
                'organization_type': o_info['type'],
                'ownership_type': o_info['ownership'],
                'verification_status': VerificationStatus.VERIFIED,
                'address': o_info['address'],
                'district': o_info['district'],
                'pincode': '673001' if o_info['district'] == 'Kozhikode' else '682024',
                'latitude': o_info['lat'],
                'longitude': o_info['lng'],
                'phone': o_info['phone'],
                'emergency_phone': o_info['emergency_phone'],
                'is_24x7_emergency': o_info['emergency'],
                'ambulance_available': o_info['ambulance'],
                'total_beds': o_info['beds'],
                'icu_beds': o_info['icu_beds'],
                'description': o_info['desc'],
                'profile_completeness_score': 95,
                'last_verified_at': timezone.now()
            }
        )
        profile.specialties.set(list(specialty_objs.values())[:6])
        profile.services.set(service_objs[:6])
        profile.facilities.set(facility_objs[:5])
        profile.save()
        created_profiles.append(profile)

        # Create Departments
        for dept_name in ['Cardiology', 'Oncology & Palliative Care', 'General Medicine', 'Emergency & Critical Care']:
            Department.objects.get_or_create(organization=org, name=dept_name)

    print(f"✅ Created {len(created_profiles)} Verified Healthcare Profiles & Departments.")

    # 4. Doctors with Multi-Hospital Affiliations & Schedules
    doctors_seed = [
        {
            'name': 'Suresh Kumar',
            'qualification': 'MD, DNB (Palliative Medicine), FPCM',
            'specialty': 'Palliative & Pain Medicine',
            'exp': 18,
            'reg_no': 'TCMC-24891',
            'org_idx': 0,
            'designation': 'Chief Medical Director & Palliative Specialist',
            'fee': 0.00,
            'schedules': [
                (DayOfWeek.MONDAY, '09:00 AM', '01:00 PM', 'OPD Room 101'),
                (DayOfWeek.WEDNESDAY, '09:00 AM', '01:00 PM', 'OPD Room 101'),
                (DayOfWeek.FRIDAY, '02:00 PM', '05:00 PM', 'Home Care Triage Wing'),
            ]
        },
        {
            'name': 'Priya Varma',
            'qualification': 'MD (Internal Medicine), DM (Medical Oncology)',
            'specialty': 'Medical & Surgical Oncology',
            'exp': 14,
            'reg_no': 'TCMC-31045',
            'org_idx': 0,
            'designation': 'Senior Consultant Medical Oncologist',
            'fee': 400.00,
            'schedules': [
                (DayOfWeek.TUESDAY, '10:00 AM', '02:00 PM', 'Oncology Suite 204'),
                (DayOfWeek.THURSDAY, '10:00 AM', '02:00 PM', 'Oncology Suite 204'),
                (DayOfWeek.SATURDAY, '10:00 AM', '01:00 PM', 'Oncology Suite 204'),
            ]
        },
        {
            'name': 'Anil Kumar',
            'qualification': 'MD, DM (Cardiology), FACC',
            'specialty': 'Cardiology',
            'exp': 16,
            'reg_no': 'TCMC-19820',
            'org_idx': 0,
            'designation': 'Head of Interventional Cardiology',
            'fee': 500.00,
            'schedules': [
                (DayOfWeek.MONDAY, '04:00 PM', '07:00 PM', 'Cardiology Lab C-1'),
                (DayOfWeek.TUESDAY, '04:00 PM', '07:00 PM', 'Cardiology Lab C-1'),
                (DayOfWeek.THURSDAY, '04:00 PM', '07:00 PM', 'Cardiology Lab C-1'),
                (DayOfWeek.FRIDAY, '04:00 PM', '07:00 PM', 'Cardiology Lab C-1'),
            ]
        },
        {
            'name': 'Sunitha Menon',
            'qualification': 'MBBS, MD (Pediatrics)',
            'specialty': 'Pediatrics & Neonatology',
            'exp': 10,
            'reg_no': 'TCMC-40192',
            'org_idx': 1,
            'designation': 'Consultant Pediatrician',
            'fee': 300.00,
            'schedules': [
                (DayOfWeek.MONDAY, '09:30 AM', '01:30 PM', 'Child Clinic Room 4'),
                (DayOfWeek.WEDNESDAY, '09:30 AM', '01:30 PM', 'Child Clinic Room 4'),
                (DayOfWeek.SATURDAY, '10:00 AM', '01:00 PM', 'Child Clinic Room 4'),
            ]
        },
    ]

    for d_data in doctors_seed:
        spec = specialty_objs.get(d_data['specialty'])
        doc, _ = Doctor.objects.get_or_create(
            registration_number=d_data['reg_no'],
            defaults={
                'name': d_data['name'],
                'qualification': d_data['qualification'],
                'primary_specialty': spec,
                'experience_years': d_data['exp'],
                'languages': 'Malayalam, English, Hindi',
                'registration_authority': 'Travancore-Cochin Medical Council (TCMC)',
                'is_reg_verified': True,
                'biography': f"Experienced specialist dedicated to compassionate, verified patient care across Kerala with over {d_data['exp']} years of clinical practice."
            }
        )

        org = created_profiles[d_data['org_idx']].organization
        dept = org.departments.first()

        aff, _ = DoctorAffiliation.objects.get_or_create(
            doctor=doc,
            organization=org,
            defaults={
                'department': dept,
                'designation': d_data['designation'],
                'consultation_fee': d_data['fee'],
                'verification_status': VerificationStatus.VERIFIED,
                'verified_at': timezone.now()
            }
        )

        for day, s_time, e_time, room in d_data['schedules']:
            DoctorSchedule.objects.get_or_create(
                affiliation=aff,
                day_of_week=day,
                defaults={
                    'start_time': s_time,
                    'end_time': e_time,
                    'location_room': room,
                    'status': ScheduleStatus.ACTIVE,
                    'last_verified_at': timezone.now()
                }
            )

    print("✅ Created Doctors, Multi-Hospital Affiliations & Weekly Consultation Schedules.")

    # 5. Moderator Change Request Example
    super_admin = User.objects.filter(role=UserRole.SUPER_ADMIN).first()
    org1 = created_profiles[0].organization
    ChangeRequest.objects.get_or_create(
        organization=org1,
        change_summary='Update Dr. Anil Kumar Saturday OPD timing from 04:00 PM to 05:00 PM',
        defaults={
            'requested_by': super_admin,
            'entity_type': ChangeRequestEntityType.DOCTOR_SCHEDULE,
            'entity_id': 'SCH-101',
            'old_data': {'day': 'Saturday', 'start_time': '04:00 PM', 'end_time': '07:00 PM'},
            'new_data': {'day': 'Saturday', 'start_time': '05:00 PM', 'end_time': '08:00 PM'},
            'reason': 'Adjusted for cath lab surgical procedures',
            'status': ChangeRequestStatus.PENDING,
            'priority': 'NORMAL'
        }
    )
    print("✅ Created Sample Moderator Change Request with JSON diff.")

    # 6. Sample Appointment Request
    doc1 = Doctor.objects.first()
    AppointmentRequest.objects.get_or_create(
        patient_name='Karthyayani Amma',
        patient_phone='+91 94471 23456',
        defaults={
            'organization': org1,
            'doctor': doc1,
            'patient_age': 74,
            'patient_gender': 'Female',
            'district': 'Kozhikode',
            'preferred_date': timezone.now().date() + timezone.timedelta(days=2),
            'preferred_time_slot': 'Morning (09:00 AM - 01:00 PM)',
            'chief_complaint': 'Chronic knee osteoarthritis pain and home care triage support',
            'status': AppointmentStatus.REQUESTED,
            'token_number': 'TK-04'
        }
    )
    print("✅ Created Sample Appointment Request.")
    print("🎉 CareLink Network 2.0 Database Seeding Complete!")

if __name__ == '__main__':
    seed_network()
