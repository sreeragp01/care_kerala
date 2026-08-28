import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/state/app_state_provider.dart';


class PatientRegistrationScreen extends StatefulWidget {
  final AppStateProvider state;

  const PatientRegistrationScreen({super.key, required this.state});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Demographic Controllers
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController(text: '58');
  final _phoneCtrl = TextEditingController(text: '+91 98470 ');
  final _addressCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _caregiverNameCtrl = TextEditingController();
  final _caregiverPhoneCtrl = TextEditingController(text: '+91 98470 ');
  final _caregiverRelationCtrl = TextEditingController(text: 'Spouse');
  final _careGoalsCtrl = TextEditingController(text: 'Pain relief, symptom control and compassionate home care.');
  final _doctorNotesCtrl = TextEditingController();

  String _gender = 'Male';
  String _bloodGroup = 'O+';
  String _district = 'Kozhikode';
  String _ward = 'Ward 12 - Beypore';
  String _categoryTier = 'Category A'; // Category A, B, C, D
  String _riskLevel = 'Moderate';
  int _painScale = 4;
  String _assignedDoctor = 'Dr. Suresh Kumar MD';
  String _assignedNurse = 'Sister Anitha R. (Palliative Nurse)';
  bool _needsWaterBed = false;
  bool _needsOxygenConcentrator = false;
  bool _needsWheelchair = false;

  @override
  void initState() {
    super.initState();
    _district = widget.state.activeOrganization?.district ?? 'Kozhikode';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _diagnosisCtrl.dispose();
    _caregiverNameCtrl.dispose();
    _caregiverPhoneCtrl.dispose();
    _caregiverRelationCtrl.dispose();
    _careGoalsCtrl.dispose();
    _doctorNotesCtrl.dispose();
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
            Text('Patient Intake Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Clinical Electronic Health Record (EHR) Onboarding', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkLightGreenSurface : AppColors.lightGreenSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, color: isDark ? AppColors.darkPrimaryGreen : AppColors.primaryGreen, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Palliative Care Intake Form',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Enroll patients into ${widget.state.activeOrganization?.name ?? "Kerala Palliative Network"} for scheduled home visits & doctor consultations.',
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
              // SECTION 1: Personal & Demographic Details
              // ==========================================
              _buildSectionTitle('1. Patient Identity & Demographics', Icons.person_rounded),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Patient Name *',
                          prefixIcon: Icon(Icons.badge_rounded, size: 20),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter patient name' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Age (Years) *',
                                prefixIcon: Icon(Icons.cake_rounded, size: 20),
                                isDense: true,
                              ),
                              validator: (v) => v == null || int.tryParse(v.trim()) == null ? 'Enter valid age' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
                              decoration: const InputDecoration(
                                labelText: 'Gender *',
                                prefixIcon: Icon(Icons.wc_rounded, size: 20),
                                isDense: true,
                              ),
                              items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) => setState(() => _gender = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _bloodGroup,
                              decoration: const InputDecoration(
                                labelText: 'Blood Group *',
                                prefixIcon: Icon(Icons.water_drop_rounded, size: 20, color: Colors.red),
                                isDense: true,
                              ),
                              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) => setState(() => _bloodGroup = v!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Primary Phone *',
                                prefixIcon: Icon(Icons.phone_rounded, size: 20),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.trim().length < 8 ? 'Enter valid phone number' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _district,
                              decoration: const InputDecoration(
                                labelText: 'District *',
                                prefixIcon: Icon(Icons.location_city_rounded, size: 20),
                                isDense: true,
                              ),
                              items: [
                                'Alappuzha', 'Ernakulam', 'Idukki', 'Kannur', 'Kasaragod',
                                'Kollam', 'Kottayam', 'Kozhikode', 'Malappuram', 'Palakkad',
                                'Pathanamthitta', 'Thiruvananthapuram', 'Thrissur', 'Wayanad'
                              ].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (v) => setState(() => _district = v!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: _ward,
                              decoration: const InputDecoration(
                                labelText: 'Ward / Locality *',
                                prefixIcon: Icon(Icons.map_rounded, size: 20),
                                isDense: true,
                              ),
                              onChanged: (v) => _ward = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Residential House Address *',
                          prefixIcon: Icon(Icons.home_rounded, size: 20),
                          hintText: 'House name, Landmark, Post Office, PIN...',
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter address' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              // SECTION 2: Clinical Diagnosis & Palliative Tier
              // ==========================================
              _buildSectionTitle('2. Clinical Assessment & Palliative Tier', Icons.medical_services_rounded),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _diagnosisCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Primary Clinical Diagnosis *',
                          prefixIcon: Icon(Icons.coronavirus_rounded, size: 20),
                          hintText: 'e.g. Ca Lung Stage IV with Bone Metastasis / Stroke / ESRD',
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter clinical diagnosis' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _categoryTier,
                              decoration: const InputDecoration(
                                labelText: 'Palliative Tier *',
                                isDense: true,
                              ),
                              items: [
                                'Category A',
                                'Category B',
                                'Category C',
                                'Category D',
                              ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                              onChanged: (v) => setState(() => _categoryTier = v!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _riskLevel,
                              decoration: const InputDecoration(
                                labelText: 'Risk Level *',
                                isDense: true,
                              ),
                              items: ['High Risk', 'Moderate', 'Low Risk'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)))).toList(),
                              onChanged: (v) => setState(() => _riskLevel = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ESAS Pain Scale Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Baseline Pain Score (0-10):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('$_painScale / 10', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _painScale > 6 ? AppColors.danger : AppColors.primaryGreen)),
                        ],
                      ),
                      Slider(
                        value: _painScale.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        activeColor: _painScale > 6 ? AppColors.danger : AppColors.primaryGreen,
                        label: '$_painScale',
                        onChanged: (val) => setState(() => _painScale = val.round()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              // SECTION 3: Caregiver & Emergency Contacts
              // ==========================================
              _buildSectionTitle('3. Primary Caregiver & Emergency Contact', Icons.family_restroom_rounded),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _caregiverNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Primary Caregiver Name *',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter caregiver name' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _caregiverRelationCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Relationship *',
                                prefixIcon: Icon(Icons.diversity_1_rounded, size: 20),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _caregiverPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Caregiver Phone *',
                                prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.trim().length < 8 ? 'Enter caregiver phone' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================
              // SECTION 4: Clinical Team Assignment & Equipment
              // ==========================================
              _buildSectionTitle('4. Assigned Care Team & Equipment Assets', Icons.local_hospital_rounded),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _assignedDoctor,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Palliative Doctor *',
                          prefixIcon: Icon(Icons.health_and_safety_rounded, size: 20),
                          isDense: true,
                        ),
                        items: ['Dr. Suresh Kumar MD', 'Dr. Radhika Menon MD', 'Dr. Anand Varma MBBS'].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (v) => setState(() => _assignedDoctor = v!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _assignedNurse,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Community Nurse *',
                          prefixIcon: Icon(Icons.medical_information_rounded, size: 20),
                          isDense: true,
                        ),
                        items: ['Sister Anitha R. (Palliative Nurse)', 'Sister Priya M. (Home Care)', 'Sister Marykutty (Field Lead)'].map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (v) => setState(() => _assignedNurse = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _careGoalsCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Initial Palliative Care Goals & Plan',
                          prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Immediate Medical Equipment Loan Required:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hospital Water / Ripple Air Bed (Pressure Sore Prevention)', style: TextStyle(fontSize: 12)),
                        value: _needsWaterBed,
                        onChanged: (val) => setState(() => _needsWaterBed = val ?? false),
                      ),
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Oxygen Concentrator (5L / 10L Continuous)', style: TextStyle(fontSize: 12)),
                        value: _needsOxygenConcentrator,
                        onChanged: (val) => setState(() => _needsOxygenConcentrator = val ?? false),
                      ),
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Mobility Wheelchair / Commode Chair', style: TextStyle(fontSize: 12)),
                        value: _needsWheelchair,
                        onChanged: (val) => setState(() => _needsWheelchair = val ?? false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Registration Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitPatientRegistration,
                  icon: const Icon(Icons.how_to_reg_rounded, size: 20),
                  label: const Text('Register & Enroll Patient into Active EHR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
    );
  }

  void _submitPatientRegistration() {
    if (_formKey.currentState?.validate() ?? false) {
      final newId = 'PAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final List<EquipmentIssued> equipmentList = [];
      if (_needsWaterBed) {
        equipmentList.add(EquipmentIssued(equipmentName: 'Air Ripple Bed', issuedDate: '2026-08-29', serialNumber: 'EQ-BED-901', status: 'Active'));
      }
      if (_needsOxygenConcentrator) {
        equipmentList.add(EquipmentIssued(equipmentName: 'Oxygen Concentrator 5L', issuedDate: '2026-08-29', serialNumber: 'EQ-O2-411', status: 'Active'));
      }
      if (_needsWheelchair) {
        equipmentList.add(EquipmentIssued(equipmentName: 'Standard Wheelchair', issuedDate: '2026-08-29', serialNumber: 'EQ-WC-102', status: 'Active'));
      }

      final newPatient = PatientModel(
        id: newId,
        name: _nameCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text.trim()) ?? 58,
        gender: _gender,
        bloodGroup: _bloodGroup,
        district: _district,
        ward: _ward.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        lifecycleStatus: 'Active Care',
        categoryTier: _categoryTier,
        diagnosis: _diagnosisCtrl.text.trim(),
        riskLevel: _riskLevel,
        aiSummary: 'Registered into clinical palliative database on 2026-08-29. Baseline pain $_painScale/10. Primary caregiver: ${_caregiverNameCtrl.text.trim()}.',
        emergencyContactName: _caregiverNameCtrl.text.trim(),
        emergencyContactPhone: _caregiverPhoneCtrl.text.trim(),
        carePlan: CarePlanModel(
          primaryNurseName: _assignedNurse,
          assignedDoctorName: _assignedDoctor,
          careGoals: _careGoalsCtrl.text.trim(),
          lastReviewedDate: '2026-08-29',
        ),
        vitalsHistory: [
          VitalsReading(
            date: '2026-08-29',
            bp: '120/80',
            pulse: 76,
            spo2: 98,
            painScale: _painScale,
            recordedBy: widget.state.currentUser.name,
          ),
        ],
        equipmentIssued: equipmentList,
        familyMembers: [
          FamilyMemberContact(
            name: _caregiverNameCtrl.text.trim(),
            relation: _caregiverRelationCtrl.text.trim(),
            phone: _caregiverPhoneCtrl.text.trim(),
          ),
        ],
        medicalHistory: [
          _diagnosisCtrl.text.trim(),
        ],
        registeredDate: '2026-08-29',
      );

      widget.state.addPatient(newPatient);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Successfully registered ${newPatient.name} ($newId) into $_district palliative care!'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context);
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
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
