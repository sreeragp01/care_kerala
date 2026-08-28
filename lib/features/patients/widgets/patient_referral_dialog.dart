import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/kerala_location_selector.dart';

class PatientReferralDialog extends StatefulWidget {
  final AppStateProvider state;

  const PatientReferralDialog({super.key, required this.state});

  static Future<void> show(BuildContext context, AppStateProvider state) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PatientReferralDialog(state: state),
    );
  }

  @override
  State<PatientReferralDialog> createState() => _PatientReferralDialogState();
}

class _PatientReferralDialogState extends State<PatientReferralDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _wardCtrl = TextEditingController(text: 'Ward 12');
  final _addressCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  final _guardianCtrl = TextEditingController();
  final _guardianPhoneCtrl = TextEditingController();

  String _gender = 'Male';
  String _bloodGroup = 'O+';
  String _urgency = 'Urgent';
  late String _district;

  @override
  void initState() {
    super.initState();
    _district = widget.state.currentUser.district.isNotEmpty
        ? widget.state.currentUser.district
        : 'Kozhikode';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _wardCtrl.dispose();
    _addressCtrl.dispose();
    _conditionCtrl.dispose();
    _guardianCtrl.dispose();
    _guardianPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final user = widget.state.currentUser;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      actionsOverflowButtonSpacing: 8,
      actionsOverflowDirection: VerticalDirection.down,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryGreen, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.translate('nominate_patient'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width > 500 ? 460 : double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.locale.languageCode == 'ml'
                              ? 'നിങ്ങൾ സമർപ്പിക്കുന്ന റഫറൽ ഉടൻ തന്നെ പ്രദേശത്തെ പാലിയേറ്റീവ് നേഴ്സിനും ഡോക്ടർക്കും പരിശോധനയ്ക്കായി ലഭ്യമാകും.'
                              : 'Your nomination will be sent directly to local Palliative Community Nurses and Duty Doctors for clinical triage and home visits.',
                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Patient basic details
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: '${l10n.translate('full_name')} *',
                    hintText: 'e.g. Radhamani Amma',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter patient name' : null,
                ),
                const SizedBox(height: 10),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 500;
                    if (isCompact) {
                      return Column(
                        children: [
                          TextFormField(
                            controller: _ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '${l10n.translate('age')} *',
                              hintText: '75',
                              prefixIcon: const Icon(Icons.cake_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter age' : null,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _gender,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: l10n.translate('gender')),
                            items: [
                              DropdownMenuItem(value: 'Male', child: Text(l10n.locale.languageCode == 'ml' ? 'പുരുഷൻ (Male)' : 'Male')),
                              DropdownMenuItem(value: 'Female', child: Text(l10n.locale.languageCode == 'ml' ? 'സ്ത്രീ (Female)' : 'Female')),
                              DropdownMenuItem(value: 'Other', child: Text(l10n.locale.languageCode == 'ml' ? 'മറ്റുള്ളവ (Other)' : 'Other')),
                            ],
                            onChanged: (v) => setState(() => _gender = v!),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '${l10n.translate('age')} *',
                              hintText: '75',
                              prefixIcon: const Icon(Icons.cake_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter age' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _gender,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: l10n.translate('gender')),
                            items: [
                              DropdownMenuItem(value: 'Male', child: Text(l10n.locale.languageCode == 'ml' ? 'പുരുഷൻ (Male)' : 'Male')),
                              DropdownMenuItem(value: 'Female', child: Text(l10n.locale.languageCode == 'ml' ? 'സ്ത്രീ (Female)' : 'Female')),
                              DropdownMenuItem(value: 'Other', child: Text(l10n.locale.languageCode == 'ml' ? 'മറ്റുള്ളവ (Other)' : 'Other')),
                            ],
                            onChanged: (v) => setState(() => _gender = v!),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Kerala Local Self Government & Palliative Unit Cascading Selector
                KeralaLocationSelector(
                  initialDistrict: _district,
                  showWard: true,
                  showPalliativeUnit: true,
                  showMedicareCenter: true,
                  showRegisteredClub: true,
                  onLocationChanged: ({required district, required localBody, palliativeUnit, medicareCenter, registeredClub, ward}) {
                    setState(() {
                      _district = district;
                      if (ward != null && ward.isNotEmpty) {
                        _wardCtrl.text = ward;
                      } else {
                        _wardCtrl.text = localBody;
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: '${l10n.translate('address_landmark')} *',
                    hintText: 'House name, lane, near temple/school for nurse navigation...',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter address' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _conditionCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: '${l10n.translate('condition')} *',
                    hintText: 'e.g., Bedridden after stroke, Severe cancer pain, Chronic wound dressing needed...',
                    prefixIcon: const Icon(Icons.healing_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe condition' : null,
                ),
                const SizedBox(height: 10),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 500;
                    if (isCompact) {
                      return Column(
                        children: [
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: '${l10n.translate('primary_phone')} *',
                              hintText: '+91 98470 XXXXX',
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter phone' : null,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _bloodGroup,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: l10n.translate('blood_group')),
                            items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-', 'Unknown'].map((bg) => DropdownMenuItem(value: bg, child: Text(bg, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() => _bloodGroup = v!),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: '${l10n.translate('primary_phone')} *',
                              hintText: '+91 98470 XXXXX',
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter phone' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _bloodGroup,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: l10n.translate('blood_group')),
                            items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-', 'Unknown'].map((bg) => DropdownMenuItem(value: bg, child: Text(bg, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() => _bloodGroup = v!),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Urgency selector
                Text(
                  l10n.locale.languageCode == 'ml' ? 'അടിയന്തര പ്രാധാന്യം (Urgency Level) *' : 'Referral Urgency Level *',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildUrgencyChip(l10n.locale.languageCode == 'ml' ? 'സാധാരണം (Routine)' : 'Routine', Colors.teal, 'Routine'),
                    const SizedBox(width: 6),
                    _buildUrgencyChip(l10n.locale.languageCode == 'ml' ? 'അടിയന്തര (Urgent)' : 'Urgent', AppColors.warning, 'Urgent'),
                    const SizedBox(width: 6),
                    _buildUrgencyChip(l10n.locale.languageCode == 'ml' ? 'ക്രിട്ടിക്കൽ (Emergency)' : 'Emergency', AppColors.danger, 'Emergency'),
                  ],
                ),
                const SizedBox(height: 12),

                // Referrer identity info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSand,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.locale.languageCode == 'ml'
                              ? 'റഫർ ചെയ്യുന്നയാൾ: ${user.name} (${user.role.displayName})'
                              : 'Nominating as: ${user.name} (${user.role.displayName})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.locale.languageCode == 'ml' ? 'റദ്ദാക്കുക' : 'Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _submitReferral,
          icon: const Icon(Icons.send_rounded, size: 16),
          label: Text(l10n.translate('submit_referral')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildUrgencyChip(String label, Color color, String valueKey) {
    final isSelected = _urgency == valueKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _urgency = valueKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  void _submitReferral() {
    if (!_formKey.currentState!.validate()) return;

    final user = widget.state.currentUser;
    final patientId = 'PAT-REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final newPatient = PatientModel(
      id: patientId,
      name: _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()) ?? 70,
      gender: _gender,
      bloodGroup: _bloodGroup,
      district: _district,
      ward: _wardCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      categoryTier: 'Pending Clinical Triage',
      diagnosis: _conditionCtrl.text.trim(),
      riskLevel: _urgency == 'Emergency'
          ? 'High Risk'
          : (_urgency == 'Urgent' ? 'Moderate Risk' : 'Low Risk'),
      aiSummary: 'Community nomination reported by ${user.name} (${user.role.displayName}). Urgency: $_urgency. Patient needs home visit clinical evaluation.',
      emergencyContactName: _guardianCtrl.text.isNotEmpty ? _guardianCtrl.text.trim() : 'Primary Caregiver',
      emergencyContactPhone: _guardianPhoneCtrl.text.isNotEmpty ? _guardianPhoneCtrl.text.trim() : _phoneCtrl.text.trim(),
      vitalsHistory: [],
      equipmentIssued: [],
      familyMembers: [],
      medicalHistory: ['Reported into CareLink Kerala by ${user.name} (${user.role.displayName}).'],
      registeredDate: '2026-08-07',
      referredBy: '${user.name} (${user.role.displayName})',
      referralUrgency: _urgency,
    );

    widget.state.referPatientInNeed(
      newPatient,
      referrerName: user.name,
      referrerRole: user.role.displayName,
      urgency: _urgency,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nomination for "${newPatient.name}" submitted! Duty Nurse & Doctor in $_district notified for triage.'),
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
