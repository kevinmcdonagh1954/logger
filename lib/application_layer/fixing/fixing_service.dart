import 'package:flutter/foundation.dart';
import '../../domain_layer/fixing/fixing_operations.dart';
import '../../domain_layer/fixing/fix_constants.dart';
import '../../models/observation.dart';

/// Service for managing fixing operations
class FixingService {
  final FixingOperations _fixingOperations = FixingOperations();

  // Value notifier for the current setup point status
  final ValueNotifier<SetupPointStatus> setupPointStatus =
      ValueNotifier<SetupPointStatus>(SetupPointStatus.unknown);

  // Singleton instance
  static final FixingService _instance = FixingService._internal();
  factory FixingService() => _instance;
  FixingService._internal();

  /// Set the setup point status
  void setSetupPointStatus(SetupPointStatus status) {
    setupPointStatus.value = status;
  }

  /// Get the current setup point status
  SetupPointStatus getSetupPointStatus() {
    return setupPointStatus.value;
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
