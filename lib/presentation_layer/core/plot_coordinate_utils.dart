import 'dart:math';
import 'package:flutter/material.dart';

class PlotCoordinateUtils {
  /// Converts a global screen position to plot Y/X coordinates.
  /// [globalPosition]: The global position (e.g., from a gesture).
  /// [renderBox]: The RenderBox of the plot area.
  /// [viewMinY], [viewMaxY], [viewMinX], [viewMaxX]: The current plot view bounds.
  static Offset screenToPlotYX({
    required Offset globalPosition,
    required RenderBox renderBox,
    required double viewMinY,
    required double viewMaxY,
    required double viewMinX,
    required double viewMaxX,
  }) {
    final Offset localPosition = renderBox.globalToLocal(globalPosition);
    final double size = min(renderBox.size.width, renderBox.size.height) - 32.0;
    final double y =
        viewMaxY - (localPosition.dx - 16.0) / size * (viewMaxY - viewMinY);
    final double x =
        viewMinX + (localPosition.dy - 16.0) / size * (viewMaxX - viewMinX);
    return Offset(y, x);
  }

  /// (Optional) Converts plot Y/X coordinates to a local screen position.
  /// Useful for highlighting or reverse-mapping.
  static Offset plotYXToScreen({
    required Offset yx,
    required RenderBox renderBox,
    required double viewMinY,
    required double viewMaxY,
    required double viewMinX,
    required double viewMaxX,
  }) {
    final double size = min(renderBox.size.width, renderBox.size.height) - 32.0;
    final double dx = 16.0 + (viewMaxY - yx.dx) / (viewMaxY - viewMinY) * size;
    final double dy = 16.0 + (yx.dy - viewMinX) / (viewMaxX - viewMinX) * size;
    return Offset(dx, dy);
  }
}
