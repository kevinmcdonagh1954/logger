import 'dart:math' as math;

/// Class to handle height calculations consistently across the app
class HeightCalculator {
  /// Calculate height difference between points including instrument and target heights
  /// Returns the difference between measured and computed height differences
  static double calculateHeightDifference({
    required double slopeDistance,
    required double verticalAngle,
    required double targetHeight,
    required double instrumentHeight,
    required double z1,
    required double z2,
    bool useCurvatureAndRefraction = false,
  }) {
    // Constants for curvature and refraction
    const double earthRadius = 6370000.0; // Earth radius in meters
    const double refractiveCoeff = 0.13; // Refractive coefficient (1-0.87)

    // Convert vertical angle to radians and handle face left/right
    double verticalRad = verticalAngle * math.pi / 180.0;
    if (verticalAngle > 180 && verticalAngle < 360) {
      verticalRad = (360 - verticalAngle) * math.pi / 180.0;
    }

    // Calculate horizontal distance
    final horizontalDistance = slopeDistance * math.sin(verticalRad);

    // Calculate measured height difference
    double measuredHeightDiff = slopeDistance * math.cos(verticalRad);

    // Add curvature and refraction correction if requested
    if (useCurvatureAndRefraction) {
      measuredHeightDiff += (horizontalDistance * horizontalDistance) *
          ((1 - refractiveCoeff) / (2 * earthRadius));
    }

    // Add instrument height and subtract target height
    measuredHeightDiff = instrumentHeight + measuredHeightDiff - targetHeight;

    // Calculate actual height difference between points
    final actualHeightDiff = z2 - z1;

    // Return difference between measured and actual
    return measuredHeightDiff - actualHeightDiff;
  }
}
