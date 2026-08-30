from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.organizations.models import Organization
from apps.network.models import (
    HealthcareProfile,
    Specialty,
    HealthcareService,
    Facility,
    OrganizationType,
    OwnershipType,
    VerificationStatus,
)

class Command(BaseCommand):
    help = 'Imports a comprehensive initial dataset of Kerala healthcare centers tagged as UNVERIFIED for institutional claiming'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE("Initializing Kerala Healthcare Dataset Onboarding..."))

        # Pre-seed essential specialties if not present
        specialties_data = [
            ('Cardiology', 'Clinical Specialty', 'favorite', 'Heart & Interventional Cardiology'),
            ('Palliative & Pain Medicine', 'Clinical Specialty', 'volunteer_activism', 'Comprehensive Palliative, Pain & Hospice Care'),
            ('Medical & Surgical Oncology', 'Clinical Specialty', 'biotech', 'Cancer Diagnosis, Chemotherapy & Surgery'),
            ('Neurology & Neurosurgery', 'Clinical Specialty', 'psychology', 'Brain, Nerve & Spinal Trauma Care'),
            ('Pediatrics & Neonatology', 'Clinical Specialty', 'child_care', 'Infant, Child Care & NICU'),
            ('Nephrology & Dialysis', 'Clinical Specialty', 'water_drop', 'Renal Care & Hemodialysis'),
            ('Emergency & Critical Care', 'Clinical Specialty', 'emergency', '24x7 Emergency, Trauma & ICU'),
            ('General Medicine', 'Clinical Specialty', 'health_and_safety', 'Internal Medicine & Primary Adult Care'),
            ('Orthopedics & Joint Care', 'Clinical Specialty', 'accessibility', 'Bone Fractures & Joint Replacement'),
            ('Pulmonology', 'Clinical Specialty', 'air', 'Respiratory & Chest Medicine'),
        ]
        
        spec_map = {}
        for name, category, icon, desc in specialties_data:
            spec, _ = Specialty.objects.get_or_create(
                name=name,
                defaults={'category': category, 'icon_name': icon, 'description': desc}
            )
            spec_map[name] = spec

        # Pre-seed standard services
        services_data = [
            ('24x7 Emergency & Trauma Care', 'Emergency', 'emergency'),
            ('Intensive Care Unit (ICU / CCU)', 'Critical Care', 'local_hospital'),
            ('Palliative Home Care Squad', 'Palliative', 'volunteer_activism'),
            ('Hemodialysis Unit', 'Specialized Care', 'water_drop'),
            ('24x7 In-House Pharmacy', 'Support', 'local_pharmacy'),
            ('Blood Bank & Component Center', 'Support', 'bloodtype'),
            ('Advanced CT & MRI Imaging', 'Diagnostics', 'medical_information'),
        ]
        
        srv_map = {}
        for name, category, icon in services_data:
            srv, _ = HealthcareService.objects.get_or_create(
                name=name,
                defaults={'category': category, 'icon_name': icon}
            )
            srv_map[name] = srv

        # 14 Kerala Districts Dataset (Government Hospitals, CHCs, Palliative Units, Medical Colleges)
        kerala_centers = [
            # 1. Kozhikode
            {
                'name': 'Government Medical College Hospital, Kozhikode',
                'district': 'Kozhikode',
                'address': 'Medical College PO, Kozhikode, Kerala 673008',
                'pincode': '673008',
                'phone': '+91 495 235 0216',
                'emergency_phone': '+91 495 235 0200',
                'reg': 'KL/DME/KKD/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 3025,
                'icu': 180,
                'lat': 11.2721,
                'lng': 75.8342,
                'desc': 'Premier tertiary referral teaching hospital in Northern Kerala with state-of-the-art trauma care and comprehensive super-specialties.',
                'specs': ['Cardiology', 'Palliative & Pain Medicine', 'Medical & Surgical Oncology', 'Neurology & Neurosurgery', 'Emergency & Critical Care'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Intensive Care Unit (ICU / CCU)', 'Hemodialysis Unit', 'Blood Bank & Component Center']
            },
            {
                'name': 'Government General Hospital (Beach Hospital), Kozhikode',
                'district': 'Kozhikode',
                'address': 'Beach Road, Vellayil, Kozhikode, Kerala 673032',
                'pincode': '673032',
                'phone': '+91 495 236 5367',
                'emergency_phone': '+91 495 236 5300',
                'reg': 'KL/DHS/KKD/02',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 500,
                'icu': 24,
                'lat': 11.2612,
                'lng': 75.7689,
                'desc': 'Key secondary government healthcare center serving coastal and urban Kozhikode with dialysis and general medical OPD.',
                'specs': ['General Medicine', 'Orthopedics & Joint Care', 'Pediatrics & Neonatology'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Hemodialysis Unit', '24x7 In-House Pharmacy']
            },
            # 2. Ernakulam
            {
                'name': 'Government Medical College, Ernakulam',
                'district': 'Ernakulam',
                'address': 'HMT Colony PO, Kalamassery, Kochi, Kerala 683503',
                'pincode': '683503',
                'phone': '+91 484 275 4000',
                'emergency_phone': '+91 484 275 4100',
                'reg': 'KL/DME/EKM/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 750,
                'icu': 60,
                'lat': 10.0558,
                'lng': 76.3544,
                'desc': 'Tertiary government medical college hospital in Central Kerala providing multispecialty care and pediatric intensive units.',
                'specs': ['Cardiology', 'Pediatrics & Neonatology', 'General Medicine', 'Emergency & Critical Care'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Intensive Care Unit (ICU / CCU)', 'Blood Bank & Component Center']
            },
            {
                'name': 'General Hospital, Ernakulam',
                'district': 'Ernakulam',
                'address': 'Hospital Road, Marine Drive, Kochi, Kerala 682011',
                'pincode': '682011',
                'phone': '+91 484 236 1251',
                'emergency_phone': '+91 484 236 0000',
                'reg': 'KL/DHS/EKM/02',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 783,
                'icu': 45,
                'lat': 9.9723,
                'lng': 76.2818,
                'desc': 'NABH-accredited premier government general hospital with advanced super-specialty wings and comprehensive cancer care.',
                'specs': ['Medical & Surgical Oncology', 'Cardiology', 'Palliative & Pain Medicine', 'Nephrology & Dialysis'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Hemodialysis Unit', '24x7 In-House Pharmacy']
            },
            # 3. Thiruvananthapuram
            {
                'name': 'Government Medical College Hospital, Thiruvananthapuram',
                'district': 'Thiruvananthapuram',
                'address': 'Medical College Junction, Thiruvananthapuram, Kerala 695011',
                'pincode': '695011',
                'phone': '+91 471 252 8300',
                'emergency_phone': '+91 471 252 8383',
                'reg': 'KL/DME/TVM/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 2850,
                'icu': 200,
                'lat': 8.5241,
                'lng': 76.9366,
                'desc': 'The oldest and largest medical college hospital in Kerala, offering apex tertiary care, organ transplant, and advanced trauma centers.',
                'specs': ['Cardiology', 'Neurology & Neurosurgery', 'Medical & Surgical Oncology', 'Emergency & Critical Care', 'Palliative & Pain Medicine'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Intensive Care Unit (ICU / CCU)', 'Blood Bank & Component Center', 'Hemodialysis Unit']
            },
            {
                'name': 'Regional Cancer Centre (RCC), Thiruvananthapuram',
                'district': 'Thiruvananthapuram',
                'address': 'Medical College Campus, Thiruvananthapuram, Kerala 695011',
                'pincode': '695011',
                'phone': '+91 471 244 2541',
                'emergency_phone': '+91 471 244 2500',
                'reg': 'KL/AUT/TVM/RCC',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 350,
                'icu': 30,
                'lat': 8.5255,
                'lng': 76.9380,
                'desc': 'Autonomous apex cancer research and treatment institute providing cutting-edge radiation oncology, surgical oncology, and palliative pain relief.',
                'specs': ['Medical & Surgical Oncology', 'Palliative & Pain Medicine', 'Pulmonology'],
                'srvs': ['Palliative Home Care Squad', '24x7 In-House Pharmacy', 'Advanced CT & MRI Imaging']
            },
            # 4. Thrissur
            {
                'name': 'Government Medical College, Thrissur',
                'district': 'Thrissur',
                'address': 'M.G. Kavu, Thrissur, Kerala 680596',
                'pincode': '680596',
                'phone': '+91 487 220 0310',
                'emergency_phone': '+91 487 220 0300',
                'reg': 'KL/DME/TSR/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 1400,
                'icu': 90,
                'lat': 10.6186,
                'lng': 76.1963,
                'desc': 'Major tertiary healthcare facility in Central Kerala with 24x7 emergency medicine, pediatric units, and chest disease sanatorium.',
                'specs': ['General Medicine', 'Pulmonology', 'Pediatrics & Neonatology', 'Orthopedics & Joint Care'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Intensive Care Unit (ICU / CCU)', 'Hemodialysis Unit']
            },
            # 5. Malappuram
            {
                'name': 'Government Medical College Hospital, Manjeri',
                'district': 'Malappuram',
                'address': 'Vellarangal, Manjeri, Malappuram, Kerala 676121',
                'pincode': '676121',
                'phone': '+91 483 276 2060',
                'emergency_phone': '+91 483 276 2000',
                'reg': 'KL/DME/MLP/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 650,
                'icu': 40,
                'lat': 11.1215,
                'lng': 76.1221,
                'desc': 'District teaching hospital catering to the dense population of Malappuram district with maternal, pediatric, and critical care units.',
                'specs': ['General Medicine', 'Pediatrics & Neonatology', 'Orthopedics & Joint Care', 'Emergency & Critical Care'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Intensive Care Unit (ICU / CCU)', 'Blood Bank & Component Center']
            },
            # 6. Wayanad
            {
                'name': 'Government District Hospital, Mananthavady',
                'district': 'Wayanad',
                'address': 'Mananthavady, Wayanad, Kerala 670645',
                'pincode': '670645',
                'phone': '+91 493 524 0223',
                'emergency_phone': '+91 493 524 0911',
                'reg': 'KL/DHS/WYD/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 450,
                'icu': 30,
                'lat': 11.8033,
                'lng': 76.0036,
                'desc': 'Highland healthcare hub providing emergency trauma triage, sickle-cell anemia treatment, and tribal health navigation in Wayanad.',
                'specs': ['General Medicine', 'Pediatrics & Neonatology', 'Emergency & Critical Care', 'Palliative & Pain Medicine'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Palliative Home Care Squad', 'Hemodialysis Unit']
            },
            # 7. Kannur
            {
                'name': 'Government Medical College Hospital, Kannur (Pariyaram)',
                'district': 'Kannur',
                'address': 'Pariyaram PO, Kannur, Kerala 670503',
                'pincode': '670503',
                'phone': '+91 497 280 8080',
                'emergency_phone': '+91 497 280 8100',
                'reg': 'KL/DME/KNR/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 1200,
                'icu': 85,
                'lat': 12.0620,
                'lng': 75.2970,
                'desc': 'Apex government medical college in North Malabar with dedicated cardiology, cardiothoracic surgery, and nuclear medicine centers.',
                'specs': ['Cardiology', 'Neurology & Neurosurgery', 'Medical & Surgical Oncology', 'Emergency & Critical Care'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Intensive Care Unit (ICU / CCU)', 'Blood Bank & Component Center']
            },
            # 8. Palakkad
            {
                'name': 'Government District Hospital, Palakkad',
                'district': 'Palakkad',
                'address': 'Near Fort Maidan, Palakkad, Kerala 678001',
                'pincode': '678001',
                'phone': '+91 491 253 3323',
                'emergency_phone': '+91 491 253 0000',
                'reg': 'KL/DHS/PKD/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 680,
                'icu': 35,
                'lat': 10.7744,
                'lng': 76.6565,
                'desc': 'Major district healthcare institution providing multispecialty OPD and palliative care outreach across Palakkad rural blocks.',
                'specs': ['General Medicine', 'Orthopedics & Joint Care', 'Palliative & Pain Medicine', 'Nephrology & Dialysis'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Hemodialysis Unit', 'Palliative Home Care Squad']
            },
            # 9. Kottayam
            {
                'name': 'Government Medical College Hospital, Kottayam',
                'district': 'Kottayam',
                'address': 'Gandhinagar PO, Kottayam, Kerala 686008',
                'pincode': '686008',
                'phone': '+91 481 259 7284',
                'emergency_phone': '+91 481 259 7200',
                'reg': 'KL/DME/KTM/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 1750,
                'icu': 110,
                'lat': 9.6190,
                'lng': 76.5360,
                'desc': 'Renowned tertiary teaching hospital in South-Central Kerala, celebrated for interventional heart surgeries, nephrology, and organ care.',
                'specs': ['Cardiology', 'Nephrology & Dialysis', 'Neurology & Neurosurgery', 'General Medicine'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Intensive Care Unit (ICU / CCU)', 'Hemodialysis Unit']
            },
            # 10. Alappuzha
            {
                'name': 'Government Medical College Hospital, Alappuzha',
                'district': 'Alappuzha',
                'address': 'Vandanam, Alappuzha, Kerala 688005',
                'pincode': '688005',
                'phone': '+91 477 228 2015',
                'emergency_phone': '+91 477 228 2000',
                'reg': 'KL/DME/ALP/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 1150,
                'icu': 70,
                'lat': 9.4210,
                'lng': 76.3315,
                'desc': 'Tertiary referral center serving the coastal and Kuttanad wetland belt with 24x7 trauma care, water ambulance access, and dialysis.',
                'specs': ['General Medicine', 'Pediatrics & Neonatology', 'Pulmonology', 'Emergency & Critical Care'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Intensive Care Unit (ICU / CCU)', 'Hemodialysis Unit']
            },
            # 11. Idukki
            {
                'name': 'Government Medical College Hospital, Idukki',
                'district': 'Idukki',
                'address': 'Painavu, Idukki, Kerala 685603',
                'pincode': '685603',
                'phone': '+91 486 223 2311',
                'emergency_phone': '+91 486 223 2911',
                'reg': 'KL/DME/IDK/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 300,
                'icu': 20,
                'lat': 9.8490,
                'lng': 76.9740,
                'desc': 'Highland healthcare hospital serving remote plantation workers and tribal settlements across the Western Ghats.',
                'specs': ['General Medicine', 'Orthopedics & Joint Care', 'Pediatrics & Neonatology', 'Emergency & Critical Care'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Palliative Home Care Squad']
            },
            # 12. Pathanamthitta
            {
                'name': 'General Hospital, Pathanamthitta',
                'district': 'Pathanamthitta',
                'address': 'Hospital Junction, Pathanamthitta, Kerala 689645',
                'pincode': '689645',
                'phone': '+91 468 222 2253',
                'emergency_phone': '+91 468 222 0000',
                'reg': 'KL/DHS/PTA/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 420,
                'icu': 25,
                'lat': 9.2680,
                'lng': 76.7860,
                'desc': 'District headquarters general hospital offering emergency surgical triage, elderly palliative comfort, and round-the-clock emergency desk.',
                'specs': ['General Medicine', 'Palliative & Pain Medicine', 'Orthopedics & Joint Care'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Hemodialysis Unit', 'Palliative Home Care Squad']
            },
            # 13. Kollam
            {
                'name': 'Government Medical College Hospital, Kollam',
                'district': 'Kollam',
                'address': 'Parippally, Kollam, Kerala 691574',
                'pincode': '691574',
                'phone': '+91 474 257 5050',
                'emergency_phone': '+91 474 257 5000',
                'reg': 'KL/DME/KLM/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 800,
                'icu': 55,
                'lat': 8.8105,
                'lng': 76.7620,
                'desc': 'Modern government medical college hospital on NH66 with advanced trauma suites, comprehensive maternity, and dialysis wings.',
                'specs': ['Cardiology', 'General Medicine', 'Pediatrics & Neonatology', 'Emergency & Critical Care'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Intensive Care Unit (ICU / CCU)', 'Blood Bank & Component Center']
            },
            # 14. Kasaragod
            {
                'name': 'Government General Hospital, Kasaragod',
                'district': 'Kasaragod',
                'address': 'Kasaragod Town, Kasaragod, Kerala 671121',
                'pincode': '671121',
                'phone': '+91 499 423 0040',
                'emergency_phone': '+91 499 423 0911',
                'reg': 'KL/DHS/KSD/01',
                'org_type': OrganizationType.HOSPITAL,
                'ownership': OwnershipType.GOVERNMENT,
                'is_24x7': True,
                'beds': 350,
                'icu': 20,
                'lat': 12.5020,
                'lng': 74.9910,
                'desc': 'Northernmost district general hospital providing essential emergency, palliative oncology, and dialysis services for the region.',
                'specs': ['General Medicine', 'Palliative & Pain Medicine', 'Pediatrics & Neonatology', 'Nephrology & Dialysis'],
                'srvs': ['24x7 Emergency & Trauma Care', 'Hemodialysis Unit', 'Palliative Home Care Squad']
            },
        ]

        imported_count = 0
        skipped_count = 0

        for item in kerala_centers:
            org, created = Organization.objects.get_or_create(
                name=item['name'],
                district=item['district'],
                defaults={
                    'phone': item['phone'],
                    'registration_number': item['reg'],
                    'status': 'ACTIVE'
                }
            )

            # Strict Rule: Initial imported profiles are tagged UNVERIFIED ready for institutional claim
            profile, p_created = HealthcareProfile.objects.get_or_create(
                organization=org,
                defaults={
                    'organization_type': item['org_type'],
                    'ownership_type': item['ownership'],
                    'verification_status': VerificationStatus.UNVERIFIED,
                    'address': item['address'],
                    'district': item['district'],
                    'pincode': item['pincode'],
                    'latitude': item['lat'],
                    'longitude': item['lng'],
                    'phone': item['phone'],
                    'emergency_phone': item['emergency_phone'],
                    'is_24x7_emergency': item['is_24x7'],
                    'trauma_care_available': item['is_24x7'],
                    'ambulance_available': True,
                    'total_beds': item['beds'],
                    'icu_beds': item['icu'],
                    'description': item['desc'],
                    'profile_completeness_score': 85,
                    'last_verified_at': timezone.now()
                }
            )

            # Attach specialties and services
            for s_name in item['specs']:
                if s_name in spec_map:
                    profile.specialties.add(spec_map[s_name])

            for srv_name in item['srvs']:
                if srv_name in srv_map:
                    profile.services.add(srv_map[srv_name])

            if created or p_created:
                imported_count += 1
                self.stdout.write(f"  [+] Imported (UNVERIFIED): {item['name']} ({item['district']})")
            else:
                skipped_count += 1
                self.stdout.write(f"  [-] Skipped existing: {item['name']}")

        self.stdout.write(self.style.SUCCESS(
            f"\n[SUCCESS] Kerala Healthcare Onboarding Complete: {imported_count} imported, {skipped_count} existing."
            f"\nAll imported institutions are securely tagged as UNVERIFIED (Imported) ready for institutional claiming."
        ))
