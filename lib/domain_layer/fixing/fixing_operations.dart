import '../../models/observation.dart';
import 'matrix_operations.dart';
import 'dart:math' as math;
import '../calculations/bearing_calculator.dart';
import '../calculations/distance_calculator.dart';

/// Class to handle fixing-specific operations
class FixingOperations {
  final MatrixOperations _matrix = MatrixOperations();

  /// Look up horizontal angle
  /// Equivalent to proc lookHcl in the Psion code
  /// Returns the index of the next observation with a non-zero horizontal angle,
  /// starting from startIndex. Returns null if no such observation is found.
  int? lookupHorizontalAngle(List<Observation> observations, int startIndex) {
    // If starting index is beyond the number of observations, return null
    if (startIndex > observations.length) {
      return null;
    }

    // Look for next non-zero observed direction
    for (var i = startIndex; i < observations.length; i++) {
      if (observations[i].horizontalAngle != null &&
          observations[i].horizontalAngle != 0) {
        return i;
      }
    }

    return null;
  }

  /// Provisional fix calculation by back polar or resection
  /// Equivalent to PROC Provfix in the Psion code
  void provisionalFix(List<Observation> observations) {
    if (observations.length < 2) {
      return;
    }

    // Find shortest measured length
    int? shortestIndex;
    double shortest = 10000;

    for (var i = 0; i < observations.length; i++) {
      final dist = observations[i].horizontalDistance;
      if (dist != null && dist > 0 && dist < shortest) {
        shortestIndex = i;
        shortest = dist;
      }
    }

    // If no measured distance found, do resection
    if (shortestIndex == null) {
      _resectionFix(observations);
      return;
    }

    // Search for direction observation
    int? directionIndex;
    for (var i = 0; i < observations.length; i++) {
      if (i != shortestIndex &&
          observations[i].horizontalAngle != null &&
          observations[i].horizontalAngle != 0) {
        directionIndex = i;
        break;
      }
    }

    if (directionIndex == null) {
      return;
    }

    // Back polar calculation
    final obs1 = observations[shortestIndex];
    final obs2 = observations[directionIndex];

    // Calculate bearing from first point to station
    final bearing1 = obs1.horizontalAngle!;
    final distance1 = obs1.horizontalDistance!;

    // Calculate provisional coordinates using back polar
    final y = obs1.y + distance1 * math.sin(bearing1 * math.pi / 180.0);
    final x = obs1.x + distance1 * math.cos(bearing1 * math.pi / 180.0);

    // Calculate height if available
    double z = 0;
    if (obs1.verticalAngle != null && obs1.targetHeight != null) {
      final zenith = obs1.verticalAngle! * math.pi / 180.0;
      z = obs1.z + (distance1 * math.cos(zenith)) - obs1.targetHeight!;
    }

    // Update station coordinates
    observations[0].y = y;
    observations[0].x = x;
    observations[0].z = z;
  }

  /// Resection fix calculation
  /// Helper method for provisionalFix
  void _resectionFix(List<Observation> observations) {
    // Find three points with horizontal angles
    int? i1, i2, i3;
    int startIndex = 0;

    i1 = lookupHorizontalAngle(observations, startIndex);
    if (i1 == null) return;

    startIndex = i1 + 1;
    i2 = lookupHorizontalAngle(observations, startIndex);
    if (i2 == null) return;

    startIndex = i2 + 1;
    i3 = lookupHorizontalAngle(observations, startIndex);
    if (i3 == null) return;

    final obs1 = observations[i1];
    final obs2 = observations[i2];
    final obs3 = observations[i3];

    // Calculate bearings between points
    final bearing12 =
        BearingCalculator.calculate(obs1.y, obs1.x, obs2.y, obs2.x);
    final bearing23 =
        BearingCalculator.calculate(obs2.y, obs2.x, obs3.y, obs3.x);
    final bearing31 =
        BearingCalculator.calculate(obs3.y, obs3.x, obs1.y, obs1.x);

    // Calculate angles between points
    final angle1 = obs1.horizontalAngle!;
    final angle2 = obs2.horizontalAngle!;
    final angle3 = obs3.horizontalAngle!;

    // Calculate orientation corrections
    final correction1 = bearing12 - angle1;
    final correction2 = bearing23 - angle2;
    final correction3 = bearing31 - angle3;

    // Average the corrections
    var totalCorrection = correction1 + correction2 + correction3;
    final averageCorrection = totalCorrection / 3.0;

    // Apply correction to all observations
    for (var obs in observations) {
      if (obs.horizontalAngle != null) {
        obs.horizontalAngle = obs.horizontalAngle! + averageCorrection;
      }
    }

    // Now calculate provisional coordinates using back polar
    provisionalFix(observations);
  }

  /// Set orientation
  /// Equivalent to PROC SetOrn in the Psion code
  void setOrientation(List<Observation> observations, bool isElectronic) {
    if (observations.isEmpty) return;

    double totalCorrection = 0;
    int count = 0;

    // Calculate orientation correction for each observation
    for (final obs in observations) {
      if (obs.horizontalAngle == null || obs.horizontalAngle == 0) continue;

      // Calculate bearing from station to point
      final calculatedBearing = BearingCalculator.calculate(
        observations[0].y,
        observations[0].x,
        obs.y,
        obs.x,
      );

      // Calculate correction
      double correction = obs.horizontalAngle! - calculatedBearing;

      // Normalize correction to -180 to +180
      while (correction > 180) correction -= 360;
      while (correction < -180) correction += 360;

      totalCorrection += correction;
      count++;
    }

    // Calculate average correction
    if (count > 0) {
      final averageCorrection = totalCorrection / count;

      // Apply correction to all observations
      for (var obs in observations) {
        if (obs.horizontalAngle != null) {
          double correctedAngle = obs.horizontalAngle! - averageCorrection;

          // Normalize angle to 0-360
          while (correctedAngle >= 360) correctedAngle -= 360;
          while (correctedAngle < 0) correctedAngle += 360;

          obs.horizontalAngle = correctedAngle;
        }
      }
    }
  }
}
