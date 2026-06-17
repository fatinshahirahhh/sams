import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../provider/Attendance/LocationVerificationController.dart';
import '../../theme/sams_theme.dart';

/// Redesigned GPS permission gate for SAMS Attendance.
class GPSPermissionPage extends StatefulWidget {
  const GPSPermissionPage({super.key});

  @override
  State<GPSPermissionPage> createState() => _GPSPermissionPageState();
}

class _GPSPermissionPageState extends State<GPSPermissionPage> {
  bool _isRequested = false;

  Future<void> _handlePermissionRequest() async {
    setState(() => _isRequested = true);
    final loc = context.read<LocationVerification>();
    
    // 1. Check/Request Permission
    final granted = await loc.checkGPSPermission();

    if (!mounted) return;

    if (granted) {
      // 2. If granted, immediately attempt to verify location
      final success = await loc.verifyCurrentLocation();
      if (mounted) {
        // Navigate to check-in page
        Navigator.pushReplacementNamed(context, '/student/check-in');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationVerification>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: SamsColors.teal,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Location Access',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Teal header decoration
          Container(
            height: 30,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: SamsColors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Visual Icon
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: SamsColors.teal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 80,
                      color: SamsColors.teal,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  const Text(
                    'Enable GPS to Check-In',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: SamsColors.tealDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'To ensure fair attendance, SAMS requires your GPS location to verify that you are physically present on campus during the session.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.blueGrey.shade600,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // Error Message if denied
                  if (_isRequested && !location.hasPermission)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SamsColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SamsColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: SamsColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  location.statusMessage ?? 'Location access is required.',
                                  style: const TextStyle(
                                    color: SamsColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => Geolocator.openAppSettings(),
                                  child: const Text(
                                    'Open Device Settings',
                                    style: TextStyle(
                                      color: SamsColors.error,
                                      decoration: TextDecoration.underline,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),
                  
                  // Action Button
                  FilledButton.icon(
                    onPressed: location.isChecking ? null : _handlePermissionRequest,
                    icon: location.isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.near_me),
                    label: Text(
                      location.hasPermission ? 'Continue' : 'Allow Access',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: SamsColors.teal,
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  
                  if (location.hasPermission)
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/student/check-in'),
                      child: const Text('Already granted? Click here'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
