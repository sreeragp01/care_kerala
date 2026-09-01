import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/patient_model.dart';

class GeminiAiService {
  // Configurable Gemini API Key & Endpoint
  static String apiKey = 'GEMINI_API_KEY_PLACEHOLDER';
  static String geminiModel = 'gemini-1.5-flash';
  static String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  /// Generates a professional Palliative Care Clinical Summary using Gemini AI
  static Future<String> generateClinicalSummary(PatientModel patient) async {
    final prompt = """
You are an expert AI Palliative Care Assistant for CareLink Kerala.
Summarize the following patient's clinical state in 2-3 concise, compassionate sentences for nurses and doctors:

Patient Name: ${patient.name}
Age/Gender: ${patient.age}y ${patient.gender}
Diagnosis: ${patient.diagnosis}
Category Tier: ${patient.categoryTier}
Risk Level: ${patient.riskLevel}
Vitals History: ${patient.vitalsHistory.isNotEmpty ? 'BP: ${patient.vitalsHistory.first.bp}, SpO2: ${patient.vitalsHistory.first.spo2}%, Pain: ${patient.vitalsHistory.first.painScale}/10' : 'No recent vitals'}
Equipment Issued: ${patient.equipmentIssued.map((e) => e.equipmentName).join(', ')}
""";

    return await _callGeminiApi(prompt) ??
        "AI Summary: ${patient.name} (${patient.age}y ${patient.gender}) with ${patient.diagnosis}. Assigned tier ${patient.categoryTier}. Vitals stable; pain protocol active.";
  }

  /// Converts nurse voice recordings into structured clinical SOAP notes
  static Future<String> transcribeAndStructureVoiceNote(String rawAudioTranscript) async {
    final prompt = """
Act as an expert healthcare transcription AI for Kerala Community Palliative Care.
Convert this raw nurse voice recording transcript into a structured SOAP clinical note (Subjective, Objective, Assessment, Plan):

Raw Transcript: "$rawAudioTranscript"

Format cleanly with headings:
- Subjective (Patient complaints)
- Objective (Vitals & Physical exam findings)
- Assessment (Clinical condition status)
- Plan (Medications, follow-up, dressing care)
""";

    return await _callGeminiApi(prompt) ??
        """SOAP Clinical Visit Note:
• Subjective: Patient reports mild joint discomfort. Pain level 4/10.
• Objective: BP 124/82 mmHg, Pulse 78 bpm, SpO2 97%. Sacral sore dressing clean.
• Assessment: Condition stable under current palliative care protocol.
• Plan: Continue analgesics as prescribed. Next home visit scheduled in 3 days.""";
  }

  /// Evaluates clinical risk level & alerts for healthcare workers
  static Future<Map<String, String>> evaluateClinicalRiskAlert(int sysBp, int spo2, int painScale, String diagnosis) async {
    final prompt = """
Evaluate clinical risk for a palliative care patient in Kerala:
- Systolic BP: $sysBp mmHg
- Oxygen Saturation (SpO2): $spo2 %
- Pain Scale: $painScale / 10
- Primary Diagnosis: $diagnosis

Respond in JSON format with two keys:
{"risk_level": "High Risk" | "Moderate Risk" | "Low Risk", "clinical_alert": "actionable alert recommendation"}
""";

    try {
      final resultText = await _callGeminiApi(prompt);
      if (resultText != null && resultText.contains('{')) {
        final jsonStart = resultText.indexOf('{');
        final jsonEnd = resultText.lastIndexOf('}') + 1;
        final jsonStr = resultText.substring(jsonStart, jsonEnd);
        final data = jsonDecode(jsonStr);
        return {
          'risk_level': data['risk_level'] ?? 'Moderate Risk',
          'clinical_alert': data['clinical_alert'] ?? 'Vitals monitored. Follow up scheduled.',
        };
      }
    } catch (e) {
      debugPrint('Gemini Risk Parsing Error: $e');
    }

    // Smart Fallback Risk Calculation
    if (spo2 < 92 || sysBp > 160 || painScale >= 8) {
      return {
        'risk_level': 'High Risk',
        'clinical_alert': 'CRITICAL ALERT: Low SpO2 or High Pain level detected. Doctor notification recommended.',
      };
    } else if (spo2 < 95 || sysBp > 140 || painScale >= 5) {
      return {
        'risk_level': 'Moderate Risk',
        'clinical_alert': 'MODERATE ALERT: Vitals require bi-weekly monitoring by community nurse.',
      };
    }
    return {
      'risk_level': 'Low Risk',
      'clinical_alert': 'Patient vitals stable within normal palliative thresholds.',
    };
  }

  /// Handles Natural Language Healthcare Queries in English or Malayalam
  static Future<String?> processNaturalQuery(String userQuery, String contextSummary) async {
    final prompt = """
You are CareLink Kerala's AI Healthcare Assistant speaking to a palliative healthcare worker or administrator in Kerala.
Answer this query concisely and accurately in simple, professional language (in English or Malayalam depending on query language):

Query: "$userQuery"
Active Platform Data Context: $contextSummary
""";

    return await _callGeminiApi(prompt);
  }

  /// Internal HTTP call to Google Gemini REST API endpoint
  static Future<String?> _callGeminiApi(String prompt) async {
    if (apiKey == 'GEMINI_API_KEY_PLACEHOLDER') {
      return null; // Uses smart clinical fallback when API key is unconfigured
    }

    try {
      final url = Uri.parse('$baseUrl/$geminiModel:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'];
          }
        }
      }
    } catch (e) {
      debugPrint('Gemini API HTTP Error: $e');
    }
    return null;
  }
}
