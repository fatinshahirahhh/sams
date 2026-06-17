import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/domain/StudentFee/Payment/PaymentModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/view/Authentication/AuthRouteGuard.dart';
import 'package:sams/view/Authentication/LoginPage.dart';
import 'package:sams/view/StudentFee/PaymentVerification.dart';

/// Main Treasury page to view all student payment records.
class PaymentManagement extends StatelessWidget {
  const PaymentManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthRouteGuard(
      allowedRoles: [UserModel.roleTreasury],
      child: _PaymentManagementView(),
    );
  }
}

class _PaymentManagementView extends StatefulWidget {
  const _PaymentManagementView();

  @override
  State<_PaymentManagementView> createState() => _PaymentManagementViewState();
}

class _PaymentManagementViewState extends State<_PaymentManagementView> {
  String _statusFilter = 'All';
  List<PaymentModel> _allPayments = [];

  static const List<String> _filterOptions = [
    'All',
    PaymentModel.statusPending,
    PaymentModel.statusApproved,
    PaymentModel.statusRejected,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPayments();
    });
  }

  Future<void> _loadPayments() async {
    final payments = await context.read<PaymentController>().getAllPayments();
    if (mounted) {
      setState(() {
        _allPayments = payments;
      });
    }
  }

  void onSelectPayment(String invoiceNo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentVerification(invoiceNo: invoiceNo)),
    ).then((_) => _loadPayments());
  }

  List<PaymentModel> getFilteredList() {
    if (_statusFilter == 'All') return _allPayments;
    return _allPayments.where((payment) => payment.status == _statusFilter).toList();
  }

  void _handleLogout() {
    context.read<AuthController>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = getFilteredList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C855E),
        foregroundColor: Colors.white,
        title: const Text('Payment Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _statusFilter,
              decoration: const InputDecoration(labelText: 'Filter Status', border: OutlineInputBorder()),
              items: _filterOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _statusFilter = val);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadPayments(),
              child: filtered.isEmpty
                  ? const Center(child: Text('No payments found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        return Card(
                          child: ListTile(
                            onTap: () => onSelectPayment(p.invoiceNo),
                            title: Text(p.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('ID: ${p.studentId} | RM ${p.amount.toStringAsFixed(2)}'),
                            trailing: _StatusBadge(status: p.status),
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
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
