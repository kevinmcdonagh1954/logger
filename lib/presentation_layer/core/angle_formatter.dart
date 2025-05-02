import 'package:flutter/services.dart';

class AngleFormatter extends TextInputFormatter {
  final bool isDMS; // true for DMS (360°), false for Grads (400g)
  final bool allowNegative;

  AngleFormatter({
    required this.isDMS,
    this.allowNegative = false,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Handle negative sign
    if (newValue.text == '-') {
      return allowNegative ? newValue : oldValue;
    }

    // Split into whole and decimal parts
    final parts = newValue.text.split('.');

    // Validate whole number part
    String wholePart = parts[0];
    if (wholePart.startsWith('-') && !allowNegative) {
      return oldValue;
    }

    // Parse the whole number, accounting for negative sign
    int? wholeNum;
    try {
      wholeNum = int.parse(wholePart.replaceAll('-', ''));
    } catch (e) {
      return oldValue;
    }

    // Check range for whole number
    int maxWhole = isDMS ? 360 : 400;
    if (wholeNum > maxWhole) {
      return oldValue;
    }

    // If there's a decimal part
    if (parts.length > 1) {
      String decimalPart = parts[1];

      // For DMS, validate minutes and seconds
      if (isDMS) {
        if (decimalPart.length > 4) {
          return oldValue;
        }

        // Check minutes (first two digits)
        if (decimalPart.length >= 2) {
          int? minutes = int.tryParse(decimalPart.substring(0, 2));
          if (minutes == null || minutes > 59) {
            return oldValue;
          }
        }

        // Check seconds (next two digits)
        if (decimalPart.length >= 4) {
          int? seconds = int.tryParse(decimalPart.substring(2, 4));
          if (seconds == null || seconds > 59) {
            return oldValue;
          }
        }
      }

      // For Grads, allow any decimal
      // But prevent more than one decimal point
      if (parts.length > 2) {
        return oldValue;
      }
    }

    return newValue;
  }
}

class NumericInputFormatter extends TextInputFormatter {
  final bool allowNegative;
  final bool allowDecimal;

  NumericInputFormatter({
    this.allowNegative = false,
    this.allowDecimal = true,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Handle negative sign
    if (newValue.text == '-') {
      return allowNegative ? newValue : oldValue;
    }

    // Check for multiple decimal points
    if (allowDecimal && newValue.text.contains('.')) {
      if (newValue.text.indexOf('.') != newValue.text.lastIndexOf('.')) {
        return oldValue;
      }
    }

    // Validate the number format
    try {
      final number = double.parse(newValue.text);
      if (!allowNegative && number < 0) {
        return oldValue;
      }
      return newValue;
    } catch (e) {
      return oldValue;
    }
  }
}
