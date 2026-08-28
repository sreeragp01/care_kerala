import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../constants/app_colors.dart';
import '../models/clinical_models.dart';
import '../models/user_model.dart';
import '../services/razorpay_service.dart';
import '../state/app_state_provider.dart';

class PaymentGatewayDialog extends StatefulWidget {
  final AppStateProvider state;
  final String title;
  final String category;
  final double defaultAmount;
  final String? fundraiserId;
  final MedicalFundraiserModel? fundraiser;
  final VoidCallback? onPaymentSuccess;

  const PaymentGatewayDialog({
    super.key,
    required this.state,
    required this.title,
    required this.category,
    this.defaultAmount = 1000.0,
    this.fundraiserId,
    this.fundraiser,
    this.onPaymentSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required AppStateProvider state,
    required String title,
    required String category,
    double defaultAmount = 1000.0,
    String? fundraiserId,
    MedicalFundraiserModel? fundraiser,
    VoidCallback? onPaymentSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PaymentGatewayDialog(
        state: state,
        title: title,
        category: category,
        defaultAmount: defaultAmount,
        fundraiserId: fundraiserId,
        fundraiser: fundraiser,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }

  @override
  State<PaymentGatewayDialog> createState() => _PaymentGatewayDialogState();
}

class _PaymentGatewayDialogState extends State<PaymentGatewayDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _prayerController;
  late TextEditingController _customAmountController;
  late TextEditingController _upiRefController;

  double _selectedAmount = 1000.0;
  bool _isCustomAmount = false;
  bool _isAnonymous = false;
  bool _isProcessing = false;
  String _selectedRazorpayMethod = 'UPI';

  OrganizationModel get _activeOrg =>
      widget.state.activeOrganization ??
      OrganizationModel(
        id: 'org_kozhikode',
        name: 'Kozhikode Palliative Care Society',
        district: 'Kozhikode',
        registrationNumber: 'KZD/NGO/2012/482',
        phone: '+91 495 272 1000',
        upiId: 'kozhikodepalliative@sbi',
        bankAccountName: 'Kozhikode Palliative Care Society Main A/C',
        bankAccountNumber: '389201948201',
        ifscCode: 'SBIN0001234',
        bankName: 'State Bank of India (Calicut Main Branch)',
        activePatientsCount: 142,
        totalVisitsCount: 1840,
      );

  /// Resolves the cooperating organization for a campaign or defaults to active organization
  OrganizationModel get _cooperatingOrg {
    if (widget.fundraiser != null) {
      final match = widget.state.organizations.firstWhere(
        (o) => o.id == widget.fundraiser!.cooperatingOrgId || o.name == widget.fundraiser!.cooperatingOrgName,
        orElse: () => _activeOrg,
      );
      return match;
    }
    return _activeOrg;
  }

  /// Whether the payment uses the organization's verified QR or a custom campaign QR
  bool get _isUsingOrgQr {
    if (widget.fundraiser != null) {
      return widget.fundraiser!.useOrgQr;
    }
    return true; // Direct donations always use Org Main QR
  }

  /// Active UPI VPA ID
  String get _activeUpiId {
    if (widget.fundraiser != null && !widget.fundraiser!.useOrgQr && widget.fundraiser!.customUpiId?.isNotEmpty == true) {
      return widget.fundraiser!.customUpiId!;
    }
    return _cooperatingOrg.upiId.isNotEmpty ? _cooperatingOrg.upiId : 'kozhikodepalliative@sbi';
  }

  /// Active Beneficiary Display Name
  String get _activePayeeName {
    if (widget.fundraiser != null) {
      return _isUsingOrgQr ? _cooperatingOrg.name : '${widget.fundraiser!.patientName} Treatment Fund';
    }
    return _cooperatingOrg.name;
  }

  /// Generated UPI Intent Payload
  String get _upiPayload {
    final amt = _effectiveAmount;
    final vpa = _activeUpiId;
    final pn = Uri.encodeComponent(_activePayeeName);
    final note = Uri.encodeComponent('${widget.category}: ${widget.title}');
    return 'upi://pay?pa=$vpa&pn=$pn&am=${amt.toStringAsFixed(2)}&cu=INR&tn=$note';
  }

  double get _effectiveAmount {
    if (_isCustomAmount) {
      return double.tryParse(_customAmountController.text.trim()) ?? 1000.0;
    }
    return _selectedAmount;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedAmount = widget.defaultAmount;
    _nameController = TextEditingController(text: widget.state.currentUser.name);
    _prayerController = TextEditingController();
    _customAmountController = TextEditingController(text: widget.defaultAmount.toInt().toString());
    _upiRefController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _prayerController.dispose();
    _customAmountController.dispose();
    _upiRefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width > 600 ? 540.0 : (size.width - 24);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header Bar
            _buildDialogHeader(isDark),

            // Tab Bar: Razorpay / Scan UPI QR / Bank Transfer
            Container(
              color: isDark ? AppColors.darkSurfaceLight : Colors.grey.shade50,
              child: TabBar(
                controller: _tabController,
                indicatorColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                indicatorWeight: 3,
                labelColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(icon: Icon(Icons.bolt_rounded, size: 18), text: 'Razorpay'),
                  Tab(icon: Icon(Icons.qr_code_2_rounded, size: 18), text: 'Scan UPI QR'),
                  Tab(icon: Icon(Icons.account_balance_rounded, size: 18), text: 'Bank A/C'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRazorpayTab(isDark),
                  _buildUpiQrTab(isDark),
                  _buildBankTransferTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F8F5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.volunteer_activism_rounded,
              color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.close, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),

                // Cooperating Organization Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isUsingOrgQr
                        ? (isDark ? AppColors.darkLightGreenSurface : const Color(0xFFE8F5E9))
                        : (isDark ? const Color(0xFF332A15) : const Color(0xFFFFF8E1)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isUsingOrgQr
                          ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen.withValues(alpha: 0.5))
                          : Colors.amber.shade700,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isUsingOrgQr ? Icons.verified_user_rounded : Icons.shield_outlined,
                        size: 13,
                        color: _isUsingOrgQr ? AppColors.primaryGreen : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _isUsingOrgQr
                              ? 'Cooperating Org Account: ${_cooperatingOrg.name}'
                              : 'Dedicated Escrow QR for ${widget.fundraiser?.patientName ?? "Patient"}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _isUsingOrgQr
                                ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                                : Colors.amber.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: RAZORPAY GATEWAY ---
  Widget _buildRazorpayTab(bool isDark) {
    final amt = _effectiveAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Selector
          _buildAmountSelector(isDark),
          const SizedBox(height: 14),

          // Donor Details Box
          _buildDonorInputSection(isDark),
          const SizedBox(height: 16),

          // Razorpay Method Selector Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceLight : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C2340),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Razorpay',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Payment Gateway',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, size: 12, color: Colors.green),
                        SizedBox(width: 3),
                        Text('256-bit SSL Secured', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPaymentMethodTile('UPI', 'Google Pay, PhonePe, Paytm', Icons.qr_code_rounded, isDark),
                    _buildPaymentMethodTile('Cards', 'Debit & Credit Cards (RuPay, Visa)', Icons.credit_card_rounded, isDark),
                    _buildPaymentMethodTile('NetBanking', 'All Indian Banks (SBI, HDFC)', Icons.account_balance_outlined, isDark),
                    _buildPaymentMethodTile('Wallets', 'Amazon Pay, Mobikwik & EMI', Icons.account_balance_wallet_outlined, isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tax Exemption 80G Notification
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkLightGreenSurface : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Instant 80G Tax Exemption Digital Receipt generated on payment success.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Razorpay Pay Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleRazorpayPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C2340),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Pay ₹${amt.toInt()} via Razorpay ($_selectedRazorpayMethod)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(String id, String desc, IconData icon, bool isDark) {
    final isSelected = _selectedRazorpayMethod == id;
    return InkWell(
      onTap: () => setState(() => _selectedRazorpayMethod = id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                : (isDark ? AppColors.darkCardBorder : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen) : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  id,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen) : null,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(fontSize: 9, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: SCAN & PAY UPI QR CODE ---
  Widget _buildUpiQrTab(bool isDark) {
    final amt = _effectiveAmount;
    final upiString = _upiPayload;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Amount Selector
          _buildAmountSelector(isDark),
          const SizedBox(height: 14),

          // Routing Notice Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceLight : const Color(0xFFF1F8F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded, size: 22, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isUsingOrgQr ? 'Cooperating Organization Main Account QR' : 'Dedicated Campaign Escrow Account QR',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                      ),
                      Text(
                        _isUsingOrgQr
                            ? 'Funds deposited directly into ${_cooperatingOrg.name}\'s verified bank account.'
                            : 'Dedicated campaign QR for ${widget.fundraiser?.patientName ?? "Patient"}.',
                        style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Dynamic QR Code Canvas Container
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: QrImageView(
                      data: upiString,
                      version: QrVersions.auto,
                      size: 170.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F5132),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Scan with GPay / PhonePe / Paytm / BHIM',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // UPI ID Display with Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceLight : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('UPI ID (VPA):', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      SelectableText(
                        _activeUpiId,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _activeUpiId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('UPI ID "$_activeUpiId" copied to clipboard!'),
                        backgroundColor: AppColors.primaryGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copy', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Donor Name & Note input
          _buildDonorInputSection(isDark),
          const SizedBox(height: 14),

          // Optional UPI Reference Number & Payment Confirmation
          TextField(
            controller: _upiRefController,
            decoration: const InputDecoration(
              labelText: 'UPI Reference / UTR Number (Optional)',
              hintText: 'e.g. 421098129038',
              prefixIcon: Icon(Icons.tag_rounded),
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleUpiPaymentConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(
                'I Have Paid ₹${amt.toInt()} via UPI QR',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: DIRECT BANK TRANSFER (NEFT / IMPS) ---
  Widget _buildBankTransferTab(bool isDark) {
    final org = _cooperatingOrg;
    final amt = _effectiveAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAmountSelector(isDark),
          const SizedBox(height: 14),

          // Official Organization Bank Account Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${org.name} Official Bank A/C',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildBankDetailRow('Account Name', org.bankAccountName.isNotEmpty ? org.bankAccountName : org.name, isDark),
                  _buildBankDetailRow('Account Number', org.bankAccountNumber.isNotEmpty ? org.bankAccountNumber : '389201948201', isDark, canCopy: true),
                  _buildBankDetailRow('IFSC Code', org.ifscCode.isNotEmpty ? org.ifscCode : 'SBIN0001234', isDark, canCopy: true),
                  _buildBankDetailRow('Bank & Branch', org.bankName.isNotEmpty ? org.bankName : 'State Bank of India (Calicut Main)', isDark),
                  _buildBankDetailRow('Account Type', 'Current Account (Palliative Charitable Trust)', isDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          _buildDonorInputSection(isDark),
          const SizedBox(height: 14),

          TextField(
            controller: _upiRefController,
            decoration: const InputDecoration(
              labelText: 'Bank NEFT / IMPS Reference / UTR Number',
              hintText: 'e.g. SBIN2608129038',
              prefixIcon: Icon(Icons.receipt_rounded),
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleBankTransferConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.task_alt_rounded, size: 18),
              label: Text(
                'Submit Bank Transfer (₹${amt.toInt()})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value, bool isDark, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          if (canCopy)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label "$value" copied!'),
                    backgroundColor: AppColors.primaryGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.copy, size: 14, color: AppColors.primaryGreen),
              ),
            ),
        ],
      ),
    );
  }

  // --- REUSABLE AMOUNT & DONOR DETAILS ---
  Widget _buildAmountSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contribution Amount (₹):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [500.0, 1000.0, 2500.0, 5000.0, 10000.0].map((amt) {
            final isSelected = !_isCustomAmount && _selectedAmount == amt;
            return ChoiceChip(
              label: Text('₹${amt.toInt()}', style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              selectedColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
              onSelected: (_) {
                setState(() {
                  _isCustomAmount = false;
                  _selectedAmount = amt;
                  _customAmountController.text = amt.toInt().toString();
                });
              },
            );
          }).toList()
            ..add(
              ChoiceChip(
                label: const Text('Custom ₹', style: TextStyle(fontSize: 11)),
                selected: _isCustomAmount,
                selectedColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                onSelected: (_) => setState(() => _isCustomAmount = true),
              ),
            ),
        ),
        if (_isCustomAmount) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Enter Custom Amount (₹)',
              prefixIcon: Icon(Icons.currency_rupee),
              isDense: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDonorInputSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Donate Anonymously', style: TextStyle(fontSize: 12)),
          subtitle: const Text('Name hidden on public feeds & gratitude records', style: TextStyle(fontSize: 10)),
          value: _isAnonymous,
          onChanged: (val) => setState(() => _isAnonymous = val ?? false),
        ),
        if (!_isAnonymous) ...[
          const SizedBox(height: 4),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Donor Full Name',
              prefixIcon: Icon(Icons.person_outline),
              isDense: true,
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: _prayerController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Healing Blessing / Prayer Note (Optional)',
            hintText: 'e.g. Wishing safe treatment and speedy recovery...',
            prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
            isDense: true,
          ),
        ),
      ],
    );
  }

  // --- ACTIONS & HANDLERS ---
  Future<void> _handleRazorpayPayment() async {
    setState(() => _isProcessing = true);
    final amt = _effectiveAmount;
    final donorName = _isAnonymous ? 'Anonymous Well-Wisher' : (_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Kind Supporter');
    final prayer = _prayerController.text.trim().isNotEmpty ? _prayerController.text.trim() : null;

    try {
      // 1. Initialize Razorpay Order
      final orderResult = await RazorpayService.createOrder(
        amount: amt,
        category: widget.category,
        organization: _cooperatingOrg,
        fundraiserId: widget.fundraiserId,
        donorName: donorName,
      );

      // Simulate realistic payment gateway processing delay
      await Future.delayed(const Duration(milliseconds: 1200));

      final mockPaymentId = 'pay_rzp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final mockSignature = 'sig_${Random().nextInt(99999999)}';

      // 2. Verify and Record Payment
      final verifyResult = await RazorpayService.verifyAndRecordPayment(
        orderId: orderResult.orderId,
        paymentId: mockPaymentId,
        signature: mockSignature,
        amount: amt,
        donorName: donorName,
        category: widget.category,
        organization: _cooperatingOrg,
        fundraiserId: widget.fundraiserId,
        donorPrayer: prayer,
        isAnonymous: _isAnonymous,
      );

      if (verifyResult.isSuccess && verifyResult.donation != null) {
        // Record in app state
        if (widget.fundraiserId != null) {
          widget.state.donateToMedicalFundraiser(
            widget.fundraiserId!,
            amt,
            donorName,
            donorPrayer: prayer,
            isAnonymous: _isAnonymous,
            paymentMode: 'Razorpay',
            razorpayPaymentId: mockPaymentId,
          );
        } else {
          widget.state.addDonation(verifyResult.donation!);
        }

        widget.onPaymentSuccess?.call();
        if (mounted) {
          Navigator.pop(context);
          _showPaymentSuccessReceiptDialog(
            context,
            verifyResult.donation!,
            _cooperatingOrg,
            'Razorpay Gateway ($_selectedRazorpayMethod)',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleUpiPaymentConfirmation() async {
    setState(() => _isProcessing = true);
    final amt = _effectiveAmount;
    final donorName = _isAnonymous ? 'Anonymous Well-Wisher' : (_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Kind Supporter');
    final prayer = _prayerController.text.trim().isNotEmpty ? _prayerController.text.trim() : null;
    final utr = _upiRefController.text.trim().isNotEmpty ? _upiRefController.text.trim() : 'UPI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    await Future.delayed(const Duration(milliseconds: 600));

    final donation = DonationModel(
      id: 'DON-UPI-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      donorName: donorName,
      amount: amt,
      category: widget.category,
      paymentMode: 'UPI_QR',
      receiptNumber: '80G-UPI-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      date: '2026-08-07',
      transactionId: utr,
      isVerified: true,
      donorPrayer: prayer,
      isAnonymous: _isAnonymous,
    );

    if (widget.fundraiserId != null) {
      widget.state.donateToMedicalFundraiser(
        widget.fundraiserId!,
        amt,
        donorName,
        donorPrayer: prayer,
        isAnonymous: _isAnonymous,
        paymentMode: 'UPI_QR',
      );
    } else {
      widget.state.addDonation(donation);
    }

    widget.onPaymentSuccess?.call();
    if (mounted) {
      Navigator.pop(context);
      _showPaymentSuccessReceiptDialog(context, donation, _cooperatingOrg, 'Scan & Pay UPI QR');
    }
  }

  Future<void> _handleBankTransferConfirmation() async {
    setState(() => _isProcessing = true);
    final amt = _effectiveAmount;
    final donorName = _isAnonymous ? 'Anonymous Well-Wisher' : (_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Kind Supporter');
    final prayer = _prayerController.text.trim().isNotEmpty ? _prayerController.text.trim() : null;
    final utr = _upiRefController.text.trim().isNotEmpty ? _upiRefController.text.trim() : 'NEFT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    await Future.delayed(const Duration(milliseconds: 600));

    final donation = DonationModel(
      id: 'DON-BNK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      donorName: donorName,
      amount: amt,
      category: widget.category,
      paymentMode: 'Bank Transfer',
      receiptNumber: '80G-BNK-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      date: '2026-08-07',
      transactionId: utr,
      isVerified: true,
      donorPrayer: prayer,
      isAnonymous: _isAnonymous,
    );

    if (widget.fundraiserId != null) {
      widget.state.donateToMedicalFundraiser(
        widget.fundraiserId!,
        amt,
        donorName,
        donorPrayer: prayer,
        isAnonymous: _isAnonymous,
        paymentMode: 'Bank Transfer',
      );
    } else {
      widget.state.addDonation(donation);
    }

    widget.onPaymentSuccess?.call();
    if (mounted) {
      Navigator.pop(context);
      _showPaymentSuccessReceiptDialog(context, donation, _cooperatingOrg, 'Bank Direct Transfer');
    }
  }

  // --- 80G DIGITAL TAX RECEIPT & GRATITUDE MODAL ---
  void _showPaymentSuccessReceiptDialog(
    BuildContext context,
    DonationModel donation,
    OrganizationModel org,
    String paymentMethodName,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 28),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Donation Received!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Official 80G Tax Exemption Certificate', style: TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width > 500 ? 460 : double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SMS / WhatsApp Notification Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkLightGreenSurface : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.mark_chat_read_rounded, size: 16, color: AppColors.primaryGreen),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '📲 Automated Receipt & Gratitude SMS dispatched to your phone.',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Digital 80G Certificate Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceLight : const Color(0xFFFFFDF7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              org.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Text('₹${donation.amount.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                        ],
                      ),
                      Text('Reg: ${org.registrationNumber}', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                      const Divider(height: 16),

                      _buildCertificateRow('Receipt Ref', '#${donation.receiptNumber}', isDark),
                      _buildCertificateRow('Transaction ID', donation.transactionId ?? 'N/A', isDark),
                      _buildCertificateRow('Donor Name', donation.donorName, isDark),
                      _buildCertificateRow('Fund / Category', donation.category, isDark),
                      _buildCertificateRow('Payment Gateway', paymentMethodName, isDark),
                      _buildCertificateRow('Date', donation.date, isDark),

                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '🏛️ Eligible for 50% deduction under Section 80G of the Income Tax Act 1961.',
                          style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                if (widget.fundraiser != null) ...[
                  Text(
                    'Heartfelt note from ${widget.fundraiser!.patientName}:',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.fundraiser!.patientFamilyGratitudeMessage,
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '80G Tax Exemption Receipt #${donation.receiptNumber} for ₹${donation.amount.toInt()} from ${org.name}.'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tax receipt details copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 14),
            label: const Text('Copy Receipt'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
