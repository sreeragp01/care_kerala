import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/user_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../emergency_sos/screens/emergency_sos_screen.dart';
import '../../../core/widgets/kerala_location_selector.dart';
import 'staff_registration_screen.dart';
import '../../patients/screens/patient_registration_screen.dart';
import '../../legal/widgets/legal_viewer.dart';
import '../../../core/widgets/carelink_brand_logo.dart';


class LoginScreen extends StatefulWidget {
  final AppStateProvider state;

  const LoginScreen({super.key, required this.state});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _patientOtpController = TextEditingController();

  bool _isStaffMode = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _patientOtpSent = false;
  String? _patientGeneratedOtp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _patientOtpController.dispose();
    super.dispose();
  }

  Future<void> _handleStaffSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your registered email or username.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.state.authenticate(
      emailOrUsername: email,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(state: widget.state),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid email or password. Please check your credentials.';
      });
    }
  }

  Future<void> _handlePatientSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit registered mobile number.');
      return;
    }

    final otp = widget.state.requestPasswordResetOtp(phone);
    setState(() {
      _patientOtpSent = true;
      _patientGeneratedOtp = otp;
      _errorMessage = null;
    });
  }

  Future<void> _handlePatientVerifyAndSignIn() async {
    final phone = _phoneController.text.trim();
    final otp = _patientOtpController.text.trim();

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the valid 6-digit OTP code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.state.authenticatePatientByPhone(
      phone: phone,
      otp: otp,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(state: widget.state),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid or expired OTP code. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isMalayalam = widget.state.locale.languageCode == 'ml';
    final isDark = widget.state.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Official Brand Logo Emblem & Wordmark
                  CareLinkBrandLogo(
                    size: 88,
                    showWordmark: true,
                    showTagline: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),

                  // "Better Days, Together ♡" Tagline Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandTeal.withValues(alpha: isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.brandTeal.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '“Better Days, Together ♡”',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.brandHealthGreen : AppColors.brandNavy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Emergency SOS Quick Access Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Ambulance & SOS',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.danger),
                              ),
                              Text(
                                'Immediate palliative distress help & 108 dispatch',
                                style: TextStyle(fontSize: 10, color: Color(0xFFC62828)),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmergencySosScreen(state: widget.state),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('SOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Language & Tenant Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSand,
                      borderRadius: BorderRadius.circular(12),
                      border: isDark ? Border.all(color: AppColors.darkCardBorder) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _showTenantSwitcherDialog(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.business_rounded,
                                    color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.state.activeOrganization?.name ?? 'CareLink Org',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'District: ${widget.state.activeOrganization?.district ?? "Kerala"} • Tap to switch',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            widget.state.setLocale(
                              isMalayalam ? const Locale('en') : const Locale('ml'),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            isMalayalam ? 'English' : 'മലയാളം',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Form Card with Mode Toggle
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Portal Mode Switcher Tabs
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isStaffMode = true;
                                      _errorMessage = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isStaffMode
                                          ? (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _isStaffMode
                                            ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.admin_panel_settings_rounded,
                                            size: 16,
                                            color: _isStaffMode
                                                ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Staff & Admin',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _isStaffMode
                                                  ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                                                  : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isStaffMode = false;
                                      _errorMessage = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_isStaffMode
                                          ? (isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: !_isStaffMode
                                            ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.family_restroom_rounded,
                                            size: 16,
                                            color: !_isStaffMode
                                                ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Patient Portal',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: !_isStaffMode
                                                ? (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Error Banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (_isStaffMode) ...[
                            const Text(
                              'Sign In to Healthcare Staff & Administration',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your authorized credentials or Super Admin account.',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                            const SizedBox(height: 14),

                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email or Username *',
                                hintText: 'admin@carelink.kerala.gov.in',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password *',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showForgotPasswordDialog(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleStaffSignIn,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'Sign In to Dashboard',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                            ),
                            const SizedBox(height: 12),

                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StaffRegistrationScreen(state: widget.state),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                              label: const Text('New Healthcare Staff? Register Here', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),

                            OutlinedButton.icon(
                              onPressed: () => _showRegisterOrgDialog(context),
                              icon: const Icon(Icons.add_business_rounded, size: 16),
                              label: Text(loc.translate('register_org'), style: const TextStyle(fontSize: 12)),
                            ),
                          ] else ...[
                            const Text(
                              'Patient & Caregiver Access',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Access your home care visits, vitals records, and emergency nurse support.',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                            const SizedBox(height: 14),

                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Registered Mobile Number *',
                                hintText: '+91 98470 12345',
                                prefixIcon: Icon(Icons.phone_android_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (_patientOtpSent) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.mark_email_read_rounded,
                                      color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'OTP sent to ${_phoneController.text.trim()}:\nCode: $_patientGeneratedOtp',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (_patientGeneratedOtp != null) {
                                          _patientOtpController.text = _patientGeneratedOtp!;
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text('Auto-Fill', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextField(
                                controller: _patientOtpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: const InputDecoration(
                                  labelText: 'Enter 6-Digit OTP *',
                                  prefixIcon: Icon(Icons.pin_outlined),
                                  counterText: '',
                                ),
                              ),
                              const SizedBox(height: 16),

                              ElevatedButton(
                                onPressed: _isLoading ? null : _handlePatientVerifyAndSignIn,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Verify & Enter Patient Portal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _handlePatientSendOtp,
                                icon: const Icon(Icons.send_rounded, size: 16),
                                label: const Text('Send Verification OTP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PatientRegistrationScreen(state: widget.state),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.person_add_rounded, size: 16),
                              label: const Text('New Patient? Enroll for Home Care', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nammal Tech Legal & Company Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => LegalViewer.openTerms(context),
                        child: Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      Text(' • ', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                      InkWell(
                        onTap: () => LegalViewer.openPrivacy(context),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      Text(' • ', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                      InkWell(
                        onTap: () => LegalViewer.showCompanyInfo(context),
                        child: Text(
                          'Nammal Tech',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 Nammal Tech. All Rights Reserved.',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTenantSwitcherDialog(BuildContext context) {
    final isMalayalam = widget.state.locale.languageCode == 'ml';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.business_rounded, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(
              isMalayalam ? 'സംഘടന തിരഞ്ഞെടുക്കുക' : 'Select Organization',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...widget.state.organizations.map((org) {
                final isSelected = widget.state.activeOrganization?.id == org.id;
                final districtName = AppLocalizations.getDistrictName(org.district, isMalayalam: isMalayalam);
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: isSelected ? AppColors.primaryGreen : AppColors.lightGreenSurface,
                    child: Icon(Icons.location_city_rounded, size: 16, color: isSelected ? Colors.white : AppColors.primaryGreen),
                  ),
                  title: Text(org.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                  subtitle: Text(
                    isMalayalam
                        ? '$districtName ജില്ല • ${org.activePatientsCount} നിലവിലെ രോഗികൾ'
                        : '${org.district} District • ${org.activePatientsCount} Active Patients',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 18) : null,
                  onTap: () {
                    widget.state.switchOrganization(org);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const Divider(height: 16),
              ListTile(
                dense: true,
                leading: const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.lightSand,
                  child: Icon(Icons.add_business_rounded, size: 16, color: AppColors.primaryGreen),
                ),
                title: Text(
                  isMalayalam ? 'പുതിയ പ്രാദേശിക സംഘടന രജിസ്റ്റർ ചെയ്യുക' : 'Register New Local Organization',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryGreen),
                ),
                subtitle: Text(
                  isMalayalam ? 'എല്ലാ കേരള മുനിസിപ്പാലിറ്റികളിൽ നിന്നും പഞ്ചായത്തുകളിൽ നിന്നും തിരഞ്ഞെടുക്കാം' : 'Select from all Kerala Municipalities & Panchayats',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRegisterOrgDialog(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMalayalam ? 'അടയ്ക്കുക' : 'Close'),
          ),
        ],
      ),
    );
  }

  void _showRegisterOrgDialog(BuildContext context) {
    String selectedDistrict = 'Thrissur';
    bool agreedToTerms = false;

    final nameCtrl = TextEditingController(text: 'Thrissur Pain and Palliative Care Society');
    final regNumberCtrl = TextEditingController(text: 'TCR/NGO/2026/089');
    final phoneCtrl = TextEditingController(text: '+91 487 2320000');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_business_rounded, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Register Organization Unit',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kerala Local Self Government & Palliative Unit Directory:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                    ),
                    const SizedBox(height: 10),

                    // Kerala Location Selector with Smart Suggestion Search & Cascading Dropdowns
                    KeralaLocationSelector(
                      initialDistrict: selectedDistrict,
                      showWard: false,
                      showPalliativeUnit: true,
                      showMedicareCenter: true,
                      showRegisteredClub: true,
                      onLocationChanged: ({required district, required localBody, palliativeUnit, medicareCenter, registeredClub, ward}) {
                        setDialogState(() {
                          selectedDistrict = district;
                          if (palliativeUnit != null && palliativeUnit.isNotEmpty) {
                            nameCtrl.text = palliativeUnit;
                          } else {
                            nameCtrl.text = '$localBody Palliative Society';
                          }
                          regNumberCtrl.text = '${district.substring(0, 3).toUpperCase()}/NGO/2026/${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Organization / Clinic Name',
                        prefixIcon: Icon(Icons.business_rounded, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: regNumberCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Government Registration / NGO License Number',
                        prefixIcon: Icon(Icons.badge_rounded, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Primary Contact Phone',
                        prefixIcon: Icon(Icons.phone_rounded, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    LegalViewer.buildTermsCheckbox(
                      context: context,
                      value: agreedToTerms,
                      onChanged: (val) => setDialogState(() => agreedToTerms = val ?? false),
                      prefixText: 'Unit Auth: I accept ',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (!agreedToTerms) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please accept the Terms of Service & Privacy Policy provided by Nammal Tech to register.')),
                    );
                    return;
                  }

                  if (nameCtrl.text.isNotEmpty) {
                    final newOrg = OrganizationModel(
                      id: 'org_${selectedDistrict.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                      name: nameCtrl.text.trim(),
                      district: selectedDistrict,
                      registrationNumber: regNumberCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      activePatientsCount: 1,
                      totalVisitsCount: 0,
                    );
                    widget.state.registerOrganization(newOrg);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ Registered & Switched to: ${newOrg.name} (${newOrg.district})'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Register & Activate Tenant'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailCtrl = TextEditingController(text: _emailController.text.isNotEmpty ? _emailController.text : 'anitha@carelink.kerala.gov.in');
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    int step = 1; // 1: Enter email, 2: Enter OTP & New Password
    String? generatedOtp;
    String? errorMessage;
    bool obscureNewPass = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.lightGreenSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Password Recovery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step == 1) ...[
                  const Text(
                    'Enter your registered staff email or phone number. We will dispatch a 6-digit recovery OTP code.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Registered Email or Phone Number *',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                      isDense: true,
                    ),
                  ),
                ] else ...[
                  // OTP Dispatch Notification Banner
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreenSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_read_rounded, color: AppColors.primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'OTP sent to ${emailCtrl.text.trim()}:\nCode: $generatedOtp',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (generatedOtp != null) {
                              setDialogState(() => otpCtrl.text = generatedOtp!);
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Auto-Fill', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Enter 6-Digit OTP *',
                      prefixIcon: Icon(Icons.pin_outlined, size: 20),
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscureNewPass,
                    decoration: InputDecoration(
                      labelText: 'New Password *',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNewPass ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setDialogState(() => obscureNewPass = !obscureNewPass),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: obscureNewPass,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password *',
                      prefixIcon: Icon(Icons.lock_clock_outlined, size: 20),
                      isDense: true,
                    ),
                  ),
                ],

                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMessage!,
                    style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            if (step == 1)
              ElevatedButton.icon(
                onPressed: () {
                  final email = emailCtrl.text.trim();
                  if (email.isEmpty) {
                    setDialogState(() => errorMessage = 'Please enter your email or phone number.');
                    return;
                  }
                  final otp = widget.state.requestPasswordResetOtp(email);
                  setDialogState(() {
                    step = 2;
                    generatedOtp = otp;
                    errorMessage = null;
                  });
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send Recovery OTP'),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  final otp = otpCtrl.text.trim();
                  final newPass = newPassCtrl.text.trim();
                  final confirmPass = confirmPassCtrl.text.trim();

                  if (otp.length != 6) {
                    setDialogState(() => errorMessage = 'Please enter the valid 6-digit OTP code.');
                    return;
                  }
                  if (newPass.length < 6) {
                    setDialogState(() => errorMessage = 'Password must be at least 6 characters.');
                    return;
                  }
                  if (newPass != confirmPass) {
                    setDialogState(() => errorMessage = 'Passwords do not match.');
                    return;
                  }

                  final success = widget.state.verifyAndResetPassword(
                    emailOrPhone: emailCtrl.text.trim(),
                    otp: otp,
                    newPassword: newPass,
                  );

                  if (success) {
                    _passwordController.text = newPass;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ Password successfully updated for ${emailCtrl.text.trim()}! You can now sign in.'),
                        backgroundColor: AppColors.primaryGreen,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  } else {
                    setDialogState(() => errorMessage = 'Invalid or expired OTP code. Please try again.');
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Reset Password'),
              ),
          ],
        ),
      ),
    );
  }
}
