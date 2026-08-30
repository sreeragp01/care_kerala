import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
                ),
                child: Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CareLink Kerala • Terms of Service',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Owned & Operated by Nammal Tech\nLast Updated: August 2026',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildSection(
                '1. Acceptance of Terms & Proprietary Rights',
                'By accessing or using the CareLink Kerala application and associated digital services, you agree to be bound by these Terms of Service. CareLink Kerala, including its code, algorithms, visual design, user workflows, and multi-tenant infrastructure, is the exclusive proprietary property of Nammal Tech ("Company"). All intellectual property rights are reserved by Nammal Tech.',
                isDark,
              ),

              _buildSection(
                '2. Scope of Healthcare Platform & Medical Disclaimer',
                'CareLink Kerala is designed to assist community palliative care nurses, doctors, volunteers, emergency dispatchers, and patients across Kerala. While the platform provides clinical decision support, triage alerts, and telemedicine tools, it does not replace independent clinical judgment by certified medical professionals. In severe life-threatening emergencies, users must utilize the 108 Emergency Ambulance service or nearest tertiary hospital.',
                isDark,
              ),

              _buildSection(
                '3. User Roles, Credentials & Account Security',
                'Authorized healthcare professionals (Doctors, Nurses, Pharmacists, Admins) must provide verifiable state registration council numbers. You are solely responsible for maintaining the confidentiality of your credentials (including Super Admin, staff passwords, and OTP verification codes). Unauthorized persona switching, credential sharing, or falsification of electronic health records is strictly prohibited and subject to legal action under applicable laws.',
                isDark,
              ),

              _buildSection(
                '4. Patient Electronic Health Records & Consent',
                'All patient intake, home visit clinical notes, vitals recordings, and palliative equipment loans are recorded in accordance with Indian healthcare regulations and the Digital Personal Data Protection (DPDP) Act. Practitioners must obtain informed consent from patients or authorized family caregivers prior to recording medical data.',
                isDark,
              ),

              _buildSection(
                '5. Multi-Tenant Organization Responsibilities',
                'Participating Palliative Care Societies, NGOs, and Primary Health Centres operate as independent tenant units. Each organization is responsible for verifying its local volunteers, managing donated medical equipment, and distributing medicines in compliance with statutory pharmacy regulations.',
                isDark,
              ),

              _buildSection(
                '6. Donations, Crowdfunding & Razorpay Escrow',
                'All charitable contributions and medical crowdfunding campaigns facilitated through CareLink Kerala are processed via authorized payment gateways (Razorpay / UPI). Nammal Tech provides the technology platform and does not hold custody of charitable funds. Participating organizations are accountable for transparent financial receipts.',
                isDark,
              ),

              _buildSection(
                '7. Limitation of Liability',
                'To the maximum extent permitted by applicable law, Nammal Tech shall not be liable for any indirect, incidental, or consequential damages resulting from platform downtime, network failures during emergency SOS routing, or unauthorized data tampering by third parties.',
                isDark,
              ),

              _buildSection(
                '8. Governing Law & Jurisdiction',
                'These terms shall be governed by and construed in accordance with the laws of the State of Kerala and the Republic of India. Any legal disputes arising out of these terms shall be subject to the exclusive jurisdiction of the competent courts in Kerala, India.',
                isDark,
              ),

              const Divider(height: 32),

              // Company Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      '© 2026 Nammal Tech. All Rights Reserved.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nammal Tech Innovations • Kerala, India\nContact: legal@nammaltech.com',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
