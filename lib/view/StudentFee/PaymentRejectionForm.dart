import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/domain/StudentFee/Payment/PaymentModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/view/Authentication/AuthRouteGuard.dart';
import 'package:sams/view/Authentication/LoginPage.dart';
import 'package:sams/view/StudentFee/PaymentManagement.dart';

/// Treasury page to enter rejection reason before rejecting a payment.
class PaymentRejectionForm extends StatelessWidget {
  final String invoiceNo;

  const PaymentRejectionForm({super.key, required this.invoiceNo});

  @override
  Widget build(BuildContext context) {
    return AuthRouteGuard(
      allowedRoles: [UserModel.roleTreasury],
      child: _PaymentRejectionFormView(invoiceNo: invoiceNo),
    );
  }
}

class _PaymentRejectionFormView extends StatefulWidget {
  final String invoiceNo;

  const _PaymentRejectionFormView({required this.invoiceNo});

  @override
  State<_PaymentRejectionFormView> createState() => _PaymentRejectionFormViewState();
}

class _PaymentRejectionFormViewState extends State<_PaymentRejectionFormView> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PaymentController>().getDetails(widget.invoiceNo);
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Save rejection with reason via PaymentController.
  Future<void> onConfirmReject(String invoiceNo) async {
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      setState(() {
        _validationError = 'Please provide a reason for the rejection.';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    final auth = context.read<AuthController>();
    final verifierId = auth.currentUser?.userId ?? 'Unknown';
    final controller = context.read<PaymentController>();
    await controller.updateStatus(invoiceNo, PaymentModel.statusRejected, reason, verifierId);

    if (controller.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment rejected successfully.')),
    );

    // Go back to the Payment Management list
    if (mounted) {
      Navigator.of(context).pop(); // Pops RejectionForm
      Navigator.of(context).pop(); // Pops PaymentVerification
    }
  }

  /// Close form without rejecting.
  void onCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentController>(
      builder: (context, controller, _) {
        final payment = controller.payment;

        return Scaffold(
          backgroundColor: const Color(0xFFF6FAF6),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0C855E),
            foregroundColor: Colors.white,
            title: const Text('Reject Payment'),
          ),
          body: payment == null || payment.invoiceNo != widget.invoiceNo
              ? Center(
                  child: Text(
                    controller.errorMessage ?? 'Payment not found.',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // --- Payment short summary ---
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Summary',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _SummaryRow(
                                label: 'Invoice Number',
                                value: payment.invoiceNo,
                              ),
                              _SummaryRow(
                                label: 'Student ID',
                                value: payment.studentId,
                              ),
                              _SummaryRow(
                                label: 'Amount',
                                value:
                                    'RM ${payment.amount.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Rejection reason text area ---
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Rejection Reason',
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                          errorText: _validationError,
                        ),
                        onChanged: (_) {
                          if (_validationError != null) {
                            setState(() {
                              _validationError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => onConfirmReject(widget.invoiceNo),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Confirm Reject'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onCancel,
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
