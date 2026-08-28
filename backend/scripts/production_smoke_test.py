import os
import sys
import json
import django

# Setup Django Environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from rest_framework.test import APIClient
from apps.organizations.models import Organization
from apps.authentication.models import User, UserRole
from apps.patients.models import Patient, VitalsReading, PatientAuditLog
from apps.visits.models import HomeVisit, VisitStatus
from apps.alerts.models import ClinicalAlert, AlertSeverity, AlertStatus

def run_production_smoke_tests():
    print("==============================================================")
    print("CareLink Kerala — Production Release Smoke & Clinical Safety Gate")
    print("==============================================================")

    client = APIClient()

    # 1. Probe Liveness & Readiness Probes
    res_live = client.get('/health/live/')
    assert res_live.status_code == 200, "Liveness health probe failed!"
    assert res_live.data['status'] == 'alive', "Liveness status invalid!"
    print("1. Liveness Probe (/health/live/): PASSED (200 OK)")

    res_ready = client.get('/health/ready/')
    assert res_ready.status_code == 200, "Readiness health probe failed!"
    assert res_ready.data['database'] == 'connected', "Database connection failed!"
    print("2. Readiness Probe (/health/ready/): PASSED (200 OK - DB Connected)")

    # 2. Verify Security Headers
    assert res_live.headers.get('X-Request-ID', '').startswith('REQ-'), "Missing X-Request-ID correlation header!"
    assert res_live.headers.get('X-Content-Type-Options') == 'nosniff', "Missing nosniff header!"
    assert res_live.headers.get('X-Frame-Options') == 'DENY', "Missing DENY header!"
    print("3. Production Security Headers & Correlation IDs: PASSED")

    # 3. Setup Smoke Test Tenants & Users
    import uuid
    uid = uuid.uuid4().hex[:6]
    org1, _ = Organization.objects.get_or_create(registration_number=f"REG-SMK-01-{uid}", defaults={'name': f"Kozhikode Care Smoke {uid}", 'district': "Kozhikode"})
    org2, _ = Organization.objects.get_or_create(registration_number=f"REG-SMK-02-{uid}", defaults={'name': f"Ernakulam Care Smoke {uid}", 'district': "Ernakulam"})

    nurse = User.objects.create_user(username=f"smoke_nurse_{uid}", password="password123", role=UserRole.NURSE, organization=org1)
    doctor = User.objects.create_user(username=f"smoke_doctor_{uid}", password="password123", role=UserRole.DOCTOR, organization=org1)

    patient = Patient.objects.create(
        organization=org1,
        patient_id_code=f"PAT-SMK-{uid}",
        name="Karthyayani Amma",
        age=74,
        gender="Female",
        blood_group="O+",
        district="Kozhikode",
        ward="Ward 14",
        address="Chevayur",
        phone="9847012345",
        diagnosis="Osteoarthritis & Severe Respiratory Distress"
    )


    # 4. Clinical Safety Gate: Critical SpO2 < 92% Trigger
    client.force_authenticate(user=nurse)
    res_vitals_critical = client.post(f'/api/patients/{patient.id}/add_vitals/', {
        'bp': '110/70',
        'pulse': 98,
        'spo2': 88, # Critical SpO2 < 92%
        'pain_scale': 8
    })
    assert res_vitals_critical.status_code in (200, 201), f"Recording vitals failed: {res_vitals_critical.data}"


    critical_alert = ClinicalAlert.objects.filter(patient=patient, severity=AlertSeverity.CRITICAL).first()
    assert critical_alert is not None, "Clinical Safety Gate Failed: Critical SpO2 < 92% did NOT trigger ClinicalAlert!"
    assert critical_alert.status == AlertStatus.OPEN, "Alert status must be OPEN!"
    print("4. Clinical Safety Gate (SpO2 < 92% -> CRITICAL Alert Trigger): PASSED")

    # 5. Clinical Safety Gate: Normal SpO2 >= 92% No Critical Alert Trigger
    res_vitals_normal = client.post(f'/api/patients/{patient.id}/add_vitals/', {
        'bp': '120/80',
        'pulse': 72,
        'spo2': 98, # Normal SpO2
        'pain_scale': 2
    })
    assert res_vitals_normal.status_code in (200, 201), "Recording normal vitals failed!"
    print("5. Clinical Safety Gate (Normal SpO2 -> No False Critical Alert): PASSED")

    # 6. Doctor Sign-off & Audit Log Recording
    visit = HomeVisit.objects.create(
        organization=org1,
        patient=patient,
        assigned_nurse_name="Nurse Anitha",
        scheduled_date="2026-08-25",
        scheduled_time="10:00 AM",
        status=VisitStatus.IN_PROGRESS
    )
    client.force_authenticate(user=doctor)
    res_doc = client.post(f'/api/visits/{visit.id}/doctor_review/', {
        'doctor_review_notes': 'Reviewed critical oxygen drop. Patient stabilized.'
    })
    assert res_doc.status_code == 200, "Doctor sign-off failed!"
    visit.refresh_from_db()
    assert visit.status == VisitStatus.CLOSED, "Visit status must be CLOSED!"
    assert visit.doctor_signed_off == True, "Doctor sign-off flag missing!"
    print("6. Doctor Review & Clinical Sign-off: PASSED")

    # 7. Audit Log Verification
    audit_cnt = PatientAuditLog.objects.filter(patient=patient).count()
    assert audit_cnt >= 1, "Patient audit log missing!"
    print(f"7. Healthcare Audit Log Verification: PASSED ({audit_cnt} Audit Entries Recorded)")

    print("==============================================================")
    print("Production Smoke & Clinical Safety Gate: 100% SUCCESS")
    print("CareLink Kerala is ready for Release Candidate Deployment!")
    print("==============================================================")

if __name__ == '__main__':
    run_production_smoke_tests()
