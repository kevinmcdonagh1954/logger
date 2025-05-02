import 'package:flutter/material.dart';
import '../../presentation_layer/core/debug_app_bar.dart';

/// Mixin that provides debug information functionality
mixin DebugInfoMixin {
  /// Creates a debug app bar with the given title
  PreferredSizeWidget createDebugAppBar(String title) {
    return DebugAppBar(
      title: title,
      fileName: 'job_defaults_view.dart',
    );
  }
}
