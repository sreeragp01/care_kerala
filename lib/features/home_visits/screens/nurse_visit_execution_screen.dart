import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/models/patient_model.dart';

class NurseVisitExecutionScreen extends StatefulWidget {
  final AppStateProvider? state;
  final VisitModel? visit;

  const NurseVisitExecutionScreen({super.key, this.state, this.visit});

  @override
  State<NurseVisitExecutionScreen> createState() => _NurseVisitExecutionScreenState();
}

class _NurseVisitExecutionScreenState extends State<NurseVisitExecutionScreen> {
  final _bpController = TextEditingController(text: '120/80');
  final _pulseController = TextEditingController(text: '78');
  final _spo2Controller = TextEditingController(text: '97');
  final _tempController = TextEditingController(text: '98.4');
  final _painController = TextEditingController(text: '3');
  final _sugarController = TextEditingController(text: '124');

  final _symptomsController = TextEditingController(text: 'Mild knee swelling, comfortable breathing');
  final _careProvidedController = TextEditingController(text: 'Sterile wound dressing change, catheter flush, passive ROM exercises');
  final _medicationController = TextEditingController(text: 'Oral Morphine 10mg verified, Paracetamol 500mg');
  final _equipmentController = TextEditingController(text: 'Air mattress pressure checked, pulse oximeter verified');
  final _followUpController = TextEditingController(text: 'Review dressing in 3 days; continue prescribed analgesic ladder');
  final _notesController = TextEditingController();

  double _painSliderValue = 3.0;

  @override
  void dispose() {
    _bpController.dispose();
    _pulseController.dispose();
    _spo2Controller.dispose();
    _tempController.dispose();
    _painController.dispose();
    _sugarController.dispose();
    _symptomsController.dispose();
    _careProvidedController.dispose();
    _medicationController.dispose();
    _equipmentController.dispose();
    _followUpController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showEmergencyDialog(BuildContext context, AppStateProvider state, VisitModel visit) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF132A2F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: AppColors.danger, size: 24),
              SizedBox(width: 8),
              Text('PALLIATIVE EMERGENCY', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trigger urgent doctor consultation and escalation alert for ${visit.patientName}.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              const Text('Escalation Reason / Clinical Distress:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0D1B1E),
                  hintText: 'e.g. Uncontrolled pain crisis, SpO2 drop < 88%, severe dyspnea...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.danger)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
              label: const Text('ESCALATE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                final reason = reasonCtrl.text.trim().isNotEmpty
                    ? reasonCtrl.text.trim()
                    : 'Field nurse triggered palliative emergency escalation.';
                state.triggerPalliativeEmergencyEscalation(visit.patientId, reason);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.danger,
                    content: Text('CRITICAL ALERT DISPATCHED: Lead Doctor & Palliative Desk alerted.'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state == null) {
      return const Scaffold(body: Center(child: Text('AppStateProvider not provided')));
    }

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final visit = widget.visit ?? (state.visits.isNotEmpty ? state.visits.first : null);
        if (visit == null) {
          return const Scaffold(
            body: Center(child: Text('No active visit selected.')),
          );
        }

        final status = visit.status;
        final isDispatched = status == 'Dispatched';
        final isInProgress = status == 'In Progress';
        final isCompleted = status == 'Completed';

        return Scaffold(
          backgroundColor: const Color(0xFF0D1B1E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF132A2F),
            elevation: 0,
            title: Text(
              'Home Visit: ${visit.patientName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            actions: [
              IconButton(
                tooltip: 'Emergency Escalation',
                icon: const Icon(Icons.emergency_rounded, color: AppColors.danger),
                onPressed: () => _showEmergencyDialog(context, state, visit),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient & Visit Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A2F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              visit.patientName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.emerald.withValues(alpha: 0.25)
                                  : isInProgress
                                      ? AppColors.secondary.withValues(alpha: 0.25)
                                      : AppColors.warning.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCompleted
                                    ? AppColors.emerald
                                    : isInProgress
                                        ? AppColors.secondary
                                        : AppColors.warning,
                              ),
                            ),
                            child: Text(
                              visit.status.toUpperCase(),
                              style: TextStyle(
                                color: isCompleted
                                    ? AppColors.emeraldLight
                                    : isInProgress
                                        ? AppColors.secondary
                                        : AppColors.warning,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.emeraldLight, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(visit.patientAddress, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, color: Colors.white38, size: 16),
                          const SizedBox(width: 6),
                          Text('Assigned Nurse: ${visit.assignedNurseName} • Time: ${visit.scheduledTime}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                      if (visit.gpsLocationName != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.pin_drop_rounded, color: AppColors.emeraldLight, size: 16),
                            const SizedBox(width: 6),
                            Text('Arrival Verified: ${visit.gpsLocationName} (${visit.gpsCheckInTime})',
                                style: const TextStyle(color: AppColors.emeraldLight, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Workflow Stage Actions
                const Text('Field Execution Workflow', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDispatched || isInProgress || isCompleted
                              ? const Color(0xFF1E3D44)
                              : AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: Icon(
                          isDispatched || isInProgress || isCompleted ? Icons.check_circle_rounded : Icons.directions_car_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          isDispatched ? 'Dispatched' : '1. Dispatch',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: isCompleted
                            ? null
                            : () => state.dispatchHomeVisit(visit.id),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInProgress || isCompleted
                              ? const Color(0xFF1E3D44)
                              : AppColors.emerald,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: Icon(
                          isInProgress || isCompleted ? Icons.check_circle_rounded : Icons.gps_fixed_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          isInProgress ? 'Arrived (Active)' : '2. GPS Arrive',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: isCompleted
                            ? null
                            : () => state.recordHomeVisitArrival(visit.id, locationName: 'Patient Home (GPS Verified)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Vitals & Pain Capture Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A2F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monitor_heart_rounded, color: AppColors.emeraldLight, size: 20),
                          SizedBox(width: 8),
                          Text('Vitals & Pain Assessment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // BP, SpO2, Pulse, Temp Inputs
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Blood Pressure', _bpController, '120/80', Icons.favorite_rounded)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('SpO₂ (%)', _spo2Controller, '98', Icons.air_rounded)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Pulse (bpm)', _pulseController, '76', Icons.timeline_rounded)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('Temp (°F)', _tempController, '98.6', Icons.thermostat_rounded)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Blood Sugar (mg/dL)', _sugarController, '130', Icons.water_drop_rounded)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // WHO Pain Scale Slider (0-10)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pain Severity Scale (0 - 10):', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _painSliderValue >= 7
                                  ? AppColors.danger.withValues(alpha: 0.3)
                                  : _painSliderValue >= 4
                                      ? AppColors.warning.withValues(alpha: 0.3)
                                      : AppColors.emerald.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_painSliderValue.toInt()} / 10',
                              style: TextStyle(
                                color: _painSliderValue >= 7
                                    ? AppColors.danger
                                    : _painSliderValue >= 4
                                        ? AppColors.warning
                                        : AppColors.emeraldLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _painSliderValue,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        activeColor: _painSliderValue >= 7
                            ? AppColors.danger
                            : _painSliderValue >= 4
                                ? AppColors.warning
                                : AppColors.emeraldLight,
                        onChanged: (val) {
                          setState(() {
                            _painSliderValue = val;
                            _painController.text = val.toInt().toString();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Structured Clinical Documentation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A2F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit_note_rounded, color: AppColors.emeraldLight, size: 20),
                          SizedBox(width: 8),
                          Text('Structured Clinical Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _buildMultilineField('Observed Symptoms & Complaints', _symptomsController),
                      const SizedBox(height: 10),
                      _buildMultilineField('Care & Procedures Provided (Dressing, Flush, ROM)', _careProvidedController),
                      const SizedBox(height: 10),
                      _buildMultilineField('Medication Administered & Verified', _medicationController),
                      const SizedBox(height: 10),
                      _buildMultilineField('Medical Equipment Inspected', _equipmentController),
                      const SizedBox(height: 10),
                      _buildMultilineField('Follow-Up & Caregiver Instructions', _followUpController),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Complete Visit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                    label: const Text('Complete & Sign-Off Visit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () {
                      final vitals = VitalsReading(
                        date: 'Today',
                        bp: _bpController.text.trim(),
                        pulse: int.tryParse(_pulseController.text.trim()) ?? 72,
                        spo2: int.tryParse(_spo2Controller.text.trim()) ?? 98,
                        temperature: double.tryParse(_tempController.text.trim()) ?? 98.6,
                        painScale: _painSliderValue.toInt(),
                        recordedBy: visit.assignedNurseName,
                      );

                      state.completeHomeVisitWithStructuredNotes(
                        visit.id,
                        symptoms: _symptomsController.text.trim(),
                        careProvided: _careProvidedController.text.trim(),
                        medicationAdministered: _medicationController.text.trim(),
                        equipmentUsed: _equipmentController.text.trim(),
                        followUp: _followUpController.text.trim(),
                        clinicalNotes: _notesController.text.trim(),
                        vitals: vitals,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.emerald,
                          content: Text('Visit for ${visit.patientName} successfully completed & documented!'),
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0D1B1E),
            prefixIcon: Icon(icon, color: AppColors.emeraldLight, size: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
          ),
        ),
      ],
    );
  }

  Widget _buildMultilineField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: 2,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0D1B1E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
          ),
        ),
      ],
    );
  }
}
