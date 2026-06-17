import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sams/firebase_options.dart';
import 'package:sams/provider/Authentication/AuthController.dart';
import 'package:sams/provider/Authentication/LoginController.dart';
import 'package:sams/provider/Authentication/RegisterController.dart';
import 'package:sams/provider/StudentFee/PaymentController.dart';
import 'package:sams/provider/Attendance/AttendanceController.dart';
import 'package:sams/provider/Attendance/ClassCodeController.dart';
import 'package:sams/provider/Attendance/LocationVerificationController.dart';
import 'package:sams/view/DashboardPage.dart';
import 'package:sams/view/Attendance/LectureAttendancePage.dart';
import 'package:sams/view/Attendance/GenerateClassCodePage.dart';
import 'package:sams/view/Attendance/AttendanceRecordPage.dart';
import 'package:sams/view/Attendance/GPSPermissionPage.dart';
import 'package:sams/view/Attendance/StudentCheckInPage.dart';
import 'package:sams/view/Attendance/AttendanceStatusPage.dart';
import 'package:sams/view/Attendance/AttendanceHistoryPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SamsApp());
}

class SamsApp extends StatelessWidget {
  const SamsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProxyProvider<AuthController, LoginController>(
          create: (context) => LoginController(context.read<AuthController>()),
          update: (context, auth, login) => login!..authController = auth,
        ),
        ChangeNotifierProxyProvider<AuthController, RegisterController>(
          create: (context) => RegisterController(context.read<AuthController>()),
          update: (context, auth, register) => register!..authController = auth,
        ),
        ChangeNotifierProvider(create: (_) => PaymentController()),
        ChangeNotifierProvider(create: (_) => LocationVerification()),
        ChangeNotifierProvider(create: (_) => ClassCodeController()),
        ChangeNotifierProxyProvider2<LocationVerification, ClassCodeController, AttendanceController>(
          create: (context) => AttendanceController(
            locationVerification: context.read<LocationVerification>(),
            classCodeController: context.read<ClassCodeController>(),
          ),
          update: (context, loc, code, attendance) => attendance!,
        ),
      ],
      child: MaterialApp(
        title: 'SAMS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routes: {
          '/': (context) => const DashboardPage(),
          '/lecturer/sessions': (context) => const LectureAttendancePage(),
          '/lecturer/generate-code': (context) => const GenerateClassCodePage(),
          '/lecturer/attendance-records': (context) => const AttendanceRecordPage(),
          '/student/gps-permission': (context) => const GPSPermissionPage(),
          '/student/check-in': (context) => const StudentCheckInPage(),
          '/student/attendance-status': (context) => const AttendanceStatusPage(),
          '/student/attendance-history': (context) => const AttendanceHistoryPage(),
        },
      ),
    );
  }
}
