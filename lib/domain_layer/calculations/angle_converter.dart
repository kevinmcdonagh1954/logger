
class AngleConverter {
  static double _gradsFactor = 1.0; // 1.0 for DMS, 10/9 for Grads

  /// Sets the conversion mode based on the angular measurement setting
  static void setAngularMode(String angularMeasurement) {
    if (angularMeasurement.toUpperCase() == "GRADS") {
      _gradsFactor = 10.0 / 9.0; // Switch to Grads
    } else {
      _gradsFactor = 1.0; // Switch to DMS
    }
  }

  /// Convert DMS bearing to Grads bearing for display
  static String toGrads(String dmsBearing) {
    if (_gradsFactor == 1.0) {
      return dmsBearing; // Already in DMS, no conversion needed
    }

    double decimalDegrees = dmsToDecimal(dmsBearing);
    double gradsValue = decimalDegrees * _gradsFactor;
    return gradsValue.toStringAsFixed(4);
  }

  /// Convert Grads bearing back to DMS
  static String toDMS(String gradsBearing) {
    // Temporarily switch to DMS mode
    double originalFactor = _gradsFactor;
    _gradsFactor = 1.0;

    try {
      double gradsValue = double.parse(gradsBearing);
      double dmsValue = gradsValue / originalFactor;
      String dmsString = decimalToDMS(dmsValue, 4);

      // Restore original mode
      _gradsFactor = originalFactor;
      return dmsString;
    } catch (e) {
      // Restore original mode even if there's an error
      _gradsFactor = originalFactor;
      throw FormatException('Invalid grads value: $gradsBearing');
    }
  }

  /// Convert DMS string to decimal degrees
  static double dmsToDecimal(String dmsString) {
    if (_gradsFactor > 1.0) {
      // If in Grads mode, first convert DMS to decimal degrees, then to Grads
      double decimalDegrees = _parseDMSToDecimal(dmsString);
      return decimalDegrees * _gradsFactor;
    }

    return _parseDMSToDecimal(dmsString);
  }

  /// Internal helper to parse DMS string to decimal
  static double _parseDMSToDecimal(String dmsString) {
    // First, clean up the input string
    String cleanInput = dmsString
        .replaceAll('°', ' ')
        .replaceAll('\'', ' ')
        .replaceAll('"', ' ')
        .replaceAll('  ', ' ')
        .trim();

    // Check if it's already in decimal format
    if (!cleanInput.contains(' ') && !cleanInput.contains('.')) {
      return double.parse(cleanInput);
    }

    // Handle DMS format with spaces (e.g., "179 09 33" or "179° 09' 33"")
    if (cleanInput.contains(' ')) {
      List<String> parts = cleanInput.split(' ');
      if (parts.length >= 3) {
        int sign = cleanInput.startsWith('-') ? -1 : 1;
        double degrees = double.parse(parts[0].replaceAll('-', ''));
        double minutes = double.parse(parts[1]);
        double seconds = double.parse(parts[2]);
        return sign * (degrees + (minutes / 60.0) + (seconds / 3600.0));
      }
    }

    // Handle numeric DMS format (e.g., "179.0933")
    int decimalPoint = cleanInput.indexOf('.');
    if (decimalPoint != -1) {
      // Ensure string is padded to proper length for seconds
      String paddedDms = cleanInput;
      while (paddedDms.length < decimalPoint + 5) {
        paddedDms += '0';
      }

      // Extract components
      int sign = cleanInput.startsWith('-') ? -1 : 1;
      String cleanDms = paddedDms.replaceAll('-', '');
      decimalPoint = cleanDms.indexOf('.');

      double degrees = double.parse(cleanDms.substring(0, decimalPoint));
      double minutes =
          double.parse(cleanDms.substring(decimalPoint + 1, decimalPoint + 3));
      double seconds =
          double.parse(cleanDms.substring(decimalPoint + 3, decimalPoint + 5));

      return sign * (degrees + (minutes / 60.0) + (seconds / 3600.0));
    }

    throw FormatException('Invalid DMS format: $dmsString');
  }

  /// Convert decimal degrees to DMS string with specified precision
  static String decimalToDMS(double decimal, int precision) {
    int sign = decimal < 0 ? -1 : 1;
    decimal = decimal.abs();

    int degrees = decimal.floor();
    double minutesDecimal = (decimal - degrees) * 60;
    int minutes = minutesDecimal.floor();
    double seconds = (minutesDecimal - minutes) * 60;

    // Round seconds to avoid floating point issues
    seconds = double.parse(seconds.toStringAsFixed(precision));
    if (seconds == 60) {
      seconds = 0;
      minutes++;
      if (minutes == 60) {
        minutes = 0;
        degrees++;
      }
    }

    String result =
        '${sign * degrees}.${minutes.toString().padLeft(2, '0')}${seconds.toStringAsFixed(0).padLeft(2, '0')}';
    return result;
  }

  /// Get the current grads factor
  static double get gradsFactor => _gradsFactor;
}
