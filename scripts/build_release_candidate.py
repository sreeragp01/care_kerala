import os
import sys
import subprocess

PYTHON_EXE = r"C:\Users\SREERAG\AppData\Local\Programs\Python\Python314\python.exe"

def run_command(cmd, cwd=None):
    print(f"\n[EXEC] {cmd}")
    result = subprocess.run(cmd, shell=True, cwd=cwd)
    if result.returncode != 0:
        print(f"[FAIL] Command failed with return code {result.returncode}: {cmd}")
        sys.exit(result.returncode)
    print("[OK] Passed!")

def build_release_candidate():
    print("==============================================================")
    print("CareLink Kerala — Release Candidate Build & Quality Gate")
    print("==============================================================")

    # 1. Run Django Backend Test Suite
    run_command(f'"{PYTHON_EXE}" manage.py test apps.authentication apps.patients apps.visits apps.inventory apps.blood_donors apps.finance apps.alerts', cwd="backend")

    # 2. Run Production Smoke & Clinical Safety Gate Test
    run_command(f'"{PYTHON_EXE}" scripts/production_smoke_test.py', cwd="backend")


    # 3. Run Flutter Unit & Widget Tests
    run_command('flutter test')

    # 4. Run Flutter Static Analysis
    run_command('flutter analyze')

    print("\n==============================================================")
    print("CareLink Kerala — Release Candidate Quality Gate: 100% PASSED")
    print("Application is approved for Production Deployment.")
    print("==============================================================")

if __name__ == '__main__':
    build_release_candidate()
