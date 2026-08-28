import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../maps/screens/field_map_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final AppStateProvider state;
  final PatientModel patient;

  const PatientDetailScreen({
    super.key,
    required this.state,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(patient.name),
          actions: [
            IconButton(
              tooltip: 'GPS Map Route',
              icon: const Icon(Icons.map_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FieldMapScreen(
                      state: state,
                      initialTargetPatientName: patient.name,
                    ),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
            labelColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
            unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline_rounded), text: 'Overview'),
              Tab(icon: Icon(Icons.monitor_heart_outlined), text: 'Vitals'),
              Tab(icon: Icon(Icons.wheelchair_pickup_rounded), text: 'Equipment'),
              Tab(icon: Icon(Icons.contacts_outlined), text: 'Contacts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(context, isDark),
            _buildVitalsTab(context, isDark),
            _buildEquipmentTab(context, isDark),
            _buildContactsTab(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, bool isDark) {
    final isHighRisk = patient.riskLevel == 'High';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Banner Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                        child: Text(
                          patient.name.substring(0, 1),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(
                              '${patient.age} years • ${patient.gender}',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${patient.ward}, ${patient.district}',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isHighRisk
                              ? (isDark ? AppColors.darkDangerSurface : AppColors.dangerSurface)
                              : (isDark ? AppColors.darkLightGreenSurface : AppColors.successSurface),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          patient.riskLevel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isHighRisk
                                ? AppColors.danger
                                : (isDark ? AppColors.darkPrimaryGreen : AppColors.success),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FieldMapScreen(
                              state: state,
                              initialTargetPatientName: patient.name,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 16, color: AppColors.primaryGreen),
                      label: const Text(
                        'Navigate to Patient Residence (GPS Map)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // AI Clinical Summary Box
          Card(
            color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        'AI Patient Health Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    patient.aiSummary,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Diagnosis & Category Tier Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinical Diagnosis',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(patient.diagnosis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  Text(
                    'Palliative Category Tier',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patient.categoryTier,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Medical History Bullet Points
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Medical History Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...patient.medicalHistory.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 16, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsTab(BuildContext context, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: patient.vitalsHistory.length,
      itemBuilder: (ctx, i) {
        final v = patient.vitalsHistory[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recorded on ${v.date}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'By ${v.recordedBy}',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildVitalBadge('BP', v.bp, Icons.favorite_border, isDark)),
                    Expanded(child: _buildVitalBadge('Pulse', '${v.pulse} bpm', Icons.monitor_heart_outlined, isDark)),
                    Expanded(child: _buildVitalBadge('SpO2', '${v.spo2}%', Icons.air_outlined, isDark)),
                    Expanded(child: _buildVitalBadge('Pain', '${v.painScale}/10', Icons.sentiment_dissatisfied_outlined, isDark)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVitalBadge(String title, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildEquipmentTab(BuildContext context, bool isDark) {
    return patient.equipmentIssued.isEmpty
        ? Center(
            child: Text(
              'No equipment currently loaned to patient.',
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: patient.equipmentIssued.length,
            itemBuilder: (ctx, i) {
              final eq = patient.equipmentIssued[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(Icons.wheelchair_pickup_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                  title: Text(eq.equipmentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Issued: ${eq.issuedDate} • Serial: ${eq.serialNumber}', style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      eq.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildContactsTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: isDark ? AppColors.darkDangerSurface : AppColors.dangerSurface,
            child: ListTile(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling Emergency Contact: ${patient.emergencyContactName} (${patient.emergencyContactPhone})...')),
                );
              },
              leading: const Icon(Icons.phone_in_talk_rounded, color: AppColors.danger, size: 26),
              title: Text('Emergency: ${patient.emergencyContactName}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 14)),
              subtitle: Text(patient.emergencyContactPhone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.call, color: AppColors.danger, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Family Members', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...patient.familyMembers.map((fam) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${fam.name} (${fam.phone})...')),
                    );
                  },
                  leading: Icon(Icons.family_restroom_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                  title: Text(fam.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${fam.relation} • ${fam.phone}', style: const TextStyle(fontSize: 12)),
                  trailing: Icon(Icons.phone_forwarded_outlined, size: 18, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                ),
              )),
        ],
      ),
    );
  }
}
