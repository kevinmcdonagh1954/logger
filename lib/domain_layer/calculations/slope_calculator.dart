import 'dart:math' as math;
import '../../presentation_layer/core/bearing_formatter.dart';
import '../../presentation_layer/core/bearing_format.dart';
import '../../presentation_layer/core/angle_converter.dart';
import 'division_helper.dart';

class SlopeCalculator {
  /// Calculates slope-related metrics between two points
  /// Returns a map containing:
  /// - heightDifference: difference in elevation (first - second point)
  /// - slopeDistance: actual distance along the slope
  /// - grade: slope as decimal
  /// - gradePercent: slope as percentage
  /// - angle: slope angle in degrees
  static Map<String, String> calculate({
    required double distance,
    required double z1,
    required double z2,
  }) {
    final result = {
      'heightDifference': '0.000',
      'slopeDistance': '0.000',
      'grade': '0.000',
      'gradePercent': '0.000',
      'angle': '0.000',
      'angleFormatted': '0° 00\' 00"'
    };

    try {
      if (distance <= 0) return result;

      // Calculate height difference (first point minus second point)
      final heightDifference = z2 - z1;
      result['heightDifference'] = heightDifference.toStringAsFixed(3);

      // Calculate grade (rise/run)
      final horizontalDistance = DivisionHelper.divz(distance);
      final grade = horizontalDistance / heightDifference;
      result['grade'] = grade.toStringAsFixed(5);

      // Calculate grade percentage
      // result['gradePercent'] = (grade * 100).toStringAsFixed(3);
      result['gradePercent'] =
          ((heightDifference / horizontalDistance) * 100).toStringAsFixed(3);

      // Calculate slope distance using Pythagorean theorem
      final slopeDis =
          math.sqrt(math.pow(heightDifference, 2) + math.pow(distance, 2));
      result['slopeDistance'] = slopeDis.toStringAsFixed(3);

      // Calculate vertical angle using the provided formula:
      // Ang=deg(atan(abs(Z2-Zref)/Divz:(Dist)))*Grads

      // Step 1: Calculate division
      double divResult = heightDifference.abs() / horizontalDistance;

      // Step 2: Calculate atan (returns radians)
      double angleRad = math.atan(divResult);

      // Step 3: Convert from radians to degrees
      double angle = angleRad * 180 / math.pi;
      result['angle'] = angle.toStringAsFixed(15);

      // Step 4: Apply grads factor for unit conversion
      angle *= AngleConverter.gradsFactor;
      String angleSign = heightDifference < 0 ? "-" : "";

      // Format angle with sign and proper notation
      String formattedAngle =
          BearingFormatter.format(angle, BearingFormat.dmsSymbols);
      result['angleFormatted'] = angleSign + formattedAngle;
      // ignore: empty_catches
    } catch (e) {}

    return result;
  }

  /// Returns default values for all fields
  static Map<String, String> getDefaultValues() {
    return {
      'heightDifference': '0.000',
      'slopeDistance': '0.000',
      'grade': '0.000',
      'gradePercent': '0.000',
      'angle': '0.000',
      'angleFormatted': '0° 00\' 00"'
    };
  }

  /// Formats the angle based on the current measurement system
  static String formatAngle(double angle, {String format = 'DMS'}) {
    // Normalize angle to 0-360 range
    angle = angle.abs();
    while (angle >= 360) {
      angle -= 360;
    }

    // Use BearingFormatter directly
    BearingFormat bearingFormat = switch (format.toUpperCase()) {
      'D.M.S' => BearingFormat.dms,
      'D.MS' => BearingFormat.dmsCompact,
      'DM' => BearingFormat.dm,
      'DMS' => BearingFormat.dmsSymbols,
      _ => BearingFormat.dmsSymbols,
    };

    return BearingFormatter.format(angle, bearingFormat);
  }
}
