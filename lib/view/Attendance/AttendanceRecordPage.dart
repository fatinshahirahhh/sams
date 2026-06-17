import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/Attendance/ClassSessionModel.dart';
import '../../provider/Attendance/AttendanceController.dart';
import '../../provider/Attendance/ClassCodeController.dart';
import '../../provider/Attendance/LocationVerificationController.dart';
import '../../theme/sams_theme.dart';

/// SAMS-PACK-312 — Real-time live check-in list with integrated controls for lecturers.
class AttendanceRecordPage extends StatefulWidget {
  const AttendanceRecordPage({super.key});

  @override
  State<AttendanceRecordPage> createState() => _AttendanceRecordPageState();
}

class _AttendanceRecordPageState extends State<AttendanceRecordPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ModalRoute.of(context)?.settings.arguments;
      if (session is ClassSessionModel) {
        context.read<AttendanceController>().listenToSessionAttendance(session.classSessionId);
        context.read<ClassCodeController>().fetchActiveCode(session.classSessionId);
      }
    });
  }

  @override
  void dispose() {
    context.read<AttendanceController>().stopListeningToSessionAttendance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ModalRoute.of(context)?.settings.arguments as ClassSessionModel?;
    final attendance = context.watch<AttendanceController>();
    final codeController = context.watch<ClassCodeController>();
    
    final records = attendance.sessionRecords;
    final timeFormat = DateFormat('hh:mm a');
    final isOpen = codeController.sessionStatus == 'Open';

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
          'Live Attendance',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Top Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 24),
            decoration: const BoxDecoration(
              color: SamsColors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${records.length}',
                  style: const TextStyle(color: SamsColors.gold, fontSize: 56, fontWeight: FontWeight.w900),
                ),
                const Text('Students Present', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '${session.subjectCode} • Sec ${session.classSection}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // QUICK CONTROLS (Toggles)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _miniToggle(
                  label: 'LOCATION',
                  value: codeController.requiresLocation,
                  onChanged: (_) => codeController.toggleLocationRequirement(session.classSessionId),
                ),
                const SizedBox(width: 12),
                _miniToggle(
                  label: 'SESSION',
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
                      codeController.toggleSessionStatus(session.classSessionId, lat: lat, lng: lng);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          
          // List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text('Check-In List', style: TextStyle(color: SamsColors.tealDark, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                const Icon(Icons.sync, size: 14, color: SamsColors.teal),
                const SizedBox(width: 4),
                const Text('Live Update', style: TextStyle(color: SamsColors.teal, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Waiting for students...', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE0F2F1),
                            child: Text('${index + 1}', style: const TextStyle(color: SamsColors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          title: Text(record.studentId, style: const TextStyle(fontWeight: FontWeight.bold, color: SamsColors.tealDark)),
                          subtitle: Text('At ${timeFormat.format(record.checkInTime)}', style: const TextStyle(fontSize: 11)),
                          trailing: const Icon(Icons.check_circle, color: SamsColors.success, size: 20),
                        ),
                      );
                    },
                  ),
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
                Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(value ? 'ON' : 'OFF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: value ? (activeColor ?? SamsColors.teal) : Colors.red)),
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
}
