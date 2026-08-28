import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../ai_assistant/screens/ai_assistant_screen.dart';
import '../../appointments/screens/appointments_screen.dart';
import '../../blood_donors/screens/blood_donor_directory_screen.dart';
import '../../emergency_sos/screens/emergency_sos_screen.dart';
import '../../fundraising/screens/medical_fundraising_screen.dart';
import '../../patients/widgets/patient_referral_dialog.dart';

class PatientPortalView extends StatelessWidget {
  final AppStateProvider state;

  const PatientPortalView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMalayalam = state.locale.languageCode == 'ml';

    // For demo purposes, pick the first patient or create a representative patient record
    final patient = state.patients.isNotEmpty
        ? state.patients.first
        : PatientModel(
            id: 'PAT-MY-01',
            name: state.currentUser.name,
            age: 72,
            gender: isMalayalam ? 'സ്ത്രീ' : 'Female',
            bloodGroup: 'O+',
            district: state.currentUser.district,
            ward: 'Ward 14',
            address: 'Palliative Care Resident, Kerala',
            phone: state.currentUser.phone,
            categoryTier: isMalayalam ? 'കാറ്റഗറി എ (കിടപ്പിലായവർ)' : 'Category A (Bedridden)',
            diagnosis: isMalayalam ? 'സാന്ത്വന പരിചരണവും വേദന നിവാരണവും' : 'Advanced Palliative Care & Pain Support',
            riskLevel: isMalayalam ? 'മിതമായ അപകടസാധ്യത' : 'Moderate Risk',
            aiSummary: isMalayalam ? 'രോഗിയുടെ അവസ്ഥ സുരക്ഷിതമാണ്. കൃത്യമായ നേഴ്സിംഗ് സന്ദർശനം നടക്കുന്നു.' : 'Patient stable. Regular nursing visits scheduled.',
            emergencyContactName: isMalayalam ? 'രമേഷ് (മകൻ)' : 'Ramesh (Son)',
            emergencyContactPhone: '+91 98470 54321',
            vitalsHistory: [
              VitalsReading(date: '2026-08-06', bp: '124/82', pulse: 78, spo2: 97, painScale: 3, recordedBy: 'Sr. Anitha'),
            ],
            equipmentIssued: [
              EquipmentIssued(equipmentName: 'Air Mattress / Water Bed', serialNumber: 'AM-2026-09', issuedDate: '2026-08-01', status: 'Active'),
            ],
            familyMembers: [],
            medicalHistory: ['Hypertension', 'Chronic joint pain'],
            registeredDate: '2026-08-01',
          );

    final recentVitals = patient.vitalsHistory.isNotEmpty ? patient.vitalsHistory.first : null;
    final districtName = AppLocalizations.getDistrictName(patient.district, isMalayalam: isMalayalam);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency SOS & Assigned Nurse Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF3E1212), const Color(0xFF1E1E1E)]
                    : [const Color(0xFFFFEBEE), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.health_and_safety_rounded, color: AppColors.danger, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isMalayalam ? '24/7 പാലിയേറ്റീവ് സഹായം' : '24/7 Palliative Support',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? const Color(0xFFFF8A80) : AppColors.danger,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isMalayalam ? 'ഡ്യൂട്ടിയിൽ' : 'On Duty',
                        style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isMalayalam
                      ? 'ചുമതലയുള്ള സിസ്റ്റർ: സിസ്റ്റർ അനിത കുമാരി ($districtName)'
                      : 'Assigned Nurse: Sr. Anitha Kumari (${state.activeOrganization?.district ?? "Kozhikode"})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmergencySosScreen(
                            state: state,
                            targetPatientId: patient.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                    label: Text(
                      isMalayalam
                          ? '⚡ അടിയന്തര SOS (വോയ്സ് / 3 ടാപ്പ്)'
                          : '⚡ Rapid SOS (Voice & Triple-Tap Trigger)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 300;
                    if (isNarrow) {
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isMalayalam
                                          ? 'സിസ്റ്റർ അനിതയെ വിളിക്കുന്നു (+91 94470 12345)...'
                                          : 'Calling Assigned Community Nurse Sr. Anitha (+91 94470 12345)...',
                                    ),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 16),
                              label: Text(
                                isMalayalam ? 'സിസ്റ്ററെ വിളിക്കുക' : 'Call Nurse Now',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EmergencySosScreen(
                                      state: state,
                                      initialTriggerMethod: '108 Ambulance Button',
                                      targetPatientId: patient.id,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.airport_shuttle_rounded, size: 16, color: AppColors.danger),
                              label: Text(
                                isMalayalam ? '108 ആംബുലൻസ് SOS' : '108 Ambulance SOS',
                                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.danger),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isMalayalam
                                        ? 'സിസ്റ്റർ അനിതയെ വിളിക്കുന്നു (+91 94470 12345)...'
                                        : 'Calling Assigned Community Nurse Sr. Anitha (+91 94470 12345)...',
                                  ),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            },
                            icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 16),
                            label: Text(
                              isMalayalam ? 'സിസ്റ്ററെ വിളിക്കുക' : 'Call Nurse',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmergencySosScreen(
                                    state: state,
                                    initialTriggerMethod: '108 Ambulance Button',
                                    targetPatientId: patient.id,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.airport_shuttle_rounded, size: 16, color: AppColors.danger),
                            label: Text(
                              isMalayalam ? '108 ആംബുലൻസ്' : '108 Ambulance SOS',
                              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Patient Care Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                        child: Text(
                          patient.bloodGroup,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(
                              '${patient.age} ${isMalayalam ? "വയസ്സ്" : "y"} • ${patient.gender} • ${patient.ward}, $districtName',
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkLightGreenSurface : AppColors.successSurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isMalayalam ? 'കാറ്റഗറി എ' : 'Category A',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimaryGreen : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSand,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMalayalam ? 'പ്രാഥമിക രോഗനിർണയം:' : 'Primary Diagnosis:',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(patient.diagnosis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (recentVitals != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      isMalayalam ? 'ഏറ്റവും പുതിയ ആരോഗ്യ വിവരങ്ങൾ:' : 'Latest Health Readings:',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildVitalItem(isMalayalam ? 'രക്തസമ്മർദ്ദം' : 'BP', recentVitals.bp, Icons.favorite_border, isDark)),
                        Expanded(child: _buildVitalItem(isMalayalam ? 'പൾസ്' : 'Pulse', '${recentVitals.pulse} bpm', Icons.monitor_heart_outlined, isDark)),
                        Expanded(child: _buildVitalItem(isMalayalam ? 'ഓക്സിജൻ' : 'SpO2', '${recentVitals.spo2}%', Icons.air_outlined, isDark)),
                        Expanded(child: _buildVitalItem(isMalayalam ? 'വേദന' : 'Pain Level', '${recentVitals.painScale}/10', Icons.sentiment_dissatisfied_outlined, isDark)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Care Services
          Text(
            isMalayalam ? 'പരിചരണ സേവനങ്ങൾ & അഭ്യർത്ഥനകൾ' : 'Care Services & Requests',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.22,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildActionCard(
                context,
                isMalayalam ? 'ഹോം വിസിറ്റ് അഭ്യർത്ഥന' : 'Request Home Visit',
                isMalayalam ? 'നേഴ്സിന്റെ ഭവന സന്ദർശനം' : 'Schedule nurse home visit',
                Icons.home_work_rounded,
                AppColors.primaryGreen,
                () => _showRequestVisitDialog(context, isMalayalam),
                isDark,
              ),
              _buildActionCard(
                context,
                isMalayalam ? 'ഡോക്ടർ ടെലികൺസൾട്ട്' : 'Doctor Tele-Consult',
                isMalayalam ? 'ഡോക്ടറുമായി സംസാരിക്കുക' : 'Book doctor appointment',
                Icons.medical_services_rounded,
                AppColors.info,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentsScreen(state: state))),
                isDark,
              ),
              _buildActionCard(
                context,
                isMalayalam ? 'ഉപകരണ വായ്പ' : 'Request Equipment',
                isMalayalam ? 'വീൽചെയർ, ഓക്സിജൻ ബെഡ്' : 'Wheelchair, oxygen bed loans',
                Icons.wheelchair_pickup_rounded,
                AppColors.secondaryGreen,
                () => _showRequestEquipmentDialog(context, isMalayalam),
                isDark,
              ),
              _buildActionCard(
                context,
                isMalayalam ? 'രക്തദാന സഹായം' : 'Blood Donor Help',
                isMalayalam ? 'അടിയന്തര രക്തദാതാക്കളെ കണ്ടെത്തുക' : 'Find emergency blood donors',
                Icons.bloodtype_rounded,
                AppColors.danger,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => BloodDonorDirectoryScreen(state: state))),
                isDark,
              ),
              _buildActionCard(
                context,
                isMalayalam ? 'രോഗി റഫറൽ' : 'Nominate Patient',
                isMalayalam ? 'അയൽവാസിയെയോ ബന്ധുവിനെയോ ചേർക്കുക' : 'Refer bedridden neighbor/relative',
                Icons.person_add_alt_1_rounded,
                Colors.teal,
                () => PatientReferralDialog.show(context, state),
                isDark,
              ),
              _buildActionCard(
                context,
                isMalayalam ? 'ചികിത്സാ ധനസഹായം' : 'Treatment Crowdfunding',
                isMalayalam ? 'ആശുപത്രി പരിശോധിച്ച ധനസഹായം' : 'Hospital-verified surgery funds',
                Icons.campaign_rounded,
                Colors.purple,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalFundraisingScreen(state: state))),
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // AI Caregiver Assistant Card
          Card(
            color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        isMalayalam ? 'AI സാന്ത്വന പരിചരണ സഹായി' : 'AI Caregiver Assistant',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isMalayalam
                        ? 'രോഗി പരിചരണം, പോഷകാഹാരം, മുറിവ് പരിചരണം, വേദന നിയന്ത്രണം എന്നിവയിൽ മലയാളത്തിലും ഇംഗ്ലീഷിലും തൽക്ഷണ ഉപദേശം നേടുക.'
                        : 'Get instant comfort care advice, nutrition tips, wound care guidance, and pain management in Malayalam or English.',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AiAssistantScreen(state: state)));
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: Text(
                        isMalayalam ? 'AI സഹായിയോട് ചോദിക്കുക (മലയാളം / English)' : 'Ask AI Care Assistant (മലയാളം / English)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // My Upcoming Schedule & Equipment
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMalayalam ? 'ലഭിച്ച മെഡിക്കൽ ഉപകരണങ്ങൾ' : 'Active Equipment on Loan',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                      child: Icon(Icons.bed_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 20),
                    ),
                    title: Text(
                      isMalayalam ? 'എയർ മാട്രസ്സ് / വാട്ടർ ബെഡ്' : 'Air Mattress / Water Bed',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isMalayalam ? 'നൽകിയ തീയതി: 2026 ആഗസ്റ്റ് 1 • സൗജന്യ വായ്പ' : 'Issued: Aug 1, 2026 • Free Community Loan',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkLightGreenSurface : AppColors.successSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isMalayalam ? 'സജീവം' : 'Active',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimaryGreen : AppColors.success),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 18, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: isDark ? 0.25 : 0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestVisitDialog(BuildContext context, bool isMalayalam) {
    final noteCtrl = TextEditingController(
      text: isMalayalam
          ? 'പതിവ് പാലിയേറ്റീവ് പരിശോധനയും വേദന മരുന്ന് കുറിപ്പടിയും.'
          : 'Routine palliative check-up and pain medicine refill.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: Text(
          isMalayalam ? 'ഹോം കെയർ സന്ദർശനം അഭ്യർത്ഥിക്കുക' : 'Request Home Care Visit',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 440 : double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMalayalam
                      ? 'നിങ്ങളുടെ അഭ്യർത്ഥന പ്രാദേശിക പാലിയേറ്റീവ് നേഴ്സിങ് യൂണിറ്റിലേക്ക് നേരിട്ട് അയക്കും.'
                      : 'Your request will be sent directly to the local Palliative Nursing Unit.',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isMalayalam ? 'സന്ദർശനത്തിനുള്ള കാരണം / ലക്ഷണങ്ങൾ' : 'Reason for Visit / Symptoms',
                    hintText: isMalayalam ? 'വേദന, ഡ്രസ്സിംഗ്, കത്തീറ്റർ ആവശ്യങ്ങൾ രേഖപ്പെടുത്തുക...' : 'Describe any pain, wound dressing, or catheter needs...',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMalayalam ? 'റദ്ദാക്കുക' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isMalayalam
                        ? 'ഹോം കെയർ അഭ്യർത്ഥന അയച്ചു! നേഴ്സിന് സന്ദേശം കൈമാറി.'
                        : 'Home Care Visit Requested! Assigned nurse has been notified.',
                  ),
                  backgroundColor: Colors.teal,
                ),
              );
            },
            child: Text(isMalayalam ? 'അഭ്യർത്ഥന അയക്കുക' : 'Submit Request'),
          ),
        ],
      ),
    );
  }

  void _showRequestEquipmentDialog(BuildContext context, bool isMalayalam) {
    String selectedEq = isMalayalam ? 'വീൽചെയർ' : 'Wheelchair';

    final equipmentList = isMalayalam
        ? [
            'വീൽചെയർ',
            'ഓക്സിജൻ കോൺസെൻട്രേറ്റർ (5L)',
            'എയർ മാട്രസ്സ് / വാട്ടർ ബെഡ്',
            'സക്ഷൻ മെഷീൻ',
            'വാക്കർ / വാക്കിംഗ് ഫ്രെയിം',
          ]
        : [
            'Wheelchair',
            'Oxygen Concentrator (5L)',
            'Air Mattress / Water Bed',
            'Suction Apparatus',
            'Walker / Walking Frame',
          ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        title: Text(
          isMalayalam ? 'മെഡിക്കൽ ഉപകരണ വായ്പ അഭ്യർത്ഥിക്കുക' : 'Request Medical Equipment Loan',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 440 : double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMalayalam
                      ? 'കെയർലിങ്ക് കേരള നൽകുന്ന സൗജന്യ കമ്മ്യൂണിറ്റി മെഡിക്കൽ ഉപകരണങ്ങൾ.'
                      : 'Free community medical equipment provided by CareLink Kerala.',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedEq,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: isMalayalam ? 'ആവശ്യമായ ഉപകരണം തിരഞ്ഞെടുക്കുക' : 'Select Equipment Needed',
                  ),
                  items: equipmentList
                      .map((eq) => DropdownMenuItem(value: eq, child: Text(eq, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => selectedEq = val!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMalayalam ? 'റദ്ദാക്കുക' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isMalayalam
                        ? '"$selectedEq" എന്ന ഉപകരണത്തിനായുള്ള അഭ്യർത്ഥന ഡെപ്പോയിലേക്ക് അയച്ചു!'
                        : 'Equipment request for "$selectedEq" submitted to Community Depot!',
                  ),
                  backgroundColor: Colors.teal,
                ),
              );
            },
            child: Text(isMalayalam ? 'വായ്പ അഭ്യർത്ഥിക്കുക' : 'Request Loan'),
          ),
        ],
      ),
    );
  }
}
