import 'package:flutter/foundation.dart';
import '../../domain_layer/fixing/fixing_operations.dart';
import '../../domain_layer/fixing/fix_constants.dart';
import '../../models/observation.dart';
import '../../domain_layer/coordinates/point.dart';

/// Service for managing fixing operations
class FixingService {
  final FixingOperations _fixingOperations = FixingOperations();

  // Value notifier for the current setup point status
  final ValueNotifier<SetupPointStatus> setupPointStatus =
      ValueNotifier<SetupPointStatus>(SetupPointStatus.unknown);

  // Value notifier for the current setup point
  final ValueNotifier<Point?> setupPoint = ValueNotifier<Point?>(null);

  // Singleton instance
  static final FixingService _instance = FixingService._internal();
  factory FixingService() => _instance;
  FixingService._internal();

  /// Set the setup point status and update the point if needed
  void setSetupPointStatus(SetupPointStatus status) {
    setupPointStatus.value = status;

    // If we have a setup point, update its fixed status
    if (setupPoint.value != null) {
      final point = setupPoint.value!;
      setupPoint.value = point.copyWith(
        isFixed: status == SetupPointStatus.fixed,
      );
    }
  }

  /// Get the current setup point status
  SetupPointStatus getSetupPointStatus() {
    return setupPointStatus.value;
  }

  /// Set the current setup point
  void setSetupPoint(Point point) {
    setupPoint.value = point;
  }

  /// Get the standard error for the current setup point
  double getSetupPointStandardError() {
    switch (setupPointStatus.value) {
      case SetupPointStatus.fixed:
        return FixConstants.stdErrFixed;
      case SetupPointStatus.provisional:
        return FixConstants.stdErrProvisional;
      case SetupPointStatus.redefine:
      case SetupPointStatus.unknown:
        return FixConstants.stdErrCurrentPoint;
    }
  }

  /// Perform a provisional fix
  Future<void> performProvisionalFix(List<Observation> observations) async {
    _fixingOperations.provisionalFix(observations);
  }
}

/// Enum to represent the status of the setup point
enum SetupPointStatus {
  unknown,
  fixed,
  provisional,
  redefine,
}
