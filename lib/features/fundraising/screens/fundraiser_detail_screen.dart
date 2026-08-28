import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/clinical_models.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/payment_gateway_dialog.dart';


class FundraiserDetailScreen extends StatelessWidget {
  final AppStateProvider state;
  final MedicalFundraiserModel fundraiser;

  const FundraiserDetailScreen({
    super.key,
    required this.state,
    required this.fundraiser,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = (fundraiser.percentFunded * 100).toInt();

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Treatment Appeal Details'),
            actions: [
              IconButton(
                tooltip: 'Share on WhatsApp',
                icon: const Icon(Icons.share_rounded, color: Colors.teal),
                onPressed: () => _shareOnWhatsApp(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor & Hospital Verification Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.primaryGreen, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verified Medical Board Appeal',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Treating Physician: ${fundraiser.doctorName}\n${fundraiser.hospitalName}',
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Cooperating Organization & QR Routing Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceLight : const Color(0xFFF1F8F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          fundraiser.useOrgQr ? Icons.account_balance_rounded : Icons.qr_code_rounded,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  fundraiser.useOrgQr ? 'Cooperating Org QR:' : 'Custom Campaign QR:',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryGreen),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    fundraiser.useOrgQr ? fundraiser.cooperatingOrgName : '${fundraiser.patientName} Escrow Fund',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fundraiser.useOrgQr
                                  ? 'All funds collected via official account QR of ${fundraiser.cooperatingOrgName}.'
                                  : 'Dedicated campaign QR (UPI: ${fundraiser.customUpiId ?? "Registered Escrow"}).',
                              style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openPaymentModal(context),
                        icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                        label: const Text('Scan QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),


                // Treatment Title Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fundraiser.treatmentTitle,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${fundraiser.patientName} (${fundraiser.patientAge}y • ${fundraiser.patientGender} • ${fundraiser.bloodGroup})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${fundraiser.ward}, ${fundraiser.district}',
                                style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Progress Stats Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSand,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${fundraiser.collectedAmount.toInt()} Raised',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                                  ),
                                  Text(
                                    '$pct% of ₹${fundraiser.targetAmount.toInt()}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: fundraiser.percentFunded,
                                  minHeight: 8,
                                  backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade300,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Remaining: ₹${fundraiser.remainingAmount.toInt()}',
                                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                    ),
                                  ),
                                  Text(
                                    '${fundraiser.donorsCount} Donors • ${fundraiser.daysRemaining} days left',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Medical Case & Financial Story
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Medical Appeal Story', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          fundraiser.story,
                          style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        ),
                        const Divider(height: 24),
                        const Text('Hospital Cost Estimate Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          fundraiser.medicalEstimateSummary,
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Bottom Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPaymentModal(context),
                    icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                    label: const Text(
                      'Contribute to Treatment Fund',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareOnWhatsApp(context),
                    icon: const Icon(Icons.share_rounded, color: Colors.teal),
                    label: const Text('Share Appeal on WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _shareOnWhatsApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Treatment Appeal copied: "Urgent Medical Appeal: Support ${fundraiser.treatmentTitle} for ${fundraiser.patientName} at ${fundraiser.hospitalName}. Donate on CareLink Kerala."',
        ),
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openPaymentModal(BuildContext context) {
    PaymentGatewayDialog.show(
      context,
      state: state,
      title: fundraiser.treatmentTitle,
      category: 'Medical Appeal (${fundraiser.patientName})',
      defaultAmount: 1000.0,
      fundraiserId: fundraiser.id,
      fundraiser: fundraiser,
    );
  }
}

