import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../../provider/Authentication/AuthController.dart';
import '../../domain/Attendance/AttendanceRecordModel.dart';
import '../../provider/Attendance/AttendanceController.dart';
import '../../theme/sams_theme.dart';
import 'AttendanceDetail.dart';

/// SAMS-PACK-314 — Chronological attendance history cards.
class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  List<AttendanceRecordModel> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final studentId = user.userId;

    try {
      final records = await context
          .read<AttendanceController>()
          .fetchStudentHistory(studentId);

      if (mounted) {
        setState(() {
          _records = records;
        });
      }
    } catch (e) {
      debugPrint('_loadHistory error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = intl.DateFormat('dd MMM yyyy • HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: SamsColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Attendance History', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: Column(
                children: [
                   Container(
                    height: 20,
                    decoration: const BoxDecoration(
                      color: SamsColors.teal,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _records.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text('No attendance records found')),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _records.length,
                            itemBuilder: (context, index) {
                              final record = _records[index];
                              final isPresent = record.attendanceStatus == 'Present';
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isPresent ? const Color(0xFFE0F2F1) : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      isPresent ? Icons.check_circle_outline : Icons.error_outline,
                                      color: isPresent ? SamsColors.teal : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    _formatSubject(record.classSessionId),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: SamsColors.tealDark),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(dateFormat.format(record.checkInTime), style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => AttendanceDetailPage(record: record),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatSubject(String sessionId) {
    if (sessionId.startsWith('SESSION_')) {
      return sessionId.replaceFirst('SESSION_', '');
    }
    return sessionId;
  }
}
