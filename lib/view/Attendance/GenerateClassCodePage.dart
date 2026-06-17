import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/Attendance/ClassSessionModel.dart';
import '../../provider/Attendance/ClassCodeController.dart';
import '../../provider/Attendance/AttendanceController.dart';
import '../../theme/sams_theme.dart';

/// SAMS-PACK-311 — Redesigned "Manage Attendance" UI based on the provided screenshot.
class GenerateClassCodePage extends StatefulWidget {
  const GenerateClassCodePage({super.key});

  @override
  State<GenerateClassCodePage> createState() => _GenerateClassCodePageState();
}

class _GenerateClassCodePageState extends State<GenerateClassCodePage> {
  ClassSessionModel? get _session {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ClassSessionModel) return args;
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCode());
  }

  Future<void> _initCode() async {
    final session = _session;
    if (session == null) return;

    final controller = context.read<ClassCodeController>();
    await controller.fetchActiveCode(session.classSessionId);

    if (mounted) {
      context
          .read<AttendanceController>()
          .listenToSessionAttendance(session.classSessionId);
    }
  }

  @override
  void dispose() {
    context.read<AttendanceController>().stopListeningToSessionAttendance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final codeController = context.watch<ClassCodeController>();
    final activeCode = codeController.activeCode;
    final isOpen = codeController.sessionStatus == 'Open';
    final session = _session;

    if (session == null) {
      return const Scaffold(body: Center(child: Text('No session selected')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: SamsColors.teal,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text('U', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 40,
              decoration: const BoxDecoration(
                color: SamsColors.teal,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: SamsColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.book_outlined, color: SamsColors.gold),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Subject', style: TextStyle(color: SamsColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('${session.subjectCode} ${session.subjectName}', style: const TextStyle(color: SamsColors.tealDark, fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _infoItem(Icons.calendar_today_outlined, 'Session', 'Lecture - Sec ${session.classSection}'),
                          const SizedBox(width: 16),
                          _infoItem(Icons.access_time, 'Time', session.startTime),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: SamsColors.gold),
                const SizedBox(width: 8),
                Text('Attendance Code', style: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FAF8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: SamsColors.teal.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Center(
                  child: _buildCodeDisplay(activeCode?.classCode),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FilledButton.icon(
                onPressed: () => context.read<ClassCodeController>().generateClassCode(session.classSessionId, session.staffId),
                icon: const Icon(Icons.flash_on, size: 20),
                label: const Text('Generate Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: SamsColors.teal,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/lecturer/attendance-records',
                    arguments: session,
                  );
                },
                icon: const Icon(Icons.people, size: 20),
                label: const Text('Live Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: SamsColors.gold,
                  foregroundColor: SamsColors.tealDark,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton(
                onPressed: activeCode == null ? null : () => context.read<ClassCodeController>().regenerateClassCode(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  side: const BorderSide(color: Colors.grey, width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Regenerate', style: TextStyle(fontSize: 16, color: Colors.black54)),
              ),
            ),
            const SizedBox(height: 32),
            // Location Requirement Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Text('Require Location', style: TextStyle(color: SamsColors.tealDark, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(codeController.requiresLocation ? 'YES' : 'NO', style: TextStyle(color: codeController.requiresLocation ? SamsColors.success : SamsColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 12),
                    CupertinoSwitch(
                      value: codeController.requiresLocation,
                      activeTrackColor: SamsColors.success,
                      onChanged: (_) => context.read<ClassCodeController>().toggleLocationRequirement(session.classSessionId),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Session Status Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Text('Session Status', style: TextStyle(color: SamsColors.tealDark, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(isOpen ? 'OPEN' : 'CLOSED', style: TextStyle(color: isOpen ? SamsColors.success : SamsColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 12),
                    CupertinoSwitch(
                      value: isOpen,
                      activeTrackColor: SamsColors.success,
                      onChanged: (_) => context.read<ClassCodeController>().toggleSessionStatus(session.classSessionId),
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

  Widget _infoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: SamsColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: SamsColors.teal, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(color: SamsColors.tealDark, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeDisplay(String? code) {
    if (code == null || code.isEmpty) {
      return const Text('———', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: SamsColors.teal, letterSpacing: 4));
    }
    final top = code.length >= 3 ? code.substring(0, 3) : code;
    final bottom = code.length > 3 ? code.substring(3) : '';
    return Column(
      children: [
        Text('${top.split('').join(' ')} -', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: SamsColors.teal, height: 1.1)),
        if (bottom.isNotEmpty)
          Text(bottom.split('').join(' '), style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: SamsColors.teal, height: 1.1)),
      ],
    );
  }
}
