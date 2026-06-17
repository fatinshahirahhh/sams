/// Model for a payment transaction submitted by a student.
class PaymentModel {
  // --- Payment status values ---
  static const String statusPending = 'Pending';
  static const String statusApproved = 'Approved';
  static const String statusRejected = 'Rejected';

  // --- Payment identity ---
  final String invoiceNo;
  final String feeId;
  final String studentId;

  // --- Payment details ---
  final String paymentMethod;
  final String refNo;
  final String receiptUpload;
  final double amount;

  // --- Verification ---
  final String status;
  final String rejectionReason;
  final String verifiedBy;
  final String dateCreated;

  // --- Constructor ---
  PaymentModel({
    required this.invoiceNo,
    required this.feeId,
    required this.studentId,
    required this.paymentMethod,
    required this.refNo,
    required this.receiptUpload,
    required this.amount,
    required this.status,
    required this.rejectionReason,
    required this.verifiedBy,
    required this.dateCreated,
  });

  // --- Convert model to Map (e.g. for Firestore writes) ---
  Map<String, dynamic> toMap() {
    return {
      'invoice_no': invoiceNo,
      'fee_id': feeId,
      'student_id': studentId,
      'payment_method': paymentMethod,
      'ref_no': refNo,
      'receipt_upload': receiptUpload,
      'amount': amount,
      'status': status,
      'rejection_reason': rejectionReason,
      'verified_by': verifiedBy,
      'date_created': dateCreated,
    };
  }

  // --- Create model from Firestore document data ---
  factory PaymentModel.fromFirestore(Map<String, dynamic> map) {
    return PaymentModel(
      invoiceNo: map['invoice_no']?.toString() ?? '',
      feeId: map['fee_id']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
      paymentMethod: map['payment_method']?.toString() ?? '',
      refNo: map['ref_no']?.toString() ?? '',
      receiptUpload: map['receipt_upload']?.toString() ?? '',
      amount: _readAmount(map['amount']),
      status: map['status']?.toString() ?? statusPending,
      rejectionReason: map['rejection_reason']?.toString() ?? '',
      verifiedBy: map['verified_by']?.toString() ?? '',
      dateCreated: map['date_created']?.toString() ?? '',
    );
  }

  // --- True when Treasury rejected this payment ---
  bool isRejected() {
    return status == statusRejected;
  }

  // --- Read numeric amount from Firestore (int or double) ---
  static double _readAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }
}
