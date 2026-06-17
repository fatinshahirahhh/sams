import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sams/domain/StudentFee/Fee/StudentFeeModel.dart';
import 'package:sams/domain/StudentFee/Payment/PaymentModel.dart';
import 'package:sams/domain/StudentFee/Student/StudentModel.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class PaymentController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StudentModel? student;
  StudentFeeModel? fee;
  PaymentModel? payment;
  bool isLoading = false;
  String? errorMessage;

  static final DateTime semesterStartDate = DateTime.now().subtract(const Duration(days: 35));

  int get currentWeek {
    final now = DateTime.now();
    final difference = now.difference(semesterStartDate).inDays;
    return (difference / 7).floor() + 1;
  }

  static const List<String> supportedPaymentMethods = ['Bank Transfer', 'QR Pay', 'Online Banking'];

  Future<void> fetchFeeDetails(String studentId) async {
    isLoading = true;
    errorMessage = null; // Clear previous errors
    notifyListeners();
    try {
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      final feeSnapshot = await _firestore.collection('fees').where('student_id', isEqualTo: studentId).limit(1).get();

      if (!studentDoc.exists || feeSnapshot.docs.isEmpty) {
        student = StudentModel(
          studentId: studentId, fullName: 'Student',
          studentEmail: '', phoneNo: '', programCode: 'BCS',
          programName: 'Computer Science', faculty: 'FK',
          currentSem: '2026/1', status: 'Active', isBlocked: false,
        );
        fee = StudentFeeModel(
          feeId: 'F-$studentId', studentId: studentId, semId: 'SEM2026-1',
          totalAmount: 860.0, amountPaid: 0.0, balance: 860.0, dueDate: '2026-06-30',
        );
        await _firestore.collection('students').doc(studentId).set(student!.toMap());
        await _firestore.collection('fees').doc(fee!.feeId).set(fee!.toMap());
      } else {
        student = StudentModel.fromFirestore(studentDoc.data()!);
        fee = StudentFeeModel.fromFirestore(feeSnapshot.docs.first.data());
      }
      fee!.calculateBalance();
    } catch (e) {
      errorMessage = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Converts any file (PDF/Image) to Base64 string (FREE storage in Firestore).
  Future<String?> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 1000000) {
        errorMessage = 'File too large (>1MB). Please use a smaller PDF or screenshot.';
        notifyListeners();
        return null;
      }
      return base64Encode(bytes);
    } catch (e) {
      errorMessage = 'Conversion failed: $e';
      notifyListeners();
      return null;
    }
  }

  /// Saves the Base64 string as a file and opens it.
  Future<void> saveAndOpenFile(String base64String, String fileName) async {
    try {
      errorMessage = null;
      notifyListeners();

      if (base64String.isEmpty) {
        throw Exception('No file data available.');
      }

      // Clean the base64 string
      final cleanBase64 = base64String.trim().replaceAll(RegExp(r'\s+'), '');
      final bytes = base64Decode(cleanBase64);

      // Detect file type
      String extension = 'pdf';
      String mimeType = 'application/pdf';
      if (bytes.length > 4) {
        if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
          extension = 'pdf';
          mimeType = 'application/pdf';
        } else if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
          extension = 'jpg';
          mimeType = 'image/jpeg';
        } else if (bytes[0] == 0x89 && bytes[1] == 0x50) {
          extension = 'png';
          mimeType = 'image/png';
        }
      }

      // Sanitize filename
      final baseName = fileName.split('.').first.replaceAll(RegExp(r'[\\/:\*\?"<>\|]'), '_');
      final safeFileName = '$baseName.$extension';

      // Use Temporary Directory for immediate viewing
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$safeFileName');

      await file.writeAsBytes(bytes, flush: true);
      
      // Open the file immediately
      final result = await OpenFilex.open(file.path, type: mimeType);
      
      if (result.type != ResultType.done) {
        errorMessage = 'Failed to open file: ${result.message}';
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> createPaymentRecord(String invoiceNo, double amount, String refNo, String method, String date, String base64Data) async {
    try {
      final p = PaymentModel(
        invoiceNo: invoiceNo, feeId: fee?.feeId ?? '', studentId: student?.studentId ?? '',
        paymentMethod: method, refNo: refNo, receiptUpload: base64Data,
        amount: amount, status: PaymentModel.statusPending,
        rejectionReason: '', verifiedBy: '', dateCreated: date,
      );
      await _firestore.collection('payments').doc(invoiceNo).set(p.toMap());
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<List<PaymentModel>> fetchStudentPayments(String studentId) async {
    final snapshot = await _firestore.collection('payments').where('student_id', isEqualTo: studentId).get();
    return snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc.data())).toList();
  }

  Future<PaymentModel?> getDetails(String invoiceNo) async {
    final doc = await _firestore.collection('payments').doc(invoiceNo).get();
    if (doc.exists) payment = PaymentModel.fromFirestore(doc.data()!);
    notifyListeners();
    return payment;
  }

  Future<List<PaymentModel>> getAllPayments() async {
    final snapshot = await _firestore.collection('payments').get();
    return snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc.data())).toList();
  }

  Future<void> updateStatus(String inv, String status, String reason, String verifierId) async {
    final docRef = _firestore.collection('payments').doc(inv);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final p = PaymentModel.fromFirestore(doc.data()!);
    final updated = PaymentModel(
      invoiceNo: p.invoiceNo, feeId: p.feeId, studentId: p.studentId,
      paymentMethod: p.paymentMethod, refNo: p.refNo, receiptUpload: p.receiptUpload,
      amount: p.amount, status: status, rejectionReason: reason,
      verifiedBy: verifierId, dateCreated: p.dateCreated,
    );
    await docRef.set(updated.toMap());
    if (status == PaymentModel.statusApproved) await _syncFee(updated);
  }

  Future<void> _syncFee(PaymentModel p) async {
    final fRef = _firestore.collection('fees').doc(p.feeId);
    final fDoc = await fRef.get();
    if (!fDoc.exists) return;
    final f = StudentFeeModel.fromFirestore(fDoc.data()!);
    final newPaid = f.amountPaid + p.amount;
    await fRef.update({'amount_paid': newPaid, 'balance': f.totalAmount - newPaid});
    await _firestore.collection('students').doc(f.studentId).update({'is_blocked': (f.totalAmount - newPaid) > 0 && currentWeek >= 5});
  }

  Future<bool> uploadDataToFirestore() async => true;
}
