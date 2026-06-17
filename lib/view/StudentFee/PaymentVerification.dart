import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/domain/StudentFee/Payment/PaymentModel.dart';
import 'package:sams/domain/StudentFee/Student/StudentModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/view/Authentication/AuthRouteGuard.dart';
import 'package:sams/view/StudentFee/PaymentManagement.dart';
import 'package:sams/view/StudentFee/PaymentRejectionForm.dart';

class PaymentVerification extends StatelessWidget {
  final String invoiceNo;
  const PaymentVerification({super.key, required this.invoiceNo});
  @override
  Widget build(BuildContext context) {
    return AuthRouteGuard(allowedRoles: [UserModel.roleTreasury], child: _PaymentVerificationView(invoiceNo: invoiceNo));
  }
}

class _PaymentVerificationView extends StatefulWidget {
  final String invoiceNo;
  const _PaymentVerificationView({required this.invoiceNo});
  @override
  State<_PaymentVerificationView> createState() => _PaymentVerificationViewState();
}

class _PaymentVerificationViewState extends State<_PaymentVerificationView> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final controller = context.read<PaymentController>();
    await controller.getDetails(widget.invoiceNo);
    if (controller.payment != null) await controller.fetchFeeDetails(controller.payment!.studentId);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> onUpdateStatus(String invoiceNo) async {
    final auth = context.read<AuthController>();
    final controller = context.read<PaymentController>();
    await controller.updateStatus(invoiceNo, PaymentModel.statusApproved, '', auth.currentUser?.userId ?? 'Unknown');
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> onViewReceipt() async {
    final controller = context.read<PaymentController>();
    final payment = controller.payment;
    
    if (payment != null && payment.receiptUpload.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await controller.saveAndOpenFile(payment.receiptUpload, 'receipt_${payment.invoiceNo}');
      
      if (mounted) Navigator.pop(context);

      if (controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No receipt file found.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentController>(
      builder: (context, controller, _) {
        final payment = controller.payment;
        if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (payment == null) return const Scaffold(body: Center(child: Text('Payment not found.')));

        return Scaffold(
          appBar: AppBar(backgroundColor: const Color(0xFF0C855E), foregroundColor: Colors.white, title: const Text('Verify Payment')),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(child: ListTile(title: const Text('Student ID'), subtitle: Text(payment.studentId))),
                    Card(child: ListTile(title: const Text('Invoice Number'), subtitle: Text(payment.invoiceNo))),
                    Card(child: ListTile(title: const Text('Amount Paid'), subtitle: Text('RM ${payment.amount.toStringAsFixed(2)}'))),
                    Card(child: ListTile(title: const Text('Payment Method'), subtitle: Text(payment.paymentMethod))),
                    Card(child: ListTile(title: const Text('Reference Number'), subtitle: Text(payment.refNo.isEmpty ? '-' : payment.refNo))),
                    Card(child: ListTile(title: const Text('Payment Date'), subtitle: Text(payment.dateCreated))),
                    Card(child: ListTile(title: const Text('Status'), subtitle: Text(payment.status, style: TextStyle(fontWeight: FontWeight.bold, color: payment.status == PaymentModel.statusApproved ? Colors.green : (payment.status == PaymentModel.statusRejected ? Colors.red : Colors.orange))))),
                    if (payment.status == PaymentModel.statusRejected)
                      Card(child: ListTile(title: const Text('Rejection Reason'), subtitle: Text(payment.rejectionReason, style: const TextStyle(color: Colors.red)))),
                    const SizedBox(height: 24),
                    const Text('Receipt Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onViewReceipt,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('VIEW RECEIPT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (payment.status == PaymentModel.statusPending)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity, 
                        child: ElevatedButton.icon(
                          onPressed: () => onUpdateStatus(payment.invoiceNo), 
                          icon: const Icon(Icons.check_circle),
                          label: const Text('APPROVE PAYMENT'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        )
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity, 
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentRejectionForm(invoiceNo: payment.invoiceNo))), 
                          icon: const Icon(Icons.cancel),
                          label: const Text('REJECT PAYMENT'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        )
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
