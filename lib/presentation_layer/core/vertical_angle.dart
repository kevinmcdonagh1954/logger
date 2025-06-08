/// Class to handle vertical angle calculations with index correction
class VerticalAngle {
  /// Calculates the corrected vertical angle given a decimal angle and vertical index correction
  /// [verticalAngle] is the input angle in decimal degrees (0-360)
  /// [verticalIndexCorrection] is the correction to be applied (default 0)
  /// Returns the corrected vertical angle in decimal degrees
  static double calculateVerticalAngle(double verticalAngle,
      [double verticalIndexCorrection = 0]) {
    double correctedAngle;

    if (verticalAngle > 0 && verticalAngle < 180) {
      correctedAngle = 90 - verticalAngle;
    } else if (verticalAngle > 180 && verticalAngle < 360) {
      correctedAngle = verticalAngle - 270;
    } else {
      correctedAngle = verticalAngle; // Handle edge cases
    }

    // Add vertical index correction
    return correctedAngle + verticalIndexCorrection;
  }
}
