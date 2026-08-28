import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/user_model.dart';
import '../../../core/state/app_state_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../emergency_sos/screens/emergency_sos_screen.dart';
import '../../../core/widgets/kerala_location_selector.dart';
import 'staff_registration_screen.dart';


class LoginScreen extends StatefulWidget {
  final AppStateProvider state;

  const LoginScreen({super.key, required this.state});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'anitha@carelink.kerala.gov.in');
  final _passwordController = TextEditingController(text: 'pass1234');

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isMalayalam = widget.state.locale.languageCode == 'ml';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Banner
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreenSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryGreen, width: 2),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      size: 48,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    loc.translate('app_title'),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  Text(
                    loc.translate('tagline'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
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
                      color: AppColors.lightSand,
                      borderRadius: BorderRadius.circular(12),
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
                                  const Icon(Icons.business_rounded, color: AppColors.primaryGreen, size: 20),
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
                                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryGreen),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
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
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (widget.state.currentUser.role.isPatientOrFamily) {
                                      widget.state.switchRole(UserRole.nurse);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: !widget.state.currentUser.role.isPatientOrFamily
                                          ? AppColors.lightGreenSurface
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: !widget.state.currentUser.role.isPatientOrFamily
                                            ? AppColors.primaryGreen
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Staff Portal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: !widget.state.currentUser.role.isPatientOrFamily
                                              ? AppColors.primaryGreen
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (!widget.state.currentUser.role.isPatientOrFamily) {
                                      widget.state.switchRole(UserRole.patient);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: widget.state.currentUser.role.isPatientOrFamily
                                          ? AppColors.lightGreenSurface
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: widget.state.currentUser.role.isPatientOrFamily
                                            ? AppColors.primaryGreen
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Patient Portal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: widget.state.currentUser.role.isPatientOrFamily
                                              ? AppColors.primaryGreen
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (!widget.state.currentUser.role.isPatientOrFamily) ...[
                            Text(
                              'Staff Sign In (${widget.state.currentUser.role.displayName})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Staff Email or User ID',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
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
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Patient & Caregiver Access',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Access your home care visits, doctor appointments, and emergency nurse support.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            const TextField(
                              decoration: InputDecoration(
                                labelText: 'Registered Mobile Number (OTP)',
                                hintText: '+91 98470 XXXXX',
                                prefixIcon: Icon(Icons.phone_android_rounded),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),

                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => DashboardScreen(state: widget.state),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              widget.state.currentUser.role.isPatientOrFamily
                                  ? 'Enter Patient Portal'
                                  : 'Sign In to Staff Dashboard',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (!widget.state.currentUser.role.isPatientOrFamily) ...[
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
                          ],

                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Demo Users 1-Click Login Directory
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.state.isDarkMode ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widget.state.isDarkMode ? AppColors.darkCardBorder : AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.supervised_user_circle_rounded, size: 20, color: AppColors.accentGold),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '1-Click Demo Profiles by Role',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Tap any role below to test its unique UI, permissions & workflows:',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        ...widget.state.demoUsers.map((demoUser) {
                          final isSelected = widget.state.currentUser.role == demoUser.role;
                          final iconData = _getRoleIcon(demoUser.role);
                          final colorData = _getRoleColor(demoUser.role, widget.state.isDarkMode);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (widget.state.isDarkMode ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface)
                                  : (widget.state.isDarkMode ? AppColors.darkBackground : AppColors.background),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? (widget.state.isDarkMode ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                                    : (widget.state.isDarkMode ? AppColors.darkCardBorder : AppColors.cardBorder),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: colorData.withValues(alpha: 0.2),
                                child: Icon(iconData, color: colorData, size: 18),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      demoUser.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorData.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      demoUser.role.displayName,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorData),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                _getRoleDescription(demoUser.role, isMalayalam),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.state.isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  widget.state.loginAsUser(demoUser);
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => DashboardScreen(state: widget.state),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? (widget.state.isDarkMode ? AppColors.darkPrimaryGreen : AppColors.primaryGreen)
                                      : (widget.state.isDarkMode ? AppColors.darkSurfaceLight : Colors.white),
                                  foregroundColor: isSelected
                                      ? Colors.white
                                      : (widget.state.isDarkMode ? AppColors.darkTextLight : AppColors.primaryGreen),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: BorderSide(
                                      color: widget.state.isDarkMode ? AppColors.darkPrimaryGreen : AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                                child: const Text('Sign In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return Icons.personal_injury_rounded;
      case UserRole.familyMember:
        return Icons.family_restroom_rounded;
      case UserRole.nurse:
        return Icons.medical_services_rounded;
      case UserRole.doctor:
        return Icons.health_and_safety_rounded;
      case UserRole.volunteer:
        return Icons.groups_rounded;
      case UserRole.ambulanceDriver:
        return Icons.airport_shuttle_rounded;
      case UserRole.pharmacist:
        return Icons.medication_rounded;
      case UserRole.orgAdmin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.superAdmin:
        return Icons.shield_rounded;
      case UserRole.palliativeMember:
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color _getRoleColor(UserRole role, bool isDark) {
    switch (role) {
      case UserRole.patient:
      case UserRole.familyMember:
        return isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen;
      case UserRole.nurse:
        return AppColors.info;
      case UserRole.doctor:
        return Colors.teal;
      case UserRole.volunteer:
        return Colors.indigo;
      case UserRole.ambulanceDriver:
        return Colors.deepOrange;
      case UserRole.pharmacist:
        return AppColors.warning;
      case UserRole.orgAdmin:
        return AppColors.accentGold;
      case UserRole.superAdmin:
        return Colors.purple;
      case UserRole.palliativeMember:
        return Colors.teal;
      default:
        return AppColors.primaryGreen;
    }
  }

  String _getRoleDescription(UserRole role, bool isMalayalam) {
    if (isMalayalam) {
      switch (role) {
        case UserRole.patient:
          return 'വ്യക്തിഗത ആരോഗ്യ വിവരങ്ങൾ, അടിയന്തര SOS, മലയാളം AI';
        case UserRole.familyMember:
          return 'കുടുംബാംഗങ്ങൾക്കായി ഹോം വിസിറ്റ് അഭ്യർത്ഥിക്കുക, ഉപകരണങ്ങൾ';
        case UserRole.nurse:
          return 'ഹോം വിസിറ്റ് റൂട്ട് ഷെഡ്യൂൾ, ജിപിഎസ് ചെക്ക്-ഇൻ, മെഡിക്കൽ കുറിപ്പുകൾ';
        case UserRole.doctor:
          return 'ടെലി-കൺസൾട്ടേഷൻ, AI കേസ് സംഗ്രഹം, അടിയന്തര മുന്നറിയിപ്പുകൾ';
        case UserRole.volunteer:
          return 'വാർഡ് രോഗികൾ, സേവന സമയം രേഖപ്പെടുത്തൽ, രക്തദാതാക്കൾ';
        case UserRole.ambulanceDriver:
          return '108 ആംബുലൻസ് ഡിസ്പാച്ച് നിലയും എമർജൻസി റൂട്ടിംഗും';
        case UserRole.pharmacist:
          return 'മരുന്ന് സ്റ്റോക്ക് വിവരങ്ങൾ, റീഓർഡർ അലേർട്ടുകൾ, ഡിപ്പോ';
        case UserRole.orgAdmin:
          return 'ജില്ലാ KPI അനലിറ്റിക്‌സ്, വളണ്ടിയർ വെരിഫിക്കേഷൻ, മൾട്ടി-ടെനന്റ്';
        case UserRole.superAdmin:
          return 'എല്ലാ 14 കേരള ജില്ലകളും, ബാക്കെൻഡ് കോൺഫിഗറേഷൻ, പൂർണ്ണ നിയന്ത്രണം';
        case UserRole.palliativeMember:
          return 'രോഗി റഫറൽ, കമ്മ്യൂണിറ്റി പരിചരണ സംരംഭങ്ങൾ, രക്തദാനം';
        default:
          return 'കെയർലിങ്ക് കേരളം കമ്മ്യൂണിറ്റി പ്രവേശനം';
      }
    }

    switch (role) {
      case UserRole.patient:
        return 'Personal health vitals, emergency nurse SOS, Malayalam AI';
      case UserRole.familyMember:
        return 'Request home visits & track equipment loans for family';
      case UserRole.nurse:
        return 'Home visit route schedule, GPS check-in, clinical notes';
      case UserRole.doctor:
        return 'Tele-consultations, AI case summaries, critical alerts';
      case UserRole.volunteer:
        return 'Ward patients, log service hours, donor directory';
      case UserRole.ambulanceDriver:
        return '108 ambulance dispatch status & emergency routing';
      case UserRole.pharmacist:
        return 'Medicine stock inventory, reorder alerts, depot loans';
      case UserRole.orgAdmin:
        return 'District KPI analytics, volunteer verification, multi-tenant';
      case UserRole.superAdmin:
        return 'All Kerala districts, backend API config, full system control';
      case UserRole.palliativeMember:
        return 'Refer needy patients, community care causes, blood donor network';
      default:
        return 'CareLink Kerala community access';
    }
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

    final nameCtrl = TextEditingController(text: 'Thrissur Pain and Palliative Care Society');
    final regNumberCtrl = TextEditingController(text: 'TCR/NGO/2026/089');
    final phoneCtrl = TextEditingController(text: '+91 487 2320000');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
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
