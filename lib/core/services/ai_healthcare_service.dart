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

  /// Solves natural language query using Gemini AI
  static Future<String> processNaturalLanguageQueryAsync(String query, List<PatientModel> patients, List<MedicineItemModel> medicines) async {
    final contextSummary = "Total Patients: ${patients.length}, Critical High Risk: ${patients.where((p) => p.riskLevel == 'High Risk').length}, Medicines Low Stock: ${medicines.where((m) => m.isLowStock).map((m) => m.name).join(', ')}";
    final result = await GeminiAiService.processNaturalQuery(query, contextSummary);
    return result;
  }

  /// Synchronous fallback processor for natural language queries
  static String processNaturalLanguageQuery(String query, List<PatientModel> patients, List<MedicineItemModel> medicines) {
    final q = query.toLowerCase();
    if (q.contains('critical') || q.contains('high risk')) {
      final highRisk = patients.where((p) => p.riskLevel == 'High Risk').toList();
      return "Found ${highRisk.length} High Risk critical patients needing urgent clinical review.";
    } else if (q.contains('medicine') || q.contains('stock') || q.contains('low')) {
      final lowStock = medicines.where((m) => m.isLowStock).toList();
      return "Low Stock Alert: ${lowStock.map((m) => m.name).join(', ')} require immediate re-ordering.";
    } else if (q.contains('bedridden') || q.contains('category a')) {
      final categoryA = patients.where((p) => p.categoryTier.contains('Category A')).toList();
      return "Found ${categoryA.length} Category A bedridden patients registered in the system.";
    }
    return "Query processed: Found relevant records across active palliative care tenants.";
  }
}
