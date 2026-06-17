import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams/domain/Authentication/UserModel.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/view/Authentication/LoginPage.dart';
import 'package:sams/view/StudentFee/PaymentManagement.dart';
import 'package:sams/view/StudentFee/StudentFeePage.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showAttendance = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = user.role;
    final isStudent = role == UserModel.roleStudent;
    final isTreasury = role == UserModel.roleTreasury;
    final isLecturer = role == UserModel.roleLecturer;
    final isPusatAdab = role == UserModel.rolePusatAdab;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SAMS Dashboard'),
        backgroundColor: const Color(0xFF0C855E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isTreasury)
            IconButton(
              icon: const Icon(Icons.cloud_upload),
              tooltip: 'Sync Sample Data',
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Syncing sample data...')),
                );
                final success = await context.read<PaymentController>().uploadDataToFirestore();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Data synced!' : 'Sync failed.')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthController>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF7F1E9),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(username: user.username, roleLabel: role),
                const SizedBox(height: 24),
                const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Student Actions
                if (isStudent) ...[
                  _ActionCard(
                    title: 'Student Fee Page',
                    subtitle: 'View fees and payment status.',
                    icon: Icons.receipt_long,
                    backgroundColor: const Color(0xFF0C855E),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentFeePage())),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Class Check-In',
                    subtitle: 'Submit attendance for your session.',
                    icon: Icons.qr_code_scanner,
                    backgroundColor: const Color(0xFF0C855E),
                    onTap: () => Navigator.pushNamed(context, '/student/check-in'),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    title: 'Attendance History',
                    subtitle: 'View your past attendance records.',
                    icon: Icons.history,
                    backgroundColor: const Color(0xFF0C855E),
                    onTap: () => Navigator.pushNamed(context, '/student/attendance-history'),
                  ),
                ],

                // Treasury Actions
                if (isTreasury)
                  _ActionCard(
                    title: 'Payment Management',
                    subtitle: 'Review student payments.',
                    icon: Icons.payments,
                    backgroundColor: const Color(0xFF0C855E),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentManagement())),
                  ),

                // Lecturer Actions
                if (isLecturer) ...[
                  _ActionCard(
                    title: 'Attendance',
                    subtitle: 'Manage your class sessions.',
                    icon: Icons.calendar_month,
                    backgroundColor: const Color(0xFF0C855E),
                    onTap: () {
                      setState(() {
                        _showAttendance = !_showAttendance;
                      });
                    },
                  ),
                  if (_showAttendance) ...[
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text('My Class Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ),
                    _ActionCard(
                      title: 'BCS3133',
                      subtitle: 'Software Engineering Practices',
                      icon: Icons.code,
                      backgroundColor: const Color(0xFF0C855E),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/lecturer/sessions',
                        arguments: {
                          'subjectCode': 'BCS3133',
                          'subjectName': 'Software Engineering Practices'
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      title: 'BCS3143',
                      subtitle: 'Software Project Management',
                      icon: Icons.assignment,
                      backgroundColor: const Color(0xFF0C855E),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/lecturer/sessions',
                        arguments: {
                          'subjectCode': 'BCS3143',
                          'subjectName': 'Software Project Management'
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      title: 'BCS3233',
                      subtitle: 'Software Testing',
                      icon: Icons.bug_report,
                      backgroundColor: const Color(0xFF0C855E),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/lecturer/sessions',
                        arguments: {
                          'subjectCode': 'BCS3233',
                          'subjectName': 'Software Testing'
                        },
                      ),
                    ),
                  ],
                ],

                // Pusat Adab Actions
                if (isPusatAdab) ...[
                  _ActionCard(
                    title: 'Student Moral Records',
                    subtitle: 'Manage and review student conduct.',
                    icon: Icons.gavel,
                    backgroundColor: const Color(0xFF0C855E),
                    onTap: () {},
                  ),
                ],

                // Fallback for empty actions
                if (!isStudent && !isTreasury && !isLecturer && !isPusatAdab)
                   Center(
                     child: Padding(
                       padding: const EdgeInsets.only(top: 40),
                       child: Text('No actions available for role: $role'),
                     ),
                   ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String username;
  final String roleLabel;
  const _DashboardHeader({required this.username, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF0C855E), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFF0C855E), size: 34)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(username, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(roleLabel, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;
  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.backgroundColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade300)),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(color: backgroundColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.all(14),
                child: Icon(icon, color: backgroundColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
