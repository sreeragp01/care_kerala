import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/models/network_models.dart';
import 'appointment_qr_checkin_screen.dart';

class PatientLiveQueueTrackerScreen extends StatelessWidget {
  final String tokenLabel;
  final int tokenNumber;
  final int currentTokenNumber;
  final String doctorName;
  final String specialty;
  final String roomNumber;
  final String hospitalName;
  final String hospitalPhone;
  final bool isQueuePaused;
  final String pauseReason;
  final int avgConsultationMinutes;

  const PatientLiveQueueTrackerScreen({
    super.key,
    this.tokenLabel = 'C-20',
    this.tokenNumber = 20,
    this.currentTokenNumber = 18,
    this.doctorName = 'Dr. Anil Kumar MD, DM',
    this.specialty = 'Cardiology & Heart Health',
    this.roomNumber = 'OPD Room 102 (Block A)',
    this.hospitalName = 'Calicut Medical Center & Palliative Institute',
    this.hospitalPhone = '+91 495 272 1000',
    this.isQueuePaused = false,
    this.pauseReason = '',
    this.avgConsultationMinutes = 13,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final patientsAhead = (tokenNumber - currentTokenNumber).clamp(0, 100);
    final estimatedWaitMinutes = patientsAhead * avgConsultationMinutes;
    final isProximityAlert = patientsAhead <= 2 && patientsAhead > 0;
    final isYourTurn = patientsAhead == 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live OPD Queue Tracker', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(hospitalName, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded, color: AppColors.brandTeal),
            tooltip: 'View Digital QR Check-In Pass',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppointmentQrCheckinScreen(
                    appointment: AppointmentRequestModel(
                      id: 'APT-101',
                      organizationId: 'org_kozhikode',
                      organizationName: hospitalName,
                      doctorId: 'DOC-101',
                      doctorName: doctorName,
                      doctorSpecialty: specialty,
                      patientName: 'Muhammed Basheer',
                      patientPhone: '+91 98472 33445',
                      preferredDate: DateTime.now().toString().split(' ').first,
                      preferredTimeSlot: '11:00 AM - 11:20 AM',
                      tokenNumber: tokenLabel,
                      status: 'CHECKED_IN',
                      statusDisplay: 'Checked In / In Waiting Area',
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.brandTeal),
            tooltip: 'Refresh Queue Position',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.brandTeal,
                  content: Text('Queue status updated. Currently Serving: Token C-$currentTokenNumber.'),
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
            // Queue Pause Alert
            if (isQueuePaused) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDC2626)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pause_circle_filled_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'QUEUE TEMPORARILY PAUSED: ${pauseReason.isNotEmpty ? pauseReason : "Doctor on short break"}. Wait time estimates will resume shortly.',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Proximity Urgent Banner
            if (isProximityAlert || isYourTurn) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isYourTurn
                      ? const Color(0xFF059669).withValues(alpha: 0.2)
                      : const Color(0xFFD97706).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isYourTurn ? const Color(0xFF10B981) : const Color(0xFFF59E0B), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      isYourTurn ? Icons.door_front_door_rounded : Icons.notifications_active_rounded,
                      color: isYourTurn ? const Color(0xFF10B981) : const Color(0xFFFBBF24),
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        isYourTurn
                            ? 'YOUR TOKEN IS BEING CALLED! Please proceed inside $roomNumber immediately.'
                            : 'PROXIMITY ALERT: Only $patientsAhead patient ahead. Please stay right outside $roomNumber.',
                        style: TextStyle(
                          color: isYourTurn ? const Color(0xFF34D399) : const Color(0xFFFDE68A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
                          Text('C-$currentTokenNumber', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.brandHealthGreen)),
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
                          Text('Dynamic Wait Time', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Direction Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.room_rounded, color: Color(0xFF0F766E), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please report to $roomNumber. Your wait time is calculated dynamically from live consultation pace.',
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
                  Text('Consultation & OPD Details', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
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

            // Action Buttons: Digital QR Pass & Call Hospital
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.brandTeal),
                    ),
                    icon: const Icon(Icons.qr_code_rounded, color: AppColors.brandTeal),
                    label: const Text('Digital QR Pass', style: TextStyle(color: AppColors.brandTeal, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppointmentQrCheckinScreen(
                            appointment: AppointmentRequestModel(
                              id: 'APT-101',
                              organizationId: 'org_kozhikode',
                              organizationName: hospitalName,
                              doctorId: 'DOC-101',
                              doctorName: doctorName,
                              doctorSpecialty: specialty,
                              patientName: 'Muhammed Basheer',
                              patientPhone: '+91 98472 33445',
                              preferredDate: DateTime.now().toString().split(' ').first,
                              preferredTimeSlot: '11:00 AM - 11:20 AM',
                              tokenNumber: tokenLabel,
                              status: 'CHECKED_IN',
                              statusDisplay: 'Checked In / In Waiting Area',
                            ),
                          ),
                        ),
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
                    icon: const Icon(Icons.phone_rounded, color: Colors.white),
                    label: const Text('Hospital Desk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Connecting to $hospitalPhone...')),
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
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
