import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/domain/StudentFee/Payment/PaymentModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/view/Authentication/AuthRouteGuard.dart';
import 'package:sams/view/Authentication/LoginPage.dart';
import 'package:sams/view/StudentFee/PaymentDetail.dart';

/// Student page to view all submitted payments.
class PaymentHistory extends StatelessWidget {
  const PaymentHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthRouteGuard(
      allowedRoles: [UserModel.roleStudent],
      child: _PaymentHistoryView(),
    );
  }
}

class _PaymentHistoryView extends StatefulWidget {
  const _PaymentHistoryView();

  @override
  State<_PaymentHistoryView> createState() => _PaymentHistoryViewState();
}

class _PaymentHistoryViewState extends State<_PaymentHistoryView> {
  String _filterText = '';
  List<PaymentModel> _studentPayments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPayments();
    });
  }

  Future<void> _loadPayments() async {
    final auth = context.read<AuthController>();
    final studentId = auth.currentUser?.userId ?? '';
    if (studentId.isNotEmpty) {
      final payments = await context.read<PaymentController>().fetchStudentPayments(studentId);
      if (mounted) {
        setState(() {
          _studentPayments = payments;
        });
      }
    }
  }

  void handleFilterChange(String query) {
    setState(() {
      _filterText = query;
    });
  }

  void onSelectPayment(String invoiceNo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentDetail(invoiceNo: invoiceNo)),
    );
  }

  List<PaymentModel> getFilteredData() {
    if (_filterText.trim().isEmpty) {
      return _studentPayments;
    }
    final query = _filterText.trim().toLowerCase();
    return _studentPayments.where((payment) {
      return payment.invoiceNo.toLowerCase().contains(query) ||
          payment.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = getFilteredData();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C855E),
        foregroundColor: Colors.white,
        title: const Text('Payment History'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Filter by invoice number or status',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: handleFilterChange,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadPayments(),
              child: filtered.isEmpty
                  ? const Center(child: Text('No payment records found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final payment = filtered[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            onTap: () => onSelectPayment(payment.invoiceNo),
                            title: Text(
                              payment.invoiceNo,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Amount: RM ${payment.amount.toStringAsFixed(2)}\nDate: ${payment.dateCreated}'),
                            trailing: _StatusBadge(status: payment.status),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case PaymentModel.statusApproved: color = Colors.green; break;
      case PaymentModel.statusRejected: color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
