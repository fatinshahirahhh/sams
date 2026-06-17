/// SAMS-PACK-303 — Scheduled class session entity (Domain layer).
class ClassSessionModel {
  final String classSessionId;
  final String staffId;
  final String subjectCode;
  final String subjectName;
  final String classSection;
  final String classDate;
  final String startTime;
  final String endTime;
  final String sessionStatus;
  final bool requiresLocation;
  final double? latitude;
  final double? longitude;

  const ClassSessionModel({
    required this.classSessionId,
    required this.staffId,
    required this.subjectCode,
    required this.subjectName,
    required this.classSection,
    required this.classDate,
    required this.startTime,
    required this.endTime,
    required this.sessionStatus,
    this.requiresLocation = true,
    this.latitude,
    this.longitude,
  });

  bool isOpen() => sessionStatus == 'Open';

  Map<String, dynamic> toMap() => {
        'class_session_id': classSessionId,
        'staff_id': staffId,
        'subject_code': subjectCode,
        'subject_name': subjectName,
        'class_section': classSection,
        'class_date': classDate,
        'start_time': startTime,
        'end_time': endTime,
        'session_status': sessionStatus,
        'requires_location': requiresLocation,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory ClassSessionModel.fromMap(Map<String, dynamic> map) {
    return ClassSessionModel(
      classSessionId: map['class_session_id'] as String? ?? '',
      staffId: map['staff_id'] as String? ?? '',
      subjectCode: map['subject_code'] as String? ?? '',
      subjectName: map['subject_name'] as String? ?? '',
      classSection: map['class_section'] as String? ?? '',
      classDate: map['class_date'] as String? ?? '',
      startTime: map['start_time'] as String? ?? '',
      endTime: map['end_time'] as String? ?? '',
      sessionStatus: map['session_status'] as String? ?? 'Closed',
      requiresLocation: map['requires_location'] as bool? ?? true,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
