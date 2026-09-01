import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_state_provider.dart';
import '../../../core/models/patient_model.dart';

class HomeVisitRequestScreen extends StatefulWidget {
  final AppStateProvider? state;

  const HomeVisitRequestScreen({super.key, this.state});

  @override
  State<HomeVisitRequestScreen> createState() => _HomeVisitRequestScreenState();
}

class _HomeVisitRequestScreenState extends State<HomeVisitRequestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  PatientModel? _selectedPatient;
  String _visitType = 'Palliative Pain & Symptom Review';
  String _urgency = 'Routine (Scheduled)';
  String _timeSlot = '10:00 AM - 12:00 PM';
  final _preferredDateController = TextEditingController(text: '2026-08-10');
  final _requesterNameController = TextEditingController(text: 'Fathima Basheer');
  final _requesterPhoneController = TextEditingController(text: '+91 98472 33446');
  final _relationshipController = TextEditingController(text: 'Daughter & Primary Caregiver');
  final _reasonController = TextEditingController();
  final _addressController = TextEditingController();

  final List<String> _visitTypes = [
    'Palliative Pain & Symptom Review',
    'Bedsore & Sterile Wound Dressing',
    'Catheter Flush / Stoma Care',
    'Physiotherapy & Mobility Assessment',
    'Family Counseling & Psychological Support',
    'Routine Nursing Assessment',
  ];

  final List<String> _urgencyTiers = [
    'Routine (Scheduled)',
    'Urgent (Within 24 Hours)',
    'High Priority (Same Day Review)',
  ];

  final List<String> _timeSlots = [
    '08:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _preferredDateController.dispose();
    _requesterNameController.dispose();
    _requesterPhoneController.dispose();
    _relationshipController.dispose();
    _reasonController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submitRequest(AppStateProvider provider) {
    if (_formKey.currentState?.validate() ?? false) {
      final patient = _selectedPatient ?? (provider.patients.isNotEmpty ? provider.patients.first : null);
      if (patient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or register a patient.')),
        );
        return;
      }

      final address = _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : patient.address;

      provider.requestHomeVisit(
        patientId: patient.id,
        patientName: patient.name,
        patientPhone: patient.phone,
        requesterName: _requesterNameController.text.trim(),
        requesterPhone: _requesterPhoneController.text.trim(),
        requesterRelationship: _relationshipController.text.trim(),
        visitType: _visitType,
        urgency: _urgency,
        preferredDate: _preferredDateController.text.trim(),
        preferredTimeSlot: _timeSlot,
        reasonAndSymptoms: _reasonController.text.trim(),
        locationAddress: address,
      );

      _reasonController.clear();
      _tabController.animateTo(1); // Switch to requests tracker tab

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emerald,
          content: Text('Home visit request for ${patient.name} submitted successfully!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state == null) {
      return const Scaffold(body: Center(child: Text('AppStateProvider not provided')));
    }

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D1B1E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF132A2F),
            elevation: 0,
            title: const Row(
              children: [
                Icon(Icons.home_work_rounded, color: AppColors.emeraldLight, size: 24),
                SizedBox(width: 10),
                Text(
                  'Home Palliative Visit Request',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.emeraldLight,
              indicatorWeight: 3,
              labelColor: AppColors.emeraldLight,
              unselectedLabelColor: Colors.white70,
              tabs: [
                const Tab(icon: Icon(Icons.add_task_rounded, size: 20), text: 'New Visit Request'),
                Tab(
                  icon: const Icon(Icons.history_rounded, size: 20),
                  text: 'Request Status (${state.homeVisitRequests.length})',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestForm(state),
              _buildRequestsList(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestForm(AppStateProvider state) {
    final patients = state.patients;
    if (_selectedPatient == null && patients.isNotEmpty) {
      _selectedPatient = patients.first;
      _addressController.text = _selectedPatient!.address;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informational Clinical Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.emeraldLight, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Palliative Home Healthcare Request Desk: Multi-disciplinary teams (Doctor, Nurse, Physiotherapist, MSW) are scheduled according to clinical urgency and area route sequence.',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Patient Selector
            const Text('Select Patient', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF132A2F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PatientModel>(
                  value: _selectedPatient,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF132A2F),
                  items: patients.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} (${p.categoryTier}) - ${p.ward}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPatient = val;
                      if (val != null) {
                        _addressController.text = val.address;
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visit Type Selector
            const Text('Clinical Visit Type', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF132A2F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _visitType,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF132A2F),
                  items: _visitTypes.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 14)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _visitType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Urgency Tier Selector
            const Text('Urgency Tier', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF132A2F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _urgency.contains('Urgent') || _urgency.contains('High')
                      ? AppColors.warning
                      : Colors.white24,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _urgency,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF132A2F),
                  items: _urgencyTiers.map((u) {
                    return DropdownMenuItem(
                      value: u,
                      child: Row(
                        children: [
                          Icon(
                            u.contains('Urgent') || u.contains('High')
                                ? Icons.warning_amber_rounded
                                : Icons.schedule_rounded,
                            color: u.contains('Urgent') || u.contains('High')
                                ? AppColors.warning
                                : AppColors.emeraldLight,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(u, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _urgency = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Preferred Date & Preferred Time Slot
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Preferred Date', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _preferredDateController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF132A2F),
                          prefixIcon: const Icon(Icons.calendar_month_rounded, color: AppColors.emeraldLight, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Preferred Window', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF132A2F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _timeSlot,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF132A2F),
                            items: _timeSlots.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 13)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _timeSlot = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Requester Details
            const Text('Requester Information', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _requesterNameController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Your Name',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF132A2F),
                      prefixIcon: const Icon(Icons.person_rounded, color: Colors.white70, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _requesterPhoneController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF132A2F),
                      prefixIcon: const Icon(Icons.phone_rounded, color: Colors.white70, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _relationshipController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Relationship to Patient',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF132A2F),
                prefixIcon: const Icon(Icons.family_restroom_rounded, color: Colors.white70, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),

            // Address
            const Text('Patient Residence / Visit Location', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF132A2F),
                prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.emeraldLight, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),

            // Specific Reason & Symptoms
            const Text('Symptoms Observed & Care Needed', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Severe knee pain breakthrough, catheter leakage, bedsore dressing replacement...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF132A2F),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Please enter observed symptoms or reason.' : null,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                label: const Text('Submit Home Visit Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: () => _submitRequest(state),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(AppStateProvider state) {
    final requests = state.homeVisitRequests;

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            const Text('No Home Visit Requests', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Submit a request to dispatch a palliative care team.', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final isAccepted = req.status == 'ACCEPTED';
        final isRejected = req.status == 'REJECTED';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF132A2F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAccepted
                  ? AppColors.emerald.withValues(alpha: 0.5)
                  : isRejected
                      ? AppColors.danger.withValues(alpha: 0.5)
                      : Colors.white12,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        req.patientName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAccepted
                            ? AppColors.emerald.withValues(alpha: 0.2)
                            : isRejected
                                ? AppColors.danger.withValues(alpha: 0.2)
                                : AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isAccepted
                              ? AppColors.emerald
                              : isRejected
                                  ? AppColors.danger
                                  : AppColors.warning,
                        ),
                      ),
                      child: Text(
                        req.status,
                        style: TextStyle(
                          color: isAccepted
                              ? AppColors.emeraldLight
                              : isRejected
                                  ? AppColors.danger
                                  : AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Visit Type & Urgency
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, color: AppColors.emeraldLight, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(req.visitType, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: Colors.white38, size: 16),
                    const SizedBox(width: 6),
                    Text('${req.preferredDate} (${req.preferredTimeSlot})', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(req.urgency, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Symptoms & Reason
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    req.reasonAndSymptoms,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                  ),
                ),
                const SizedBox(height: 10),

                // Location & Requester
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white38, size: 15),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(req.locationAddress, style: const TextStyle(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle_outlined, color: Colors.white38, size: 15),
                    const SizedBox(width: 4),
                    Text('Requested by: ${req.requesterName} (${req.requesterRelationship})', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),

                // Hospital Review Action Buttons (If User is Nurse/Doctor/Admin)
                if (req.status == 'PENDING') ...[
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Decline'),
                          onPressed: () {
                            state.rejectHomeVisitRequest(req.id, 'Outside district coverage or team booked');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                          label: const Text('Accept & Schedule', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            state.acceptHomeVisitRequest(req.id, assignedNurse: 'Nurse Anitha');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
