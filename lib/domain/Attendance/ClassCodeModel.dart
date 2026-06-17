import 'package:cloud_firestore/cloud_firestore.dart';

/// SAMS-PACK-304 — Ephemeral attendance class code entity (Domain layer).
class ClassCodeModel {
  final String codeId;
  final String classSessionId;
  final String staffId;
  final String classCode;
  final DateTime generatedAt;
  final DateTime expiredAt;
  final bool isActive;

  const ClassCodeModel({
    required this.codeId,
    required this.classSessionId,
    required this.staffId,
    required this.classCode,
    required this.generatedAt,
    required this.expiredAt,
    required this.isActive,
  });

  bool isExpired() => DateTime.now().isAfter(expiredAt);

  Map<String, dynamic> toMap() => {
        'code_id': codeId,
        'class_session_id': classSessionId,
        'staff_id': staffId,
        'class_code': classCode,
        'generated_at': generatedAt.toIso8601String(),
        'expired_at': expiredAt.toIso8601String(),
        'is_active': isActive,
      };

  factory ClassCodeModel.fromMap(Map<String, dynamic> map) {
    return ClassCodeModel(
      codeId: map['code_id'] as String? ?? '',
      classSessionId: map['class_session_id'] as String? ?? '',
      staffId: map['staff_id'] as String? ?? '',
      classCode: map['class_code'] as String? ?? '',
      generatedAt: _parseDateTime(map['generated_at']),
      expiredAt: _parseDateTime(map['expired_at']),
      isActive: map['is_active'] as bool? ?? false,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
