import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/models/user_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/payment_gateway_dialog.dart';
import 'fundraiser_detail_screen.dart';


class MedicalFundraisingScreen extends StatefulWidget {
  final AppStateProvider state;

  const MedicalFundraisingScreen({super.key, required this.state});

  @override
  State<MedicalFundraisingScreen> createState() => _MedicalFundraisingScreenState();
}

class _MedicalFundraisingScreenState extends State<MedicalFundraisingScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final fundraisers = widget.state.fundraisers.where((f) {
          final matchesCategory = _selectedCategory == 'All' ||
              f.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
              f.district.toLowerCase() == _selectedCategory.toLowerCase();

          final matchesSearch = f.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              f.treatmentTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              f.hospitalName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              f.district.toLowerCase() == _selectedCategory.toLowerCase();

          return matchesCategory && matchesSearch;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Medical Treatment Crowdfunding'),
            actions: [
              IconButton(
                tooltip: 'Start a Treatment Appeal',
                icon: Icon(Icons.add_circle_outline_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                onPressed: () => _showStartFundraiserDialog(context, isDark),
              ),
            ],
          ),
          body: GlassScaffoldBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Banner
                  GlassCard(
                    borderRadius: 18,
                    blur: 14,
                    padding: const EdgeInsets.all(16),
                    customFillColor: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.12),
                    customBorderColor: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.35),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.primaryGreen, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verified Hospital Treatment Appeals',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Direct hospital-verified crowdfunding for patients needing high-cost cardiac surgeries, cancer therapies, and organ transplants.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search & Filter Header
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search patient, surgery, or hospital...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = ''))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'Pediatric Cardiac',
                        'Oncology',
                        'Orthopedic Surgery',
                        'Kozhikode',
                        'Ernakulam',
                      ].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            selectedColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                            onSelected: (_) => setState(() => _selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (fundraisers.isEmpty)
                    GlassCard(
                      borderRadius: 16,
                      blur: 10,
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 44, color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                          const SizedBox(height: 10),
                          Text('No medical fundraisers found matching "$_searchQuery"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    ...fundraisers.map((f) => _buildFundraiserCard(context, f, isDark)),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
            onPressed: () => _showStartFundraiserDialog(context, isDark),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Start Treatment Appeal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildFundraiserCard(BuildContext context, MedicalFundraiserModel f, bool isDark) {
    final pct = (f.percentFunded * 100).toInt();

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: 18,
      blur: 14,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FundraiserDetailScreen(state: widget.state, fundraiser: f),
          ),
        );
      },
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Verification Badge & Days Remaining
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 13, color: AppColors.primaryGreen),
                        SizedBox(width: 4),
                        Text(
                          'Doctor & Hospital Verified',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkWarningSurface : AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${f.daysRemaining} days left',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Patient details & Treatment Title
              Text(
                f.treatmentTitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Patient: ${f.patientName} (${f.patientAge}y • ${f.patientGender}) • ${f.ward}, ${f.district}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                'Treating Hospital: ${f.hospitalName}',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),

              // Cooperating Organization & QR Routing Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceLight : const Color(0xFFF1F8F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f.useOrgQr ? Icons.account_balance_rounded : Icons.qr_code_rounded,
                      size: 13,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        f.useOrgQr
                            ? 'Cooperating with: ${f.cooperatingOrgName} (Org QR)'
                            : 'Dedicated Escrow QR (${f.customUpiId ?? "Custom"})',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Appeal Story Snippet
              Text(
                f.story,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: f.percentFunded,
                  minHeight: 7,
                  backgroundColor: isDark ? AppColors.darkSurfaceLight : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    f.status == 'Target Reached' ? AppColors.success : AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Amounts & Donors Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${f.collectedAmount.toInt()} Raised ($pct%)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Target: ₹${f.targetAmount.toInt()}',
                          style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_alt_rounded, size: 15, color: AppColors.accentGold),
                      const SizedBox(width: 4),
                      Text(
                        '${f.donorsCount} Donors',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),

              // Action Buttons: Donate and Share with LayoutBuilder
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 320;
                  if (isNarrow) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _shareOnWhatsApp(context, f),
                            icon: const Icon(Icons.share_rounded, size: 14, color: Colors.teal),
                            label: const Text('Share Appeal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openPaymentModal(context, f),
                            icon: const Icon(Icons.favorite_rounded, size: 14),
                            label: const Text('Contribute', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareOnWhatsApp(context, f),
                          icon: const Icon(Icons.share_rounded, size: 14, color: Colors.teal),
                          label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Share Appeal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openPaymentModal(context, f),
                          icon: const Icon(Icons.favorite_rounded, size: 14),
                          label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Contribute', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  );

                },
              ),
            ],
          ),
        );
  }


  void _shareOnWhatsApp(BuildContext context, MedicalFundraiserModel f) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Treatment Appeal copied for WhatsApp: "Urgent Medical Appeal: Support ${f.treatmentTitle} for ${f.patientName} at ${f.hospitalName}. Donate on CareLink Kerala."',
        ),
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openPaymentModal(BuildContext context, MedicalFundraiserModel f) {
    PaymentGatewayDialog.show(
      context,
      state: widget.state,
      title: f.treatmentTitle,
      category: 'Medical Appeal (${f.patientName})',
      defaultAmount: 1000.0,
      fundraiserId: f.id,
      fundraiser: f,
    );
  }


  void _showStartFundraiserDialog(BuildContext context, bool isDark) {
    final patientNameCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: '45');
    final surgeryCtrl = TextEditingController();
    final hospitalCtrl = TextEditingController(text: 'Govt. Medical College Hospital, Calicut');
    final doctorCtrl = TextEditingController(text: 'Dr. Suresh Kumar MD');
    final targetCtrl = TextEditingController(text: '500000');
    final storyCtrl = TextEditingController();
    final customUpiCtrl = TextEditingController();

    String category = 'Surgery';
    String district = widget.state.currentUser.district.isNotEmpty ? widget.state.currentUser.district : 'Kozhikode';
    OrganizationModel selectedCoopOrg = widget.state.activeOrganization ?? widget.state.organizations.first;
    bool useOrgQr = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          actionsOverflowButtonSpacing: 8,
          actionsOverflowDirection: VerticalDirection.down,
          title: const Text('Start Verified Medical Fundraiser', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width > 500 ? 480 : double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cooperating Organization Selector
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceLight : const Color(0xFFF1F8F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cooperating Palliative Organization *',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCoopOrg.id,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          items: widget.state.organizations.map((org) {
                            return DropdownMenuItem(
                              value: org.id,
                              child: Text(
                                '${org.name} (${org.district})',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedCoopOrg = widget.state.organizations.firstWhere((o) => o.id == val);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),

                        // QR Routing Mode Choice
                        const Text('Fund QR Code Routing Method:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setDialogState(() => useOrgQr = true),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: useOrgQr ? (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: useOrgQr ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen) : Colors.grey.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(useOrgQr ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 16, color: useOrgQr ? AppColors.primaryGreen : Colors.grey),
                                          const SizedBox(width: 6),
                                          const Expanded(
                                            child: Text('Org Master QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(selectedCoopOrg.upiId.isNotEmpty ? selectedCoopOrg.upiId : 'kozhikodepalliative@sbi', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => setDialogState(() => useOrgQr = false),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: !useOrgQr ? (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: !useOrgQr ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen) : Colors.grey.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(!useOrgQr ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 16, color: !useOrgQr ? AppColors.primaryGreen : Colors.grey),
                                          const SizedBox(width: 6),
                                          const Expanded(
                                            child: Text('Custom QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Beneficiary UPI VPA', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ],
                                  ),

                                ),
                              ),
                            ),
                          ],
                        ),


                        if (!useOrgQr) ...[
                          const SizedBox(height: 4),
                          TextField(
                            controller: customUpiCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Custom Campaign UPI ID (VPA) *',
                              hintText: 'e.g. adithyan.heartcare@sbi',
                              prefixIcon: Icon(Icons.qr_code_2_rounded),
                              isDense: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: patientNameCtrl,
                    decoration: const InputDecoration(labelText: 'Patient Full Name *', prefixIcon: Icon(Icons.person_outline), isDense: true),
                  ),
                  const SizedBox(height: 10),

                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isCompact = constraints.maxWidth < 500;
                      if (isCompact) {
                        return Column(
                          children: [
                            TextField(
                              controller: ageCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Age *', prefixIcon: Icon(Icons.cake_outlined), isDense: true),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: category,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Category', isDense: true),
                              items: ['Surgery', 'Oncology', 'Pediatric Cardiac', 'Transplant', 'Rehabilitation'].map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (val) => setDialogState(() => category = val!),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ageCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Age *', prefixIcon: Icon(Icons.cake_outlined), isDense: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: category,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Category', isDense: true),
                              items: ['Surgery', 'Oncology', 'Pediatric Cardiac', 'Transplant', 'Rehabilitation'].map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (val) => setDialogState(() => category = val!),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: surgeryCtrl,
                    decoration: const InputDecoration(labelText: 'Surgery / Medical Treatment Title *', prefixIcon: Icon(Icons.healing_outlined), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: hospitalCtrl,
                    decoration: const InputDecoration(labelText: 'Treating Hospital *', prefixIcon: Icon(Icons.local_hospital_outlined), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: doctorCtrl,
                    decoration: const InputDecoration(labelText: 'Treating Doctor / Verification Physician *', prefixIcon: Icon(Icons.badge_outlined), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Target Treatment Amount Needed (₹) *', prefixIcon: Icon(Icons.currency_rupee), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: storyCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Patient Condition & Financial Appeal Story *', hintText: 'Describe medical urgency and reason for fundraising...'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () {
                if (patientNameCtrl.text.isNotEmpty && surgeryCtrl.text.isNotEmpty) {
                  final target = double.tryParse(targetCtrl.text) ?? 500000.0;
                  final newFundraiser = MedicalFundraiserModel(
                    id: 'CROWD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    patientId: 'PAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    patientName: patientNameCtrl.text.trim(),
                    patientAge: int.tryParse(ageCtrl.text) ?? 45,
                    patientGender: 'Male',
                    bloodGroup: 'O+',
                    district: district,
                    ward: 'Ward 10',
                    hospitalName: hospitalCtrl.text.trim(),
                    doctorName: doctorCtrl.text.trim(),
                    treatmentTitle: surgeryCtrl.text.trim(),
                    category: category,
                    targetAmount: target,
                    collectedAmount: 0.0,
                    donorsCount: 0,
                    story: storyCtrl.text.isNotEmpty ? storyCtrl.text.trim() : 'Urgent medical treatment appeal for ${patientNameCtrl.text.trim()}.',
                    medicalEstimateSummary: 'Hospital Board Estimate: ₹${target.toInt()}',
                    isDoctorVerified: true,
                    daysRemaining: 30,
                    createdDate: '2026-08-07',
                    status: 'Active',
                    cooperatingOrgId: selectedCoopOrg.id,
                    cooperatingOrgName: selectedCoopOrg.name,
                    useOrgQr: useOrgQr,
                    customUpiId: !useOrgQr && customUpiCtrl.text.trim().isNotEmpty ? customUpiCtrl.text.trim() : null,
                    patientFamilyGratitudeMessage:
                        'With tears of gratitude and folded hands from ${patientNameCtrl.text.trim()} and our family. Your generous contribution brings healing, life, and hope during our most difficult trial. Thank you so much! ❤️',
                  );

                  widget.state.createMedicalFundraiser(newFundraiser);
                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Verified Treatment Fundraiser created for ${newFundraiser.patientName} (Cooperating with ${selectedCoopOrg.name})!'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.publish_rounded, size: 16),
              label: const Text('Launch Fundraiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
