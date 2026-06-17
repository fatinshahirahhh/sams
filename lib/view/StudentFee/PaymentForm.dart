import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/view/Authentication/AuthRouteGuard.dart';
import 'package:sams/view/StudentFee/PaymentHistory.dart';

class PaymentForm extends StatelessWidget {
  const PaymentForm({super.key});
  @override
  Widget build(BuildContext context) {
    return const AuthRouteGuard(
      allowedRoles: [UserModel.roleStudent],
      child: _PaymentFormView(),
    );
  }
}

class _PaymentFormView extends StatefulWidget {
  const _PaymentFormView();
  @override
  State<_PaymentFormView> createState() => _PaymentFormViewState();
}

class _PaymentFormViewState extends State<_PaymentFormView> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _receiptController = TextEditingController();

  String _invoiceNo = '';
  String _amount = '';
  String _paymentMethod = PaymentController.supportedPaymentMethods.first;
  String _refNo = '';
  String _paymentDate = '';
  File? _selectedFile;

  @override
  void dispose() {
    _dateController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final studentId = auth.currentUser?.userId ?? '';
      if (studentId.isNotEmpty) context.read<PaymentController>().fetchFeeDetails(studentId);
    });
  }

  Future<void> onSelectedDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _paymentDate = formatted;
        _dateController.text = formatted;
      });
    }
  }

  Future<void> onUploadReceipt() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'pdf', 'png']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _receiptController.text = result.files.single.name;
      });
    }
  }

  Future<void> submitPayment() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a receipt.')));
        return;
      }

      final controller = context.read<PaymentController>();
      
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final base64String = await controller.fileToBase64(_selectedFile!);
      Navigator.pop(context);

      if (base64String == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage ?? 'File error.')));
        return;
      }

      await controller.createPaymentRecord(_invoiceNo, double.parse(_amount), _refNo, _paymentMethod, _paymentDate, base64String);

      if (controller.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment submitted!')));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PaymentHistory()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF0C855E), foregroundColor: Colors.white, title: const Text('Submit Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(decoration: const InputDecoration(labelText: 'Invoice Number', border: OutlineInputBorder()), onChanged: (v) => _invoiceNo = v),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: 'Amount', prefixText: 'RM ', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => _amount = v),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                items: PaymentController.supportedPaymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: 'Reference Number', border: OutlineInputBorder()), onChanged: (v) => _refNo = v),
              const SizedBox(height: 16),
              TextFormField(controller: _dateController, readOnly: true, decoration: const InputDecoration(labelText: 'Payment Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), onTap: onSelectedDate),
              const SizedBox(height: 16),
              TextFormField(controller: _receiptController, readOnly: true, decoration: const InputDecoration(labelText: 'Receipt', border: OutlineInputBorder(), hintText: 'Select file')),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: onUploadReceipt, icon: const Icon(Icons.upload_file), label: const Text('Upload Receipt')),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: submitPayment, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C855E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Submit Payment'))),
            ],
          ),
        ),
      ),
    );
  }
}
