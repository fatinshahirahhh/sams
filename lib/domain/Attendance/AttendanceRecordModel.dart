import 'package:cloud_firestore/cloud_firestore.dart';

/// SAMS-PACK-305 — Student attendance check-in record (Domain layer).
class AttendanceRecordModel {
  final String attendanceId;
  final String classSessionId;
  final String codeId;
  final String studentId;
  final String locationId;
  DateTime checkInTime;
  final double latitude;
  final double longitude;
  String attendanceStatus;
  String remarks;

  AttendanceRecordModel({
    required this.attendanceId,
    required this.classSessionId,
    required this.codeId,
    required this.studentId,
    required this.locationId,
    required this.checkInTime,
    required this.latitude,
    required this.longitude,
    required this.attendanceStatus,
    required this.remarks,
  });

  void markPresent() {
    attendanceStatus = 'Present';
  }

  void setRemarks(String value) {
    remarks = value;
  }

  Map<String, dynamic> toMap() => {
        'attendance_id': attendanceId,
        'class_session_id': classSessionId,
        'code_id': codeId,
        'student_id': studentId,
        'location_id': locationId,
        'check_in_time': checkInTime.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'attendance_status': attendanceStatus,
        'remarks': remarks,
      };

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map) {
    return AttendanceRecordModel(
      attendanceId: map['attendance_id'] as String? ?? '',
      classSessionId: map['class_session_id'] as String? ?? '',
      codeId: map['code_id'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      locationId: map['location_id'] as String? ?? '',
      checkInTime: _parseDateTime(map['check_in_time']),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      attendanceStatus: map['attendance_status'] as String? ?? 'Pending',
      remarks: map['remarks'] as String? ?? '',
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
