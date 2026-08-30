import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/network_models.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/widgets/glass_card.dart';

class JoinCareLinkScreen extends StatefulWidget {
  final AppStateProvider state;

  const JoinCareLinkScreen({super.key, required this.state});

  @override
  State<JoinCareLinkScreen> createState() => _JoinCareLinkScreenState();
}

class _JoinCareLinkScreenState extends State<JoinCareLinkScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _bedsController = TextEditingController(text: '0');
  final _icuBedsController = TextEditingController(text: '0');
  final _descController = TextEditingController();

  String _selectedType = 'Multispecialty / General Hospital';
  String _selectedOwnership = 'Charitable Trust / Non-Profit';
  String _selectedDistrict = 'Kozhikode';
  bool _is24x7Emergency = false;
  bool _ambulanceAvailable = false;
  bool _agreedToTerms = true;
  bool _duplicateWarning = false;
  String _duplicateMatchedName = '';

  final List<String> _districts = const [
    'Kozhikode', 'Ernakulam', 'Thiruvananthapuram', 'Wayanad',
    'Thrissur', 'Malappuram', 'Kannur', 'Palakkad', 'Kottayam',
    'Alappuzha', 'Idukki', 'Pathanamthitta', 'Kollam', 'Kasaragod'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    _regNumberController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _bedsController.dispose();
    _icuBedsController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _checkDuplicates(String name) {
    final match = widget.state.healthcareProfiles.where(
      (h) => h.name.toLowerCase().trim() == name.toLowerCase().trim() && h.district == _selectedDistrict,
    ).firstOrNull;

    if (match != null) {
      setState(() {
        _duplicateWarning = true;
        _duplicateMatchedName = match.name;
      });
    } else {
      if (_duplicateWarning) {
        setState(() {
          _duplicateWarning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final isDark = widget.state.isDarkMode;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            title: const Text('Join CareLink Network', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.brandTeal, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Institutional Onboarding',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Register your Hospital, Clinic, or Palliative Center to publish verified doctor schedules and 24x7 emergency contacts.',
                                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_duplicateWarning) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Similar Organization Found',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                                Text(
                                  '"$_duplicateMatchedName" is already registered in $_selectedDistrict. Would you like to claim this organization instead?',
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.brandTeal,
                                  content: Text('Claim request for "$_duplicateMatchedName" initiated.'),
                                ),
                              );
                              Navigator.pop(context);
                            },
                            child: const Text('Claim Org', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandTeal)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildSectionTitle('1. Organization Identity', isDark),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    onChanged: _checkDuplicates,
                    decoration: const InputDecoration(
                      labelText: 'Organization / Hospital Name *',
                      prefixIcon: Icon(Icons.apartment_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter hospital name' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Facility Category',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Multispecialty / General Hospital', child: Text('Multispecialty / General Hospital')),
                      DropdownMenuItem(value: 'Medical Clinic / Polyclinic', child: Text('Medical Clinic / Polyclinic')),
                      DropdownMenuItem(value: 'Palliative Care Center & Hospice', child: Text('Palliative Care Center & Hospice')),
                      DropdownMenuItem(value: 'Diagnostic Center & Imaging Lab', child: Text('Diagnostic Center & Imaging Lab')),
                      DropdownMenuItem(value: 'Community Pharmacy', child: Text('Community Pharmacy')),
                      DropdownMenuItem(value: 'Blood Bank & Component Center', child: Text('Blood Bank & Component Center')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOwnership,
                    decoration: const InputDecoration(
                      labelText: 'Ownership & Legal Form',
                      prefixIcon: Icon(Icons.account_balance_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Government / Public Sector', child: Text('Government / Public Sector')),
                      DropdownMenuItem(value: 'Private Healthcare', child: Text('Private Healthcare')),
                      DropdownMenuItem(value: 'Charitable Trust / Non-Profit', child: Text('Charitable Trust / Non-Profit')),
                      DropdownMenuItem(value: 'Mission Hospital', child: Text('Mission Hospital')),
                      DropdownMenuItem(value: 'Cooperative Society', child: Text('Cooperative Society')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedOwnership = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _regNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Registration / License Number *',
                      hintText: 'e.g. KZD/HOSP/2024/991',
                      prefixIcon: Icon(Icons.badge_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter registration number' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildSectionTitle('2. Location & Contact Details', isDark),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedDistrict,
                          decoration: const InputDecoration(
                            labelText: 'District',
                            prefixIcon: Icon(Icons.location_city_rounded),
                          ),
                          items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedDistrict = val);
                              _checkDuplicates(_nameController.text);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Pincode',
                            hintText: '673001',
                            prefixIcon: Icon(Icons.pin_drop_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Complete Street Address *',
                      prefixIcon: Icon(Icons.map_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter address' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Main Hospital Phone *',
                            prefixIcon: Icon(Icons.phone_rounded),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _emergencyPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: '24x7 Emergency Line',
                            prefixIcon: Icon(Icons.emergency_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildSectionTitle('3. Capacity & Emergency Readiness', isDark),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bedsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Beds',
                            prefixIcon: Icon(Icons.bed_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _icuBedsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'ICU / CCU Beds',
                            prefixIcon: Icon(Icons.monitor_heart_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('24x7 Emergency & Trauma Care Available', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Highlighted with an emergency badge on the patient directory', style: TextStyle(fontSize: 11)),
                    value: _is24x7Emergency,
                    activeTrackColor: AppColors.brandHealthGreen,
                    onChanged: (v) => setState(() => _is24x7Emergency = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dedicated Ambulance Fleet Available', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: _ambulanceAvailable,
                    activeTrackColor: AppColors.brandHealthGreen,
                    onChanged: (v) => setState(() => _ambulanceAvailable = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Brief Description & Services Overview',
                      prefixIcon: Icon(Icons.description_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _agreedToTerms,
                    activeColor: AppColors.brandTeal,
                    title: const Text(
                      'I certify that I am an authorized administrative officer of this institution. Information submitted will undergo document verification before public publishing.',
                      style: TextStyle(fontSize: 11),
                    ),
                    onChanged: (v) => setState(() => _agreedToTerms = v ?? true),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandNavy,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'Submit Application for Review',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submitApplication() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to verification terms.')),
        );
        return;
      }

      final profile = HealthcareProfileModel(
        id: 'HOSP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        organizationId: 'org_${_nameController.text.toLowerCase().replaceAll(' ', '_')}',
        name: _nameController.text.trim(),
        organizationType: _selectedType,
        ownershipType: _selectedOwnership,
        verificationStatus: 'UNDER_REVIEW',
        isCareLinkVerified: false,
        district: _selectedDistrict,
        address: _addressController.text.trim(),
        pincode: _pincodeController.text.trim().isNotEmpty ? _pincodeController.text.trim() : '673001',
        phone: _phoneController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim(),
        is24x7Emergency: _is24x7Emergency,
        ambulanceAvailable: _ambulanceAvailable,
        totalBeds: int.tryParse(_bedsController.text) ?? 0,
        icuBeds: int.tryParse(_icuBedsController.text) ?? 0,
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : 'Verified Healthcare Center on CareLink Kerala Network.',
        profileCompletenessScore: 75,
        lastVerifiedDate: 'Pending Review',
        specialties: const ['General Medicine', 'Emergency Care'],
        services: _is24x7Emergency ? const ['24x7 Emergency Care', 'Outpatient OPD'] : const ['Outpatient OPD'],
        facilities: const ['Wheelchair Accessible', 'Oxygen Support'],
        doctors: const [],
      );

      widget.state.submitHospitalApplication(profile);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.brandNavy,
          title: const Text('Application Submitted', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            'Your application for "${_nameController.text}" has been received and queued for document verification by the CareLink Platform Administrator.\n\nStatus: Under Review',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandTeal),
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
    );
  }
}
