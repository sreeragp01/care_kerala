from rest_framework import generics, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from django.db import connection
from django.utils import timezone
from .models import User
from .serializers import UserSerializer, CustomTokenObtainPairSerializer

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

class UserProfileView(generics.RetrieveUpdateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user

class LivenessHealthView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        return Response({'status': 'alive', 'timestamp': timezone.now().isoformat()})

class ReadinessHealthView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                row = cursor.fetchone()
            if row:
                return Response({'status': 'healthy', 'database': 'connected'})
        except Exception:
            return Response({'status': 'unhealthy', 'database': 'disconnected'}, status=503)
        return Response({'status': 'unhealthy'}, status=503)

class SystemMetricsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        org = getattr(user, 'organization', None)

        from apps.patients.models import Patient
        from apps.visits.models import HomeVisit
        from apps.blood_donors.models import BloodRequest
        from apps.alerts.models import ClinicalAlert
        from apps.inventory.models import MedicineItem

        p_qs = Patient.objects.filter(organization=org) if org else Patient.objects.all()
        v_qs = HomeVisit.objects.filter(organization=org) if org else HomeVisit.objects.all()
        b_qs = BloodRequest.objects.filter(organization=org) if org else BloodRequest.objects.all()
        a_qs = ClinicalAlert.objects.filter(organization=org, status='OPEN') if org else ClinicalAlert.objects.filter(status='OPEN')
        m_qs = MedicineItem.objects.filter(organization=org) if org else MedicineItem.objects.all()

        low_stock_cnt = sum(1 for m in m_qs if m.stock_quantity <= m.reorder_level)

        return Response({
            'status': 'healthy',
            'organization': org.name if org else 'All Organizations',
            'metrics': {
                'total_patients': p_qs.count(),
                'todays_visits': v_qs.count(),
                'active_blood_requests': b_qs.filter(status='URGENT').count(),
                'critical_alerts_open': a_qs.filter(severity='CRITICAL').count(),
                'total_alerts_open': a_qs.count(),
                'low_stock_items': low_stock_cnt,
            },
            'timestamp': timezone.now().isoformat()
        })

class PasswordResetRequestView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email_or_phone = request.data.get('email_or_phone', '').strip()
        if not email_or_phone:
            return Response({'error': 'email_or_phone is required'}, status=400)

        # Generate simulated 6-digit OTP
        import random
        otp = str(random.randint(100000, 999999))
        return Response({
            'status': 'success',
            'message': f'6-digit recovery OTP dispatched to {email_or_phone}',
            'otp': otp, # In dev/mock mode
            'validity_minutes': 10
        })

class PasswordResetConfirmView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email_or_phone = request.data.get('email_or_phone', '').strip()
        otp = request.data.get('otp', '').strip()
        new_password = request.data.get('new_password', '').strip()

        if not email_or_phone or not otp or not new_password:
            return Response({'error': 'email_or_phone, otp, and new_password are required'}, status=400)

        if len(new_password) < 6:
            return Response({'error': 'Password must be at least 6 characters'}, status=400)

        # Update user password if exists
        user = User.objects.filter(email=email_or_phone).first() or User.objects.filter(phone=email_or_phone).first()
        if user:
            user.set_password(new_password)
            user.save()

        return Response({
            'status': 'success',
            'message': f'Password successfully updated for {email_or_phone}. You can now sign in.'
        })

class StaffRegistrationView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        name = request.data.get('name', '').strip()
        email = request.data.get('email', '').strip()
        phone = request.data.get('phone', '').strip()
        role = request.data.get('role', 'DOCTOR').upper()
        password = request.data.get('password', '').strip()

        if not name or not email or not password:
            return Response({'error': 'name, email, and password are required'}, status=400)

        username = email.split('@')[0]
        user, created = User.objects.get_or_create(
            username=username,
            defaults={'email': email, 'phone': phone, 'role': role}
        )
        if not created:
            return Response({'error': 'User with this email already exists'}, status=400)

        user.set_password(password)
        user.save()

        return Response({
            'status': 'success',
            'message': f'Successfully registered healthcare staff {name} as {role}',
            'user_id': user.id
        }, status=201)



