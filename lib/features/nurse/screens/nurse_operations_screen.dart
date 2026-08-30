import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/glass_card.dart';

class NurseOperationsScreen extends StatefulWidget {
  final AppStateProvider state;

  const NurseOperationsScreen({super.key, required this.state});

  @override
  State<NurseOperationsScreen> createState() => _NurseOperationsScreenState();
}

class _NurseOperationsScreenState extends State<NurseOperationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
                const Text('Nurse Home Care Hub', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Staff: ${user.name} • Community Palliative Nurse', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              labelColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.home_work_rounded), text: 'Visit Queue'),
                Tab(icon: Icon(Icons.favorite_rounded), text: 'Bedside Vitals & Care'),
                Tab(icon: Icon(Icons.medication_liquid_rounded), text: 'Dispense Medicine'),
              ],
            ),
          ),
          body: GlassScaffoldBackground(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVisitQueueTab(context, isDark),
                _buildBedsideCareTab(context, isDark),
                _buildDispenseMedicineTab(context, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: Home Visit Requests & Schedule Queue
  // ==========================================
  Widget _buildVisitQueueTab(BuildContext context, bool isDark) {
    final visits = widget.state.visits;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: visits.length,
      itemBuilder: (ctx, i) {
        final v = visits[i];
        final isCompleted = v.status == 'Completed';

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          borderRadius: 16,
          blur: 12,
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
                      color: isCompleted
                          ? (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface)
                          : (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isCompleted ? AppColors.primaryGreen : AppColors.warning).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Status: ${v.status}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen) : AppColors.warning,
                      ),
                    ),
                  ),
                  Text(
                    '${v.scheduledDate} • ${v.scheduledTime}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(v.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('Address: ${v.patientAddress}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text('Assigned Nurse: ${v.assignedNurseName}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, fontWeight: FontWeight.w600)),
              if (v.clinicalNotes != null && v.clinicalNotes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Visit Notes: ${v.clinicalNotes}', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
              ],
              Divider(height: 18, color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
              Row(
                children: [
                  if (!isCompleted) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          widget.state.acceptNurseVisit(v.id, nurseName: widget.state.currentUser.name);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Accepted home visit for ${v.patientName}!')),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                        label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Accept Visit', style: TextStyle(fontSize: 11))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showLogVitalsDialog(context, v.patientId, v.patientName),
                        icon: const Icon(Icons.medical_information_rounded, size: 15),
                        label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Log Vitals & Care', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Text('Visit Completed & Synced with Clinical Record', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],

                ],
              ),
            ],
          ),
        );
      },
    );
  }


  // ==========================================
  // TAB 2: Bedside Vitals & Nursing Procedures
  // ==========================================
  Widget _buildBedsideCareTab(BuildContext context, bool isDark) {
    final patients = widget.state.patients;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: patients.length,
      itemBuilder: (ctx, i) {
        final p = patients[i];
        final latestVitals = p.vitalsHistory.isNotEmpty ? p.vitalsHistory.first : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Tier: ${p.categoryTier}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  ],
                ),
                Text('Diagnosis: ${p.diagnosis} • Ward: ${p.ward}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                const SizedBox(height: 6),

                if (latestVitals != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceLight : const Color(0xFFF1F8F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recorded Vitals (${latestVitals.date}):', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          'BP: ${latestVitals.bp} mmHg • SpO2: ${latestVitals.spo2}% • Pulse: ${latestVitals.pulse} bpm • Temp: ${latestVitals.temperature}°F • Pain: ${latestVitals.painScale}/10',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogVitalsDialog(context, p.id, p.name),
                        icon: const Icon(Icons.favorite_rounded, size: 15),
                        label: const Text('Record Vitals', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showEscalateDoctorDialog(context, p),
                        icon: const Icon(Icons.arrow_upward_rounded, size: 15),
                        label: const Text('Escalate to Doctor', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                      ),
                    ),
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
  // TAB 3: Bedside Medicine & Consumables Dispenser
  // ==========================================
  Widget _buildDispenseMedicineTab(BuildContext context, bool isDark) {
    final medicines = widget.state.medicines;
    final patients = widget.state.patients;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: medicines.length,
      itemBuilder: (ctx, i) {
        final m = medicines[i];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                  child: Icon(Icons.medication_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Category: ${m.category} • Batch: ${m.batchNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text('Stock Available: ${m.stockQuantity} ${m.unit}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: m.stockQuantity <= m.reorderLevel ? AppColors.danger : AppColors.primaryGreen,
                          )),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDispenseDialog(context, m, patients),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('Dispense', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // NURSING MODAL DIALOGS
  // ==========================================
  void _showLogVitalsDialog(BuildContext context, String patientId, String patientName) {
    final bpCtrl = TextEditingController(text: '120/80');
    final pulseCtrl = TextEditingController(text: '76');
    final spo2Ctrl = TextEditingController(text: '98');
    final tempCtrl = TextEditingController(text: '98.6');
    final painCtrl = TextEditingController(text: '3');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bedside Care Log: $patientName', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: bpCtrl, decoration: const InputDecoration(labelText: 'BP (mmHg) *', isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: spo2Ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'SpO2 (%) *', isDense: true))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: pulseCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pulse (bpm) *', isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: tempCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Temp (°F) *', isDense: true))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: painCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pain Score (0-10) *', isDense: true)),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Procedure / Dressing / Catheter Notes',
                  hintText: 'e.g. Catheter flushed, Foley balloon 10ml, wound dressed with saline...',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final reading = VitalsReading(
                date: '2026-08-28',
                bp: bpCtrl.text.trim(),
                pulse: int.tryParse(pulseCtrl.text) ?? 76,
                spo2: int.tryParse(spo2Ctrl.text) ?? 98,
                temperature: double.tryParse(tempCtrl.text) ?? 98.6,
                painScale: int.tryParse(painCtrl.text) ?? 3,
                recordedBy: widget.state.currentUser.name,
              );

              widget.state.addVitalsToPatient(patientId, reading);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Vitals and nursing notes recorded for $patientName!'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
            child: const Text('Save Vitals'),
          ),
        ],
      ),
    );
  }

  void _showDispenseDialog(BuildContext context, MedicineItemModel medicine, List<PatientModel> patients) {
    final qtyCtrl = TextEditingController(text: '10');
    PatientModel selectedPatient = patients.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Dispense ${medicine.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available in Stock: ${medicine.stockQuantity} ${medicine.unit}', style: const TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<PatientModel>(
                  initialValue: selectedPatient,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Select Patient *', isDense: true),
                  items: patients.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.ward})', style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) => setDialogState(() => selectedPatient = val!),
                ),
                const SizedBox(height: 8),
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity (${medicine.unit}) *', isDense: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text) ?? 10;
                widget.state.issueMedicine(medicine.id, qty);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dispensed $qty ${medicine.unit} of ${medicine.name} to ${selectedPatient.name}.'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              },
              child: const Text('Confirm Dispense'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEscalateDoctorDialog(BuildContext context, PatientModel patient) {
    final reasonCtrl = TextEditingController(text: 'Persistent breakthrough pain & deteriorating oxygen saturation');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Urgent Doctor Consult: ${patient.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This will create an urgent high-priority tele-palliative triage alert to the treating physician.', style: TextStyle(fontSize: 11)),
              const SizedBox(height: 10),
              TextField(controller: reasonCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Clinical Escalation Reason *', isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              widget.state.addAppointment(
                AppointmentModel(
                  id: 'APT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  patientName: patient.name,
                  doctorName: patient.carePlan?.assignedDoctorName ?? 'Dr. Suresh Kumar MD',
                  date: '2026-08-28',
                  time: 'Urgent Tele-Consult',
                  type: 'Tele-Palliative (Urgent Escalation)',
                  status: 'Pending',
                ),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('High-priority escalation dispatched to ${patient.carePlan?.assignedDoctorName ?? "Physician"}!'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            child: const Text('Dispatch Urgent Alert'),
          ),
        ],
      ),
    );
  }
}
