import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/network_models.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/glass_card.dart';
import 'doctor_detail_screen.dart';

class HospitalDetailScreen extends StatelessWidget {
  final HealthcareProfileModel hospital;
  final AppStateProvider state;

  const HospitalDetailScreen({super.key, required this.hospital, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final isDark = state.isDarkMode;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandNavy,
                          AppColors.brandNavy.withValues(alpha: 0.85),
                          isDark ? AppColors.darkBackground : AppColors.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (hospital.dataFreshnessTier == 'CURRENT' ? AppColors.brandHealthGreen : Colors.orangeAccent).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: hospital.dataFreshnessTier == 'CURRENT' ? AppColors.brandHealthGreen : Colors.orangeAccent),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 14, color: hospital.dataFreshnessTier == 'CURRENT' ? AppColors.brandHealthGreen : Colors.orangeAccent),
                                    const SizedBox(width: 4),
                                    Text(
                                      hospital.dataFreshnessLabel,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (hospital.is24x7Emergency)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.redAccent),
                                  ),
                                  child: const Text(
                                    '24x7 Emergency',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hospital.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${hospital.organizationType} • ${hospital.district}, Kerala',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActionButtons(context, isDark),
                      const SizedBox(height: 14),

                      // Clinical Safety & Real-Time Availability Disclaimer
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.brandNavy : AppColors.brandPeaceBlue).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.brandTeal.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.shield_outlined, size: 18, color: AppColors.brandTeal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CareLink Verified Profile',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.brandNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Institutional infrastructure, specialties, and emergency lines are verified with Kerala health authorities. For live ICU bed availability and immediate emergency admission, please call the 24x7 desk directly.',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      height: 1.35,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Capacity & Infrastructure', isDark),
                      const SizedBox(height: 8),
                      _buildCapacityGrid(isDark),
                      const SizedBox(height: 16),
                      _buildSectionTitle('About Healthcare Center', isDark),
                      const SizedBox(height: 8),
                      GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          hospital.description,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Verified Doctors & OPD Schedules (${hospital.doctors.length})', isDark),
                      const SizedBox(height: 8),
                      if (hospital.doctors.isEmpty)
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'No doctors currently listed under this hospital center.',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...hospital.doctors.map((d) => _buildDoctorRow(context, d, isDark)),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Specialties & Clinical Departments', isDark),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hospital.specialties.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.brandNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.brandNavy.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.brandPeaceBlue : AppColors.brandNavy,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Services & Amenities', isDark),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hospital.services.map((srv) {
                          return Chip(
                            avatar: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.brandTeal),
                            label: Text(srv, style: const TextStyle(fontSize: 11)),
                            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
                            side: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      _buildFreshnessFooter(context, isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dialing ${hospital.phone}...')),
              );
            },
            icon: const Icon(Icons.phone_rounded, size: 16, color: Colors.white),
            label: const Text('Call Desk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandNavy,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (hospital.emergencyPhone.isNotEmpty)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text('Emergency Call: ${hospital.emergencyPhone}'),
                  ),
                );
              },
              icon: const Icon(Icons.emergency_rounded, size: 16, color: Colors.white),
              label: const Text('24x7 SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCapacityGrid(bool isDark) {
    return Row(
      children: [
        _buildStatCard('Total Beds', '${hospital.totalBeds}', Icons.bed_rounded, AppColors.brandNavy, isDark),
        const SizedBox(width: 8),
        _buildStatCard('ICU / CCU', '${hospital.icuBeds}', Icons.monitor_heart_rounded, AppColors.brandTeal, isDark),
        const SizedBox(width: 8),
        _buildStatCard('Ambulance', hospital.ambulanceAvailable ? 'Available' : 'No', Icons.airport_shuttle_rounded, AppColors.brandHealthGreen, isDark),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorRow(BuildContext context, DoctorModel doctor, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doctor, state: state)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.brandTeal.withValues(alpha: 0.15),
              child: Text(
                doctor.name.split(' ').length > 1 ? doctor.name.split(' ')[1][0] : 'D',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandTeal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${doctor.specialty} • ${doctor.designation}',
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.brandTeal),
          ],
        ),
      ),
    );
  }

  Widget _buildFreshnessFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.brandTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Freshness Guarantee',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Last verified: ${hospital.lastVerifiedDate}. See inaccurate details?',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showReportDialog(context),
            child: const Text('Report', style: TextStyle(fontSize: 12, color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    String selectedType = 'Doctor no longer practices here';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: AppColors.brandNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Inaccurate Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Help keep the CareLink Kerala directory accurate for all patients.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    dropdownColor: AppColors.brandSplashDark,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Inaccuracy Category',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Doctor no longer practices here', child: Text('Doctor no longer practices here')),
                      DropdownMenuItem(value: 'Consultation schedule is incorrect', child: Text('Consultation schedule is incorrect')),
                      DropdownMenuItem(value: 'Phone / Contact number is incorrect', child: Text('Phone / Contact number is incorrect')),
                      DropdownMenuItem(value: 'Hospital moved location', child: Text('Hospital moved location')),
                      DropdownMenuItem(value: 'Service not available', child: Text('Service not available')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Describe accurate details *',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (reasonController.text.trim().isNotEmpty) {
                        state.reportIncorrectInformation(
                          hospitalName: hospital.name,
                          reportType: selectedType,
                          description: reasonController.text.trim(),
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.brandHealthGreen,
                            content: Text('Thank you! Your report has been received by CareLink Moderation Desk.'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandTeal,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
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
