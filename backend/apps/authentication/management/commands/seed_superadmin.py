from django.core.management.base import BaseCommand
from apps.authentication.models import User, UserRole
from apps.organizations.models import Organization

class Command(BaseCommand):
    help = 'Seeds the production Super Admin user (psreerag304@gmail.com)'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE('Provisioning Super Admin user for CareLink Kerala...'))
        
        # Remove old super admin account if present
        deleted_count, _ = User.objects.filter(email='mrtuf2204@gmail.com').delete()
        if deleted_count:
            self.stdout.write(self.style.WARNING(f'Removed old super admin mrtuf2204@gmail.com ({deleted_count} record(s)).'))

        org, _ = Organization.objects.get_or_create(
            name='Kozhikode Palliative Care Society',
            defaults={
                'district': 'Kozhikode',
                'registration_number': 'KZD/NGO/2012/482',
                'phone': '+91 495 272 1000'
            }
        )

        import os
        admin_email = os.getenv('SUPERADMIN_EMAIL', 'psreerag304@gmail.com')
        admin_pass = os.getenv('SUPERADMIN_PASSWORD', 'Sree321#')

        user, created = User.objects.get_or_create(
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

        user.email = admin_email
        user.set_password(admin_pass)
        user.is_staff = True
        user.is_superuser = True
        user.role = UserRole.SUPER_ADMIN
        user.save()

        action = 'Created' if created else 'Updated'
        self.stdout.write(self.style.SUCCESS(
            f'Successfully {action} Super Admin: {admin_email}'
        ))
