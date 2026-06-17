import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/domain/StudentFee/Student/StudentModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/view/Authentication/AuthRouteGuard.dart';
import 'package:sams/view/Authentication/LoginPage.dart';
import 'package:sams/view/StudentFee/PaymentForm.dart';
import 'package:sams/view/StudentFee/PaymentHistory.dart';

class StudentFeePage extends StatelessWidget {
  const StudentFeePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthRouteGuard(
      allowedRoles: [UserModel.roleStudent],
      child: _StudentFeeView(),
    );
  }
}

class _StudentFeeView extends StatefulWidget {
  const _StudentFeeView();

  @override
  State<_StudentFeeView> createState() => _StudentFeeViewState();
}

class _StudentFeeViewState extends State<_StudentFeeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthController>();
    final controller = context.read<PaymentController>();
    controller.errorMessage = null; // Reset error state on refresh
    final studentId = auth.currentUser?.userId ?? '';
    if (studentId.isNotEmpty) {
      await controller.fetchFeeDetails(studentId);
    }
  }

  void _handleLogout() {
    context.read<AuthController>().logout();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    
    return Consumer<PaymentController>(
      builder: (context, paymentCtrl, _) {
        if (paymentCtrl.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        // Check for specific error message from the controller
        if (paymentCtrl.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(paymentCtrl.errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            )),
          );
        }

        final student = paymentCtrl.student;
        final fee = paymentCtrl.fee;
        
        final displayName = student?.fullName ?? auth.currentUser?.username ?? 'Student';
        final displayId = student?.studentId ?? auth.currentUser?.userId ?? '-';
        final totalFee = fee?.totalAmount ?? 860.0;
        final paidAmount = fee?.amountPaid ?? 0.0;
        final balance = fee?.balance ?? 860.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F1E9),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0C855E),
            foregroundColor: Colors.white,
            title: const Text('Fee Dashboard'),
            actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout)],
          ),
          body: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: const BoxDecoration(color: Color(0xFF0C855E), borderRadius: BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22))),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Student Name', style: TextStyle(color: Colors.white70)),
                              Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              Text(displayId, style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _Row(label: 'Total Fee', value: 'RM ${totalFee.toStringAsFixed(2)}'),
                              _Row(label: 'Paid Amount', value: 'RM ${paidAmount.toStringAsFixed(2)}'),
                              _Row(label: 'Outstanding Balance', value: 'RM ${balance.toStringAsFixed(2)}', color: Colors.red),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (balance > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFFFECE8), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.red.withOpacity(0.3))),
                      child: const Row(children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFEB5757)),
                        SizedBox(width: 12),
                        Expanded(child: Text('Payment Required\nYour academic access is restricted due to unpaid fees after Week 5. Please make payment immediately.', style: TextStyle(color: Color(0xFFB42318), fontWeight: FontWeight.w600))),
                      ]),
                    ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentForm())),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C855E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Make Payment'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistory())),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0C855E), side: const BorderSide(color: Color(0xFF0C855E)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('View Payment History'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Row({required this.label, required this.value, this.color = Colors.black});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color))]));
  }
}
