import 'dart:math';

/// Constants used in the fixing routine, based on the original Psion code
class FixConstants {
  /// Number of unknowns (y, x, orientation correction = 3)
  static const int unknowns = 3;

  /// Conversion factor from radians to degrees
  static const double radiansToDegrees = 180 / pi; // equivalent to 57.295779

  /// Default option weighting system (0 = cadastral)
  static const int defaultWeightingSystem = 0;

  /// Engineering weights: constant EDM standard error
  static const double engWeightDistanceConstant = 0.005;

  /// Engineering weights: distance dependent standard error (10ppm)
  static const double engWeightDistanceDependent = 10.0 / 1000000.0;

  /// Engineering weights: direction standard error in radians (10 seconds of arc)
  static const double engWeightDirection = (10.0 / 3600.0) * (pi / 180.0);

  /// Standard error for points already fixed provisionally
  static const double stdErrProvisional = 0.02;

  /// Standard error for fixed points
  static const double stdErrFixed = 0.0001;

  /// Standard error of current point
  static const double stdErrCurrentPoint = 0.0001;

  /// Number of stored observations (initialized to 0)
  static int storedObservations = 0;

  /// Number of decimal places for display
  static const int decimalPlaces = 3;

  /// Acceptable height difference threshold
  static const double heightDifferenceThreshold = 0.05;
}
