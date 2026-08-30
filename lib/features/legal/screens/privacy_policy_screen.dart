import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                    Icon(Icons.privacy_tip_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CareLink Kerala • Data Privacy Policy',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Protected by Nammal Tech Healthcare Cloud\nLast Updated: August 2026',
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
                '1. Commitment to Data Protection & Privacy',
                'Nammal Tech ("we", "our", "Company") is committed to protecting the sensitive personal and health information of patients, families, healthcare professionals, and donors utilizing the CareLink Kerala platform. This policy explains how information is collected, safeguarded, and processed in compliance with the Digital Personal Data Protection (DPDP) Act and Indian healthcare data standards.',
                isDark,
              ),

              _buildSection(
                '2. Information We Collect',
                '• Patient Electronic Health Records (EHR): Name, age, gender, diagnosis, category tier, vitals readings (BP, SpO2, pulse, pain scale), care plans, and emergency contacts.\n• Healthcare Staff Data: Name, professional council registration numbers, phone numbers, assigned organization, and home visit audit logs.\n• Location Data: GPS coordinates collected exclusively during active emergency SOS dispatch and nurse home visit check-in.\n• Donor Records: Contribution amounts, PAN details for 80G tax receipts, and payment transaction IDs.',
                isDark,
              ),

              _buildSection(
                '3. How We Use and Safeguard Medical Data',
                'Health records collected on CareLink Kerala are utilized exclusively to:\n• Coordinate home visit routing and bedside palliative nursing.\n• Trigger clinical safety alerts (e.g. SpO2 < 92% escalation to doctors).\n• Verify volunteer and medical equipment loans across Kerala districts.\n• All electronic health data is encrypted in transit via TLS 1.3 and at rest with AES-256 encryption on secure servers.',
                isDark,
              ),

              _buildSection(
                '4. Role-Based Access Control & Multi-Tenancy',
                'Patient data is strictly segmented by tenant organization and role. Clinical notes and vitals are accessible only by certified medical doctors, registered nurses, and verified ward volunteers assigned to the specific patient. Cross-district or unauthorized data export is strictly blocked.',
                isDark,
              ),

              _buildSection(
                '5. Emergency SOS & 108 Dispatch Sharing',
                'When an Emergency SOS distress call is initiated by a patient or family caregiver, vital triage metrics and real-time location data are securely dispatched to the nearest 108 ambulance driver and on-call triage doctor to facilitate life-saving intervention.',
                isDark,
              ),

              _buildSection(
                '6. Data Retention, Patient Rights & Portability',
                'Patients and legal caregivers retain the right to review their health record summaries, request corrections, or request data archiving upon discharge from home palliative care. Requests can be submitted through tenant administrators or directly to the Nammal Tech Privacy Officer.',
                isDark,
              ),

              _buildSection(
                '7. Changes to this Policy',
                'Nammal Tech reserves the right to periodically update this privacy policy to reflect evolving statutory healthcare mandates or platform capabilities. Continued usage of CareLink Kerala signifies acceptance of updated terms.',
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
                      'Data Protection & Privacy Officer: privacy@nammaltech.com\nNammal Tech Innovations • Kerala, India',
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
