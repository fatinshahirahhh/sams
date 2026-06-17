import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/Authentication/AuthController.dart';
import '../../provider/Attendance/AttendanceController.dart';
import '../../provider/Attendance/LocationVerificationController.dart';

/// SAMS-PACK-313 — Student "Class Check-In" UI with exact colors from screenshot.
class StudentCheckInPage extends StatelessWidget {
  const StudentCheckInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StudentCheckInView();
  }
}

class _StudentCheckInView extends StatefulWidget {
  const _StudentCheckInView();

  @override
  State<_StudentCheckInView> createState() => _StudentCheckInViewState();
}

class _StudentCheckInViewState extends State<_StudentCheckInView> {
  final _codeController = TextEditingController();
  Timer? _gpsPollTimer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGps());
  }

  @override
  void dispose() {
    _gpsPollTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _initGps() async {
    final loc = context.read<LocationVerification>();
    if (loc.hasPermission) {
      _isVerifying = true;
      try {
        await loc.verifyCurrentLocation();
      } finally {
        if (mounted) setState(() => _isVerifying = false);
      }
    }

    _gpsPollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false) && !_isVerifying && loc.hasPermission) {
        _isVerifying = true;
        try {
          await loc.verifyCurrentLocation();
        } finally {
          if (mounted) setState(() => _isVerifying = false);
        }
      }
    });
  }

  Future<void> _submitCheckIn() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;
    final studentId = user.userId;

    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final result = await context.read<AttendanceController>().submitAttendance(
          studentId: studentId,
          codeInput: code,
        );

    if (!mounted) return;
    Navigator.pushNamed(context, '/student/attendance-status', arguments: result);
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationVerification>();
    final attendance = context.watch<AttendanceController>();
    final onCampus = location.isOnCampus;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C855E),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Class Check-In',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Teal Banner Header
            Container(
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF0C855E),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
            ),
            const SizedBox(height: 12),
            
            // Mint Location Status Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7F1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFB2DFDB), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C855E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Location Status', style: TextStyle(color: Color(0xFF00796B), fontSize: 12, fontWeight: FontWeight.w500)),
                          Row(
                            children: [
                              Text(
                                onCampus ? 'On Campus (Verified)' : 'Verification Pending',
                                style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Color(0xFF4DB6AC), shape: BoxShape.circle),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.location_on_outlined, color: Color(0xFF0C855E), size: 20),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 120),
            
            // Instruction Labels
            const Text(
              'Enter Attendance Code',
              style: TextStyle(color: Color(0xFF263238), fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Provided by your lecturer',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            
            const SizedBox(height: 24),
            
            // Code Input Box (White with Light Teal Border)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFB2DFDB), width: 2),
                ),
                child: TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Color(0xFF00796B), // Brighter teal for the input text
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 24),
                    hintText: 'X 7 9 - B',
                    hintStyle: TextStyle(color: Colors.black12, letterSpacing: 2),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Submit Button (Solid Teal)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FilledButton.icon(
                onPressed: attendance.isSubmitting ? null : _submitCheckIn,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Submit Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0C855E),
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Quick Tip Card (Yellow)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFF176), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF176).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome_outlined, color: Color(0xFFFBC02D), size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quick Tip', style: TextStyle(color: Color(0xFF795548), fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 4),
                          Text(
                            'Make sure you\'re on campus and GPS is enabled before submitting.',
                            style: TextStyle(color: Color(0xFF8D6E63), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
