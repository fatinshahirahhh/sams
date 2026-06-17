/// Model for logged-in user information.
class UserModel {
  // --- Role names used in SAMS ---
  static const String roleStudent = 'Student';
  static const String roleTreasury = 'Treasury';
  static const String roleLecturer = 'Lecturer';

  // --- User attributes ---
  final String userId; // e.g. Student ID (CB23026), Staff ID
  final String username; // Full Name
  final String role;

  // --- Constructor ---
  UserModel({
    required this.userId,
    required this.username,
    required this.role,
  });

  // --- Convert model to Map (e.g. for Firestore writes) ---
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'role': role,
    };
  }

  // --- Create model from Firestore document data ---
  factory UserModel.fromFirestore(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
    );
  }
}
