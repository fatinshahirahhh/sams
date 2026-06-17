/// Model for student data in the Student Fee module.
/// Also tracks academic access restriction (blocked / active).
class StudentModel {
  // --- Student identity ---
  final String studentId;
  final String fullName;
  final String studentEmail;
  final String phoneNo;

  // --- Academic program ---
  final String programCode;
  final String programName;
  final String faculty;
  final String currentSem;

  // --- Enrollment status ---
  final String status;

  // --- Academic access (true = blocked, false = active) ---
  bool isBlocked;

  // --- Constructor ---
  StudentModel({
    required this.studentId,
    required this.fullName,
    required this.studentEmail,
    required this.phoneNo,
    required this.programCode,
    required this.programName,
    required this.faculty,
    required this.currentSem,
    required this.status,
    required this.isBlocked,
  });

  // --- Convert model to Map (e.g. for Firestore writes) ---
  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'full_name': fullName,
      'student_email': studentEmail,
      'phone_no': phoneNo,
      'program_code': programCode,
      'program_name': programName,
      'faculty': faculty,
      'current_sem': currentSem,
      'status': status,
      'is_blocked': isBlocked,
    };
  }

  // --- Create model from Firestore document data ---
  factory StudentModel.fromFirestore(Map<String, dynamic> map) {
    return StudentModel(
      studentId: map['student_id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      studentEmail: map['student_email']?.toString() ?? '',
      phoneNo: map['phone_no']?.toString() ?? '',
      programCode: map['program_code']?.toString() ?? '',
      programName: map['program_name']?.toString() ?? '',
      faculty: map['faculty']?.toString() ?? '',
      currentSem: map['current_sem']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      isBlocked: map['is_blocked'] == true,
    );
  }

  // --- Update academic access: true = blocked, false = active ---
  void updateBlockStatus(bool status) {
    isBlocked = status;
  }
}
