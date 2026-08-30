import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../screens/terms_of_service_screen.dart';
import '../screens/privacy_policy_screen.dart';

class LegalViewer {
  static void openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
    );
  }

  static void openPrivacy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  static void showCompanyInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.business_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'About Nammal Tech',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nammal Tech Innovations',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Digital Healthcare & Community Operating Systems',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'CareLink Kerala is architected, developed, and maintained by Nammal Tech. All software rights, patent-pending clinical triage workflows, and proprietary algorithms are owned by Nammal Tech.',
              style: TextStyle(fontSize: 12, height: 1.35, color: isDark ? AppColors.darkTextLight : null),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('• Legal Entity: Nammal Tech Private Limited', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                  Text('• Headquarters: Kerala, India', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                  Text('• Support: support@nammaltech.com', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                  Text('• Legal: legal@nammaltech.com', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '© 2026 Nammal Tech. All Rights Reserved.',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openTerms(context);
            },
            child: const Text('Terms'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openPrivacy(context);
            },
            child: const Text('Privacy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Reusable agreement widget with clickable Terms & Privacy links
  static Widget buildTermsCheckbox({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool?> onChanged,
    String? prefixText,
    bool isDark = false,
  }) {
    final primaryColor = isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          activeColor: primaryColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          onChanged: onChanged,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  prefixText ?? 'I agree to the ',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextLight : AppColors.textPrimary,
                  ),
                ),
                InkWell(
                  onTap: () => openTerms(context),
                  child: Text(
                    'Terms of Service',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' and ',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextLight : AppColors.textPrimary,
                  ),
                ),
                InkWell(
                  onTap: () => openPrivacy(context),
                  child: Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' provided by Nammal Tech *',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextLight : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
