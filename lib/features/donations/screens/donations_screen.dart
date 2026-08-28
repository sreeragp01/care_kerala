import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/payment_gateway_dialog.dart';


class DonationsScreen extends StatelessWidget {
  final AppStateProvider state;

  const DonationsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final donations = state.donations;
        final org = state.activeOrganization ??
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Palliative Care Fund & Donations'),
            actions: [
              IconButton(
                tooltip: 'Scan Organization Main Account QR',
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: () {
                  PaymentGatewayDialog.show(
                    context,
                    state: state,
                    title: '${org.name} Community Fund',
                    category: 'General Palliative Fund',
                    defaultAmount: 1000.0,
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Fund Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: isDark ? AppColors.darkSurfaceLight : AppColors.accentGoldLight,
                  child: Column(
                    children: [
                      Text(
                        'Total Community Fund Balance',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${state.totalDonationsFund.toInt()}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Managed under ${org.name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Organization Main Account QR & Banking Profile Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance_rounded,
                                  color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${org.name} Official Main A/C',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      'Official verified account & QR for direct contributions',
                                      style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),

                          // UPI & Bank Details
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Primary Org UPI ID:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    SelectableText(
                                      org.upiId.isNotEmpty ? org.upiId : 'kozhikodepalliative@sbi',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copy UPI ID',
                                icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryGreen),
                                onPressed: () {
                                  final vpa = org.upiId.isNotEmpty ? org.upiId : 'kozhikodepalliative@sbi';
                                  Clipboard.setData(ClipboardData(text: vpa));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('UPI ID "$vpa" copied!'), backgroundColor: AppColors.primaryGreen),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bank: ${org.bankName.isNotEmpty ? org.bankName : "SBI Calicut"} • A/C: ${org.bankAccountNumber.isNotEmpty ? org.bankAccountNumber : "389201948201"} • IFSC: ${org.ifscCode.isNotEmpty ? org.ifscCode : "SBIN0001234"}',
                            style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),

                          // Buttons: Pay with Razorpay / Scan Org QR
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    PaymentGatewayDialog.show(
                                      context,
                                      state: state,
                                      title: '${org.name} Community Fund',
                                      category: 'General Palliative Fund',
                                      defaultAmount: 1000.0,
                                    );
                                  },
                                  icon: const Icon(Icons.bolt_rounded, size: 16, color: Colors.amber),
                                  label: const Text('Donate (Razorpay / QR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Donation Ledger Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Community Contributions',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${donations.length} Donations',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Donation list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: donations.length,
                  itemBuilder: (ctx, i) {
                    final d = donations[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                          child: Icon(
                            d.paymentMode == 'Razorpay' ? Icons.bolt_rounded : Icons.volunteer_activism_rounded,
                            color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                          ),
                        ),
                        title: Text(d.donorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fund: ${d.category}', style: const TextStyle(fontSize: 11)),
                            Text(
                              'Receipt: #${d.receiptNumber} • ${d.paymentMode} • ${d.date}',
                              style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+₹${d.amount.toInt()}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkLightGreenSurface : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('80G Verified', style: TextStyle(fontSize: 8, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
            onPressed: () {
              PaymentGatewayDialog.show(
                context,
                state: state,
                title: '${org.name} Community Fund',
                category: 'General Palliative Fund',
                defaultAmount: 1000.0,
              );
            },
            icon: const Icon(Icons.favorite_rounded, color: Colors.white),
            label: const Text('Donate Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

