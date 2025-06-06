import 'fix_constants.dart';
import 'dart:math' as math;

/// Class to handle matrix operations for the fixing routine
class MatrixOperations {
  /// The BA matrix used in fixing calculations
  /// This is a one-dimensional array representing a matrix
  /// The size is determined by the number of observations and unknowns
  List<double> _ba = [];

  /// The A matrix used in fixing calculations
  List<double> _a = [];

  /// Initialize the BA matrix with zeros
  /// Size is determined by number of observations (n) and unknowns (m)
  void initializeBA(int numberOfObservations) {
    final size = numberOfObservations * FixConstants.unknowns;
    _ba = List.filled(size, 0.0);
  }

  /// Initialize the A matrix with zeros
  void initializeA(int size) {
    _a = List.filled(size * size, 0.0);
  }

  /// Add an amount to an element of the BA matrix
  /// Equivalent to PROC BAadd in the Psion code
  ///
  /// Parameters:
  /// - iref: row reference (1-based index)
  /// - jref: column reference (1-based index)
  /// - amount: value to add
  double addToBA(int iref, int jref, double amount) {
    final row = (iref - 1) * FixConstants.unknowns + (jref - 1);
    _ba[row] += amount;
    return _ba[row];
  }

  /// Get a value from the BA matrix
  /// Equivalent to PROC BAget in the Psion code
  ///
  /// Parameters:
  /// - iref: row reference (1-based index)
  /// - jref: column reference (1-based index)
  double getBA(int iref, int jref) {
    final row = (iref - 1) * FixConstants.unknowns + (jref - 1);
    return _ba[row];
  }

  /// Put a value into the BA matrix
  /// Equivalent to PROC BAput in the Psion code
  ///
  /// Parameters:
  /// - iref: row reference (1-based index)
  /// - jref: column reference (1-based index)
  /// - value: value to set
  void putBA(int iref, int jref, double value) {
    final row = (iref - 1) * FixConstants.unknowns + (jref - 1);
    _ba[row] = value;
  }

  /// Form the A matrix from BA matrix
  /// Equivalent to PROC Aform in the Psion code
  void formA() {
    final n = FixConstants.unknowns;
    initializeA(n);

    // Form the normal equations matrix A
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= n; j++) {
        var sum = 0.0;
        for (var k = 1; k <= FixConstants.storedObservations; k++) {
          sum += getBA(k, i) * getBA(k, j);
        }
        _a[(i - 1) * n + (j - 1)] = sum;
      }
    }
  }

  /// Add an equation to the BA matrix
  /// Equivalent to proc Addeqn in the Psion code
  ///
  /// Parameters:
  /// - weight: weight of the equation
  /// - coefficients: list of coefficients for the equation
  /// - constant: constant term
  void addEquation(double weight, List<double> coefficients, double constant) {
    if (coefficients.length != FixConstants.unknowns) {
      throw Exception('Number of coefficients must match number of unknowns');
    }

    final eqnNumber = FixConstants.storedObservations + 1;

    // Add weighted coefficients to BA matrix
    for (var i = 0; i < coefficients.length; i++) {
      putBA(eqnNumber, i + 1, coefficients[i] * weight);
    }

    // Add weighted constant term
    putBA(eqnNumber, FixConstants.unknowns, constant * weight);

    FixConstants.storedObservations++;
  }

  /// Invert the A matrix
  /// Equivalent to PROC Invert in the Psion code
  void invert() {
    final n = FixConstants.unknowns;

    // Gauss-Jordan elimination with full pivoting
    List<int> index = List.generate(n, (i) => i);

    for (var i = 0; i < n; i++) {
      // Find pivot
      var pivot = 0.0;
      var pivotRow = i;
      var pivotCol = i;

      for (var j = i; j < n; j++) {
        for (var k = i; k < n; k++) {
          final absValue = _a[j * n + k].abs();
          if (absValue > pivot) {
            pivot = absValue;
            pivotRow = j;
            pivotCol = k;
          }
        }
      }

      if (pivot == 0) {
        throw Exception('Matrix is singular');
      }

      // Swap rows if necessary
      if (pivotRow != i) {
        for (var j = 0; j < n; j++) {
          final temp = _a[i * n + j];
          _a[i * n + j] = _a[pivotRow * n + j];
          _a[pivotRow * n + j] = temp;
        }
      }

      // Swap columns if necessary
      if (pivotCol != i) {
        for (var j = 0; j < n; j++) {
          final temp = _a[j * n + i];
          _a[j * n + i] = _a[j * n + pivotCol];
          _a[j * n + pivotCol] = temp;
        }
        final temp = index[i];
        index[i] = index[pivotCol];
        index[pivotCol] = temp;
      }

      // Divide row by pivot
      final pivotValue = _a[i * n + i];
      for (var j = 0; j < n; j++) {
        _a[i * n + j] /= pivotValue;
      }

      // Subtract from other rows
      for (var j = 0; j < n; j++) {
        if (j != i) {
          final factor = _a[j * n + i];
          for (var k = 0; k < n; k++) {
            _a[j * n + k] -= factor * _a[i * n + k];
          }
        }
      }
    }

    // Reorder columns
    for (var i = n - 1; i >= 0; i--) {
      if (index[i] != i) {
        for (var j = 0; j < n; j++) {
          final temp = _a[j * n + i];
          _a[j * n + i] = _a[j * n + index[i]];
          _a[j * n + index[i]] = temp;
        }
      }
    }
  }

  /// Solve the system of equations
  /// Equivalent to PROC Solve in the Psion code
  List<double> solve() {
    final n = FixConstants.unknowns;
    List<double> solution = List.filled(n, 0.0);

    // Form normal equations
    formA();

    // Invert matrix
    invert();

    // Calculate solution
    for (var i = 0; i < n; i++) {
      var sum = 0.0;
      for (var j = 0; j < n; j++) {
        sum += _a[i * n + j] * getBA(j + 1, n);
      }
      solution[i] = sum;
    }

    return solution;
  }
}
