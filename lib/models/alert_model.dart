class AlertModel {
  const AlertModel({
    required this.id,
    this.cattleId,
    required this.title,
    required this.message,
    this.severity,
    this.createdAt,
  });

  final int id;
  final int? cattleId;
  final String title;
  final String message;
  final String? severity;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cattleId': cattleId,
      'title': title,
      'message': message,
      'severity': severity,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] as int? ?? 0,
      cattleId: map['cattleId'] as int?,
      title: map['title'] as String? ?? 'Alert',
      message: map['message'] as String? ?? '',
      severity: map['severity'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }
}
