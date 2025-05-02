import 'package:flutter/services.dart';

class AngleValidator extends TextInputFormatter {
  static bool isValidDMSAngle(String value) {
    if (value.isEmpty) return true;

    // Split into whole and decimal parts
    final parts = value.split('.');

    // Validate whole number (degrees)
    if (parts[0].isNotEmpty) {
      try {
        final degrees = int.parse(parts[0]);
        if (degrees < 0 || degrees > 360) return false;
      } catch (e) {
        return false;
      }
    }

    // If there's a decimal part, validate minutes and seconds
    if (parts.length > 1) {
      final decimal = parts[1];

      // Check minutes (first two digits)
      if (decimal.length >= 2) {
        try {
          final minutes = int.parse(decimal.substring(0, 2));
          if (minutes > 59) return false;
        } catch (e) {
          return false;
        }
      }

      // Check seconds (next two digits)
      if (decimal.length >= 4) {
        try {
          final seconds = int.parse(decimal.substring(2, 4));
          if (seconds > 59) return false;
        } catch (e) {
          return false;
        }
      }

      // Don't allow more than 4 decimal places
      if (decimal.length > 4) return false;
    }

    return true;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty value
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Only allow digits and one decimal point
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(newValue.text)) {
      return oldValue;
    }

    // Validate the angle
    if (!isValidDMSAngle(newValue.text)) {
      return oldValue;
    }

    return newValue;
  }

  /// Format a numeric angle value to DMS string representation
  static String formatToDMS(double angle) {
    int degrees = angle.floor();
    double minutesDecimal = (angle - degrees) * 60;
    int minutes = minutesDecimal.floor();
    double secondsDecimal = (minutesDecimal - minutes) * 60;
    int seconds = secondsDecimal.round();

    // Handle case where seconds round to 60
    if (seconds == 60) {
      minutes++;
      seconds = 0;
      if (minutes == 60) {
        degrees++;
        minutes = 0;
      }
    }

    return '$degrees.${minutes.toString().padLeft(2, '0')}${seconds.toString().padLeft(2, '0')}';
  }

  /// Parse a DMS string to a numeric angle value
  static double? parseFromDMS(String dmsString) {
    try {
      final parts = dmsString.split('.');
      int degrees = int.parse(parts[0]);

      if (parts.length > 1) {
        final decimal = parts[1].padRight(4, '0');
        int minutes = int.parse(decimal.substring(0, 2));
        int seconds = int.parse(decimal.substring(2, 4));

        if (minutes > 59 || seconds > 59) return null;

        return degrees + (minutes / 60) + (seconds / 3600);
      }

      return degrees.toDouble();
    } catch (e) {
      return null;
    }
  }
}
