import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';

class PatientLiveQueueTrackerScreen extends StatelessWidget {
  final String tokenLabel;
  final int tokenNumber;
  final int currentTokenNumber;
  final String doctorName;
  final String specialty;
  final String roomNumber;
  final String hospitalName;
  final String hospitalPhone;

  const PatientLiveQueueTrackerScreen({
    super.key,
    this.tokenLabel = 'A-27',
    this.tokenNumber = 27,
    this.currentTokenNumber = 18,
    this.doctorName = 'Dr. Priya Varma',
    this.specialty = 'Cardiology & Heart Health',
    this.roomNumber = 'OPD Room 102 (Block A)',
    this.hospitalName = 'Calicut Medical Center',
    this.hospitalPhone = '+914952800100',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final patientsAhead = (tokenNumber - currentTokenNumber).clamp(0, 100);
    final estimatedWaitMinutes = patientsAhead * 10;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live OPD Queue Tracker', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(hospitalName, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.brandTeal),
            tooltip: 'Refresh Queue Position',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.brandTeal,
                  content: Text('Queue status refreshed. Current Serving: Token A-18.'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Live Token Hero Banner
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NOW SERVING', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('A-$currentTokenNumber', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.brandHealthGreen)),
                        ],
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('YOUR TOKEN', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandTeal)),
                          const SizedBox(height: 4),
                          Text(tokenLabel, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.brandTeal)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Wait Status Gauge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('$patientsAhead', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                          Text('Patients Ahead', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('~$estimatedWaitMinutes mins', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.brandNavy)),
                          Text('Est. Wait Time', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Alert Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: Color(0xFF0F766E), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your token is estimated within 40 minutes. Please proceed towards the 2nd Floor Cardiology OPD waiting area.',
                      style: GoogleFonts.inter(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Doctor & Location Details
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consultation Information', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  _infoRow(Icons.person_outline_rounded, 'Consultant Doctor', doctorName, isDark),
                  const SizedBox(height: 10),
                  _infoRow(Icons.medical_services_outlined, 'Clinical Specialty', specialty, isDark),
                  const SizedBox(height: 10),
                  _infoRow(Icons.meeting_room_outlined, 'Room / OPD Station', roomNumber, isDark),
                  const SizedBox(height: 10),
                  _infoRow(Icons.local_hospital_outlined, 'Hospital', hospitalName, isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.brandTeal),
                    ),
                    icon: const Icon(Icons.phone_rounded, color: AppColors.brandTeal),
                    label: const Text('Call Hospital', style: TextStyle(color: AppColors.brandTeal, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Connecting to $hospitalPhone...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandNavy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.directions_rounded, color: Colors.white),
                    label: const Text('Hospital Route', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening GPS route navigation to Calicut Medical Center.')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brandTeal),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
