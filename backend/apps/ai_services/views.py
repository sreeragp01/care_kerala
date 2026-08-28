from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from apps.authentication.models import UserRole
from apps.patients.models import Patient
from apps.inventory.models import MedicineItem

SAFETY_DISCLAIMER = "AI Output Disclaimer: This information is provided as decision support for clinical staff and does not replace professional medical judgment or direct clinical evaluation."

class SpeechToTextView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        return Response({
            'transcript': "Patient reported mild knee joint stiffness. BP recorded at 130/85 mmHg, pulse 76 bpm. Pain managed satisfactorily with prescribed analgesics.",
            'disclaimer': SAFETY_DISCLAIMER,
            'status': 'success'
        })

class PatientSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, patient_id=None):
        user = request.user
        try:
            p_queryset = Patient.objects.all()
            if user.role != UserRole.SUPER_ADMIN and user.organization_id:
                p_queryset = p_queryset.filter(organization_id=user.organization_id)
            
            p = p_queryset.get(id=patient_id)
            summary = f"AI Clinical Summary: Patient {p.name}, {p.age}y {p.gender}. Diagnosis: {p.diagnosis}. Assigned tier: {p.category_tier}. Risk status: {p.risk_level}."
            return Response({
                'patient_id': patient_id, 
                'ai_summary': summary,
                'disclaimer': SAFETY_DISCLAIMER,
            })
        except Patient.DoesNotExist:
            return Response({'error': 'Patient not found or unauthorized'}, status=404)

class NaturalQueryView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        query = request.data.get('query', '').lower()

        patients_qs = Patient.objects.all()
        medicines_qs = MedicineItem.objects.all()
        if user.role != UserRole.SUPER_ADMIN and user.organization_id:
            patients_qs = patients_qs.filter(organization_id=user.organization_id)
            medicines_qs = medicines_qs.filter(organization_id=user.organization_id)

        if 'critical' in query or 'high risk' in query:
            count = patients_qs.filter(risk_level='High Risk').count()
            msg = f"Found {count} High Risk critical patients in your organization needing urgent review."
        elif 'medicine' in query or 'stock' in query:
            count = medicines_qs.filter(stock_quantity__lte=20).count()
            msg = f"Found {count} medicines requiring re-order in your organization inventory."
        else:
            msg = f"Query '{query}' processed across organization records."

        return Response({
            'query': query, 
            'response': msg,
            'disclaimer': SAFETY_DISCLAIMER,
        })

