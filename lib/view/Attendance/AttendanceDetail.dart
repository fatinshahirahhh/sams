import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../domain/Attendance/AttendanceRecordModel.dart';
import '../../theme/sams_theme.dart';

/// SAMS-PACK-315 — Single attendance record metadata detail.
class AttendanceDetailPage extends StatelessWidget {
  const AttendanceDetailPage({super.key, required this.record});

  final AttendanceRecordModel record;

  @override
  Widget build(BuildContext context) {
    final dateFormat = intl.DateFormat('EEEE, dd MMMM yyyy');
    final timeFormat = intl.DateFormat('HH:mm:ss');

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Detail')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: SamsColors.teal,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    record.attendanceStatus == 'Present'
                        ? Icons.verified
                        : Icons.pending,
                    size: 48,
                    color: SamsColors.gold,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record.attendanceStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DetailTile(
            icon: Icons.tag,
            label: 'Attendance ID',
            value: record.attendanceId,
          ),
          _DetailTile(
            icon: Icons.class_,
            label: 'Class Session',
            value: record.classSessionId,
          ),
          _DetailTile(
            icon: Icons.pin,
            label: 'Code ID',
            value: record.codeId,
          ),
          _DetailTile(
            icon: Icons.person,
            label: 'Student ID',
            value: record.studentId,
          ),
          _DetailTile(
            icon: Icons.place,
            label: 'Location ID',
            value: record.locationId,
          ),
          _DetailTile(
            icon: Icons.calendar_today,
            label: 'Date',
            value: dateFormat.format(record.checkInTime),
          ),
          _DetailTile(
            icon: Icons.access_time,
            label: 'Check-in Time',
            value: timeFormat.format(record.checkInTime),
          ),
          _DetailTile(
            icon: Icons.my_location,
            label: 'Coordinates',
            value:
                '${record.latitude.toStringAsFixed(6)}, ${record.longitude.toStringAsFixed(6)}',
          ),
          if (record.remarks.isNotEmpty)
            _DetailTile(
              icon: Icons.notes,
              label: 'Remarks',
              value: record.remarks,
            ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: SamsColors.teal),
        title: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: SamsColors.tealDark,
          ),
        ),
      ),
    );
  }
}
