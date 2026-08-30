import os
import sys
from pathlib import Path

# Setup Django environment
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

import django
django.setup()

from django.db import connection
from apps.authentication.models import User
from apps.organizations.models import Organization
from apps.patients.models import Patient

def verify_live_database():
    print("=" * 65)
    print("CareLink Kerala — Live Database & Supabase Verification")
    print("=" * 65)
    
    settings_db = connection.settings_dict
    engine = settings_db.get('ENGINE', '')
    host = settings_db.get('HOST', 'localhost')
    port = settings_db.get('PORT', '')
    name = settings_db.get('NAME', '')
    user = settings_db.get('USER', '')

    is_supabase = 'supabase.co' in host or 'supabase.com' in host or 'pooler.supabase.com' in host
    is_postgres = 'postgresql' in engine

    print(f"• Database Engine : {engine}")
    print(f"• Active Host     : {host}:{port}")
    print(f"• Database Name   : {name}")
    print(f"• Active User     : {user}")
    print(f"• Supabase Cloud  : {'YES (Connected to Supabase)' if is_supabase else 'NO (Local / Alternative Database)'}")
    print("-" * 65)

    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT version();" if is_postgres else "SELECT sqlite_version();")
            version_row = cursor.fetchone()
            print(f"[OK] Database Query Successful!")
            print(f"     Version: {version_row[0][:60]}...")
            
            # Inspect existing tables
            if is_postgres:
                cursor.execute("""
                    SELECT table_name 
                    FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    ORDER BY table_name;
                """)
                tables = [row[0] for row in cursor.fetchall()]
            else:
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
                tables = [row[0] for row in cursor.fetchall()]

        print(f"\n• Tables Found ({len(tables)} tables):")
        carelink_tables = [t for t in tables if any(t.startswith(prefix) for prefix in ['auth', 'org', 'pat', 'vis', 'blo', 'inv', 'fin', 'ale'])]
        for t in carelink_tables:
            print(f"   - {t}")

        if len(carelink_tables) == 0:
            print("\n[WARNING] No CareLink tables found! You must run:")
            print("          py manage.py migrate")
            return False

        # Check Seeded Super Admin
        admin = User.objects.filter(email='psreerag304@gmail.com').first()
        if admin:
            print(f"\n[OK] Super Admin Found: {admin.email} (Role: {admin.role}, Superuser: {admin.is_superuser})")
        else:
            print("\n[NOTICE] Super Admin psreerag304@gmail.com not yet seeded. Run:")
            print("         py manage.py seed_superadmin")

        print("=" * 65)
        print("Live Database Verification Status: 100% READY")
        print("=" * 65)
        return True

    except Exception as e:
        print(f"\n[ERROR] Database connection failed: {e}")
        print("\nTroubleshooting tips:")
        print("1. Check that your password is correct in DATABASE_URL")
        print("2. Ensure you are using Port 5432 (Session mode) for running migrations")
        print("3. Check that your network allows outgoing PostgreSQL connections on port 5432/6543")
        return False

if __name__ == '__main__':
    verify_live_database()
