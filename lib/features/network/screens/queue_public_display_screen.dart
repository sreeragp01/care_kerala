import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/state/app_state_provider.dart';

class QueuePublicDisplayScreen extends StatefulWidget {
  final String sessionId;
  final AppStateProvider? state;

  const QueuePublicDisplayScreen({super.key, required this.sessionId, this.state});

  @override
  State<QueuePublicDisplayScreen> createState() => _QueuePublicDisplayScreenState();
}

class _QueuePublicDisplayScreenState extends State<QueuePublicDisplayScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  late AppStateProvider _appState;

  @override
  void initState() {
    super.initState();
    _appState = widget.state ?? AppStateProvider();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        final session = _appState.queueSessions.where((s) => s.id == widget.sessionId).firstOrNull ??
            (_appState.queueSessions.isNotEmpty ? _appState.queueSessions.first : null);

        if (session == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: const Center(
              child: Text('No active queue session found for display.', style: TextStyle(color: Colors.white70, fontSize: 20)),
            ),
          );
        }

        final activeTokens = session.tokens;
        final nowServing = activeTokens.where((t) => t.status == 'CALLED' || t.status == 'IN_CONSULTATION').firstOrNull;
        final waitingTokens = activeTokens.where((t) => t.status == 'WAITING' || t.status == 'CHECKED_IN').toList();

        waitingTokens.sort((a, b) {
          final r = b.priorityRank.compareTo(a.priorityRank);
          if (r != 0) return r;
          return a.tokenNumber.compareTo(b.tokenNumber);
        });

        final nextTokens = waitingTokens.take(5).toList();
        final timeString = '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';

        return Scaffold(
          backgroundColor: const Color(0xFF0A0F1D),
          body: SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFF131B2E),
                    border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF10B981), size: 32),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.organizationName,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '${session.departmentName ?? session.queueTypeDisplay} • ${session.doctorName}',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF3B82F6)),
                                  ),
                                  child: Text(
                                    session.roomNumber,
                                    style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            timeString,
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                          ),
                          const Text(
                            'LIVE QUEUE MONITOR',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.close_fullscreen_rounded, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Queue Pause Alert Banner
                if (session.isPaused)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    color: const Color(0xFFDC2626),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pause_circle_filled_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'QUEUE TEMPORARILY PAUSED: ${session.pauseReason.toUpperCase()}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ),

                // Main Public Signage Split
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Column: NOW SERVING (Prominent Focus)
                        Expanded(
                          flex: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFF334155), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withValues(alpha: 0.15),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'NOW SERVING / ഇപ്പോൾ വിളിക്കുന്നത്',
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  nowServing != null ? nowServing.tokenLabel : '---',
                                  style: TextStyle(
                                    color: nowServing != null ? const Color(0xFF34D399) : Colors.white24,
                                    fontSize: 110,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF0284C7)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.meeting_room_rounded, color: Color(0xFF38BDF8), size: 28),
                                      const SizedBox(width: 12),
                                      Text(
                                        'PROCEED TO: ${session.roomNumber.toUpperCase()}',
                                        style: const TextStyle(color: Color(0xFFE0F2FE), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                ),
                                if (nowServing != null && nowServing.priority != 'NORMAL') ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: nowServing.priority == 'EMERGENCY'
                                          ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                                          : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: nowServing.priority == 'EMERGENCY' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                    child: Text(
                                      'PRIORITY: ${nowServing.priority}',
                                      style: TextStyle(
                                        color: nowServing.priority == 'EMERGENCY' ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Right Column: UP NEXT & WAITING
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF131B2E),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFF1E293B), width: 2),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'UP NEXT / അടുത്തത്',
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF334155),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${waitingTokens.length} Waiting',
                                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: nextTokens.isEmpty
                                      ? const Center(
                                          child: Text('No more patients in queue.', style: TextStyle(color: Colors.white38, fontSize: 16)),
                                        )
                                      : ListView.separated(
                                          itemCount: nextTokens.length,
                                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final token = nextTokens[index];
                                            final isFirst = index == 0;
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                              decoration: BoxDecoration(
                                                color: isFirst ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isFirst ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                                                  width: isFirst ? 2 : 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: isFirst ? const Color(0xFF2563EB) : const Color(0xFF334155),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '${index + 1}',
                                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Text(
                                                      token.tokenLabel,
                                                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1),
                                                    ),
                                                  ),
                                                  if (token.priority != 'NORMAL')
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        token.priority,
                                                        style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
                                                      ),
                                                    )
                                                  else if (token.status == 'CHECKED_IN')
                                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Privacy & Instruction Ticker
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: const Color(0xFF0F172A),
                  child: Row(
                    children: [
                      const Icon(Icons.privacy_tip_outlined, color: Color(0xFF64748B), size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'CareLink Kerala • Patient identities are anonymized on public screens for health privacy compliance.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Scan QR code at entrance to check in.',
                        style: TextStyle(color: Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
