import 'dart:math' as math;

class GeofenceResult {
  final double distanceMeters;
  final bool isWithinGeofence;
  final double userLat;
  final double userLng;

  GeofenceResult({
    required this.distanceMeters,
    required this.isWithinGeofence,
    required this.userLat,
    required this.userLng,
  });
}

class GeofenceService {
  // Haversine formula to compute great-circle distance between two GPS coordinates in meters
  static double calculateDistanceInMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadius = 6371000.0; // in meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  // Validate geofence compliance against office policy
  static GeofenceResult verifyLocation({
    required double userLat,
    required double userLng,
    required double officeLat,
    required double officeLng,
    required double allowedRadiusMeters,
  }) {
    final distance = calculateDistanceInMeters(
      lat1: userLat,
      lon1: userLng,
      lat2: officeLat,
      lon2: officeLng,
    );

    return GeofenceResult(
      distanceMeters: double.parse(distance.toStringAsFixed(1)),
      isWithinGeofence: distance <= allowedRadiusMeters,
      userLat: userLat,
      userLng: userLng,
    );
  }
}
