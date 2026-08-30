import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/network_models.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/glass_card.dart';

class PlatformNetworkAdminScreen extends StatelessWidget {
  final AppStateProvider state;

  const PlatformNetworkAdminScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final isDark = state.isDarkMode;
        final allHospitals = state.healthcareProfiles;
        final verifiedCount = allHospitals.where((h) => h.isCareLinkVerified).length;
        final pendingCount = allHospitals.where((h) => !h.isCareLinkVerified).length;
        final pendingClaims = state.claimRequests.where((c) => c.status == 'PENDING').toList();

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CareLink Platform Network Center',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Super Admin Governance & Verification Console',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildMetricCard('Total Institutions', '${allHospitals.length}', Icons.apartment_rounded, AppColors.brandNavy, isDark),
                    const SizedBox(width: 8),
                    _buildMetricCard('Verified 🟢', '$verifiedCount', Icons.verified_rounded, AppColors.brandHealthGreen, isDark),
                    const SizedBox(width: 8),
                    _buildMetricCard('Claims Queue', '${pendingClaims.length}', Icons.how_to_reg_rounded, Colors.purpleAccent, isDark),
                  ],
                ),
                const SizedBox(height: 16),

                // Organization Claims Review Queue
                if (pendingClaims.isNotEmpty) ...[
                  _buildSectionTitle('Organization Ownership Claims (${pendingClaims.length} Pending)', isDark),
                  const SizedBox(height: 8),
                  ...pendingClaims.map((claim) => _buildClaimCard(context, claim, state, isDark)),
                  const SizedBox(height: 16),
                ],

                _buildSectionTitle('Kerala District Health Coverage', isDark),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildDistrictCoverageRow('Kozhikode', 2, 450, isDark),
                      _buildDistrictCoverageRow('Ernakulam', 1, 60, isDark),
                      _buildDistrictCoverageRow('Wayanad', 1, 120, isDark),
                      _buildDistrictCoverageRow('Thiruvananthapuram', 1, 200, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Institutional Verification Queue ($pendingCount Pending)', isDark),
                const SizedBox(height: 8),
                if (pendingCount == 0)
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 36, color: AppColors.brandHealthGreen),
                          const SizedBox(height: 8),
                          Text(
                            'All healthcare institutions are fully verified and up to date.',
                            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...allHospitals.where((h) => !h.isCareLinkVerified).map((h) => _buildPendingOrgCard(context, h, state, isDark)),
                const SizedBox(height: 20),
                _buildSectionTitle('Active Verified Institutions', isDark),
                const SizedBox(height: 8),
                ...allHospitals.where((h) => h.isCareLinkVerified).map((h) => _buildVerifiedOrgCard(h, isDark)),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClaimCard(BuildContext context, ClaimOrganizationRequestModel claim, AppStateProvider state, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Claim for "${claim.organizationName}"',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Claim Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Claimant: @${claim.claimantUsername} • Designation: ${claim.claimantDesignation}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.brandTeal : AppColors.brandNavy),
          ),
          Text(
            'Email: ${claim.officialEmail} • Phone: ${claim.officialPhone}',
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 14, color: AppColors.brandTeal),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Proof: ${claim.proofDocumentUrl}',
                  style: const TextStyle(fontSize: 11, color: Colors.blueAccent, decoration: TextDecoration.underline),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => state.rejectClaimRequest(claim.id),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('Reject Claim', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => state.approveClaimRequest(claim.id),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandHealthGreen),
                  child: const Text('Approve & Assign Admin', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictCoverageRow(String district, int count, int totalBeds, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: AppColors.brandTeal),
              const SizedBox(width: 6),
              Text(
                district,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            '$count centers • $totalBeds beds',
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOrgCard(BuildContext context, HealthcareProfileModel h, AppStateProvider state, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  h.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Under Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${h.organizationType} • ${h.district} • Contact: ${h.phone}',
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            h.description,
            maxLines: 2,
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Request for clarification sent to ${h.name}.')),
                    );
                  },
                  child: const Text('Request Docs', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.brandHealthGreen,
                        content: Text('Institutional application for "${h.name}" approved. Verified badge issued!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandHealthGreen),
                  child: const Text('Approve & Verify', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedOrgCard(HealthcareProfileModel h, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.local_hospital_rounded, color: AppColors.brandTeal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${h.district} • ${h.organizationType} • ${h.totalBeds} Beds',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brandHealthGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandHealthGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
    );
  }
}
