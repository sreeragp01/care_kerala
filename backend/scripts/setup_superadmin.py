import os
import sys
import django

# Setup Django environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.authentication.models import User, UserRole
from apps.organizations.models import Organization
from rest_framework.test import APIClient

def setup_and_verify_superadmin():
    print("Provisioning Super Admin user...")
    
    # Remove old super admin
    User.objects.filter(email='mrtuf2204@gmail.com').delete()

    org = Organization.objects.first()
    if not org:
        org = Organization.objects.create(
            name='Kozhikode Palliative Care Society',
            district='Kozhikode',
            registration_number='KZD/NGO/2012/482',
            phone='+91 495 272 1000'
        )

    admin_email = os.getenv('SUPERADMIN_EMAIL', 'psreerag304@gmail.com')
    admin_pass = os.getenv('SUPERADMIN_PASSWORD', 'Sree321#')

    # Provision Super Admin
    super_admin, created = User.objects.get_or_create(
        username=admin_email,
        defaults={
            'email': admin_email,
            'first_name': 'Sreerag',
            'last_name': 'Admin',
            'role': UserRole.SUPER_ADMIN,
            'is_staff': True,
            'is_superuser': True,
            'organization': org,
            'district': 'Kozhikode',
            'phone': '+91 94470 00001',
        }
    )
    super_admin.email = admin_email
    super_admin.set_password(admin_pass)
    super_admin.is_staff = True
    super_admin.is_superuser = True
    super_admin.role = UserRole.SUPER_ADMIN
    super_admin.save()

    print(f"Super Admin provisioned: {super_admin.email} (Active: {super_admin.is_active}, Superuser: {super_admin.is_superuser})")

    # Verify JWT authentication with email and password
    print(f"Verifying JWT Login for {admin_email}...")
    client = APIClient()
    response = client.post('/api/auth/login/', {
        'username': admin_email,
        'password': admin_pass
    })

    if response.status_code == 200:
        data = response.data
        print("[SUCCESS] JWT Auth SUCCESSFUL!")
        print(f"  Access Token generated: {data.get('access')[:25]}...")
        print(f"  User payload: {data.get('user')}")
        return True
    else:
        print(f"[FAIL] JWT Auth FAILED: Status {response.status_code}, Body: {response.data}")
        return False

if __name__ == '__main__':
    success = setup_and_verify_superadmin()
    if not success:
        sys.exit(1)
