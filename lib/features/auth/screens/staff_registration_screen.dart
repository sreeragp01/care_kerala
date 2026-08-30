import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../legal/widgets/legal_viewer.dart';

class StaffRegistrationScreen extends StatefulWidget {
  final AppStateProvider state;

  const StaffRegistrationScreen({super.key, required this.state});

  @override
  State<StaffRegistrationScreen> createState() => _StaffRegistrationScreenState();
}

class _StaffRegistrationScreenState extends State<StaffRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+91 98470 ');
  final _councilRegCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController(text: 'MD Palliative Medicine');
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  UserRole _selectedRole = UserRole.doctor;
  String _selectedDistrict = 'Kozhikode';
  String _selectedOrgId = 'org_kozhikode';
  bool _agreedToEthics = true;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _selectedDistrict = widget.state.activeOrganization?.district ?? 'Kozhikode';
    _selectedOrgId = widget.state.activeOrganization?.id ?? 'org_kozhikode';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _councilRegCtrl.dispose();
    _qualificationCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Staff & Clinical Onboarding', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Palliative Care Healthcare Professional Registration', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: GlassScaffoldBackground(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 16,
                  blur: 12,
                  customFillColor: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.12),
                  customBorderColor: (isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen).withValues(alpha: 0.35),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.badge_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Clinical & Field Staff Portal',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Register as a verified Doctor, Nurse, Volunteer Coordinator, Pharmacist, or Driver in Kerala Palliative Network.',
                              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              // ==========================================
              // SECTION 1: Professional Role
              // ==========================================
              _buildSectionHeader('1. Select Your Healthcare / Field Role', Icons.badge_outlined),
              GlassCard(
                borderRadius: 14,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    DropdownButtonFormField<UserRole>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Select Professional Role *',
                        prefixIcon: Icon(Icons.psychology_alt_rounded, size: 20),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: UserRole.doctor, child: Text('Doctor / Palliative Physician', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: UserRole.nurse, child: Text('Staff Nurse / Home Care Specialist', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: UserRole.volunteer, child: Text('Community Volunteer / Coordinator', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: UserRole.pharmacist, child: Text('Pharmacist / Dispensary Officer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: UserRole.ambulanceDriver, child: Text('Ambulance / Emergency Driver', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: UserRole.orgAdmin, child: Text('Organization Administrator', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedRole = val;
                            if (val == UserRole.doctor) {
                              _qualificationCtrl.text = 'MD Palliative Medicine';
                            } else if (val == UserRole.nurse) {
                              _qualificationCtrl.text = 'B.Sc Nursing (Palliative Certified)';
                            } else if (val == UserRole.pharmacist) {
                              _qualificationCtrl.text = 'B.Pharm / D.Pharm';
                            } else if (val == UserRole.ambulanceDriver) {
                              _qualificationCtrl.text = 'Commercial & Emergency Driver License';
                            } else {
                              _qualificationCtrl.text = 'Graduate / Social Worker';
                            }
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              // SECTION 2: Identity & Contact Details
              // ==========================================
              _buildSectionHeader('2. Personal & Contact Information', Icons.person_outline_rounded),
              GlassCard(
                borderRadius: 14,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: _getRoleNameLabel(),
                        prefixIcon: const Icon(Icons.person_rounded, size: 20),
                        hintText: _getRoleNameHint(),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your full name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Official / Professional Email *',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                        hintText: 'e.g. name@carelink.kerala.gov.in',
                        isDense: true,
                      ),
                      validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Primary Mobile Phone (with WhatsApp) *',
                        prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().length < 8 ? 'Enter valid phone number' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              // SECTION 3: Council Credentials & Qualifications
              // ==========================================
              _buildSectionHeader('3. Council Credentials & Qualifications', Icons.verified_user_rounded),
              GlassCard(
                borderRadius: 14,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _councilRegCtrl,
                      decoration: InputDecoration(
                        labelText: _getCouncilLabel(),
                        prefixIcon: const Icon(Icons.document_scanner_rounded, size: 20),
                        hintText: _getCouncilHint(),
                        isDense: true,
                      ),
                      validator: (v) {
                        if (_selectedRole == UserRole.doctor || _selectedRole == UserRole.nurse) {
                          if (v == null || v.trim().isEmpty) return 'Council registration is mandatory';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _qualificationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Highest Medical / Academic Qualification *',
                        prefixIcon: Icon(Icons.school_rounded, size: 20),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter qualification' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              // SECTION 4: Organization & Jurisdiction
              // ==========================================
              _buildSectionHeader('4. Palliative Organization & District', Icons.domain_rounded),
              GlassCard(
                borderRadius: 14,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDistrict,
                      decoration: const InputDecoration(
                        labelText: 'Operational District *',
                        prefixIcon: Icon(Icons.location_on_rounded, size: 20),
                        isDense: true,
                      ),
                      items: [
                        'Alappuzha', 'Ernakulam', 'Idukki', 'Kannur', 'Kasaragod',
                        'Kollam', 'Kottayam', 'Kozhikode', 'Malappuram', 'Palakkad',
                        'Pathanamthitta', 'Thiruvananthapuram', 'Thrissur', 'Wayanad'
                      ].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => _selectedDistrict = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedOrgId,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Palliative Care Unit *',
                        prefixIcon: Icon(Icons.local_hospital_rounded, size: 20),
                        isDense: true,
                      ),
                      items: widget.state.organizations.map((o) => DropdownMenuItem(value: o.id, child: Text(o.name, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) => setState(() => _selectedOrgId = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              // SECTION 5: Account Password & Ethics Agreement
              // ==========================================
              _buildSectionHeader('5. Account Security & Compassion Oath', Icons.security_rounded),
              GlassCard(
                borderRadius: 14,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Create Account Password *',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password *',
                        prefixIcon: Icon(Icons.lock_clock_outlined, size: 20),
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim() != _passwordCtrl.text.trim()) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'I solemnly agree to abide by the Kerala Palliative Care Code of Ethics, patient confidentiality, and compassionate care guidelines.',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _agreedToEthics,
                      onChanged: (val) => setState(() => _agreedToEthics = val ?? false),
                    ),
                    const SizedBox(height: 4),
                    LegalViewer.buildTermsCheckbox(
                      context: context,
                      value: _agreedToTerms,
                      onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitStaffRegistration,
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text('Complete Professional Registration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      ),
    );
  }


  void _submitStaffRegistration() {
    if (!_agreedToEthics) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Code of Ethics agreement to proceed.')),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms of Service and Privacy Policy provided by Nammal Tech.')),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final newUserId = 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final newUser = UserModel(
        id: newUserId,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: _selectedRole,
        organizationId: _selectedOrgId,
        district: _selectedDistrict,
      );

      // Register into users list and log in as newly registered user
      widget.state.registerStaffUser(newUser);
      widget.state.loginAsUser(newUser);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Welcome ${_nameCtrl.text.trim()}! Registered as ${_selectedRole.displayName}.'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 4),
        ),
      );

      // Navigate to dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => DashboardScreen(state: widget.state)),
        (route) => false,
      );
    }
  }

  String _getRoleNameLabel() {
    switch (_selectedRole) {
      case UserRole.doctor:
        return 'Doctor Name (with title) *';
      case UserRole.nurse:
        return 'Nurse Full Name *';
      default:
        return 'Full Legal Name *';
    }
  }

  String _getRoleNameHint() {
    switch (_selectedRole) {
      case UserRole.doctor:
        return 'e.g. Dr. K. M. Mathew MD';
      case UserRole.nurse:
        return 'e.g. Sister Shiny Joseph';
      default:
        return 'e.g. Rahul Varma';
    }
  }

  String _getCouncilLabel() {
    switch (_selectedRole) {
      case UserRole.doctor:
        return 'Travancore-Cochin Medical Council (TCMC) Reg No *';
      case UserRole.nurse:
        return 'Kerala Nurses and Midwives Council (KNMC) Reg No *';
      case UserRole.pharmacist:
        return 'Kerala State Pharmacy Council Registration No *';
      case UserRole.ambulanceDriver:
        return 'Commercial Heavy Driving License & Badge No *';
      default:
        return 'Government ID / Aadhaar Number (Optional)';
    }
  }

  String _getCouncilHint() {
    switch (_selectedRole) {
      case UserRole.doctor:
        return 'e.g. TCMC / 48920 / 2014';
      case UserRole.nurse:
        return 'e.g. KNMC / RN / 12903';
      case UserRole.pharmacist:
        return 'e.g. KSPC / 29103 / 2018';
      case UserRole.ambulanceDriver:
        return 'e.g. KL-11-2015-003910';
      default:
        return 'e.g. 9840 1204 8812';
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
