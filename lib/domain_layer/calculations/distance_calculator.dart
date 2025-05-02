import 'dart:math' as math;

class DistanceCalculator {
  /// Calculates the horizontal distance between two points
  /// Returns the distance rounded to 3 decimal places
  /// If points are identical, returns a small non-zero value (0.000000001)
  static double calculate(double y1, double x1, double y2, double x2) {
    if (y1 - y2 == 0 && x1 - x2 == 0) {
      return 0.000000001; // Avoid zero as per original code
    }

    final distance = math.sqrt(math.pow(y2 - y1, 2) + math.pow(x2 - x1, 2));

    // Return distance rounded to 3 decimal places
    return double.parse(distance.toStringAsFixed(3));
  }
}
