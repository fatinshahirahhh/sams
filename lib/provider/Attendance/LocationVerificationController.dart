import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/Attendance/LocationModel.dart';
import '../../utils/constants.dart';
import '../../utils/haversine.dart';

/// SAMS-PACK-309 — GPS permission and campus geofence verification.
class LocationVerification extends ChangeNotifier {
  final FirebaseFirestore _db;

  LocationVerification({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  bool _hasPermission = false;
  bool _isOnCampus = false;
  bool _isChecking = false;
  String? _statusMessage;
  LocationModel? _activeLocation;
  double? _currentLatitude;
  double? _currentLongitude;
  double? _lastDistanceMeters;

  bool get hasPermission => _hasPermission;
  bool get isOnCampus => _isOnCampus;
  bool get isChecking => _isChecking;
  String? get statusMessage => _statusMessage;
  LocationModel? get activeLocation => _activeLocation;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  double? get lastDistanceMeters => _lastDistanceMeters;

  Future<bool> checkGPSPermission() async {
    _isChecking = true;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _hasPermission = false;
        _statusMessage = 'Location services are disabled';
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 10));
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        _hasPermission = false;
        _statusMessage = 'Location permission denied';
        return false;
      }

      _hasPermission = true;
      _statusMessage = 'GPS permission granted';
      return true;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<LocationModel?> _loadActiveCampusLocation() async {
    final snapshot = await _db
        .collection(FirestoreCollections.locations)
        .where('is_active', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return LocationModel.fromMap(snapshot.docs.first.data());
  }

  Future<bool> verifyCurrentLocation() async {
    if (_isChecking) return false;
    _isChecking = true;
    _isOnCampus = false;
    notifyListeners();

    try {
      if (!_hasPermission) {
        final granted = await checkGPSPermission();
        if (!granted) return false;
      }

      final campus = await _loadActiveCampusLocation();
      if (campus == null) {
        _statusMessage = 'Service Unavailable: No active campus configuration found.';
        return false;
      }
      _activeLocation = campus;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      _lastDistanceMeters = haversineDistanceMeters(
        lat1: position.latitude,
        lon1: position.longitude,
        lat2: campus.centerLatitude,
        lon2: campus.centerLongitude,
      );

      _isOnCampus = _lastDistanceMeters! <= campus.allowedMeter;
      _statusMessage = _isOnCampus
          ? 'On Campus (Verified) — ${campus.campusName}'
          : 'Outside campus — ${_lastDistanceMeters!.toStringAsFixed(0)}m from ${campus.campusName}';

      return _isOnCampus;
    } catch (e) {
      _statusMessage = 'Location verification failed: $e';
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}
