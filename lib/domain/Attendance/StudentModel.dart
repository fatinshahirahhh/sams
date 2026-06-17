/// SAMS-PACK-301 — Student entity (Domain layer).
class StudentModel {
  final String studentId;
  final String fullName;
  final String studentEmail;
  final String phoneNo;
  final String programCode;
  final String programName;
  final String faculty;
  final int currentSem;
  final String status;

  const StudentModel({
    required this.studentId,
    required this.fullName,
    required this.studentEmail,
    required this.phoneNo,
    required this.programCode,
    required this.programName,
    required this.faculty,
    required this.currentSem,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'student_id': studentId,
        'full_name': fullName,
        'student_email': studentEmail,
        'phone_no': phoneNo,
        'program_code': programCode,
        'program_name': programName,
        'faculty': faculty,
        'current_sem': currentSem,
        'status': status,
      };

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      studentId: map['student_id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      studentEmail: map['student_email'] as String? ?? '',
      phoneNo: map['phone_no'] as String? ?? '',
      programCode: map['program_code'] as String? ?? '',
      programName: map['program_name'] as String? ?? '',
      faculty: map['faculty'] as String? ?? '',
      currentSem: (map['current_sem'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'Active',
    );
  }
}
