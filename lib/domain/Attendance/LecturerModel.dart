/// SAMS-PACK-302 — Lecturer entity (Domain layer).
class LecturerModel {
  final String staffId;
  final String staffName;
  final String staffEmail;
  final String department;
  final String faculty;
  final String role;
  final String status;

  const LecturerModel({
    required this.staffId,
    required this.staffName,
    required this.staffEmail,
    required this.department,
    required this.faculty,
    required this.role,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'staff_id': staffId,
        'staff_name': staffName,
        'staff_email': staffEmail,
        'department': department,
        'faculty': faculty,
        'role': role,
        'status': status,
      };

  factory LecturerModel.fromMap(Map<String, dynamic> map) {
    return LecturerModel(
      staffId: map['staff_id'] as String? ?? '',
      staffName: map['staff_name'] as String? ?? '',
      staffEmail: map['staff_email'] as String? ?? '',
      department: map['department'] as String? ?? '',
      faculty: map['faculty'] as String? ?? '',
      role: map['role'] as String? ?? 'Lecturer',
      status: map['status'] as String? ?? 'Active',
    );
  }
}
