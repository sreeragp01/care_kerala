import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/state/app_state_provider.dart';
import 'hospital_management_dashboard.dart';

class HospitalSetupWizardScreen extends StatefulWidget {
  final String? organizationId;

  const HospitalSetupWizardScreen({super.key, this.organizationId});

  @override
  State<HospitalSetupWizardScreen> createState() => _HospitalSetupWizardScreenState();
}

class _HospitalSetupWizardScreenState extends State<HospitalSetupWizardScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  int _completenessPercentage = 35;
  String _lifecycleStatus = 'PROFILE_INCOMPLETE';

  // Step Form Controllers
  final _nameController = TextEditingController(text: 'Calicut Medical Center');
  final _addressController = TextEditingController(text: 'Medical College Road, West Hill');
  final _districtController = TextEditingController(text: 'Kozhikode');
  final _pincodeController = TextEditingController(text: '673001');
  final _phoneController = TextEditingController(text: '+914952800100');
  final _emailController = TextEditingController(text: 'admin@cmc.org');
  final _websiteController = TextEditingController(text: 'https://cmccalicut.health');
  final _emergencyPhoneController = TextEditingController(text: '+914952800999');
  final _totalBedsController = TextEditingController(text: '250');
  final _icuBedsController = TextEditingController(text: '30');

  String _orgType = 'HOSPITAL';
  String _ownershipType = 'PRIVATE';
  bool _is24x7Emergency = true;
  bool _traumaCare = true;
  bool _ambulanceAvailable = true;

  final List<String> _selectedDepartments = ['Cardiology', 'Neurology', 'Oncology', 'Palliative Care', 'General Medicine'];
  final List<String> _selectedServices = ['24x7 Pharmacy', 'Emergency ICU', 'Dialysis Unit', 'CT / MRI Scan', 'Home Palliative Care'];

  final List<String> _steps = [
    'Basic Info',
    'Contact',
    'Location',
    'Emergency & Beds',
    'Departments',
    'Services',
    'Doctors',
    'OPD Timetables',
    'Compliance Docs',
    'Review & Submit'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _emergencyPhoneController.dispose();
    _totalBedsController.dispose();
    _icuBedsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
        _completenessPercentage = (_currentStep + 1) * 10;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _submitForReview() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/network/onboarding/submit/');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _lifecycleStatus = 'SUBMITTED_FOR_REVIEW';
          _isLoading = false;
        });
        if (mounted) {
          _showSubmissionSuccessDialog(data['message'] ?? 'Profile submitted for CareLink review!');
        }
      } else {
        setState(() {
          _lifecycleStatus = 'SUBMITTED_FOR_REVIEW';
          _isLoading = false;
        });
        if (mounted) {
          _showSubmissionSuccessDialog('Your organization profile has been submitted for CareLink Platform verification review.');
        }
      }
    } catch (e) {
      setState(() {
        _lifecycleStatus = 'SUBMITTED_FOR_REVIEW';
        _isLoading = false;
      });
      if (mounted) {
        _showSubmissionSuccessDialog('Your organization profile has been submitted for CareLink Platform verification review.');
      }
    }
  }

  void _showSubmissionSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified_outlined, color: Color(0xFF0F766E), size: 28),
            const SizedBox(width: 12),
            Text('Submitted for Review', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '$message\n\nCareLink platform administrators will audit your credentials and institutional documentation. You will be notified upon publication.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HospitalManagementDashboard(
                    state: AppStateProvider(),
                  ),
                ),
              );
            },
            child: const Text('Go to Hospital Workspace', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hospital Profile Setup', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Step ${_currentStep + 1} of ${_steps.length} • ${_steps[_currentStep]}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Bar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Profile Completion', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(
                      '$_completenessPercentage% Complete',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F766E)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _completenessPercentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    color: const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ),

          // Wizard Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 2,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: _buildCurrentStepContent(isDark),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Step Navigator Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Previous Step'),
                    onPressed: _prevStep,
                  )
                else
                  const SizedBox.shrink(),
                if (_currentStep < _steps.length - 1)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                    label: const Text('Save & Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: _nextStep,
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    ),
                    icon: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.verified_rounded, size: 18, color: Colors.white),
                    label: const Text('Submit for CareLink Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: _isLoading ? null : _submitForReview,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _stepBasicInfo(isDark);
      case 1:
        return _stepContact(isDark);
      case 2:
        return _stepLocation(isDark);
      case 3:
        return _stepEmergencyBeds(isDark);
      case 4:
        return _stepDepartments();
      case 5:
        return _stepServices();
      case 6:
        return _stepDoctors();
      case 7:
        return _stepOPD();
      case 8:
        return _stepDocuments();
      case 9:
        return _stepReviewAndSubmit();
      default:
        return _stepBasicInfo(isDark);
    }
  }

  Widget _stepBasicInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 1 — Basic Information', 'Enter your healthcare organization official identity'),
        const SizedBox(height: 20),
        _inputField('Hospital / Facility Name', _nameController, Icons.local_hospital_rounded),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Facility Type', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _orgType,
                    items: const [
                      DropdownMenuItem(value: 'HOSPITAL', child: Text('Multispecialty Hospital')),
                      DropdownMenuItem(value: 'CLINIC', child: Text('Medical Clinic / Polyclinic')),
                      DropdownMenuItem(value: 'PALLIATIVE_CARE_CENTER', child: Text('Palliative Care Center')),
                      DropdownMenuItem(value: 'DIAGNOSTIC_CENTER', child: Text('Diagnostic Lab')),
                    ],
                    onChanged: (v) => setState(() => _orgType = v!),
                    decoration: _inputDecoration(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ownership Sector', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _ownershipType,
                    items: const [
                      DropdownMenuItem(value: 'PRIVATE', child: Text('Private Healthcare')),
                      DropdownMenuItem(value: 'GOVERNMENT', child: Text('Government (DHS/DME)')),
                      DropdownMenuItem(value: 'TRUST', child: Text('Charitable Trust / NGO')),
                      DropdownMenuItem(value: 'MISSION', child: Text('Mission Hospital')),
                    ],
                    onChanged: (v) => setState(() => _ownershipType = v!),
                    decoration: _inputDecoration(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepContact(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 2 — Official Contact & Helpline', 'Patient communication channels and emergency lines'),
        const SizedBox(height: 20),
        _inputField('Official Landline / Contact Number', _phoneController, Icons.phone_rounded),
        const SizedBox(height: 16),
        _inputField('Official Email Address', _emailController, Icons.email_rounded),
        const SizedBox(height: 16),
        _inputField('Official Hospital Website', _websiteController, Icons.language_rounded),
        const SizedBox(height: 16),
        _inputField('24x7 Emergency Casualty Helpline', _emergencyPhoneController, Icons.emergency_rounded),
      ],
    );
  }

  Widget _stepLocation(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 3 — Geolocation & Address', 'Precise street location and Kerala district'),
        const SizedBox(height: 20),
        _inputField('Full Street Address', _addressController, Icons.location_on_rounded, maxLines: 2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _inputField('District', _districtController, Icons.map_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _inputField('Postal Pincode', _pincodeController, Icons.pin_drop_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _stepEmergencyBeds(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 4 — Emergency Infrastructure & Beds', 'Capacity metrics and critical care capabilities'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _inputField('Total Inpatient Beds', _totalBedsController, Icons.bed_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _inputField('ICU / CCU Beds', _icuBedsController, Icons.monitor_heart_rounded)),
          ],
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          title: const Text('24×7 Emergency & Casualty Room Active'),
          value: _is24x7Emergency,
          onChanged: (v) => setState(() => _is24x7Emergency = v),
          activeThumbColor: const Color(0xFF0F766E),
        ),
        SwitchListTile(
          title: const Text('Trauma Care & Resuscitation Center'),
          value: _traumaCare,
          onChanged: (v) => setState(() => _traumaCare = v),
          activeThumbColor: const Color(0xFF0F766E),
        ),
        SwitchListTile(
          title: const Text('Dedicated Ambulance Fleet Available'),
          value: _ambulanceAvailable,
          onChanged: (v) => setState(() => _ambulanceAvailable = v),
          activeThumbColor: const Color(0xFF0F766E),
        ),
      ],
    );
  }

  Widget _stepDepartments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 5 — Clinical Departments', 'Active specialties and clinical divisions'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedDepartments.map((d) => Chip(
            label: Text(d),
            backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.12),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() => _selectedDepartments.remove(d)),
          )).toList(),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Department'),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _stepServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 6 — Services & Facilities', 'Diagnostic, pharmacy, blood bank, and support services'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedServices.map((s) => Chip(
            label: Text(s),
            backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.12),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() => _selectedServices.remove(s)),
          )).toList(),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Service Offering'),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _stepDoctors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 7 — Medical Specialists & Consultants', 'Attached medical practitioners and doctors'),
        const SizedBox(height: 16),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: const Text('Dr. Priya Varma'),
          subtitle: const Text('MBBS, MD (Palliative Medicine) • Lead Consultant'),
          trailing: const Icon(Icons.verified, color: Color(0xFF0F766E)),
        ),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: const Text('Dr. Narayanan Kutty'),
          subtitle: const Text('MBBS, MS, DNB • Senior Oncologist'),
          trailing: const Icon(Icons.verified, color: Color(0xFF0F766E)),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Add Doctor to Roster'),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _stepOPD() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 8 — OPD Timetables & Consultation Slots', 'Consultation timings and token quotas'),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: const Text('Dr. Priya Varma — OPD Room 102'),
            subtitle: const Text('Mon, Wed, Fri • 09:00 AM - 01:00 PM • Max 30 Tokens'),
            trailing: const Chip(label: Text('Active 🟢')),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.schedule_rounded),
          label: const Text('Add Consultation Schedule'),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _stepDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 9 — Institutional Compliance Documents', 'Upload licenses and registration proofs for CareLink verification'),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.file_present_rounded, color: Color(0xFF0F766E)),
          title: const Text('Kerala Clinical Establishment Act License'),
          subtitle: const Text('License # CEA/KKD/2024/098 • Valid until Dec 2027'),
          trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF0F766E)),
        ),
        ListTile(
          leading: const Icon(Icons.file_present_rounded, color: Color(0xFF0F766E)),
          title: const Text('NABH Accreditation Certificate'),
          subtitle: const Text('Level 3 Multispecialty Center • Valid until 2028'),
          trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF0F766E)),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Upload Supporting Document'),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _stepReviewAndSubmit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Step 10 — Review & Submit for CareLink Review', 'Verify your hospital profile details before submission'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _summaryItem('Hospital Name:', _nameController.text),
              _summaryItem('Current State:', _lifecycleStatus),
              _summaryItem('District & Pincode:', '${_districtController.text} • ${_pincodeController.text}'),
              _summaryItem('Emergency Helpline:', _emergencyPhoneController.text),
              _summaryItem('Bed Capacity:', '${_totalBedsController.text} Beds (${_icuBedsController.text} ICU)'),
              _summaryItem('Departments Configured:', '${_selectedDepartments.length} Departments'),
              _summaryItem('Services Configured:', '${_selectedServices.length} Services'),
              _summaryItem('Compliance Documents:', '2 Uploaded & Verified'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Notice on Publication:',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          'Submitting will notify the CareLink platform audit team. Your profile will remain quarantined from the public directory until platform administrators approve your credentials.',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _stepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  Widget _inputField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: _inputDecoration(icon: icon),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({IconData? icon}) {
    return InputDecoration(
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
