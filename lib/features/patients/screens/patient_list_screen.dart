import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../blood_donors/screens/blood_donor_directory_screen.dart';
import '../widgets/patient_referral_dialog.dart';
import 'patient_detail_screen.dart';
import 'patient_registration_screen.dart';


class PatientListScreen extends StatefulWidget {
  final AppStateProvider state;
  final String? initialFilterTier;

  const PatientListScreen({super.key, required this.state, this.initialFilterTier});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilterTier != null) {
      _selectedFilter = widget.initialFilterTier!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.state.currentUser;
    final canViewClinicalRecords = user.role.canAccessClinicalRecords;

    if (!canViewClinicalRecords) {
      return _buildCommunityReferralPortal(context, loc, isDark);
    }

    return _buildClinicalRegistryView(context, loc, isDark);
  }

  /// Clinical & Administrative Full EHR Registry View (Doctors, Nurses, Volunteers, Admins)
  Widget _buildClinicalRegistryView(BuildContext context, AppLocalizations loc, bool isDark) {
    final filteredPatients = widget.state.patients.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.district.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.ward.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.categoryTier.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.referredBy != null && p.referredBy!.toLowerCase().contains(_searchQuery.toLowerCase()));

      if (_selectedFilter == 'All') return matchesSearch;
      if (_selectedFilter == 'Pending Triage') return matchesSearch && (p.categoryTier.contains('Pending') || p.referredBy != null);
      if (_selectedFilter == 'Category A') return matchesSearch && p.categoryTier.contains('Category A');
      if (_selectedFilter == 'High Risk') return matchesSearch && p.riskLevel == 'High Risk';
      return matchesSearch && p.district == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.translate('patients'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              'Clinical EHR Registry • ${widget.state.currentUser.role.displayName}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Full Patient Registration (EHR)',
            icon: Icon(Icons.how_to_reg_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PatientRegistrationScreen(state: widget.state)),
            ),
          ),
          IconButton(
            tooltip: 'Quick Community Referral',
            icon: Icon(Icons.person_add_alt_1_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
            onPressed: () => PatientReferralDialog.show(context, widget.state),
          ),
        ],
      ),
      body: GlassScaffoldBackground(
        child: Column(
          children: [
            // Search & Filter Header
            Container(
              color: isDark ? AppColors.darkSurface.withValues(alpha: 0.6) : AppColors.surface.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by patient name, ward, diagnosis, or referrer...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = ''))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'Pending Triage',
                        'Category A',
                        'High Risk',
                        'Kozhikode',
                        'Ernakulam',
                      ].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        final isTriageTab = filter == 'Pending Triage';

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            avatar: isTriageTab ? const Icon(Icons.notification_important_rounded, size: 14, color: AppColors.warning) : null,
                            label: Text(filter),
                            selected: isSelected,
                            selectedColor: isTriageTab
                                ? (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface)
                                : (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface),
                            onSelected: (_) => setState(() => _selectedFilter = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Patient Cards List
            Expanded(
              child: filteredPatients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_off_rounded, size: 64, color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                          const SizedBox(height: 12),
                          Text(
                            'No patients found matching "$_searchQuery"',
                            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredPatients.length,
                      itemBuilder: (context, index) {
                        final patient = filteredPatients[index];
                        return _buildPatientCard(context, patient, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PatientRegistrationScreen(state: widget.state)),
        ),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Register Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// Community Patient Referral & Nomination Portal View (Blood Donors, Family, General Users)
  Widget _buildCommunityReferralPortal(BuildContext context, AppLocalizations loc, bool isDark) {
    final user = widget.state.currentUser;
    final myReferrals = widget.state.patients.where((p) => p.referredBy != null).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Patient Referrals'),
      ),
      body: GlassScaffoldBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Privacy Shield Notice
              GlassCard(
                padding: const EdgeInsets.all(14),
                borderRadius: 16,
                blur: 10,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primaryGreen, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Protected Clinical EHR Registry',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'To safeguard patient medical privacy, full clinical histories are restricted to accredited doctors and palliative nurses.',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Hero Nomination Card
              GlassCard(
                customFillColor: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.12),
                customBorderColor: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.4),
                borderRadius: 18,
                blur: 12,
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                          child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Report / Nominate a Patient in Need',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Know someone in your neighborhood who is bedridden, elderly, suffering from severe cancer pain, or in need of palliative nursing care?',
                      style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => PatientReferralDialog.show(context, widget.state),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Nominate Patient Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // My Submitted Referrals Tracking
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Community Referrals in District',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${myReferrals.length} Active',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (myReferrals.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 16,
                  blur: 10,
                  child: Column(
                    children: [
                      Icon(Icons.volunteer_activism_outlined, size: 40, color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                      const SizedBox(height: 8),
                      const Text('No community nominations yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Nominate bedridden individuals in your ward to bring them to the notice of local healthcare teams.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ...myReferrals.map((ref) => GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      borderRadius: 16,
                      blur: 12,
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  ref.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: ref.categoryTier.contains('Pending')
                                      ? (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface)
                                      : (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ref.categoryTier,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: ref.categoryTier.contains('Pending') ? AppColors.warning : AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${ref.age}y • ${ref.gender} • ${ref.ward}, ${ref.district}',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Condition: ${ref.diagnosis}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Divider(height: 16, color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Referred by: ${ref.referredBy ?? user.name}',
                                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  const Icon(Icons.pending_actions_rounded, size: 14, color: AppColors.warning),
                                  const SizedBox(width: 4),
                                  Text(
                                    ref.referralUrgency ?? 'Urgent',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),

              const SizedBox(height: 20),

              // Emergency Blood Shortcut
              GlassCard(
                borderRadius: 16,
                blur: 10,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BloodDonorDirectoryScreen(state: widget.state)));
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDark ? AppColors.darkDangerSurface : AppColors.dangerSurface,
                    child: const Icon(Icons.water_drop_rounded, color: AppColors.danger, size: 20),
                  ),
                  title: const Text('Emergency Blood Donor Registry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Available to all community members and donors.', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, PatientModel patient, bool isDark) {

    final isHighRisk = patient.riskLevel == 'High Risk';
    final isReferral = patient.referredBy != null;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 16,
      blur: 12,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailScreen(state: widget.state, patient: patient),
          ),
        );
      },
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Referral Banner if nominated by community
          if (isReferral)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkWarningSurface : AppColors.warningSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Community Referral • Nominated by: ${patient.referredBy} (${patient.referralUrgency ?? "Urgent"})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isHighRisk
                    ? (isDark ? AppColors.darkDangerSurface : AppColors.dangerSurface)
                    : (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface),
                child: Text(
                  patient.bloodGroup,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isHighRisk ? AppColors.danger : (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${patient.age}y • ${patient.gender} • ${patient.ward}, ${patient.district}',
                      style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isHighRisk
                      ? (isDark ? AppColors.darkDangerSurface : AppColors.dangerSurface)
                      : (isDark ? AppColors.darkWarningSurface : AppColors.warningSurface),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  patient.riskLevel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHighRisk ? AppColors.danger : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceLight.withValues(alpha: 0.5) : const Color(0xFFE8F5E9).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.medical_services_outlined, size: 16, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    patient.diagnosis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


