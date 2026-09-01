import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/network_models.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/state/app_state_provider.dart';
import 'queue_public_display_screen.dart';

class DoctorOPDConsoleScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String hospitalName;
  final String roomNumber;
  final AppStateProvider? state;

  const DoctorOPDConsoleScreen({
    super.key,
    this.doctorName = 'Dr. Anil Kumar MD, DM',
    this.specialty = 'Cardiology',
    this.hospitalName = 'Calicut Medical Center & Palliative Institute',
    this.roomNumber = 'Room 102 (OPD Block A)',
    this.state,
  });

  @override
  State<DoctorOPDConsoleScreen> createState() => _DoctorOPDConsoleScreenState();
}

class _DoctorOPDConsoleScreenState extends State<DoctorOPDConsoleScreen> {
  final _clinicalNotesController = TextEditingController();
  late AppStateProvider _appState;

  @override
  void initState() {
    super.initState();
    _appState = widget.state ?? AppStateProvider();
  }

  @override
  void dispose() {
    _clinicalNotesController.dispose();
    super.dispose();
  }

  void _showPauseDialog(BuildContext context, String sessionId) {
    String reason = 'BREAK';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Pause Consultation Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select mandatory reason for pausing:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: reason,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'BREAK', child: Text('Lunch / Rest Break')),
                      DropdownMenuItem(value: 'EMERGENCY', child: Text('Emergency Case Interruption')),
                      DropdownMenuItem(value: 'DOCTOR_UNAVAILABLE', child: Text('Doctor Called to Ward')),
                      DropdownMenuItem(value: 'TECHNICAL', child: Text('EMR / Equipment Troubleshooting')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other Administrative Delay')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() {
                          reason = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton(
                  onPressed: () {
                    _appState.pauseQueueSession(sessionId, reason);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                  child: const Text('Pause Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        // Get active session for this doctor/OPD
        final session = _appState.queueSessions.where((s) => s.queueType == 'OPD').firstOrNull ??
            (_appState.queueSessions.isNotEmpty ? _appState.queueSessions.first : null);

        if (session == null) {
          return const Scaffold(body: Center(child: Text('No active OPD session found.')));
        }

        final inConsultation = session.tokens.where((t) => t.status == 'IN_CONSULTATION' || t.status == 'CALLED').firstOrNull;
        final waitingTokens = session.tokens.where((t) => t.status == 'WAITING' || t.status == 'CHECKED_IN').toList();

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.doctorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${widget.specialty} • ${session.roomNumber}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tv_rounded, color: Color(0xFF34D399)),
                tooltip: 'Launch Waiting Room Signage Display',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QueuePublicDisplayScreen(sessionId: session.id, state: _appState)),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  session.isPaused ? Icons.play_arrow_rounded : Icons.pause_circle_filled_rounded,
                  color: session.isPaused ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
                tooltip: session.isPaused ? 'Resume OPD Queue' : 'Pause OPD Queue',
                onPressed: () {
                  if (session.isPaused) {
                    _appState.resumeQueueSession(session.id);
                  } else {
                    _showPauseDialog(context, session.id);
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pause Warning Banner
                if (session.isPaused) ...[
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
                        const Icon(Icons.pause_circle_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'QUEUE PAUSED: ${session.pauseReason} • Waiting patients alerted.',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _appState.resumeQueueSession(session.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Resume', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],

                // OPD Metric Bar
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        'Now Serving',
                        inConsultation != null ? inConsultation.tokenLabel : '---',
                        AppColors.brandTeal,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricCard(
                        'Waiting Patients',
                        '${waitingTokens.length}',
                        Colors.orange,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricCard(
                        'Completed',
                        '${session.totalCompletedConsultations} / ${session.totalTokensIssued}',
                        AppColors.brandHealthGreen,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active Consultation Desk
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.brandTeal.withValues(alpha: 0.2),
                                  child: Text(
                                    inConsultation != null ? inConsultation.tokenLabel : '---',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandTeal),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inConsultation != null ? inConsultation.patientName : 'No Patient in Room',
                                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        inConsultation != null ? 'Phone: ${inConsultation.patientPhone}' : 'Click "Call Next" to invite next patient',
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (inConsultation != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: inConsultation.status == 'IN_CONSULTATION'
                                    ? AppColors.brandHealthGreen.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                inConsultation.status == 'IN_CONSULTATION' ? 'In Consultation 🩺' : 'Token Called 🔔',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: inConsultation.status == 'IN_CONSULTATION' ? AppColors.brandHealthGreen : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (inConsultation != null) ...[
                        const SizedBox(height: 16),
                        Text('Doctor Clinical Notes & Observations:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _clinicalNotesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter clinical observations, prescription, and follow-up advice...',
                            filled: true,
                            fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (inConsultation.status == 'CALLED') ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                                  icon: const Icon(Icons.replay_rounded, color: Colors.orange),
                                  label: Text(
                                    'Recall (${inConsultation.callCount}/3)',
                                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () => _appState.recallQueueToken(session.id, inConsultation.id),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandHealthGreen, padding: const EdgeInsets.symmetric(vertical: 12)),
                                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                                  label: const Text('Start OPD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () => _appState.startConsultationQueueToken(session.id, inConsultation.id),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy, padding: const EdgeInsets.symmetric(vertical: 12)),
                                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                                  label: const Text('Complete Consultation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    _appState.completeConsultationQueueToken(
                                      session.id,
                                      inConsultation.id,
                                      notes: _clinicalNotesController.text.trim(),
                                    );
                                    _clinicalNotesController.clear();
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                            icon: const Icon(Icons.volume_up_rounded, color: Colors.white),
                            label: const Text('Call Next Patient in Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: session.isPaused ? null : () => _appState.callNextQueueToken(session.id),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // OPD Waiting Queue Roster
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today\'s OPD Queue (${session.tokens.length} Registered)', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text('Prioritized by Clinical Triage', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),
                ...session.tokens.map((token) => _queueRow(token, isDark)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metricCard(String label, String value, Color color, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _queueRow(QueueTokenModel token, bool isDark) {
    final isCurrent = token.status == 'IN_CONSULTATION' || token.status == 'CALLED';
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.brandTeal : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              token.tokenLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isCurrent ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(token.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${token.patientPhone} ${token.isWalkIn ? '• Walk-In' : '• Appt'}', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (token.priority != 'NORMAL')
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: token.priority == 'EMERGENCY'
                    ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                token.priority,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: token.priority == 'EMERGENCY' ? const Color(0xFFFCA5A5) : const Color(0xFFFBBF24),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: token.status == 'IN_CONSULTATION'
                  ? AppColors.brandHealthGreen.withValues(alpha: 0.15)
                  : (token.status == 'COMPLETED'
                      ? Colors.blue.withValues(alpha: 0.15)
                      : (token.status == 'CHECKED_IN' ? Colors.teal.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15))),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              token.statusDisplay,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: token.status == 'IN_CONSULTATION'
                    ? AppColors.brandHealthGreen
                    : (token.status == 'COMPLETED' ? Colors.blue : (token.status == 'CHECKED_IN' ? Colors.teal : Colors.orange)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
