import 'package:flutter/material.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/models/network_models.dart';
import 'queue_public_display_screen.dart';
import 'hospital_queue_analytics_screen.dart';

class QueueManagementScreen extends StatefulWidget {
  final AppStateProvider? state;

  const QueueManagementScreen({super.key, this.state});

  @override
  State<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends State<QueueManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppStateProvider _appState;

  @override
  void initState() {
    super.initState();
    _appState = widget.state ?? AppStateProvider();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showIssueWalkInDialog(BuildContext context, QueueSessionModel session) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String priority = 'NORMAL';
    bool authorizedTriage = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Issue Token • ${session.queueTypeDisplay}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Patient Full Name',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Contact Phone (+91)',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Clinical Priority / Triage Tier:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: priority,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'NORMAL', child: Text('NORMAL (Standard OPD)')),
                      DropdownMenuItem(value: 'PRIORITY', child: Text('PRIORITY (Senior / Palliative Category B)')),
                      DropdownMenuItem(value: 'URGENT', child: Text('URGENT (Acute Symptoms / Bedridden)')),
                      DropdownMenuItem(value: 'EMERGENCY', child: Text('EMERGENCY (Critical Triage)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() {
                          priority = val;
                        });
                      }
                    },
                  ),
                  if (priority != 'NORMAL') ...[
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: authorizedTriage,
                      onChanged: (val) {
                        setSheetState(() {
                          authorizedTriage = val ?? false;
                        });
                      },
                      title: const Text('Clinical Triage Authorization', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('I confirm priority escalation is authorized by triage staff.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      activeColor: const Color(0xFF2563EB),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter patient name and phone.')),
                          );
                          return;
                        }
                        if (priority != 'NORMAL' && !authorizedTriage) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please verify triage authorization for priority tokens.')),
                          );
                          return;
                        }
                        _appState.issueWalkInToken(
                          sessionId: session.id,
                          patientName: nameCtrl.text.trim(),
                          patientPhone: phoneCtrl.text.trim(),
                          priority: priority,
                        );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Generate Walk-In Token', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  void _showPauseDialog(BuildContext context, QueueSessionModel session) {
    String reason = 'BREAK';
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Pause Queue Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select mandatory reason for pausing queue:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
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
                      DropdownMenuItem(value: 'BREAK', child: Text('Doctor Rest / Lunch Break')),
                      DropdownMenuItem(value: 'EMERGENCY', child: Text('Emergency Case Interruption')),
                      DropdownMenuItem(value: 'DOCTOR_UNAVAILABLE', child: Text('Doctor Stepped Away')),
                      DropdownMenuItem(value: 'TECHNICAL', child: Text('Diagnostic Equipment / EMR Issue')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other Administrative Reason')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() {
                          reason = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Optional notes for waiting patients...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
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
                    _appState.pauseQueueSession(session.id, reason);
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
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        final sessions = _appState.queueSessions;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            title: const Text('Live OPD & Multi-Queue Desk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.analytics_rounded, color: Color(0xFF38BDF8)),
                tooltip: 'Hospital Flow Analytics',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HospitalQueueAnalyticsScreen(state: _appState)),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.tv_rounded, color: Color(0xFF34D399)),
                tooltip: 'Launch Waiting Area TV Monitor Display',
                onPressed: () {
                  if (sessions.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QueuePublicDisplayScreen(sessionId: sessions.first.id, state: _appState),
                      ),
                    );
                  }
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF38BDF8),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF94A3B8),
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.medical_services_rounded), text: 'Cardiology OPD'),
                Tab(icon: Icon(Icons.volunteer_activism_rounded), text: 'Palliative Suite'),
                Tab(icon: Icon(Icons.local_pharmacy_rounded), text: 'Dispensary'),
                Tab(icon: Icon(Icons.science_rounded), text: 'Diagnostic Lab'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildQueueSessionView(context, sessions.where((s) => s.queueType == 'OPD').firstOrNull ?? (sessions.isNotEmpty ? sessions.first : null)),
              _buildQueueSessionView(context, sessions.where((s) => s.queueType == 'PALLIATIVE').firstOrNull ?? (sessions.isNotEmpty ? sessions.first : null)),
              _buildQueueSessionView(context, sessions.where((s) => s.queueType == 'PHARMACY').firstOrNull ?? (sessions.isNotEmpty ? sessions.first : null)),
              _buildQueueSessionView(context, sessions.where((s) => s.queueType == 'LABORATORY').firstOrNull ?? (sessions.isNotEmpty ? sessions.first : null)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQueueSessionView(BuildContext context, QueueSessionModel? session) {
    if (session == null) {
      return const Center(child: Text('No active session for this department.', style: TextStyle(color: Colors.white70)));
    }

    final waitingTokens = session.tokens.where((t) => t.status == 'WAITING' || t.status == 'CHECKED_IN').toList();
    final inConsultation = session.tokens.where((t) => t.status == 'IN_CONSULTATION' || t.status == 'CALLED').firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: session.isPaused ? const Color(0xFFDC2626) : const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.departmentName ?? session.queueTypeDisplay,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${session.doctorName} • ${session.roomNumber}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: session.isPaused
                            ? const Color(0xFFDC2626).withValues(alpha: 0.2)
                            : const Color(0xFF059669).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: session.isPaused ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(session.isPaused ? Icons.pause_circle_rounded : Icons.check_circle_rounded,
                              color: session.isPaused ? const Color(0xFFEF4444) : const Color(0xFF10B981), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            session.isPaused ? 'PAUSED' : 'ACTIVE',
                            style: TextStyle(
                              color: session.isPaused ? const Color(0xFFFCA5A5) : const Color(0xFF34D399),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (session.isPaused) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1D1D).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFFCA5A5), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reason: ${session.pauseReason}',
                            style: const TextStyle(color: Color(0xFFFEE2E2), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Toolbar: Call Next, Issue Walk-in, Pause / Resume, Display Mode
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: session.isPaused ? null : () => _appState.callNextQueueToken(session.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.volume_up_rounded, size: 20),
                  label: const Text('Call Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _showIssueWalkInDialog(context, session),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                  label: const Text('Walk-In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (session.isPaused) {
                    _appState.resumeQueueSession(session.id);
                  } else {
                    _showPauseDialog(context, session);
                  }
                },
                icon: Icon(
                  session.isPaused ? Icons.play_arrow_rounded : Icons.pause_circle_filled_rounded,
                  color: session.isPaused ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 28,
                ),
                tooltip: session.isPaused ? 'Resume Queue' : 'Pause Queue',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Now Serving Card
          if (inConsultation != null) ...[
            const Text('Now In Consultation / Called', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF059669), width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          inConsultation.tokenLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inConsultation.patientName,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Phone: ${inConsultation.patientPhone} • ${inConsultation.statusDisplay}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (inConsultation.priority != 'NORMAL')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            inConsultation.priority,
                            style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (inConsultation.status == 'CALLED') ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _appState.recallQueueToken(session.id, inConsultation.id),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFF59E0B)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.replay_rounded, color: Color(0xFFFBBF24), size: 16),
                            label: Text(
                              'Recall (${inConsultation.callCount}/3)',
                              style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _appState.startConsultationQueueToken(session.id, inConsultation.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                            label: const Text('Start OPD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _appState.completeConsultationQueueToken(session.id, inConsultation.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                            label: const Text('Complete Consultation', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Waiting Tokens List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Waiting in Queue (${waitingTokens.length})', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              Text(
                'Est. Wait: ~${(waitingTokens.length * (session.avgConsultationDurationSeconds / 60)).round()} min',
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (waitingTokens.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Text('No waiting patients in this queue session.', style: TextStyle(color: Colors.white38, fontSize: 14)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: waitingTokens.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final token = waitingTokens[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          token.tokenLabel,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(token.patientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(
                              '${token.statusDisplay} ${token.isWalkIn ? '• Walk-In' : '• Pre-Booked'}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (token.priority != 'NORMAL')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: token.priority == 'EMERGENCY'
                                ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            token.priority,
                            style: TextStyle(
                              color: token.priority == 'EMERGENCY' ? const Color(0xFFFCA5A5) : const Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (token.status == 'CHECKED_IN')
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
