/// SAMS-PACK-306 — Campus geofence location entity (Domain layer).
class LocationModel {
  final String locationId;
  final String campusName;
  final double centerLatitude;
  final double centerLongitude;
  final double allowedMeter;
  final bool isActive;

  const LocationModel({
    required this.locationId,
    required this.campusName,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.allowedMeter,
    required this.isActive,
  });

  Map<String, dynamic> toMap() => {
        'location_id': locationId,
        'campus_name': campusName,
        'center_latitude': centerLatitude,
        'center_longitude': centerLongitude,
        'allowed_meter': allowedMeter,
        'is_active': isActive,
      };

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      locationId: map['location_id'] as String? ?? '',
      campusName: map['campus_name'] as String? ?? '',
      centerLatitude: (map['center_latitude'] as num?)?.toDouble() ?? 0.0,
      centerLongitude: (map['center_longitude'] as num?)?.toDouble() ?? 0.0,
      allowedMeter: (map['allowed_meter'] as num?)?.toDouble() ?? 100.0,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
