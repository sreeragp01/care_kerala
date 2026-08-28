import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/state/app_state_provider.dart';

class CoordinatorWorkspaceScreen extends StatefulWidget {
  final AppStateProvider state;

  const CoordinatorWorkspaceScreen({super.key, required this.state});

  @override
  State<CoordinatorWorkspaceScreen> createState() => _CoordinatorWorkspaceScreenState();
}

class _CoordinatorWorkspaceScreenState extends State<CoordinatorWorkspaceScreen> with SingleTickerProviderStateMixin {
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
                const Text('Community Coordinator Hub', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Coordinator: ${user.name} • Volunteer & Relief Desk', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              labelColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.person_add_alt_1_rounded), text: 'Patient Referrals'),
                Tab(icon: Icon(Icons.verified_rounded), text: 'Appeal Moderation'),
                Tab(icon: Icon(Icons.volunteer_activism_rounded), text: 'Relief Aid Dispatch'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildReferralsTab(context, isDark),
              _buildAppealsTab(context, isDark),
              _buildReliefAidTab(context, isDark),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: Community Patient Nominations & Triage
  // ==========================================
  Widget _buildReferralsTab(BuildContext context, bool isDark) {
    final patients = widget.state.patients;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: patients.length,
      itemBuilder: (ctx, i) {
        final p = patients[i];
        final isEnrolled = p.lifecycleStatus == 'Active Care';

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
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.categoryTier,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      ),
                    ),
                  ],
                ),
                Text('Diagnosis: ${p.diagnosis} • Ward: ${p.ward}, ${p.district}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                Text('Contact: ${p.phone} • Caregiver: ${p.emergencyContactName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                if (p.referredBy != null)
                  Text('Referred By: ${p.referredBy} (${p.referralUrgency ?? "Normal Priority"})', style: const TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAssignVolunteerDialog(context, p),
                        icon: const Icon(Icons.badge_outlined, size: 15),
                        label: const Text('Assign Volunteer', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final updated = PatientModel(
                            id: p.id,
                            name: p.name,
                            age: p.age,
                            gender: p.gender,
                            bloodGroup: p.bloodGroup,
                            district: p.district,
                            ward: p.ward,
                            address: p.address,
                            phone: p.phone,
                            lifecycleStatus: 'Active Care',
                            categoryTier: p.categoryTier,
                            diagnosis: p.diagnosis,
                            riskLevel: p.riskLevel,
                            aiSummary: p.aiSummary,
                            emergencyContactName: p.emergencyContactName,
                            emergencyContactPhone: p.emergencyContactPhone,
                            carePlan: p.carePlan,
                            vitalsHistory: p.vitalsHistory,
                            equipmentIssued: p.equipmentIssued,
                            familyMembers: p.familyMembers,
                            medicalHistory: p.medicalHistory,
                            registeredDate: p.registeredDate,
                          );
                          widget.state.updatePatient(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Verified and enrolled ${p.name} into active community palliative rounds!')),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 15),
                        label: Text(isEnrolled ? 'Enrolled' : 'Verify & Enroll', style: const TextStyle(fontSize: 11)),
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
    );
  }

  // ==========================================
  // TAB 2: Fundraiser Verification & Moderation
  // ==========================================
  Widget _buildAppealsTab(BuildContext context, bool isDark) {
    final appeals = widget.state.fundraisers;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: appeals.length,
      itemBuilder: (ctx, i) {
        final f = appeals[i];

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
                    Text(f.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Status: ${f.status}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  ],
                ),
                Text('Treatment: ${f.treatmentTitle} • Hospital: ${f.hospitalName}', style: const TextStyle(fontSize: 11)),
                Text('Target: ₹${f.targetAmount.toInt()} • Raised: ₹${f.collectedAmount.toInt()}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(f.story, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditStoryDialog(context, f),
                        icon: const Icon(Icons.edit_note_rounded, size: 15),
                        label: const Text('Edit Story / Letter', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.state.moderateFundraiser(f.id, status: 'Active');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Published treatment appeal for ${f.patientName} to Kerala network!')),
                          );
                        },
                        icon: const Icon(Icons.publish_rounded, size: 15),
                        label: const Text('Approve & Publish', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
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
  // TAB 3: Relief Aid & Equipment Dispatch
  // ==========================================
  Widget _buildReliefAidTab(BuildContext context, bool isDark) {
    final equipment = widget.state.equipment;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Community Relief Aid Assets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${equipment.length} items', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        ...equipment.map((e) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                  child: Icon(Icons.volunteer_activism_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 20),
                ),
                title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Available: ${e.availableCount} • In Active Loan: ${e.loanedCount}'),
                trailing: ElevatedButton(
                  onPressed: () => _showLoanDialog(context, e),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Allocate', style: TextStyle(fontSize: 11)),
                ),
              ),
            )),
      ],
    );
  }

  void _showAssignVolunteerDialog(BuildContext context, PatientModel patient) {
    final volunteers = widget.state.volunteers;
    VolunteerModel selectedVolunteer = volunteers.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Assign Volunteer: ${patient.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<VolunteerModel>(
                initialValue: selectedVolunteer,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Select Ward Volunteer *', isDense: true),
                items: volunteers.map((v) => DropdownMenuItem(value: v, child: Text('${v.name} (${v.ward})', style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) => setDialogState(() => selectedVolunteer = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Assigned volunteer ${selectedVolunteer.name} to visit ${patient.name}.')),
                );
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStoryDialog(BuildContext context, MedicalFundraiserModel f) {
    final storyCtrl = TextEditingController(text: f.story);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Story: ${f.patientName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: TextField(
            controller: storyCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Family Appeal Narrative', isDense: true),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              f.story = storyCtrl.text.trim();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Updated appeal story!')),
              );
            },
            child: const Text('Save Story'),
          ),
        ],
      ),
    );
  }

  void _showLoanDialog(BuildContext context, EquipmentItemModel item) {
    final patients = widget.state.patients;
    PatientModel selectedPatient = patients.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Allocate ${item.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<PatientModel>(
                initialValue: selectedPatient,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Recipient Patient *', isDense: true),
                items: patients.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.ward})', style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) => setDialogState(() => selectedPatient = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                widget.state.loanEquipmentToPatient(item.id, selectedPatient.name);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Allocated 1 unit of ${item.name} to ${selectedPatient.name}.')),
                );
              },
              child: const Text('Dispatch Loan'),
            ),
          ],
        ),
      ),
    );
  }
}
