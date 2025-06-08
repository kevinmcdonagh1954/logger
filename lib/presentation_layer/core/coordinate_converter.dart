import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utility class for converting between different coordinate systems
class CoordinateConverter {
  /// Convert from local coordinates to WGS84 (latitude, longitude)
  /// This handles different coordinate formats (YXZ, ENZ, MPC)
  static LatLng localToWgs84(double y, double x, {String format = 'YXZ'}) {
    // For now, we'll assume the coordinates are already in WGS84
    // and just handle the coordinate order based on the format
    switch (format) {
      case 'YXZ':
        // Y is latitude, X is longitude
        return LatLng(y, x);
      case 'ENZ':
        // E is longitude, N is latitude
        return LatLng(x, y);
      case 'MPC':
        // M is longitude, P is latitude
        return LatLng(x, y);
      default:
        // Default to YXZ format
        return LatLng(y, x);
    }
  }

  /// Convert from WGS84 (latitude, longitude) to local coordinates
  static Map<String, double> wgs84ToLocal(double latitude, double longitude, {String format = 'YXZ'}) {
    switch (format) {
      case 'YXZ':
        return {
          'Y': latitude,
          'X': longitude,
        };
      case 'ENZ':
        return {
          'E': longitude,
          'N': latitude,
        };
      case 'MPC':
        return {
          'M': longitude,
          'P': latitude,
        };
      default:
        return {
          'Y': latitude,
          'X': longitude,
        };
    }
  }

  /// Check if coordinates are valid for the given coordinate system
  static bool isValidCoordinates(double y, double x, {String format = 'YXZ'}) {
    // For WGS84:
    // Latitude: -90 to 90
    // Longitude: -180 to 180
    
    // Determine which value represents latitude and which represents longitude
    // based on the coordinate format
    final (double lat, double lon) = switch (format) {
      'YXZ' => (y, x),
      'ENZ' => (x, y),
      'MPC' => (x, y),
      _ => (y, x),
    };

    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }

  /// Format coordinates for display in the specified format
  static String formatCoordinates(double y, double x, double z, String format) {
    switch (format) {
      case 'YXZ':
        return 'Y: ${y.toStringAsFixed(6)}, X: ${x.toStringAsFixed(6)}, Z: ${z.toStringAsFixed(3)}';
      case 'ENZ':
        return 'E: ${y.toStringAsFixed(6)}, N: ${x.toStringAsFixed(6)}, Z: ${z.toStringAsFixed(3)}';
      case 'MPC':
        return 'M: ${y.toStringAsFixed(6)}, P: ${x.toStringAsFixed(6)}, C: ${z.toStringAsFixed(3)}';
      default:
        return 'Y: ${y.toStringAsFixed(6)}, X: ${x.toStringAsFixed(6)}, Z: ${z.toStringAsFixed(3)}';
    }
  }
}
