import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/Authentication/AuthController.dart';
import '../../domain/Attendance/ClassSessionModel.dart';
import '../../provider/Attendance/AttendanceController.dart';
import '../../provider/Attendance/ClassCodeController.dart';
import '../../provider/Attendance/LocationVerificationController.dart';
import '../../theme/sams_theme.dart';

/// SAMS-PACK-310 — "Manage Attendance" UI based on the provided screenshot with integrated toggles.
class LectureAttendancePage extends StatefulWidget {
  const LectureAttendancePage({super.key});

  @override
  State<LectureAttendancePage> createState() => _LectureAttendancePageState();
}

class _LectureAttendancePageState extends State<LectureAttendancePage> {
  ClassSessionModel? _selectedSession;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPage());
  }

  Future<void> _initPage() async {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;
    final staffId = user.userId;

    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args is ClassSessionModel) {
      _selectedSession = args;
    } else if (args is Map<String, dynamic>) {
      _selectedSession = ClassSessionModel(
        classSessionId: 'SESSION_${args['subjectCode']}',
        staffId: staffId,
        subjectCode: args['subjectCode'] ?? 'BCS3133',
        subjectName: args['subjectName'] ?? 'Software Engineering Practices',
        classSection: '01',
        classDate: '2024-05-20',
        startTime: '10:00 AM',
        endTime: '12:00 PM',
        sessionStatus: 'Closed',
      );
    }

    if (_selectedSession == null) {
      _selectedSession = ClassSessionModel(
        classSessionId: 'SESS001',
        staffId: staffId,
        subjectCode: 'BCS3133',
        subjectName: 'Software Engineering Practices',
        classSection: '01',
        classDate: '2024-05-20',
        startTime: '10:00 AM',
        endTime: '12:00 PM',
        sessionStatus: 'Closed',
      );
    }

    final controller = context.read<ClassCodeController>();
    await controller.fetchActiveCode(_selectedSession!.classSessionId);

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final codeController = context.watch<ClassCodeController>();
    final activeCode = codeController.activeCode;
    final isOpen = codeController.sessionStatus == 'Open';
    final session = _selectedSession!;

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
              child: Column(
                children: [
                  // SUBJECT CARD
                  Padding(
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
                  
                  const SizedBox(height: 12),
                  
                  // QUICK TOGGLES (Moved here for better visibility)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _miniToggle(
                          label: 'REQUIRE LOCATION',
                          value: codeController.requiresLocation,
                          onChanged: (_) => context.read<ClassCodeController>().toggleLocationRequirement(session.classSessionId),
                        ),
                        const SizedBox(width: 12),
                        _miniToggle(
                          label: 'SESSION STATUS',
                          value: isOpen,
                          activeColor: SamsColors.success,
                          onChanged: (_) async {
                            final loc = context.read<LocationVerification>();
                            double? lat, lng;
                            if (!isOpen) { // If opening
                              await loc.checkGPSPermission();
                              await loc.verifyCurrentLocation();
                              lat = loc.currentLatitude;
                              lng = loc.currentLongitude;
                            }
                            if (mounted) {
                              context.read<ClassCodeController>().toggleSessionStatus(session.classSessionId, lat: lat, lng: lng);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Attendance Code Section
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
                padding: const EdgeInsets.symmetric(vertical: 24),
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
            const SizedBox(height: 24),
            // Actions
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
                child: const Text('Regenerate', style: TextStyle(fontSize: 16, color: Colors.black54)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  side: const BorderSide(color: Colors.grey, width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _miniToggle({required String label, required bool value, required ValueChanged<bool> onChanged, Color? activeColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(value ? 'YES' : 'NO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: value ? (activeColor ?? SamsColors.teal) : Colors.red)),
              ],
            ),
            const Spacer(),
            Transform.scale(
              scale: 0.7,
              child: CupertinoSwitch(
                value: value,
                activeTrackColor: activeColor ?? SamsColors.teal,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
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
