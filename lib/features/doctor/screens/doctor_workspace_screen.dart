import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/state/app_state_provider.dart';

class DoctorWorkspaceScreen extends StatefulWidget {
  final AppStateProvider state;

  const DoctorWorkspaceScreen({super.key, required this.state});

  @override
  State<DoctorWorkspaceScreen> createState() => _DoctorWorkspaceScreenState();
}

class _DoctorWorkspaceScreenState extends State<DoctorWorkspaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final user = widget.state.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Doctor Clinical Workbench', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Consultant: ${user.name} • MD Palliative Medicine', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              labelColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.video_camera_front_rounded), text: 'Consult Requests'),
                Tab(icon: Icon(Icons.medical_services_rounded), text: 'My Patients & Rx'),
                Tab(icon: Icon(Icons.emergency_rounded), text: 'SOS & Appeals'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildConsultRequestsTab(context, isDark),
              _buildAssignedPatientsTab(context, isDark),
              _buildEmergencyAppealsTab(context, isDark),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: Pending Consult Requests & Triage
  // ==========================================
  Widget _buildConsultRequestsTab(BuildContext context, bool isDark) {
    final appointments = widget.state.appointments;

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: appointments.length,
      itemBuilder: (ctx, i) {
        final apt = appointments[i];
        final isConfirmed = apt.status == 'Confirmed';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isConfirmed
                            ? (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface)
                            : (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        apt.type,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isConfirmed ? AppColors.primaryGreen : AppColors.warning,
                        ),
                      ),
                    ),
                    Text(
                      'Status: ${apt.status}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isConfirmed ? AppColors.primaryGreen : (apt.status == 'Declined' ? AppColors.danger : AppColors.warning),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(apt.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Scheduled: ${apt.date} at ${apt.time} • Assigned to: ${apt.doctorName}',
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                const Divider(height: 20),
                Row(
                  children: [
                    if (!isConfirmed && apt.status != 'Declined') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            widget.state.rejectDoctorConsultation(apt.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Declined consult request for ${apt.patientName}')),
                            );
                          },
                          icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                          label: const Text('Decline', style: TextStyle(fontSize: 11, color: AppColors.danger)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAcceptConsultDialog(context, apt),
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: const Text('Accept & Schedule', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ] else if (isConfirmed) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchTeleConsult(context, apt),
                          icon: const Icon(Icons.video_call_rounded, size: 18),
                          label: const Text('Launch Tele-Palliative Video Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: Assigned Patients, Care Plans & Rx
  // ==========================================
  Widget _buildAssignedPatientsTab(BuildContext context, bool isDark) {
    final patients = widget.state.patients.where((p) {
      final query = _search.toLowerCase();
      return p.name.toLowerCase().contains(query) || p.diagnosis.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search clinical rounds by patient name, diagnosis...',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
              isDense: true,
            ),
            onChanged: (val) => setState(() => _search = val),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: patients.length,
            itemBuilder: (ctx, i) {
              final p = patients[i];
              final latestVitals = p.vitalsHistory.isNotEmpty ? p.vitalsHistory.first : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                            child: Icon(Icons.person_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('${p.age}y • ${p.gender} • ${p.ward}, ${p.district}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(p.categoryTier, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Primary Diagnosis: ${p.diagnosis}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),

                      if (latestVitals != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceLight : const Color(0xFFF1F8F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Latest Vitals: BP ${latestVitals.bp} • SpO2 ${latestVitals.spo2}% • Pulse ${latestVitals.pulse} bpm • Pain: ${latestVitals.painScale}/10 (${latestVitals.date})',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                          ),
                        ),
                      ],

                      const SizedBox(height: 6),
                      Text('Care Goals: ${p.carePlan?.careGoals ?? "Comfort care & symptom control"}',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontStyle: FontStyle.italic)),

                      const Divider(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showPrescriptionDialog(context, p),
                              icon: const Icon(Icons.medication_rounded, size: 16),
                              label: const Text('Prescribe Rx & Opioids', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showEditCarePlanDialog(context, p),
                              icon: const Icon(Icons.edit_note_rounded, size: 16),
                              label: const Text('Update Care Plan', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: Emergency SOS Alarms & Appeals
  // ==========================================
  Widget _buildEmergencyAppealsTab(BuildContext context, bool isDark) {
    final sosEvents = widget.state.sosEvents;
    final appeals = widget.state.fundraisers;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Section: Active Emergency SOS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Clinical Emergency SOS Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger)),
            Text('${sosEvents.length} alarms', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        if (sosEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No active clinical SOS alarms at present.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          )
        else
          ...sosEvents.map((sos) => Card(
                color: isDark ? AppColors.darkDangerSurface : AppColors.dangerSurface,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.emergency_rounded, color: AppColors.danger),
                  title: Text('${sos.patientName} (${sos.triggerMethod})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger)),
                  subtitle: Text('Ward ${sos.ward}, ${sos.district} • ${sos.timestamp}\nAmbulance: ${sos.dispatchedAmbulanceVehicle} (${sos.dispatchedAmbulanceDriver})'),
                  trailing: TextButton(
                    onPressed: () {
                      widget.state.resolveEmergencySos(sos.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Resolved SOS alarm for ${sos.patientName}')),
                      );
                    },
                    child: const Text('Mark Handled', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger)),
                  ),
                ),
              )),

        const SizedBox(height: 16),
        // Section: Medical Treatment Crowdfunding Verifications
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Hospital Medical Board Appeals to Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${appeals.length} appeals', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        ...appeals.map((f) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(f.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: f.isDoctorVerified
                                ? (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface)
                                : (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            f.isDoctorVerified ? 'Physician Verified' : 'Needs MD Signoff',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: f.isDoctorVerified ? AppColors.primaryGreen : AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                    Text('${f.treatmentTitle} • Hospital: ${f.hospitalName}', style: const TextStyle(fontSize: 11)),
                    Text('Target Needed: ₹${f.targetAmount.toInt()} • Doctor: ${f.doctorName}',
                        style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    if (!f.isDoctorVerified)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.state.moderateFundraiser(f.id, status: 'Active', isDoctorVerified: true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Clinically signed off and verified treatment appeal for ${f.patientName}!')),
                            );
                          },
                          icon: const Icon(Icons.verified_user_rounded, size: 16),
                          label: const Text('Clinically Verify Medical Appeal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  // ==========================================
  // CLINICAL DIALOGS & ACTIONS
  // ==========================================
  void _showAcceptConsultDialog(BuildContext context, AppointmentModel apt) {
    final timeCtrl = TextEditingController(text: apt.time);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Accept Consult: ${apt.patientName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consultation Type: ${apt.type}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Confirmed Consult Time *', isDense: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              widget.state.acceptDoctorConsultation(
                apt.id,
                doctorName: widget.state.currentUser.name,
                time: timeCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Accepted consultation for ${apt.patientName}! Scheduled at ${timeCtrl.text.trim()}')),
              );
            },
            child: const Text('Confirm Schedule'),
          ),
        ],
      ),
    );
  }

  void _launchTeleConsult(BuildContext context, AppointmentModel apt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.video_call_rounded, color: AppColors.primaryGreen, size: 24),
            const SizedBox(width: 8),
            Text('Tele-Palliative Room: ${apt.patientName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.tealAccent, size: 28),
                    SizedBox(height: 6),
                    Text('End-to-End Encrypted Tele-Consult Live', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('WebRTC Video & Audio Connected', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Doctor: ${widget.state.currentUser.name} • Patient: ${apt.patientName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const Text('AI Tele-Scribe is listening to generate automatic clinical summary.', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('End Call')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tele-consultation completed. Summary written to patient timeline.')),
              );
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Save & Finish'),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionDialog(BuildContext context, PatientModel patient) {
    final medCtrl = TextEditingController(text: 'Morphine Sulfate 10mg TDS');
    final instructionsCtrl = TextEditingController(text: 'Take 1 tablet every 8 hours with milk for severe pain breakthrough.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Prescribe Rx: ${patient.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                    SizedBox(width: 6),
                    Expanded(child: Text('Step III Opioid Safeguard Active. Digital Doctor Signature required.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(controller: medCtrl, decoration: const InputDecoration(labelText: 'Medication & Dosage *', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: instructionsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Dosing Instructions *', isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Prescription dispatched for ${patient.name}: ${medCtrl.text.trim()}'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
            child: const Text('Sign & Issue Rx'),
          ),
        ],
      ),
    );
  }

  void _showEditCarePlanDialog(BuildContext context, PatientModel patient) {
    final goalsCtrl = TextEditingController(text: patient.carePlan?.careGoals ?? 'Total pain relief and compassionate support');
    final doctorCtrl = TextEditingController(text: widget.state.currentUser.name);
    final nurseCtrl = TextEditingController(text: patient.carePlan?.primaryNurseName ?? 'Sister Anitha');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Care Plan: ${patient.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: doctorCtrl, decoration: const InputDecoration(labelText: 'Assigned Doctor', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: nurseCtrl, decoration: const InputDecoration(labelText: 'Primary Community Nurse', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: goalsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Palliative Care Goals & Regimen', isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newPlan = CarePlanModel(
                primaryNurseName: nurseCtrl.text.trim(),
                assignedDoctorName: doctorCtrl.text.trim(),
                careGoals: goalsCtrl.text.trim(),
                lastReviewedDate: '2026-08-28',
              );
              widget.state.updatePatientCarePlan(patient.id, newPlan);
              Navigator.pop(ctx);
            },
            child: const Text('Save Plan'),
          ),
        ],
      ),
    );
  }
}
