/// Model for student tuition fee and outstanding balance.
class StudentFeeModel {
  // --- Fee identity ---
  final String feeId;
  final String studentId;
  final String semId;

  // --- Amounts ---
  final double totalAmount;
  final double amountPaid;

  // --- Updated by calculateBalance() ---
  double balance;

  // --- Payment deadline ---
  final String dueDate;

  // --- Constructor ---
  StudentFeeModel({
    required this.feeId,
    required this.studentId,
    required this.semId,
    required this.totalAmount,
    required this.amountPaid,
    required this.balance,
    required this.dueDate,
  });

  // --- Convert model to Map (e.g. for Firestore writes) ---
  Map<String, dynamic> toMap() {
    return {
      'fee_id': feeId,
      'student_id': studentId,
      'sem_id': semId,
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      'balance': balance,
      'due_date': dueDate,
    };
  }

  // --- Create model from Firestore document data ---
  factory StudentFeeModel.fromFirestore(Map<String, dynamic> map) {
    final model = StudentFeeModel(
      feeId: map['fee_id']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
      semId: map['sem_id']?.toString() ?? '',
      totalAmount: _readAmount(map['total_amount']),
      amountPaid: _readAmount(map['amount_paid']),
      balance: _readAmount(map['balance']),
      dueDate: map['due_date']?.toString() ?? '',
    );
    model.calculateBalance();
    return model;
  }

  // --- balance = total_amount - amount_paid ---
  double calculateBalance() {
    balance = totalAmount - amountPaid;
    return balance;
  }

  // --- Block academic access when week >= 5 and balance still owed ---
  bool isBlocked(int week) {
    calculateBalance();
    return week >= 5 && balance > 0;
  }

  // --- Read numeric amount from Firestore (int or double) ---
  static double _readAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}
