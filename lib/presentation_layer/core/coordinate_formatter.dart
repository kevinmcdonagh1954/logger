import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain_layer/coordinates/point.dart';

/// Utility class for formatting coordinates according to job defaults
class CoordinateFormatter {
  /// Get the label for a coordinate based on the format
  static String getCoordinateLabel(String coordinate, String format) {
    switch (format) {
      case 'YXZ':
        return coordinate;
      case 'ENZ':
        switch (coordinate) {
          case 'Y':
            return 'E';
          case 'X':
            return 'N';
          case 'Z':
            return 'Z';
          default:
            return coordinate;
        }
      case 'MPC':
        switch (coordinate) {
          case 'Y':
            return 'M';
          case 'X':
            return 'P';
          case 'Z':
            return 'C';
          default:
            return coordinate;
        }
      default:
        return coordinate;
    }
  }

  /// Format coordinates as a string based on the format
  static String formatCoordinates(Point point, String format) {
    switch (format) {
      case 'YXZ':
        return 'Y: ${point.y.toStringAsFixed(3)}, X: ${point.x.toStringAsFixed(3)}, Z: ${point.z.toStringAsFixed(3)}';
      case 'ENZ':
        return 'E: ${point.y.toStringAsFixed(3)}, N: ${point.x.toStringAsFixed(3)}, Z: ${point.z.toStringAsFixed(3)}';
      case 'MPC':
        return 'M: ${point.y.toStringAsFixed(3)}, P: ${point.x.toStringAsFixed(3)}, C: ${point.z.toStringAsFixed(3)}';
      default:
        return 'Y: ${point.y.toStringAsFixed(3)}, X: ${point.x.toStringAsFixed(3)}, Z: ${point.z.toStringAsFixed(3)}';
    }
  }

  /// Build a coordinate text field with the correct label
  static Widget buildCoordinateField({
    required TextEditingController controller,
    required String coordinate,
    required String format,
    required TextInputFormatter formatter,
    required FormFieldValidator<String> validator,
    InputDecoration? decoration,
    ValueChanged<String>? onChanged,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      decoration: (decoration ?? const InputDecoration()).copyWith(
        labelText: '${getCoordinateLabel(coordinate, format)} Coordinate',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [formatter],
      validator: validator,
      onChanged: onChanged,
      focusNode: focusNode,
    );
  }
}
