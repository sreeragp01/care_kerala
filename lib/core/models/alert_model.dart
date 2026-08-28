class ClinicalAlertModel {
  final String id;
  final String patientName;
  final String alertType;
  final String severity; // CRITICAL, HIGH, MEDIUM, LOW, INFO
  final String title;
  final String message;
  final String status; // OPEN, ACKNOWLEDGED, RESOLVED, DISMISSED
  final String createdAt;
  final String acknowledgedBy;
  final String? acknowledgedAt;

  ClinicalAlertModel({
    required this.id,
    required this.patientName,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
    this.acknowledgedBy = '',
    this.acknowledgedAt,
  });

  factory ClinicalAlertModel.fromJson(Map<String, dynamic> json) {
    return ClinicalAlertModel(
      id: json['id'].toString(),
      patientName: json['patient_name'] ?? '',
      alertType: json['alert_type'] ?? 'VITAL_ABNORMAL',
      severity: json['severity'] ?? 'MEDIUM',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'OPEN',
      createdAt: json['created_at'] ?? '',
      acknowledgedBy: json['acknowledged_by'] ?? '',
      acknowledgedAt: json['acknowledged_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_name': patientName,
      'alert_type': alertType,
      'severity': severity,
      'title': title,
      'message': message,
      'status': status,
      'created_at': createdAt,
      'acknowledged_by': acknowledgedBy,
      'acknowledged_at': acknowledgedAt,
    };
  }
}
