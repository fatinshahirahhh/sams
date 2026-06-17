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
    } catch (e) {
      _statusMessage = 'Permission check failed: $e';
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<List<LocationModel>> _loadAllActiveCampusLocations() async {
    final snapshot = await _db
        .collection(FirestoreCollections.locations)
        .where('is_active', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => LocationModel.fromMap(doc.data())).toList();
  }

  Future<bool> verifyCurrentLocation({
    double? targetLat,
    double? targetLon,
    double? targetRadius,
  }) async {
    if (_isChecking) return false;
    _isChecking = true;
    _isOnCampus = false;
    _lastDistanceMeters = null;
    notifyListeners();

    try {
      if (!_hasPermission) {
        final granted = await checkGPSPermission();
        if (!granted) return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      // 1. If a specific target location is provided (e.g. Lecturer's position)
      if (targetLat != null && targetLon != null) {
        final dist = haversineDistanceMeters(
          lat1: position.latitude,
          lon1: position.longitude,
          lat2: targetLat,
          lon2: targetLon,
        );
        
        final radius = targetRadius ?? 100.0;
        if (dist <= radius) {
          _isOnCampus = true;
          _lastDistanceMeters = dist;
          _statusMessage = 'Location Verified: Near Lecturer';
          return true;
        }
      }

      // 2. Fallback to check all active Campus Geofences
      final campuses = await _loadAllActiveCampusLocations();
      if (campuses.isEmpty) {
        _statusMessage = 'Service Unavailable: No active campus configuration found.';
        return false;
      }

      double minDistance = double.infinity;
      LocationModel? closestCampus;

      for (final campus in campuses) {
        final dist = haversineDistanceMeters(
          lat1: position.latitude,
          lon1: position.longitude,
          lat2: campus.centerLatitude,
          lon2: campus.centerLongitude,
        );

        if (dist < minDistance) {
          minDistance = dist;
          closestCampus = campus;
        }

        if (dist <= campus.allowedMeter) {
          _isOnCampus = true;
          _activeLocation = campus;
          _lastDistanceMeters = dist;
          _statusMessage = 'On Campus (Verified) — ${campus.campusName}';
          return true;
        }
      }

      // If not in any campus
      _activeLocation = closestCampus;
      _lastDistanceMeters = minDistance;
      _statusMessage = closestCampus != null
          ? 'Outside campus — ${minDistance.toStringAsFixed(0)}m from ${closestCampus.campusName}'
          : 'Outside defined campus area.';

      return false;
    } catch (e) {
      _statusMessage = 'Location verification failed: $e';
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}
