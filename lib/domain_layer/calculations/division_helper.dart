class DivisionHelper {
  /// Returns a small non-zero value (0.000000001) if input is zero
  /// Otherwise returns the input value unchanged
  static double divz(double value) {
    if (value == 0) {
      return 0.000000001;
    }
    return value;
  }
}
