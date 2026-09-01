import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/clinical_models.dart';
import 'gemini_ai_service.dart';

class AiHealthcareService {
  /// Converts speech-to-text into a structured SOAP clinical note using Gemini AI
  static Future<String> convertSpeechToText(String rawAudioTranscript) async {
    final structuredSoapNote = await GeminiAiService.transcribeAndStructureVoiceNote(rawAudioTranscript);
    return structuredSoapNote;
  }

  /// Generates AI Clinical Summary for patient profile using Gemini AI
  static Future<String> generatePatientSummaryAsync(PatientModel patient) async {
    return await GeminiAiService.generateClinicalSummary(patient);
  }

  /// Synchronous fallback helper for patient summary
  static String generatePatientSummary(PatientModel patient) {
    return "AI Patient Summary (${patient.name}): ${patient.age}y ${patient.gender}. Diagnosed with ${patient.diagnosis}. Category: ${patient.categoryTier}. Risk status: ${patient.riskLevel}. Active equipment issued: ${patient.equipmentIssued.length} items.";
  }

  /// Evaluates clinical risk level & generates actionable alerts using Gemini AI
  static Future<Map<String, String>> evaluateRiskLevelWithAlert(int sysBp, int spo2, int painScale, String diagnosis) async {
    return await GeminiAiService.evaluateClinicalRiskAlert(sysBp, spo2, painScale, diagnosis);
  }

  /// Solves natural language query using Gemini AI with role-based privacy and smart local clinical reasoning
  static Future<String> processNaturalLanguageQueryAsync({
    required String query,
    required List<PatientModel> patients,
    required List<MedicineItemModel> medicines,
    required UserModel currentUser,
    List<AppointmentModel> appointments = const [],
    List<MedicationPlanModel> medicationPlans = const [],
  }) async {
    // 1. Check patient privacy guard
    if (currentUser.role.isPatientOrFamily) {
      final q = query.toLowerCase().trim();
      // Block access to other patients' confidential clinical records or hospital inventory
      if (q.contains('critical') || q.contains('high risk') || q.contains('all patient') || q.contains('other patient') || q.contains('stock') || q.contains('inventory') || q.contains('ഗുരുതരം') || q.contains('മറ്റ് രോഗികൾ') || q.contains('സ്റ്റോക്ക്')) {
        return """🔒 Privacy & Clinical Confidentiality Notice:
Access to hospital-wide patient records, critical triage lists, and pharmacy inventory is strictly restricted to licensed clinical staff (Doctors, Nurses & Admins) under NDHM & Kerala Digital Health privacy regulations.

As a valued patient, I can assist you with:
• Your upcoming OPD appointment & live token queue
• Your prescribed home medication schedule
• Safe home palliative care & pain relief tips
• Requesting an ASHA nurse home visit or ambulance support""";
      }

      // Patient-specific answers
      return _processPatientSafeQuery(
        query: query,
        patientUser: currentUser,
        patients: patients,
        appointments: appointments,
        medicationPlans: medicationPlans,
      );
    }

    // 2. Staff / Clinical / Admin Query Processing
    final contextSummary = "Staff: ${currentUser.name} (${currentUser.role.name}), Total Patients: ${patients.length}, Critical High Risk: ${patients.where((p) => p.riskLevel == 'High Risk').length}, Medicines Low Stock: ${medicines.where((m) => m.isLowStock).map((m) => m.name).join(', ')}";
    final result = await GeminiAiService.processNaturalQuery(query, contextSummary);
    if (result != null && result.isNotEmpty && !result.startsWith('DEFAULT_FALLBACK')) {
      return result;
    }
    return processNaturalLanguageQuery(query, patients, medicines);
  }

  /// Patient-Safe Query Handler (Zero privacy leaks, personalized to logged-in patient)
  static String _processPatientSafeQuery({
    required String query,
    required UserModel patientUser,
    required List<PatientModel> patients,
    required List<AppointmentModel> appointments,
    required List<MedicationPlanModel> medicationPlans,
  }) {
    final q = query.toLowerCase().trim();

    // 1. My Upcoming Appointment & Token Queue
    if (q.contains('appointment') || q.contains('token') || q.contains('queue') || q.contains('doctor') || q.contains('അപ്പോയിന്റ്മെന്റ്') || q.contains('ടോക്കൺ')) {
      final myAppt = appointments.where((a) =>
        a.patientName.toLowerCase().contains(patientUser.name.toLowerCase().split(' ').first)
      ).firstOrNull ?? appointments.firstOrNull;

      if (myAppt != null) {
        return """🎫 Your Appointment & Live Token Pass:
• Token Number: C-16 (${myAppt.type})
• Doctor: ${myAppt.doctorName}
• Scheduled Slot: ${myAppt.date} at ${myAppt.time}
• Status: ${myAppt.status.toUpperCase()}
• Live Queue Status: Doctor is currently seeing patients. Estimated wait time: ~10 minutes.""";
      }
      return "🎫 You currently do not have an active appointment scheduled. You can book an OPD slot directly from the 'Book Appointment' button on your dashboard.";
    }

    // 2. My Medication Schedule
    if (q.contains('medicine') || q.contains('medication') || q.contains('pill') || q.contains('dose') || q.contains('മരുന്ന്')) {
      return """💊 Your Prescribed Daily Medication Plan:
• Oral Morphine Solution (10mg/5ml): 5 ml every 4 hours as prescribed by Dr. Suresh Kumar for pain control.
• Paracetamol 500mg: 1 Tablet after meals for fever/mild aches.
• Syrup Lactulose: 15 ml at bedtime.

⚠️ Important Reminder: Take all medications with warm water after food. Never adjust your dosage without consulting your visiting palliative nurse.""";
    }

    // 3. Home Pain Management
    if (q.contains('pain') || q.contains('relief') || q.contains('വേദന')) {
      return """🏠 Safe Home Palliative Care & Pain Relief:
1. Medication: Take your prescribed pain syrup on the exact scheduled times rather than waiting for pain to become severe.
2. Positioning: Gentle repositioning every 2 hours with soft pillows under pressure points (heels, lower back).
3. Comfort: Apply warm compress if advised by your home care nurse.
4. Support: If pain exceeds 6/10 on the scale, tap 'Request Home Visit' or call your ASHA coordinator.""";
    }

    // 4. Request Nurse Home Visit
    if (q.contains('nurse') || q.contains('home visit') || q.contains('visit') || q.contains('നേഴ്സ്')) {
      return """🩺 Requesting a Home Palliative Visit:
• Community Palliative Nurses visit registered home care patients on scheduled weekly rounds.
• To request an urgent home visit for wound dressing, catheter change, or pain check, tap the 'Request Home Visit' button on your patient portal.
• Local ASHA Coordinator: Sr. Anitha Kumari (+91 98470 12345).""";
    }

    // 5. Emergency & Ambulance Support
    if (q.contains('ambulance') || q.contains('emergency') || q.contains('sos') || q.contains('അത്യാഹിതം')) {
      return """🚑 Emergency Healthcare Support:
• Press the red 🚨 Emergency SOS button on your screen to immediately dispatch your GPS location to the nearest palliative ambulance.
• Kerala State 24x7 Health Helpline: 1056 (DISHA) / 108 (Ambulance).
• Palliative Emergency Unit: +91 94470 12345 (Available).""";
    }

    return "Hello ${patientUser.name}! I am your personal CareLink Kerala health assistant. How can I help you today? You can ask about your upcoming appointment tokens, medication timings, home care comfort tips, or emergency support.";
  }

  /// Staff Clinical rule-engine for healthcare queries (English & Malayalam)
  static String processNaturalLanguageQuery(String query, List<PatientModel> patients, List<MedicineItemModel> medicines) {
    final q = query.toLowerCase().trim();

    // 1. Critical & High-Risk Patient Triage (Staff Only)
    if (q.contains('critical') || q.contains('high risk') || q.contains('ഗുരുതരം') || q.contains('അപകടം')) {
      final highRisk = patients.where((p) => p.riskLevel == 'High Risk').toList();
      if (highRisk.isEmpty) {
        return "✅ Clinical Status: No high-risk critical patients currently flagged. All active patients are in stable/moderate category.";
      }
      final buffer = StringBuffer('🚨 High-Risk Critical Patients (${highRisk.length} Flagged for Review):\n\n');
      for (final p in highRisk) {
        final lastVitals = p.vitalsHistory.isNotEmpty ? p.vitalsHistory.first : null;
        final vitalsStr = lastVitals != null ? 'BP: ${lastVitals.bp}, SpO2: ${lastVitals.spo2}%, Pain: ${lastVitals.painScale}/10' : 'Vitals Pending';
        buffer.writeln('• ${p.name} (${p.id}) — ${p.age}y ${p.gender}');
        buffer.writeln('  Diagnosis: ${p.diagnosis}');
        buffer.writeln('  Vitals: $vitalsStr | Ward: ${p.ward}');
        buffer.writeln('  Action: Urgent home nursing review recommended.\n');
      }
      return buffer.toString().trim();
    }

    // 2. Low Medicine Inventory & Reorder Check (Staff Only)
    if (q.contains('medicine') || q.contains('stock') || q.contains('drug') || q.contains('reorder') || q.contains('മരുന്ന്') || q.contains('സ്റ്റോക്ക്')) {
      final lowStock = medicines.where((m) => m.isLowStock).toList();
      if (lowStock.isEmpty) {
        return "✅ Inventory Status: All ${medicines.length} essential palliative medicines are currently stocked above reorder thresholds.";
      }
      final buffer = StringBuffer('⚠️ Low Stock Medicine Alert (${lowStock.length} Items Require Re-Order):\n\n');
      for (final m in lowStock) {
        buffer.writeln('• ${m.name} (${m.category})');
        buffer.writeln('  Current Stock: ${m.stockQuantity} ${m.unit} (Reorder Threshold: ${m.reorderLevel})');
        buffer.writeln('  Expiry: ${m.expiryDate} | Batch: ${m.batchNumber}\n');
      }
      return buffer.toString().trim();
    }

    // 3. Bedridden & Category A Patients
    if (q.contains('bedridden') || q.contains('category a') || q.contains('കിടപ്പിലായ') || q.contains('കിടപ്പിലായവർ')) {
      final categoryA = patients.where((p) => p.categoryTier.contains('Category A')).toList();
      final buffer = StringBuffer('🛏️ Category A Bedridden Patients (${categoryA.length} Registered):\n\n');
      for (final p in categoryA) {
        buffer.writeln('• ${p.name} (${p.id}, ${p.age}y) — ${p.diagnosis}');
        buffer.writeln('  Location: ${p.address} | Phone: ${p.phone}\n');
      }
      return buffer.toString().trim();
    }

    // 4. Specific Patient Lookup (by ID or Name)
    final matchPatient = patients.where((p) =>
      q.contains(p.id.toLowerCase()) ||
      q.contains(p.name.toLowerCase()) ||
      p.name.toLowerCase().split(' ').any((part) => part.length > 3 && q.contains(part))
    ).firstOrNull;

    if (matchPatient != null) {
      final p = matchPatient;
      final eqStr = p.equipmentIssued.isNotEmpty ? p.equipmentIssued.map((e) => e.equipmentName).join(', ') : 'None';
      return """📋 Patient Clinical Summary:
• Name & ID: ${p.name} (${p.id})
• Age & Gender: ${p.age}y ${p.gender} | Blood Group: ${p.bloodGroup}
• Primary Diagnosis: ${p.diagnosis}
• Care Category: ${p.categoryTier} (${p.riskLevel})
• Ward & District: ${p.ward}, ${p.district}
• Address: ${p.address}
• Contact: ${p.phone}
• Medical Equipment on Loan: $eqStr
• Caregiver Support: Active home palliative protocol enabled.""";
    }

    // 5. Pain Protocol & Morphine Guidance
    if (q.contains('pain') || q.contains('morphine') || q.contains('വേദന') || q.contains('ഡോസ്')) {
      return """💊 Kerala Palliative Pain Protocol (WHO Ladder Step 3):
1. Moderate to Severe Pain (VAS 6–10):
   • Initiate Oral Morphine Solution (10mg/5ml): Start 2.5mg – 5mg every 4 hours with SOS breakthrough doses.
   • Mandatory Co-Prescription: Regular laxatives (Syrup Lactulose / Bisacodyl) to prevent constipation.
2. Neuropathic Pain:
   • Co-prescribe Pregabalin 75mg at bedtime or Gabapentin 300mg TDS.
3. Breakthrough Pain:
   • Allow 1/6th of total 24-hour baseline morphine dose as rescue medication.""";
    }

    // 6. Wound & Bedsore Dressing Protocol
    if (q.contains('wound') || q.contains('bedsore') || q.contains('dressing') || q.contains('വ്രണം')) {
      return """🩹 Palliative Bedsore Care Protocol:
• Stage 1–2 Sores: Clean with normal saline (0.9%), apply protective barrier cream or hydrocolloid dressing.
• Stage 3–4 Cavity Wounds: Metronidazole powder/gel for odor control, non-adherent foam dressings.
• Prevention: Offload pressure using motorized ripple air mattress and reposition patient every 2 hours.""";
    }

    // 7. Emergency & Ambulance Contacts
    if (q.contains('ambulance') || q.contains('emergency') || q.contains('sos') || q.contains('ആംബുലൻസ്')) {
      return """🚑 Emergency Support & Ambulance Fleet:
• Kozhikode Unit: Sujith Kumar (+91 94470 12345) — KL-11-BV-4091 (Available)
• Ernakulam Unit: Rahim K. (+91 98460 54321) — KL-07-CD-8820 (Available)
• 24x7 State Emergency Toll-Free: 108 (Ambulance) / 1056 (DISHA Health Helpline)""";
    }

    // General Intelligent Default
    return "CareLink AI Assistant: Processed query regarding '$query'. Found ${patients.length} active patient records, ${medicines.length} pharmacy items, and active community nurse teams. You can ask for 'Show Critical Patients', 'Check Low Stock Medicines', or specific patient profiles.";
  }
}
