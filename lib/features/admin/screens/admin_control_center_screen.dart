import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/payment_gateway_dialog.dart';
import '../../patients/screens/patient_registration_screen.dart';
import '../../auth/screens/staff_registration_screen.dart';


class AdminControlCenterScreen extends StatefulWidget {
  final AppStateProvider state;

  const AdminControlCenterScreen({super.key, required this.state});

  @override
  State<AdminControlCenterScreen> createState() => _AdminControlCenterScreenState();
}

class _AdminControlCenterScreenState extends State<AdminControlCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _patientSearch = '';
  String _inventorySearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
        final org = widget.state.activeOrganization;
        final user = widget.state.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Master Control Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '${user.role.displayName} • ${org?.name ?? "CareLink Kerala"}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              labelColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'Org & Banking QR'),
                Tab(icon: Icon(Icons.people_alt_rounded), text: 'Patient Master'),
                Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Inventory Catalog'),
                Tab(icon: Icon(Icons.badge_rounded), text: 'Staff & Roles'),
                Tab(icon: Icon(Icons.campaign_rounded), text: 'Appeal Moderation'),
                Tab(icon: Icon(Icons.receipt_long_rounded), text: '80G Audit Ledger'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOrgBankingTab(context, isDark, org),
              _buildPatientMasterTab(context, isDark),
              _buildInventoryMasterTab(context, isDark),
              _buildStaffRolesTab(context, isDark),
              _buildAppealModerationTab(context, isDark),
              _buildAuditLedgerTab(context, isDark),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: Organization Banking, UPI & QR Code
  // ==========================================
  Widget _buildOrgBankingTab(BuildContext context, bool isDark, OrganizationModel? org) {
    if (org == null) {
      return const Center(child: Text('No active organization selected.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.account_balance_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(org.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Reg #${org.registrationNumber} • District: ${org.district}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  _buildDetailRow('Official UPI ID (VPA):', org.upiId.isNotEmpty ? org.upiId : 'kozhikodepalliative@sbi', isBold: true),
                  const SizedBox(height: 8),
                  _buildDetailRow('Account Holder:', org.bankAccountName.isNotEmpty ? org.bankAccountName : org.name),
                  const SizedBox(height: 8),
                  _buildDetailRow('Bank & Branch:', org.bankName.isNotEmpty ? org.bankName : 'State Bank of India, Calicut'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Account Number:', org.bankAccountNumber.isNotEmpty ? org.bankAccountNumber : '389201948201'),
                  const SizedBox(height: 8),
                  _buildDetailRow('IFSC Code:', org.ifscCode.isNotEmpty ? org.ifscCode : 'SBIN0001234'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Razorpay Key ID:', org.razorpayKeyId.isNotEmpty ? org.razorpayKeyId : 'rzp_test_palliative2026'),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditOrgDialog(context, org),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit Bank & UPI Details', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            PaymentGatewayDialog.show(
                              context,
                              state: widget.state,
                              title: '${org.name} Official Main A/C',
                              category: 'General Palliative Fund',
                              defaultAmount: 1000.0,
                            );
                          },
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                          label: const Text('Test Live Org QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
          ),
          const SizedBox(height: 16),

          // QR Code Routing Guidelines Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceLight : const Color(0xFFF1F8F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primaryGreen, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All community donations and medical fundraisers cooperating with this unit will automatically route payments and scan QR codes using this verified account.',
                    style: TextStyle(fontSize: 11, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: Patient Master Record Management
  // ==========================================
  Widget _buildPatientMasterTab(BuildContext context, bool isDark) {
    final patients = widget.state.patients.where((p) {
      final query = _patientSearch.toLowerCase();
      return p.name.toLowerCase().contains(query) ||
          p.diagnosis.toLowerCase().contains(query) ||
          p.ward.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Search & Add Patient Bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search patients by name, ward, diagnosis...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _patientSearch = val),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PatientRegistrationScreen(state: widget.state)),
                  );
                },
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Add Patient', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),

            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: patients.length,
            itemBuilder: (ctx, i) {
              final p = patients[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                            child: Text(
                              p.name.isNotEmpty ? p.name[0] : 'P',
                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '${p.age}y • ${p.gender} • ${p.bloodGroup} • ${p.ward}, ${p.district}',
                                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
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
                      const SizedBox(height: 8),
                      Text('Diagnosis: ${p.diagnosis}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Assigned Doctor: ${p.carePlan?.assignedDoctorName ?? "Dr. Suresh Kumar"} • Nurse: ${p.carePlan?.primaryNurseName ?? "Sister Anitha"}',
                          style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showAddOrEditPatientDialog(context, p),
                            icon: const Icon(Icons.edit_note_rounded, size: 16),
                            label: const Text('Edit Details', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 6),
                          TextButton.icon(
                            onPressed: () => _confirmDeletePatient(context, p),
                            icon: const Icon(Icons.archive_rounded, size: 16, color: AppColors.danger),
                            label: const Text('Discharge / Archive', style: TextStyle(fontSize: 11, color: AppColors.danger)),
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
  // TAB 3: Inventory & Equipment Catalog Master
  // ==========================================
  Widget _buildInventoryMasterTab(BuildContext context, bool isDark) {
    final medicines = widget.state.medicines.where((m) {
      final query = _inventorySearch.toLowerCase();
      return m.name.toLowerCase().contains(query) || m.category.toLowerCase().contains(query);
    }).toList();

    final equipment = widget.state.equipment.where((e) {
      final query = _inventorySearch.toLowerCase();
      return e.name.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search medicines & equipment catalog...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _inventorySearch = val),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddMedicineDialog(context),
                icon: const Icon(Icons.add_box_rounded, size: 16),
                label: const Text('Add Item', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              // Section: Medicines
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Palliative Pharmacy Medicines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${medicines.length} items', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 6),
              ...medicines.map((m) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                        child: Icon(Icons.medication_rounded, size: 18, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                      ),
                      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Category: ${m.category} • Batch: ${m.batchNumber} • Exp: ${m.expiryDate}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${m.stockQuantity} ${m.unit}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: m.stockQuantity <= m.reorderLevel ? AppColors.danger : AppColors.primaryGreen,
                                  )),
                              if (m.stockQuantity <= m.reorderLevel)
                                const Text('Low Stock', style: TextStyle(fontSize: 9, color: AppColors.danger, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.primaryGreen),
                            tooltip: 'Restock Batch',
                            onPressed: () => _showRestockDialog(context, m),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, size: 20),
                            tooltip: 'Edit Item',
                            onPressed: () => _showEditMedicineDialog(context, m),
                          ),
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: 14),
              // Section: Equipment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Palliative Care Equipment & Mobility Assets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${equipment.length} assets', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 6),
              ...equipment.map((e) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: isDark ? AppColors.darkLightGreenSurface : const Color(0xFFE0F2FE),
                        child: const Icon(Icons.airline_seat_recline_extra_rounded, size: 18, color: Colors.blue),
                      ),
                      title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Total: ${e.totalCount} units • In Loan: ${e.loanedCount} • Status: ${e.maintenanceStatus}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${e.availableCount} Available', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, size: 20),
                            onPressed: () => _showEditEquipmentDialog(context, e),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 4: Staff & User Role Management
  // ==========================================
  Widget _buildStaffRolesTab(BuildContext context, bool isDark) {
    final staff = widget.state.demoUsers;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Healthcare Staff Directory (${staff.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StaffRegistrationScreen(state: widget.state)),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Register Staff', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: staff.length,
            itemBuilder: (ctx, i) {

        final u = staff[i];
        final isCurrent = u.id == widget.state.currentUser.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                  child: Icon(Icons.person_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(4)),
                              child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Text('${u.email} • ${u.phone}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text('Assigned Role: ${u.role.displayName}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)),
                    ],
                  ),
                ),
                DropdownButton<UserRole>(
                  value: u.role,
                  underline: const SizedBox(),
                  items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.displayName, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (newRole) {
                    if (newRole != null) {
                      widget.state.updateUserRole(u.id, newRole);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Updated role for ${u.name} to ${newRole.displayName}')),
                      );
                    }
                  },
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
  // TAB 5: Medical Appeal & Fundraiser Moderation
  // ==========================================
  Widget _buildAppealModerationTab(BuildContext context, bool isDark) {
    final appeals = widget.state.fundraisers;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: appeals.length,
      itemBuilder: (ctx, i) {
        final f = appeals[i];
        final isTargetMet = f.collectedAmount >= f.targetAmount;

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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Status: ${f.status}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      ),
                    ),
                    Text(
                      'Target: ₹${f.targetAmount.toInt()} • Raised: ₹${f.collectedAmount.toInt()}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(f.treatmentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Patient: ${f.patientName} (${f.patientAge}y) • Hospital: ${f.hospitalName}',
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Cooperating Org: ${f.cooperatingOrgName} • QR: ${f.useOrgQr ? "Official Org QR" : "Custom Escrow (${f.customUpiId})" }',
                    style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditAppealDialog(context, f),
                        icon: const Icon(Icons.tune_rounded, size: 15),
                        label: const Text('Moderate & Edit Target', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (f.status != 'Approved' && !isTargetMet)
                      ElevatedButton.icon(
                        onPressed: () {
                          widget.state.moderateFundraiser(f.id, status: 'Active', isDoctorVerified: true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Approved & Verified treatment appeal for ${f.patientName}!')),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 15),
                        label: const Text('Approve Appeal', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
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
  // TAB 6: Financial Audit Ledger & 80G Tax Certificates
  // ==========================================
  Widget _buildAuditLedgerTab(BuildContext context, bool isDark) {
    final donations = widget.state.donations;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: isDark ? AppColors.darkSurfaceLight : AppColors.accentGoldLight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Fund Ledger Balance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(
                    '₹${widget.state.totalDonationsFund.toInt()}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  PaymentGatewayDialog.show(
                    context,
                    state: widget.state,
                    title: 'Community Palliative Fund',
                    category: 'General Palliative Fund',
                    defaultAmount: 1000.0,
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Accept Donation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: donations.length,
            itemBuilder: (ctx, i) {
              final d = donations[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                    child: Icon(
                      d.paymentMode == 'Razorpay' ? Icons.bolt_rounded : Icons.account_balance_wallet_rounded,
                      color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                    ),
                  ),
                  title: Text(d.donorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Category: ${d.category}\nReceipt #${d.receiptNumber} • ${d.paymentMode} • ${d.date}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('+₹${d.amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryGreen)),
                      const Text('80G Tax Deductible', style: TextStyle(fontSize: 9, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
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
  // MODAL DIALOGS
  // ==========================================
  void _showEditOrgDialog(BuildContext context, OrganizationModel org) {
    final upiCtrl = TextEditingController(text: org.upiId);
    final accNameCtrl = TextEditingController(text: org.bankAccountName);
    final accNumCtrl = TextEditingController(text: org.bankAccountNumber);
    final ifscCtrl = TextEditingController(text: org.ifscCode);
    final bankNameCtrl = TextEditingController(text: org.bankName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Banking & UPI: ${org.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: upiCtrl, decoration: const InputDecoration(labelText: 'UPI ID (VPA) *', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: accNameCtrl, decoration: const InputDecoration(labelText: 'Account Holder Name *', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: accNumCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Account Number *', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: ifscCtrl, decoration: const InputDecoration(labelText: 'IFSC Code *', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: bankNameCtrl, decoration: const InputDecoration(labelText: 'Bank & Branch Name *', isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              widget.state.updateOrganizationBankingInfo(
                orgId: org.id,
                upiId: upiCtrl.text.trim(),
                bankAccountName: accNameCtrl.text.trim(),
                bankAccountNumber: accNumCtrl.text.trim(),
                ifscCode: ifscCtrl.text.trim().toUpperCase(),
                bankName: bankNameCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditPatientDialog(BuildContext context, PatientModel? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final ageCtrl = TextEditingController(text: existing != null ? '${existing.age}' : '50');
    final diagnosisCtrl = TextEditingController(text: existing?.diagnosis ?? '');
    final wardCtrl = TextEditingController(text: existing?.ward ?? 'Ward 12');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '+91 98470 12345');
    final addressCtrl = TextEditingController(text: existing?.address ?? 'House No 12, Palliative Colony');
    String tier = existing?.categoryTier ?? 'Category A';
    String status = existing?.lifecycleStatus ?? 'Active Care';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Master Patient Record' : 'Edit Patient: ${existing.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *', isDense: true)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age *', isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: tier,
                        decoration: const InputDecoration(labelText: 'Tier', isDense: true),
                        items: ['Category A', 'Category B', 'Category C', 'Category D'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) => setDialogState(() => tier = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: diagnosisCtrl, decoration: const InputDecoration(labelText: 'Clinical Diagnosis *', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: wardCtrl, decoration: const InputDecoration(labelText: 'Ward Location *', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Primary Phone *', isDense: true)),
                const SizedBox(height: 8),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address Details *', isDense: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && diagnosisCtrl.text.isNotEmpty) {
                  if (existing == null) {
                    final newPatient = PatientModel(
                      id: 'PAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      name: nameCtrl.text.trim(),
                      age: int.tryParse(ageCtrl.text) ?? 50,
                      gender: 'Male',
                      bloodGroup: 'O+',
                      district: widget.state.activeOrganization?.district ?? 'Kozhikode',
                      ward: wardCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      lifecycleStatus: status,
                      categoryTier: tier,
                      diagnosis: diagnosisCtrl.text.trim(),
                      riskLevel: 'Moderate',
                      aiSummary: 'Registered in master database.',
                      emergencyContactName: 'Caregiver',
                      emergencyContactPhone: phoneCtrl.text.trim(),
                      registeredDate: '2026-08-07',
                      vitalsHistory: const [],
                      equipmentIssued: const [],
                      familyMembers: const [],
                      medicalHistory: const [],
                    );
                    widget.state.addPatient(newPatient);
                  } else {
                    final updated = PatientModel(
                      id: existing.id,
                      name: nameCtrl.text.trim(),
                      age: int.tryParse(ageCtrl.text) ?? existing.age,
                      gender: existing.gender,
                      bloodGroup: existing.bloodGroup,
                      district: existing.district,
                      ward: wardCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      lifecycleStatus: status,
                      categoryTier: tier,
                      diagnosis: diagnosisCtrl.text.trim(),
                      riskLevel: existing.riskLevel,
                      aiSummary: existing.aiSummary,
                      emergencyContactName: existing.emergencyContactName,
                      emergencyContactPhone: existing.emergencyContactPhone,
                      carePlan: existing.carePlan,
                      vitalsHistory: existing.vitalsHistory,
                      equipmentIssued: existing.equipmentIssued,
                      familyMembers: existing.familyMembers,
                      medicalHistory: existing.medicalHistory,
                      registeredDate: existing.registeredDate,
                      referredBy: existing.referredBy,
                      referralUrgency: existing.referralUrgency,
                    );
                    widget.state.updatePatient(updated);
                  }
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save Patient'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePatient(BuildContext context, PatientModel patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Discharge ${patient.name}?', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to archive / discharge patient ${patient.name} from active clinical rounds?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              widget.state.deletePatient(patient.id);
              Navigator.pop(ctx);
            },
            child: const Text('Discharge / Archive'),
          ),
        ],
      ),
    );
  }

  void _showAddMedicineDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Analgesic');
    final qtyCtrl = TextEditingController(text: '100');
    final unitCtrl = TextEditingController(text: 'tablets');
    final batchCtrl = TextEditingController(text: 'KL-2026-B1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Medicine Listing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Medicine Name *', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category *', isDense: true)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Qty *', isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit *', isDense: true))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Batch Number *', isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                widget.state.addMedicineItem(
                  MedicineItemModel(
                    id: 'MED-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    name: nameCtrl.text.trim(),
                    category: catCtrl.text.trim(),
                    stockQuantity: int.tryParse(qtyCtrl.text) ?? 100,
                    unit: unitCtrl.text.trim(),
                    reorderLevel: 20,
                    expiryDate: '2027-12-31',
                    batchNumber: batchCtrl.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  void _showEditMedicineDialog(BuildContext context, MedicineItemModel item) {
    final nameCtrl = TextEditingController(text: item.name);
    final catCtrl = TextEditingController(text: item.category);
    final reorderCtrl = TextEditingController(text: '${item.reorderLevel}');
    final batchCtrl = TextEditingController(text: item.batchNumber);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit: ${item.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Medicine Name', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: reorderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reorder Level Threshold', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Batch Number', isDense: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              widget.state.updateMedicineItem(
                MedicineItemModel(
                  id: item.id,
                  name: nameCtrl.text.trim(),
                  category: catCtrl.text.trim(),
                  stockQuantity: item.stockQuantity,
                  unit: item.unit,
                  reorderLevel: int.tryParse(reorderCtrl.text) ?? item.reorderLevel,
                  expiryDate: item.expiryDate,
                  batchNumber: batchCtrl.text.trim(),
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(BuildContext context, MedicineItemModel item) {
    final qtyCtrl = TextEditingController(text: '50');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restock ${item.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Quantity to Add (${item.unit})'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text) ?? 50;
              widget.state.restockMedicine(item.id, qty);
              Navigator.pop(ctx);
            },
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }

  void _showEditEquipmentDialog(BuildContext context, EquipmentItemModel item) {
    final totalCtrl = TextEditingController(text: '${item.totalCount}');
    final availCtrl = TextEditingController(text: '${item.availableCount}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Asset: ${item.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: totalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Units Owned', isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: availCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Available Units', isDense: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              widget.state.updateEquipmentItem(
                EquipmentItemModel(
                  id: item.id,
                  name: item.name,
                  totalCount: int.tryParse(totalCtrl.text) ?? item.totalCount,
                  availableCount: int.tryParse(availCtrl.text) ?? item.availableCount,
                  loanedCount: item.loanedCount,
                  maintenanceStatus: item.maintenanceStatus,
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditAppealDialog(BuildContext context, MedicalFundraiserModel f) {
    final targetCtrl = TextEditingController(text: '${f.targetAmount.toInt()}');
    String status = f.status;
    bool useOrgQr = f.useOrgQr;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Moderate Appeal: ${f.patientName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Treatment Amount (₹)', isDense: true)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Campaign Status', isDense: true),
                items: ['Active', 'Under Verification', 'Target Reached', 'Paused', 'Rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setDialogState(() => status = val!),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use Cooperating Org Official QR', style: TextStyle(fontSize: 12)),
                subtitle: Text('Routes to ${f.cooperatingOrgName}', style: const TextStyle(fontSize: 10)),
                value: useOrgQr,
                onChanged: (val) => setDialogState(() => useOrgQr = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                widget.state.moderateFundraiser(
                  f.id,
                  status: status,
                  targetAmount: double.tryParse(targetCtrl.text),
                  useOrgQr: useOrgQr,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save Moderation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ],
    );
  }
}
