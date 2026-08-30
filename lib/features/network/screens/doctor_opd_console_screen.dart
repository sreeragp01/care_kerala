import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/network_models.dart';
import '../../../core/widgets/glass_card.dart';

class DoctorOPDConsoleScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String hospitalName;
  final String roomNumber;

  const DoctorOPDConsoleScreen({
    super.key,
    this.doctorName = 'Dr. Priya Varma',
    this.specialty = 'Cardiology',
    this.hospitalName = 'Calicut Medical Center',
    this.roomNumber = 'Room 102 (OPD Block A)',
  });

  @override
  State<DoctorOPDConsoleScreen> createState() => _DoctorOPDConsoleScreenState();
}

class _DoctorOPDConsoleScreenState extends State<DoctorOPDConsoleScreen> {
  int _currentToken = 18;
  final int _totalTokens = 30;
  String _activePatient = 'Rahul Narayanan';
  String _activeTokenLabel = 'A-18';
  bool _inConsultation = true;
  final _clinicalNotesController = TextEditingController();

  final List<QueueTokenModel> _queueList = [
    const QueueTokenModel(id: '18', tokenNumber: 18, tokenLabel: 'A-18', patientName: 'Rahul Narayanan', patientPhone: '+919876543210', status: 'IN_CONSULTATION', statusDisplay: 'In Consultation'),
    const QueueTokenModel(id: '19', tokenNumber: 19, tokenLabel: 'A-19', patientName: 'Fatima Zahra', patientPhone: '+919876543211', status: 'WAITING', statusDisplay: 'Waiting'),
    const QueueTokenModel(id: '20', tokenNumber: 20, tokenLabel: 'A-20', patientName: 'George Joseph', patientPhone: '+919876543212', status: 'WAITING', statusDisplay: 'Waiting'),
    const QueueTokenModel(id: '21', tokenNumber: 21, tokenLabel: 'A-21', patientName: 'Meenakshi Amma', patientPhone: '+919876543213', status: 'WAITING', statusDisplay: 'Waiting'),
    const QueueTokenModel(id: '22', tokenNumber: 22, tokenLabel: 'A-22', patientName: 'Sanjay Nair', patientPhone: '+919876543214', status: 'WAITING', statusDisplay: 'Waiting'),
  ];

  @override
  void dispose() {
    _clinicalNotesController.dispose();
    super.dispose();
  }

  void _callNextPatient() {
    if (_currentToken < _totalTokens) {
      setState(() {
        _currentToken++;
        _activeTokenLabel = 'A-$_currentToken';
        _inConsultation = false;
        final nextToken = _queueList.firstWhere(
          (t) => t.tokenNumber == _currentToken,
          orElse: () => QueueTokenModel(
            id: '$_currentToken',
            tokenNumber: _currentToken,
            tokenLabel: 'A-$_currentToken',
            patientName: 'Patient #$_currentToken',
            patientPhone: '+9198000000$_currentToken',
            status: 'CALLED',
          ),
        );
        _activePatient = nextToken.patientName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.brandTeal,
          content: Text('Token $_activeTokenLabel ($_activePatient) called to ${widget.roomNumber}.'),
        ),
      );
    }
  }

  void _startConsultation() {
    setState(() {
      _inConsultation = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.brandHealthGreen,
        content: Text('Consultation started for $_activePatient ($_activeTokenLabel).'),
      ),
    );
  }

  void _completeConsultation() {
    setState(() {
      _inConsultation = false;
      _clinicalNotesController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.brandNavy,
        content: Text('Consultation for $_activePatient completed! Prescription & notes saved.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.doctorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${widget.specialty} • ${widget.roomNumber}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandHealthGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record, color: AppColors.brandHealthGreen, size: 10),
                const SizedBox(width: 4),
                Text('OPD Active', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandHealthGreen)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OPD Metric Bar
            Row(
              children: [
                Expanded(child: _metricCard('Now Serving', _activeTokenLabel, AppColors.brandTeal, isDark)),
                const SizedBox(width: 10),
                Expanded(child: _metricCard('Waiting', '${_queueList.where((t) => t.status == "WAITING").length}', Colors.orange, isDark)),
                const SizedBox(width: 10),
                Expanded(child: _metricCard('Completed', '$_currentToken / $_totalTokens', AppColors.brandHealthGreen, isDark)),
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
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.brandTeal.withValues(alpha: 0.2),
                            child: Text(_activeTokenLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandTeal)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_activePatient, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Male • 48 Years • General Cardiology', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _inConsultation ? AppColors.brandHealthGreen.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _inConsultation ? 'In Consultation 🩺' : 'Token Called 🔔',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _inConsultation ? AppColors.brandHealthGreen : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Chief Complaint:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Mild chest tightness on exertion for past 3 days. Known hypertensive for 4 years.', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 14),
                  Text('Doctor Clinical Notes & Observations:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _clinicalNotesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter clinical observations, ECG findings, and prescribed medicines...',
                      filled: true,
                      fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!_inConsultation)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandHealthGreen, padding: const EdgeInsets.symmetric(vertical: 12)),
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                            label: const Text('Start Consultation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: _startConsultation,
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy, padding: const EdgeInsets.symmetric(vertical: 12)),
                            icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                            label: const Text('Complete Consultation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: _completeConsultation,
                          ),
                        ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Call Next Token'),
                        onPressed: _callNextPatient,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // OPD Waiting Queue Roster
            Text('Today\'s OPD Queue (${_queueList.length} Registered)', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._queueList.map((token) => _queueRow(token, isDark)),
          ],
        ),
      ),
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
    final isCurrent = token.tokenLabel == _activeTokenLabel;
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
                Text(token.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(token.patientPhone, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: token.status == 'IN_CONSULTATION'
                  ? AppColors.brandHealthGreen.withValues(alpha: 0.15)
                  : (token.status == 'COMPLETED' ? Colors.blue.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              token.statusDisplay,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: token.status == 'IN_CONSULTATION'
                    ? AppColors.brandHealthGreen
                    : (token.status == 'COMPLETED' ? Colors.blue : Colors.orange),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
