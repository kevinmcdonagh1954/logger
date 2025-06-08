import 'dart:math' as math;
import 'division_helper.dart';

class BearingCalculator {
  /// Calculates the bearing between two points
  /// Returns the bearing in decimal degrees
  static double calculate(double y1, double x1, double y2, double x2) {
    final dy = y2 - y1;
    final dx = x2 - x1;
    final safeDx = DivisionHelper.divz(dx);

    // Calculate bearing using the formula from the original code
    // B = 270 + DEG(ATAN(Dy/Dx)) + 90 * ABS(Dx)/Dx
    double bearing = 270 +
        (math.atan(dy / safeDx) * 180 / math.pi) +
        90 * (safeDx.abs() / safeDx);

    // Normalize bearing to 0-360 range
    if (bearing > 360) {
      bearing -= 360;
    }

    // For now, assume Grads = 1 as specified
    return bearing;
  }
}
