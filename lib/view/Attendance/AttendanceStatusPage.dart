import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../provider/Attendance/LocationVerificationController.dart';

/// SAMS-PACK-317 — Result feedback illustration screen matching the success screenshot.
class AttendanceStatusPage extends StatelessWidget {
  const AttendanceStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String status = 'unknown';
    String subjectCode = 'Subject';

    if (args is String) {
      status = args;
    } else if (args is Map<String, dynamic>) {
      status = args['status'] ?? 'unknown';
      subjectCode = args['subjectCode'] ?? 'Subject';
    }

    final isSuccess = status == 'success' || status == 'duplicate';
    final isGpsError = status == 'gps_denied';
    final isLocationError = status == 'outside_campus';
    final isInvalidCode = status == 'invalid_code';

    return Scaffold(
      backgroundColor: const Color(0xFF8A9A9A).withValues(alpha: 0.6), // Dimmed background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Container
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: (isGpsError || isLocationError)
                            ? LinearGradient(
                                colors: isLocationError
                                    ? [const Color(0xFFFF2D55), const Color(0xFFFF3B30)]
                                    : [const Color(0xFFFF5252), const Color(0xFFFF8A00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: (!isGpsError && !isLocationError)
                            ? (isSuccess ? const Color(0xFF00BFA5) : const Color(0xFFFF2D55))
                            : null,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocationError
                            ? Icons.location_on
                            : (isGpsError
                                ? Icons.warning_amber_rounded
                                : (isInvalidCode || !isSuccess ? Icons.close : Icons.check)),
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    if (isLocationError)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cancel,
                          color: Color(0xFFFF2D55),
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  isInvalidCode
                      ? 'Invalid Code'
                      : (isLocationError
                          ? 'Location Error'
                          : (isGpsError
                              ? 'Permission Required'
                              : (isSuccess ? 'Success!' : _getErrorTitle(status)))),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Badge
                if (isSuccess || isGpsError || isLocationError || isInvalidCode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? const Color(0xFFD1F2EB)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                      border: (isGpsError || isLocationError || isInvalidCode)
                          ? Border.all(color: const Color(0xFFFFCDD2))
                          : null,
                    ),
                    child: Text(
                      isSuccess
                          ? 'ATTENDANCE RECORDED'
                          : (isInvalidCode
                              ? 'VERIFICATION FAILED'
                              : (isLocationError ? 'NOT ON CAMPUS' : 'GPS ACCESS NEEDED')),
                      style: TextStyle(
                        color: isSuccess ? const Color(0xFF00897B) : const Color(0xFFD32F2F),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Message
                if (isSuccess)
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 15,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'Your attendance for '),
                        TextSpan(
                          text: subjectCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const TextSpan(text: ' has\nbeen recorded as '),
                        const TextSpan(
                          text: 'Present',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00BFA5),
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  )
                else
                  Text(
                    isInvalidCode
                        ? 'The class code you entered is incorrect or has expired. Please try again.'
                        : (isLocationError
                            ? 'Check-in failed. You must be physically on the UMPSA campus to record your attendance.'
                            : (isGpsError
                                ? 'Location access is required to check in. Please enable GPS in your device settings.'
                                : _getErrorMessage(status))),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: (isGpsError || isLocationError)
                          ? LinearGradient(
                              colors: isLocationError
                                  ? [const Color(0xFFFF2D55), const Color(0xFFFF3B30)]
                                  : [const Color(0xFFFF5252), const Color(0xFFFF8A00)],
                            )
                          : null,
                      color: isInvalidCode ? const Color(0xFFFF2D55) : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: FilledButton(
                      onPressed: () async {
                        if (isGpsError) {
                          final loc = context.read<LocationVerification>();
                          await loc.checkGPSPermission();
                          if (!loc.hasPermission) {
                            await Geolocator.openAppSettings();
                          }
                        } else if (isSuccess) {
                          Navigator.popUntil(
                            context,
                            ModalRoute.withName('/student/check-in'),
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: (isGpsError || isLocationError || isInvalidCode)
                            ? Colors.transparent
                            : const Color(0xFF00897B),
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isInvalidCode
                            ? 'Retry'
                            : (isLocationError
                                ? 'Close'
                                : (isGpsError ? 'Go to Settings' : (isSuccess ? 'Done' : 'Back'))),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorTitle(String status) {
    switch (status) {
      case 'gps_denied': return 'GPS Error';
      case 'outside_campus': return 'Location Alert';
      case 'invalid_code': return 'Invalid Code';
      case 'db_error': return 'System Error';
      default: return 'Oops!';
    }
  }

  String _getErrorMessage(String status) {
    switch (status) {
      case 'gps_denied': return 'Please enable GPS to check in.';
      case 'outside_campus': return 'You must be on campus to submit attendance.';
      case 'invalid_code': return 'The code is incorrect or expired.';
      case 'db_error': return 'Database connection failed.';
      default: return 'Something went wrong. Please try again.';
    }
  }
}
