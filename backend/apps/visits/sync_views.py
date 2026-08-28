from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from apps.patients.models import Patient, VitalsReading
from apps.visits.models import HomeVisit, VisitStatus
from .views import HomeVisitSerializer
from apps.patients.serializers import PatientSerializer

class SyncPushView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        org = getattr(user, 'organization', None)
        operations = request.data.get('operations', [])
        accepted = []
        failed = []

        for op in operations:
            try:
                op_type = op.get('operation')
                local_id = op.get('local_id')
                data = op.get('data', {})

                if op_type == 'CREATE_VISIT':
                    patient_id = data.get('patient_id')
                    patient = Patient.objects.get(id=patient_id, organization=org)
                    sched_date = data.get('scheduled_date', timezone.now().date())
                    visit, created = HomeVisit.objects.get_or_create(
                        organization=org,
                        patient=patient,
                        scheduled_date=sched_date,
                        defaults={
                            'assigned_nurse_name': data.get('assigned_nurse_name', user.username),
                            'scheduled_time': data.get('scheduled_time', '10:00 AM'),
                            'status': VisitStatus.SCHEDULED,
                            'is_synced_offline': True
                        }
                    )
                    accepted.append({'local_id': local_id, 'server_id': visit.id, 'entity': 'visit', 'is_new': created})


                elif op_type == 'ADD_VITALS':
                    patient_id = data.get('patient_id')
                    patient = Patient.objects.get(id=patient_id, organization=org)
                    vitals = VitalsReading.objects.create(
                        patient=patient,
                        bp=data.get('bp', '120/80'),
                        pulse=data.get('pulse', 72),
                        spo2=data.get('spo2', 98),
                        temperature=data.get('temperature', 98.6),
                        pain_scale=data.get('pain_scale', 0),
                        respiratory_rate=data.get('respiratory_rate', 16),
                        recorded_by=user.username
                    )
                    accepted.append({'local_id': local_id, 'server_id': vitals.id, 'entity': 'vitals'})

                elif op_type == 'COMPLETE_VISIT':
                    server_id = data.get('server_id')
                    visit = HomeVisit.objects.get(id=server_id, organization=org)
                    visit.status = VisitStatus.COMPLETED
                    visit.symptoms_observed = data.get('symptoms_observed', '')
                    visit.assessment_notes = data.get('assessment_notes', '')
                    visit.care_provided = data.get('care_provided', '')
                    visit.medication_administered = data.get('medication_administered', '')
                    visit.equipment_used = data.get('equipment_used', '')
                    visit.follow_up_instructions = data.get('follow_up_instructions', '')
                    visit.clinical_notes = data.get('clinical_notes', '')
                    visit.save()
                    accepted.append({'local_id': local_id, 'server_id': visit.id, 'entity': 'visit'})

            except Exception as e:
                failed.append({'local_id': op.get('local_id'), 'error': str(e)})

        return Response({
            'status': 'success',
            'accepted': accepted,
            'failed': failed,
            'synced_at': timezone.now().isoformat()
        })

class SyncPullView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        org = getattr(user, 'organization', None)

        patients = Patient.objects.filter(organization=org) if org else Patient.objects.none()
        visits = HomeVisit.objects.filter(organization=org) if org else HomeVisit.objects.none()

        return Response({
            'patients': PatientSerializer(patients, many=True).data,
            'visits': HomeVisitSerializer(visits, many=True).data,
            'synced_at': timezone.now().isoformat()
        })
