import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/patient_model.dart';

class ApiService {
  // Configurable Backend API Endpoint
  static String baseUrl = 'http://127.0.0.1:8000/api';
  static String? authToken;
  static String? activeTenantId;

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    if (activeTenantId != null) {
      headers['X-Tenant-ID'] = activeTenantId!;
    }
    return headers;
  }

  // Auth & Token API
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        authToken = data['access'];
        return data;
      }
    } catch (e) {
      debugPrint('API Login error: $e');
    }
    return null;
  }

  // Organizations API
  static Future<List<OrganizationModel>> getOrganizations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orgs/'), headers: _headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => OrganizationModel(
          id: item['id'].toString(),
          name: item['name'],
          district: item['district'],
          registrationNumber: item['registration_number'],
          phone: item['phone'],
          upiId: item['upi_id'] ?? '',
          bankAccountName: item['bank_account_name'] ?? '',
          bankAccountNumber: item['bank_account_number'] ?? '',
          ifscCode: item['ifsc_code'] ?? '',
          bankName: item['bank_name'] ?? '',
          qrCodeUrl: item['qr_code_image_url'] ?? '',
          razorpayKeyId: item['razorpay_account_id']?.toString().isNotEmpty == true ? item['razorpay_account_id'] : 'rzp_test_CareLinkKerala2026',
          activePatientsCount: item['active_patients_count'] ?? 0,
          totalVisitsCount: item['total_visits_count'] ?? 0,
        )).toList();
      }
    } catch (e) {
      debugPrint('API getOrganizations error: $e');
    }
    return [];
  }

  // Razorpay Payment Gateway APIs
  static Future<Map<String, dynamic>?> createRazorpayOrder({
    required double amount,
    required String category,
    String? fundraiserId,
    String? donorName,
    String? organizationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/finance/razorpay/create-order/'),
        headers: _headers,
        body: jsonEncode({
          'amount': amount,
          'category': category,
          'fundraiser_id': fundraiserId ?? '',
          'donor_name': donorName ?? 'CareLink Supporter',
          'organization_id': organizationId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('API createRazorpayOrder error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required double amount,
    required String donorName,
    required String category,
    String paymentMode = 'Razorpay',
    String? fundraiserId,
    String? donorPrayer,
    bool isAnonymous = false,
    String? organizationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/finance/razorpay/verify-payment/'),
        headers: _headers,
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          'amount': amount,
          'donor_name': donorName,
          'category': category,
          'payment_mode': paymentMode,
          'fundraiser_id': fundraiserId ?? '',
          'donor_prayer': donorPrayer ?? '',
          'is_anonymous': isAnonymous,
          'organization_id': organizationId,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('API verifyRazorpayPayment error: $e');
    }
    return null;
  }


  // Patients API
  static Future<List<PatientModel>> getPatients({String? district, String? tier}) async {
    try {
      var uri = Uri.parse('$baseUrl/patients/');
      final params = <String, String>{};
      if (district != null) params['district'] = district;
      if (tier != null) params['tier'] = tier;
      if (params.isNotEmpty) uri = uri.replace(queryParameters: params);

      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((p) => PatientModel(
          id: p['patient_id_code'] ?? 'PAT-${p['id']}',
          name: p['name'],
          age: p['age'],
          gender: p['gender'],
          bloodGroup: p['blood_group'],
          district: p['district'],
          ward: p['ward'],
          address: p['address'],
          phone: p['phone'],
          categoryTier: p['category_tier'],
          diagnosis: p['diagnosis'],
          riskLevel: p['risk_level'],
          aiSummary: p['ai_summary'] ?? '',
          emergencyContactName: p['emergency_contact_name'],
          emergencyContactPhone: p['emergency_contact_phone'],
          vitalsHistory: (p['vitals_history'] as List? ?? []).map((v) => VitalsReading(
            date: v['recorded_date'] ?? '2026-08-06',
            bp: v['bp'],
            pulse: v['pulse'],
            spo2: v['spo2'],
            painScale: v['pain_scale'],
            recordedBy: v['recorded_by'],
          )).toList(),
          equipmentIssued: (p['equipment_issued'] as List? ?? []).map((eq) => EquipmentIssued(
            equipmentName: eq['equipment_name'],
            issuedDate: eq['issued_date'],
            serialNumber: eq['serial_number'],
            status: eq['status'],
          )).toList(),
          familyMembers: (p['family_members'] as List? ?? []).map((fam) => FamilyMemberContact(
            name: fam['name'],
            relation: fam['relation'],
            phone: fam['phone'],
          )).toList(),
          medicalHistory: [p['diagnosis']],
          registeredDate: p['created_at']?.toString().substring(0, 10) ?? '2026-08-06',
        )).toList();
      }
    } catch (e) {
      debugPrint('API getPatients error: $e');
    }
    return [];
  }

  // Home Visits API
  static Future<bool> performGpsCheckIn(String visitId, String checkInTime, String locationName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/visits/$visitId/gps_check_in/'),
        headers: _headers,
        body: jsonEncode({
          'gps_check_in_time': checkInTime,
          'gps_location_name': locationName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API performGpsCheckIn error: $e');
      return false;
    }
  }

  // Blood Donors API
  static Future<bool> recordBloodDonation(String donorId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/blood-donors/$donorId/record_donation/'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API recordBloodDonation error: $e');
      return false;
    }
  }

  // AI Services API
  static Future<String?> processNaturalLanguageQuery(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/natural-query/'),
        headers: _headers,
        body: jsonEncode({'query': query}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      }
    } catch (e) {
      debugPrint('API processNaturalLanguageQuery error: $e');
    }
    return null;
  }

  // ============================================================================
  // Email & OTP Authentication APIs
  // ============================================================================

  /// Dispatches a 6-digit OTP code directly to user email or phone via Django SMTP
  static Future<Map<String, dynamic>?> requestPasswordResetOtp(String emailOrPhone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/password-reset/request/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email_or_phone': emailOrPhone.trim()}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('API requestPasswordResetOtp error: $e');
    }
    return null;
  }

  /// Verifies OTP and updates user password on backend
  static Future<Map<String, dynamic>?> confirmPasswordReset({
    required String emailOrPhone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/password-reset/confirm/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_or_phone': emailOrPhone.trim(),
          'otp': otp.trim(),
          'new_password': newPassword.trim(),
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('API confirmPasswordReset error: $e');
    }
    return null;
  }

  /// Dispatches a diagnostic test email to verify live SMTP connectivity
  static Future<Map<String, dynamic>?> sendTestEmail(String recipientEmail) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/test-email/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': recipientEmail.trim()}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('API sendTestEmail error: $e');
    }
    return null;
  }

  // ============================================================================
  // Phone OTP & SMS Delivery APIs
  // ============================================================================

  /// Dispatches a 6-digit OTP code directly to an Indian mobile number via SMS Gateway
  static Future<Map<String, dynamic>?> sendPhoneOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/phone-otp/send/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phoneNumber.trim()}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('API sendPhoneOtp error: $e');
    }
    return null;
  }

  /// Verifies phone OTP and returns authenticated patient session
  static Future<Map<String, dynamic>?> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/phone-otp/verify/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phoneNumber.trim(),
          'otp': otp.trim(),
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('API verifyPhoneOtp error: $e');
    }
    return null;
  }
}
