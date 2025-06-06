/// Utility functions for the fixing routine
class FixingUtils {
  /// Pad a name to 5 characters
  /// Equivalent to proc padnme5$ in the Psion code
  static String padNameTo5(String name) {
    // Pad with spaces to make it exactly 5 characters
    if (name.length >= 5) {
      return name.substring(0, 5);
    }
    return name.padRight(5);
  }
}
