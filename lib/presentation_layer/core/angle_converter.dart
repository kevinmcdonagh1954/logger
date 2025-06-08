import 'dart:math' show pi;

/// Utility class for angle conversions
class AngleConverter {
  /// Factor for converting between degrees and grads
  static const double gradsFactor = 1.0; // Default to degrees

  /// Convert decimal degrees to DMS format
  static Map<String, int> decimalToDMS(double decimal) {
    var d = decimal.abs().floor();
    var minTemp = (decimal.abs() - d) * 60;
    var m = minTemp.floor();
    var s = ((minTemp - m) * 60).round();

    // Handle carry-over from seconds to minutes
    if (s == 60) {
      s = 0;
      m++;
    }
    // Handle carry-over from minutes to degrees
    if (m == 60) {
      m = 0;
      d++;
    }

    return {'degrees': decimal < 0 ? -d : d, 'minutes': m, 'seconds': s};
  }

  /// Convert DMS to decimal degrees
  static double dmsToDecimal(int degrees, int minutes, int seconds) {
    return degrees + minutes / 60 + seconds / 3600;
  }

  /// Convert angle to radians based on measurement system
  /// [angle] The angle to convert
  /// [isGrads] Whether the angle is in grads (true) or degrees (false)
  /// Returns the angle in radians
  static double toRadians(double angle, bool isGrads) {
    if (isGrads) {
      return angle * (pi / 200); // Convert from grads to radians
    } else {
      return angle * (pi / 180); // Convert from degrees to radians
    }
  }

  /// Convert multiple angles to radians based on measurement system
  /// [angles] List of angles to convert
  /// [isGrads] Whether the angles are in grads (true) or degrees (false)
  /// Returns list of angles in radians
  static List<double> allToRadians(List<double> angles, bool isGrads) {
    return angles.map((angle) => toRadians(angle, isGrads)).toList();
  }

  /// Convert angle from radians to degrees or grads
  /// [radians] The angle in radians
  /// [toGrads] Whether to convert to grads (true) or degrees (false)
  /// Returns the converted angle
  static double fromRadians(double radians, bool toGrads) {
    if (toGrads) {
      return radians * (200 / pi); // Convert to grads
    } else {
      return radians * (180 / pi); // Convert to degrees
    }
  }
}
