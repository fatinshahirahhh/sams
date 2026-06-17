import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/domain/StudentFee/Payment/PaymentModel.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/view/Authentication/AuthRouteGuard.dart';

class PaymentDetail extends StatelessWidget {
  final String invoiceNo;
  const PaymentDetail({super.key, required this.invoiceNo});
  @override
  Widget build(BuildContext context) {
    return AuthRouteGuard(allowedRoles: [UserModel.roleStudent], child: _PaymentDetailView(invoiceNo: invoiceNo));
  }
}

class _PaymentDetailView extends StatefulWidget {
  final String invoiceNo;
  const _PaymentDetailView({required this.invoiceNo});
  @override
  State<_PaymentDetailView> createState() => _PaymentDetailViewState();
}

class _PaymentDetailViewState extends State<_PaymentDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PaymentController>().getDetails(widget.invoiceNo));
  }

  Future<void> onDownloadReceipt() async {
    final controller = context.read<PaymentController>();
    final payment = controller.payment;
    if (payment != null && payment.receiptUpload.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await controller.saveAndOpenFile(payment.receiptUpload, 'receipt_${payment.invoiceNo}');
      
      if (mounted) Navigator.pop(context);

      if (controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage!),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentController>(
      builder: (context, controller, _) {
        final payment = controller.payment;
        if (payment == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        return Scaffold(
          appBar: AppBar(backgroundColor: const Color(0xFF0C855E), foregroundColor: Colors.white, title: const Text('Payment Details')),
          body: ListView(
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
              ElevatedButton.icon(
                onPressed: onDownloadReceipt, 
                icon: const Icon(Icons.picture_as_pdf), 
                label: const Text('VIEW RECEIPT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
