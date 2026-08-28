import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/services/ai_healthcare_service.dart';
import '../../../core/state/app_state_provider.dart';

class VisitEntryScreen extends StatefulWidget {
  final AppStateProvider state;
  final VisitModel visit;

  const VisitEntryScreen({
    super.key,
    required this.state,
    required this.visit,
  });

  @override
  State<VisitEntryScreen> createState() => _VisitEntryScreenState();
}

class _VisitEntryScreenState extends State<VisitEntryScreen> {
  final _bpCtrl = TextEditingController(text: '124/82');
  final _pulseCtrl = TextEditingController(text: '78');
  final _spo2Ctrl = TextEditingController(text: '97');
  final _notesCtrl = TextEditingController();
  double _painScale = 3.0;
  bool _isRecordingVoice = false;
  bool _isGpsCheckedIn = false;
  String _gpsStatus = 'GPS Not Checked In';

  @override
  void initState() {
    super.initState();
    if (widget.visit.clinicalNotes != null) {
      _notesCtrl.text = widget.visit.clinicalNotes!;
    }
    if (widget.visit.gpsCheckInTime != null) {
      _isGpsCheckedIn = true;
      _gpsStatus = widget.visit.gpsCheckInTime!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Visit Notes: ${widget.visit.patientName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GPS Location Check-In Card
            Card(
              color: _isGpsCheckedIn
                  ? (isDark ? AppColors.darkLightGreenSurface : AppColors.successSurface)
                  : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSand),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Icon(
                      _isGpsCheckedIn ? Icons.check_circle_rounded : Icons.location_off_rounded,
                      color: _isGpsCheckedIn
                          ? (isDark ? AppColors.darkPrimaryGreen : AppColors.success)
                          : (isDark ? AppColors.darkTextLight : AppColors.textSecondary),
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isGpsCheckedIn ? 'GPS Location Verified' : 'GPS Check-In Required',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _gpsStatus,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isGpsCheckedIn)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isGpsCheckedIn = true;
                            _gpsStatus = 'Verified at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} (11.2588° N, 75.7804° E)';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Check-In', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Record Vitals Section - Responsive Clean 3-Grid
            const Text('Record Patient Vitals', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            LayoutBuilder(
              builder: (ctx, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                return isNarrow
                    ? Column(
                        children: [
                          TextField(
                            controller: _bpCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Blood Pressure (e.g. 120/80)',
                              prefixIcon: Icon(Icons.favorite_outline, size: 20),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _pulseCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Pulse (bpm)',
                                    prefixIcon: Icon(Icons.monitor_heart_outlined, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _spo2Ctrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'SpO2 (%)',
                                    prefixIcon: Icon(Icons.air_outlined, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _bpCtrl,
                              decoration: const InputDecoration(labelText: 'BP (mmHg)', prefixIcon: Icon(Icons.favorite_outline, size: 18)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _pulseCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Pulse (bpm)', prefixIcon: Icon(Icons.monitor_heart_outlined, size: 18)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _spo2Ctrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'SpO2 (%)', prefixIcon: Icon(Icons.air_outlined, size: 18)),
                            ),
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 16),

            // Pain Scale Slider (1-10)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pain Level Scale (1 to 10):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '${_painScale.toInt()} / 10',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _painScale >= 7
                        ? AppColors.danger
                        : (_painScale >= 4 ? AppColors.warning : (isDark ? AppColors.darkPrimaryGreen : AppColors.success)),
                  ),
                ),
              ],
            ),
            Slider(
              value: _painScale,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: _painScale >= 7
                  ? AppColors.danger
                  : (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
              onChanged: (val) => setState(() => _painScale = val),
            ),
            const SizedBox(height: 16),

            // AI Voice-to-Text Clinical Note Generator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Clinical Visit Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _isRecordingVoice ? null : _simulateVoiceToText,
                  icon: Icon(
                    _isRecordingVoice ? Icons.mic : Icons.mic_none_rounded,
                    color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                    size: 18,
                  ),
                  label: Text(
                    _isRecordingVoice ? 'Transcribing...' : 'Voice Note AI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter clinical observations, medications administered, wound care, or use AI Voice-to-Text...',
              ),
            ),
            const SizedBox(height: 16),

            // Photos & Document Upload Buttons (Safe Wrap)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Simulating wound/clinical photo capture.')),
                    );
                  },
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Add Wound Photo', style: TextStyle(fontSize: 12)),
                ),
                OutlinedButton.icon(
                  onPressed: () => widget.state.queueOfflineVisitDraft(),
                  icon: const Icon(Icons.cloud_off_rounded, size: 18),
                  label: const Text('Save Offline Draft', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Complete Visit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final vitals = VitalsReading(
                    date: '2026-08-06',
                    bp: _bpCtrl.text,
                    pulse: int.tryParse(_pulseCtrl.text) ?? 75,
                    spo2: int.tryParse(_spo2Ctrl.text) ?? 97,
                    painScale: _painScale.toInt(),
                    recordedBy: widget.state.currentUser.name,
                  );

                  widget.state.completeVisit(
                    widget.visit.id,
                    notes: _notesCtrl.text.isEmpty ? 'Visit completed. Patient stable.' : _notesCtrl.text,
                    vitals: vitals,
                  );

                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('Complete Visit & Update Timeline', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateVoiceToText() async {
    setState(() => _isRecordingVoice = true);
    final text = await AiHealthcareService.convertSpeechToText('sample_voice.wav');
    setState(() {
      _isRecordingVoice = false;
      _notesCtrl.text = _notesCtrl.text.isEmpty ? text : '${_notesCtrl.text}\n$text';
    });
  }
}
