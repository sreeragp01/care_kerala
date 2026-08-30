from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from apps.network.models import HealthcareProfile, VerificationStatus

class Command(BaseCommand):
    help = 'Evaluates data freshness for all CareLink Network healthcare profiles and flags stale or expired entries'

    def handle(self, *args, **options):
        now = timezone.now()
        thirty_days_ago = now - timedelta(days=30)
        ninety_days_ago = now - timedelta(days=90)
        one_eighty_days_ago = now - timedelta(days=180)

        total = HealthcareProfile.objects.count()
        current_count = 0
        review_count = 0
        reverify_count = 0
        expired_count = 0

        self.stdout.write(self.style.NOTICE("[SCAN] Scanning CareLink Network profiles for data freshness..."))

        for profile in HealthcareProfile.objects.all():
            if not profile.last_verified_at or profile.verification_status != VerificationStatus.VERIFIED:
                expired_count += 1
            elif profile.last_verified_at >= thirty_days_ago:
                current_count += 1
            elif profile.last_verified_at >= ninety_days_ago:
                review_count += 1
            elif profile.last_verified_at >= one_eighty_days_ago:
                reverify_count += 1
            else:
                expired_count += 1
                # Auto-transition profiles older than 180 days to UNVERIFIED for re-audit
                profile.verification_status = VerificationStatus.UNVERIFIED
                profile.save(update_fields=['verification_status'])
                self.stdout.write(f"  [!] Expired verification for {profile.organization.name} -> Marked UNVERIFIED")

        self.stdout.write(self.style.SUCCESS(
            f"\n[METRICS] Freshness Evaluation Results (Total: {total}):\n"
            f"  [Tier 1 - Current (0-30d)]: {current_count}\n"
            f"  [Tier 2 - Review Recommended (31-90d)]: {review_count}\n"
            f"  [Tier 3 - Re-verification Required (91-180d)]: {reverify_count}\n"
            f"  [Tier 4 - Unverified / Expired (>180d)]: {expired_count}\n"
        ))
