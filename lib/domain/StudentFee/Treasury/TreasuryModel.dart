/// Model for Treasury staff who verify student fee payments.
class TreasuryModel {
  // --- Role name used for payment verification ---
  static const String roleTreasury = 'Treasury';

  // --- Staff identity ---
  final String staffId;
  final String staffName;
  final String staffEmail;

  // --- Work details ---
  final String department;
  final String role;

  // --- Constructor ---
  TreasuryModel({
    required this.staffId,
    required this.staffName,
    required this.staffEmail,
    required this.department,
    required this.role,
  });

  // --- Convert model to Map (e.g. for Firestore writes) ---
  Map<String, dynamic> toMap() {
    return {
      'staff_id': staffId,
      'staff_name': staffName,
      'staff_email': staffEmail,
      'department': department,
      'role': role,
    };
  }

  // --- Create model from Firestore document data ---
  factory TreasuryModel.fromFirestore(Map<String, dynamic> map) {
    return TreasuryModel(
      staffId: map['staff_id']?.toString() ?? '',
      staffName: map['staff_name']?.toString() ?? '',
      staffEmail: map['staff_email']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
    );
  }

  // --- Check if this staff member can verify payments ---
  bool canVerify() {
    return role == roleTreasury;
  }
}
