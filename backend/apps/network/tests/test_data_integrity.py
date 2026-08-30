from django.test import TestCase
from django.db import IntegrityError
from django.utils import timezone
from datetime import timedelta
from apps.organizations.models import Organization
from apps.network.models import (
    Specialty,
    HealthcareProfile,
    Doctor,
    DoctorAffiliation,
    DoctorSchedule,
)

class NetworkDataIntegrityTests(TestCase):
    """Database integrity, constraints, schedule validation, and freshness engine tests"""

    def setUp(self):
        self.org = Organization.objects.create(
            name='Aster MIMS Calicut',
            district='Kozhikode',
            phone='+914952700000',
            registration_number='MIMS/2024/01',
            status='ACTIVE'
        )
        self.specialty = Specialty.objects.create(
            name='Oncology & Palliative Care',
            category='Clinical Specialty'
        )
        self.profile = HealthcareProfile.objects.create(
            organization=self.org,
            organization_type='HOSPITAL',
            verification_status='VERIFIED',
            district='Kozhikode',
            phone=self.org.phone,
            last_verified_at=timezone.now()
        )
        self.doctor = Doctor.objects.create(
            name='Dr. Narayanan Kutty',
            qualification='MBBS, MS, DNB',
            primary_specialty=self.specialty,
            registration_number='TCMC/44123/KL'
        )

    def test_duplicate_doctor_affiliation_prevented(self):
        """Cannot create duplicate affiliation for the same doctor at the same hospital"""
        DoctorAffiliation.objects.create(
            doctor=self.doctor,
            organization=self.org,
            designation='Consultant'
        )
        with self.assertRaises(IntegrityError):
            DoctorAffiliation.objects.create(
                doctor=self.doctor,
                organization=self.org,
                designation='Senior Consultant'
            )

    def test_doctor_can_practice_at_multiple_hospitals(self):
        """Doctor CAN practice at two different hospitals with distinct affiliations"""
        org2 = Organization.objects.create(
            name='Baby Memorial Hospital',
            district='Kozhikode',
            phone='+914952800000',
            registration_number='BMH/2024/02'
        )
        aff1 = DoctorAffiliation.objects.create(
            doctor=self.doctor,
            organization=self.org,
            designation='Visiting Specialist'
        )
        aff2 = DoctorAffiliation.objects.create(
            doctor=self.doctor,
            organization=org2,
            designation='Head of Oncology'
        )
        self.assertNotEqual(aff1.id, aff2.id)
        self.assertEqual(self.doctor.affiliations.count(), 2)

    def test_schedule_validation_rejects_identical_times(self):
        """Schedule clean() rejects identical start and end times"""
        from django.core.exceptions import ValidationError
        aff = DoctorAffiliation.objects.create(
            doctor=self.doctor,
            organization=self.org
        )
        schedule = DoctorSchedule(
            affiliation=aff,
            day_of_week='MONDAY',
            start_time='10:00 AM',
            end_time='10:00 AM'
        )
        with self.assertRaises(ValidationError):
            schedule.clean()

    def test_data_freshness_engine_tiers(self):
        """Data freshness engine correctly transitions between 4 tiers based on elapsed days"""
        # Tier 1: Verified today -> CURRENT (0-30 days)
        self.profile.last_verified_at = timezone.now()
        self.assertEqual(self.profile.data_freshness_tier, 'CURRENT')

        # Tier 2: Verified 45 days ago -> REVIEW_RECOMMENDED (31-90 days)
        self.profile.last_verified_at = timezone.now() - timedelta(days=45)
        self.assertEqual(self.profile.data_freshness_tier, 'REVIEW_RECOMMENDED')

        # Tier 3: Verified 120 days ago -> VERIFICATION_REQUIRED (90+ days)
        self.profile.last_verified_at = timezone.now() - timedelta(days=120)
        self.assertEqual(self.profile.data_freshness_tier, 'VERIFICATION_REQUIRED')

        # Tier 4: Unverified status -> UNVERIFIED
        self.profile.verification_status = 'UNVERIFIED'
        self.assertEqual(self.profile.data_freshness_tier, 'UNVERIFIED')

    def test_negative_beds_validation_error(self):
        """HealthcareProfile full_clean() rejects negative total beds or ICU beds"""
        from django.core.exceptions import ValidationError
        self.profile.total_beds = -50
        with self.assertRaises(ValidationError):
            self.profile.full_clean()

    def test_duplicate_doctor_detection_by_registration_number(self):
        """Doctor registration number matching signals potential duplicates"""
        existing_doc = Doctor.objects.filter(registration_number='TCMC/44123/KL').first()
        self.assertIsNotNone(existing_doc)
        # Attempting to query with same registration number finds the existing doctor
        matches = Doctor.objects.filter(registration_number='TCMC/44123/KL')
        self.assertEqual(matches.count(), 1)
        self.assertEqual(matches.first().name, 'Dr. Narayanan Kutty')
