import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../application_layer/core/service_locator.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../../domain_layer/coordinates/point.dart';
import '../../core/dialogs/point_dialog.dart';
import 'dart:math';
import 'dart:async';
import '../../core/plot_coordinate_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../calculations/single_join_view.dart';

class PlotCoordinatesView extends StatefulWidget {
  final bool isSelectionMode;
  const PlotCoordinatesView({
    super.key,
    this.isSelectionMode = false,
  });

  @override
  State<PlotCoordinatesView> createState() => _PlotCoordinatesViewState();
}

class PointWithLabelsPainter extends FlDotPainter {
  final Color color;
  final String? comment;
  final String? elevation;
  final bool showComment;
  final bool showZ;

  const PointWithLabelsPainter({
    required this.color,
    this.comment,
    this.elevation,
    this.showComment = false,
    this.showZ = false,
  });

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offset) {
    // Save the canvas state
    canvas.save();
    // Clip to the chart area (assuming 0,0 is top-left and chart is square with padding 16)
    const chartRect =
        Rect.fromLTWH(0, 0, 360, 360); // You may want to pass actual size
    canvas.clipRect(chartRect);

    // Draw the point
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, 2, paint);

    // Draw labels if enabled
    if (showComment && comment != null && comment!.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: comment,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        offset + Offset(-textPainter.width / 2, -12),
      );
    }

    if (showZ && elevation != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: elevation,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        offset + Offset(-textPainter.width / 2, 8),
      );
    }
    // Restore the canvas state
    canvas.restore();
  }

  @override
  Size getSize(FlSpot spot) {
    return const Size(4, 4); // Point size
  }

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is PointWithLabelsPainter && b is PointWithLabelsPainter) {
      return PointWithLabelsPainter(
        color: Color.lerp(a.color, b.color, t) ?? a.color,
        comment: t < 0.5 ? a.comment : b.comment,
        elevation: t < 0.5 ? a.elevation : b.elevation,
        showComment: t < 0.5 ? a.showComment : b.showComment,
        showZ: t < 0.5 ? a.showZ : b.showZ,
      );
    }
    return this;
  }

  @override
  List<Object?> get props => [color, comment, elevation, showComment, showZ];

  @override
  Color get mainColor => color;
}

class _PointsPlotPainter extends CustomPainter {
  final List<Point> points;
  final Color pointColor;
  final bool showGrid;
  final double gridSpacing;
  final double minX, maxX, minY, maxY;
  final bool showComment, showDescriptor, showZ;
  final int zDecimals;

  _PointsPlotPainter({
    required this.points,
    required this.pointColor,
    required this.showGrid,
    required this.gridSpacing,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.showComment,
    required this.showDescriptor,
    required this.showZ,
    required this.zDecimals,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Save the canvas state and clip to the plot area
    canvas.save();
    final plotRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(plotRect);

    final paint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    // Draw grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white30
        ..strokeWidth = 0.5;
      // Vertical grid lines
      for (double x = (minX / gridSpacing).ceil() * gridSpacing;
          x <= maxX;
          x += gridSpacing) {
        final dx = _mapX(x, size.height);
        canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
        // Draw vertical grid value at the bottom, written vertically up
        final xLabel = x.toStringAsFixed(0);
        final textPainter = TextPainter(
          text: TextSpan(
            text: xLabel,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(dx, size.height - 24); // 2 px from bottom
        canvas.rotate(
            -pi / 2); // Rotate 90 degrees counterclockwise (vertical up)
        textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
        canvas.restore();
      }
      // Horizontal grid lines
      for (double y = (minY / gridSpacing).ceil() * gridSpacing;
          y <= maxY;
          y += gridSpacing) {
        final dy = _mapY(y, size.width);
        canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
        // Draw horizontal grid value at the left
        final yLabel = y.toStringAsFixed(0);
        final textPainter = TextPainter(
          text: TextSpan(
            text: yLabel,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(2, dy - textPainter.height / 2));
      }
    }

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(plotRect, borderPaint);

    // Draw points that are within the view boundaries
    for (final point in points) {
      if (point.y >= minY &&
          point.y <= maxY &&
          point.x >= minX &&
          point.x <= maxX) {
        final dx = _mapY(point.y, size.width);
        final dy = _mapX(point.x, size.height);

        // Only draw if the point is within the canvas bounds
        if (dx >= 0 && dx <= size.width && dy >= 0 && dy <= size.height) {
          canvas.drawCircle(Offset(dx, dy), 1, paint);

          // Draw labels if enabled
          if ((showComment || showDescriptor) &&
              (point.comment.isNotEmpty ||
                  (showDescriptor &&
                      point.descriptor != null &&
                      point.descriptor!.isNotEmpty))) {
            String label = '';
            if (showComment && point.comment.isNotEmpty) label += point.comment;
            if (showDescriptor &&
                point.descriptor != null &&
                point.descriptor!.isNotEmpty) {
              if (label.isNotEmpty) label += '/';
              label += point.descriptor!;
            }
            final textPainter = TextPainter(
              text: TextSpan(
                text: label,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            textPainter.paint(
                canvas, Offset(dx - textPainter.width / 2, dy - 12));
          }
          if (showZ) {
            final textPainter = TextPainter(
              text: TextSpan(
                text: point.z.toStringAsFixed(zDecimals),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            textPainter.paint(
                canvas, Offset(dx - textPainter.width / 2, dy + 8));
          }
        }
      }
    }

    // Restore the canvas state
    canvas.restore();
  }

  // Map data X to canvas Y (vertical)
  double _mapX(double x, double height) {
    return ((x - minX) / (maxX - minX)) * height;
  }

  // Map data Y to canvas X (horizontal, inverted for right rotation)
  double _mapY(double y, double width) {
    return width - ((y - minY) / (maxY - minY)) * width;
  }

  @override
  bool shouldRepaint(covariant _PointsPlotPainter oldDelegate) {
    return points != oldDelegate.points ||
        pointColor != oldDelegate.pointColor ||
        showGrid != oldDelegate.showGrid ||
        gridSpacing != oldDelegate.gridSpacing ||
        minX != oldDelegate.minX ||
        maxX != oldDelegate.maxX ||
        minY != oldDelegate.minY ||
        maxY != oldDelegate.maxY ||
        showComment != oldDelegate.showComment ||
        showDescriptor != oldDelegate.showDescriptor ||
        showZ != oldDelegate.showZ ||
        zDecimals != oldDelegate.zDecimals;
  }
}

class PlotViewManager {
  final double minScale;
  final double maxScale;
  final double zoomIncrement;
  final double borderPercentage;

  PlotViewManager({
    this.minScale = 0.1,
    this.maxScale = 10000.0,
    this.zoomIncrement = 1.2,
    this.borderPercentage = 0.1,
  });

  void adjustViewForZoom({
    required double currentScale,
    required double newScale,
    required double centerY,
    required double centerX,
    required double currentRangeY,
    required double currentRangeX,
    required Function(double, double, double, double) onViewUpdated,
  }) {
    // Calculate new range based on zoom direction
    final newRangeY = newScale > currentScale
        ? currentRangeY / zoomIncrement // Zoom in: reduce range
        : currentRangeY * zoomIncrement; // Zoom out: increase range
    final newRangeX = newScale > currentScale
        ? currentRangeX / zoomIncrement // Zoom in: reduce range
        : currentRangeX * zoomIncrement; // Zoom out: increase range

    // Calculate new view boundaries
    double newMinY = centerY - newRangeY / 2;
    double newMaxY = centerY + newRangeY / 2;
    double newMinX = centerX - newRangeX / 2;
    double newMaxX = centerX + newRangeX / 2;

    // Update the view
    onViewUpdated(newMinY, newMaxY, newMinX, newMaxX);
  }

  void calculateInitialBounds(List<Point> points,
      Function(double, double, double, double) onBoundsCalculated) {
    if (points.isEmpty) return;

    double minY = points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    double maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    double minX = points.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    double maxX = points.map((p) => p.x).reduce((a, b) => a > b ? a : b);

    // Calculate ranges
    final rangeY = maxY - minY;
    final rangeX = maxX - minX;

    // Use the larger range for both axes to maintain square proportions
    final maxRange = max(rangeY, rangeX);

    // Calculate border size based on percentage of the larger range
    final borderSize = maxRange * borderPercentage;

    // Center the smaller range within the larger one
    if (rangeY > rangeX) {
      // Y range is larger, center X range
      final extraX = (rangeY - rangeX) / 2;
      minX -= (extraX + borderSize);
      maxX += (extraX + borderSize);
      minY -= borderSize;
      maxY += borderSize;
    } else {
      // X range is larger, center Y range
      final extraY = (rangeX - rangeY) / 2;
      minY -= (extraY + borderSize);
      maxY += (extraY + borderSize);
      minX -= borderSize;
      maxX += borderSize;
    }

    onBoundsCalculated(minY, maxY, minX, maxX);
  }
}

enum PlotTool { none, pan, zoomBox }

class _PlotCoordinatesViewState extends State<PlotCoordinatesView> {
  final JobService _jobService = locator<JobService>();
  final PlotViewManager _viewManager = PlotViewManager();
  List<Point> _points = [];
  List<Point> _visiblePointsCache = [];
  double _minY = 0;
  double _maxY = 0;
  double _minX = 0;
  double _maxX = 0;
  Color _pointColor = Colors.white;
  bool _showGrid = true;
  double _gridSpacing = 100.0;

  // Display options
  bool _showComment = false;
  bool _showZ = false;
  bool _showDescriptor = false;
  int _zDecimals = 2;

  // View state
  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;
  double? _origMinY, _origMaxY, _origMinX, _origMaxX;

  // Add timer for debouncing
  Timer? _panTimer;

  // Add timer for zoom debounce
  Timer? _zoomDebounceTimer;

  // Tool mode management
  PlotTool _activeTool = PlotTool.none;
  Offset? _panStartLocal;
  Offset? _panStartPlot;
  Offset? _zoomBoxStart;
  Offset? _zoomBoxEnd;
  Offset? _zoomBoxStartLocal;
  Offset? _zoomBoxEndLocal;
  bool _isZoomBoxValid = true;

  // Add temporary offset for smooth panning
  Offset _tempOffset = Offset.zero;

  // Add snapshot controller
  final GlobalKey _plotKey = GlobalKey();
  Uint8List? _snapshot;
  Offset _panOffset = Offset.zero;

  // Add join mode state
  bool _isJoinMode = false;
  Point? _firstJoinPoint;
  Point? _secondJoinPoint;
  Offset? _firstJoinScreenPosition;

  // Add new state variables for measurement mode
  bool _isMeasureMode = false;
  Offset? _firstMeasurePoint;
  Offset? _secondMeasurePoint;
  Offset? _firstMeasureScreen;
  Offset? _secondMeasureScreen;

  // Getters for view boundaries
  double get _viewMinX =>
      _minX +
      (_maxX - _minX - (_maxX - _minX) / _currentScale) / 2 -
      (_currentOffset.dy + _tempOffset.dy);
  double get _viewMaxX =>
      _maxX -
      (_maxX - _minX - (_maxX - _minX) / _currentScale) / 2 -
      (_currentOffset.dy + _tempOffset.dy);
  double get _viewMinY =>
      _minY +
      (_maxY - _minY - (_maxY - _minY) / _currentScale) / 2 -
      (_currentOffset.dx + _tempOffset.dx);
  double get _viewMaxY =>
      _maxY -
      (_maxY - _minY - (_maxY - _minY) / _currentScale) / 2 -
      (_currentOffset.dx + _tempOffset.dx);

  // Add fields to store pan start info

  // Add minimum zoom box size (in pixels)
  static const double _minZoomBoxSize = 20.0;

  Offset? _lastTappedPosition;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  @override
  void dispose() {
    _panTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPoints() async {
    final points = _jobService.points.value;
    if (points.isNotEmpty) {
      _viewManager.calculateInitialBounds(points, (minY, maxY, minX, maxX) {
        _minY = minY;
        _maxY = maxY;
        _minX = minX;
        _maxX = maxX;

        // Store original bounds for pan clamping
        _origMinY = minY;
        _origMaxY = maxY;
        _origMinX = minX;
        _origMaxX = maxX;
      });
    }
    setState(() {
      _points = points;
      _resetView();
      _updateVisiblePoints();
    });
  }

  void _updateVisiblePoints() {
    if (_origMinX != null &&
        _origMaxX != null &&
        _origMinY != null &&
        _origMaxY != null &&
        _minX == _origMinX &&
        _maxX == _origMaxX &&
        _minY == _origMinY &&
        _maxY == _origMaxY) {
      _visiblePointsCache = _points;
    } else {
      _visiblePointsCache = _points.where((point) {
        return point.y >= _minY &&
            point.y <= _maxY &&
            point.x >= _minX &&
            point.x <= _maxX;
      }).toList();
    }
  }

  void _resetView() {
    _panTimer?.cancel();
    setState(() {
      // Reset to original bounds
      if (_origMinY != null &&
          _origMaxY != null &&
          _origMinX != null &&
          _origMaxX != null) {
        _minY = _origMinY!;
        _maxY = _origMaxY!;
        _minX = _origMinX!;
        _maxX = _origMaxX!;
      }
      _currentScale = 1.0;
      _currentOffset = Offset.zero;
      _tempOffset = Offset.zero;
      _snapshot = null;
      _panOffset = Offset.zero;
      _activeTool = PlotTool.none;
      _zoomBoxStart = null;
      _zoomBoxEnd = null;
      _isZoomBoxValid = true;
      _clampViewToBounds();
      _updateVisiblePoints();
    });
  }

  void _zoomIn() {
    _zoomDebounceTimer?.cancel();
    final newScale = (_currentScale * _viewManager.zoomIncrement)
        .clamp(_viewManager.minScale, _viewManager.maxScale);
    debugPrint('Zooming in - Old scale: $_currentScale, New scale: $newScale');
    if (newScale != _currentScale) {
      _zoomDebounceTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() {
            // Calculate the center point of the current view
            final centerY = (_viewMinY + _viewMaxY) / 2;
            final centerX = (_viewMinX + _viewMaxX) / 2;

            // Calculate the current range
            final currentRangeY = _viewMaxY - _viewMinY;
            final currentRangeX = _viewMaxX - _viewMinX;

            _viewManager.adjustViewForZoom(
              currentScale: _currentScale,
              newScale: newScale,
              centerY: centerY,
              centerX: centerX,
              currentRangeY: currentRangeY,
              currentRangeX: currentRangeX,
              onViewUpdated: (newMinY, newMaxY, newMinX, newMaxX) {
                _minY = newMinY;
                _maxY = newMaxY;
                _minX = newMinX;
                _maxX = newMaxX;
              },
            );

            _currentScale = newScale;
            _constrainOffset();
            _clampViewToBounds();
            _updateVisiblePoints();
          });
        }
      });
    }
  }

  void _zoomOut() {
    _zoomDebounceTimer?.cancel();
    final newScale = (_currentScale / _viewManager.zoomIncrement)
        .clamp(_viewManager.minScale, _viewManager.maxScale);
    debugPrint('Zooming out - Old scale: $_currentScale, New scale: $newScale');
    if (newScale != _currentScale) {
      _zoomDebounceTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() {
            // Calculate the center point of the current view
            final centerY = (_viewMinY + _viewMaxY) / 2;
            final centerX = (_viewMinX + _viewMaxX) / 2;

            // Calculate the current range
            final currentRangeY = _viewMaxY - _viewMinY;
            final currentRangeX = _viewMaxX - _viewMinX;

            _viewManager.adjustViewForZoom(
              currentScale: _currentScale,
              newScale: newScale,
              centerY: centerY,
              centerX: centerX,
              currentRangeY: currentRangeY,
              currentRangeX: currentRangeX,
              onViewUpdated: (newMinY, newMaxY, newMinX, newMaxX) {
                _minY = newMinY;
                _maxY = newMaxY;
                _minX = newMinX;
                _maxX = newMaxX;
              },
            );

            _currentScale = newScale;
            _constrainOffset();
            _clampViewToBounds();
            _updateVisiblePoints();
          });
        }
      });
    }
  }

  void _constrainOffset() {
    final visibleRangeY = (_maxY - _minY) / _currentScale;
    final visibleRangeX = (_maxX - _minX) / _currentScale;
    final visibleRange = max(visibleRangeY, visibleRangeX);

    double maxOffsetY = (_maxY - _minY - visibleRange) / 2;
    double maxOffsetX = (_maxX - _minX - visibleRange) / 2;

    // Ensure offsets are not negative or NaN
    if (maxOffsetY.isNaN || maxOffsetY < 0) maxOffsetY = 0;
    if (maxOffsetX.isNaN || maxOffsetX < 0) maxOffsetX = 0;

    _currentOffset = Offset(
      _currentOffset.dx.clamp(-maxOffsetY, maxOffsetY),
      _currentOffset.dy.clamp(-maxOffsetX, maxOffsetX),
    );
    debugPrint('Constrained offset: $_currentOffset');
  }

  void _clampViewToBounds() {
    // Clamp the view extents to the original bounds
    if (_origMinX != null &&
        _origMaxX != null &&
        _origMinY != null &&
        _origMaxY != null) {
      _minX = _minX.clamp(_origMinX!, _origMaxX!);
      _maxX = _maxX.clamp(_origMinX!, _origMaxX!);
      _minY = _minY.clamp(_origMinY!, _origMaxY!);
      _maxY = _maxY.clamp(_origMinY!, _origMaxY!);
    }
  }

  Future<void> _editPoint(Point point) async {
    try {
      final updatedPoint = await PointDialog.showAddEditPointDialog(
        context: context,
        jobService: _jobService,
        coordinateFormat: 'YXZ',
        existingPoint: point,
        onDelete: () async {
          // Remove the point and replot in place
          await _jobService.deletePoint(point.id!);
          if (mounted) {
            setState(() {
              _points.removeWhere((p) => p.id == point.id);
              _updateVisiblePoints(); // Update visible points after deletion
            });
          }
        },
      );

      if (updatedPoint != null && mounted) {
        // Check if Y or X changed and if new point is within current bounds
        final inBounds = updatedPoint.y >= _viewMinY &&
            updatedPoint.y <= _viewMaxY &&
            updatedPoint.x >= _viewMinX &&
            updatedPoint.x <= _viewMaxX;

        setState(() {
          final idx = _points.indexWhere((p) => p.id == updatedPoint.id);
          if (idx != -1) {
            _points[idx] = updatedPoint;
            _updateVisiblePoints(); // Always update visible points after modification
          }
        });

        if (!inBounds) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.pointMovedOutOfView)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.pointUpdatedSuccess)),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.error(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: Text(widget.isSelectionMode
            ? l10n.selectPointFromPlot
            : l10n.plotCoordinatesTitle(_points.length)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              setState(() {
                switch (value) {
                  case 'comment':
                    _showComment = !_showComment;
                    break;
                  case 'descriptor':
                    _showDescriptor = !_showDescriptor;
                    break;
                  case 'z':
                    _showZ = !_showZ;
                    break;
                  case 'grid_interval':
                    _showGridIntervalDialog();
                    break;
                  case 'z_decimals_0':
                    _zDecimals = 0;
                    break;
                  case 'z_decimals_1':
                    _zDecimals = 1;
                    break;
                  case 'z_decimals_2':
                    _zDecimals = 2;
                    break;
                  case 'z_decimals_3':
                    _zDecimals = 3;
                    break;
                }
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              CheckedPopupMenuItem<String>(
                value: 'comment',
                checked: _showComment,
                child: Text(l10n.showComments),
              ),
              CheckedPopupMenuItem<String>(
                value: 'descriptor',
                checked: _showDescriptor,
                child: Text(l10n.showDescriptors),
              ),
              CheckedPopupMenuItem<String>(
                value: 'z',
                checked: _showZ,
                child: Text(l10n.showZValues),
              ),
              if (_showZ) ...[
                PopupMenuItem<String>(
                  value: 'z_decimals_0',
                  child: Row(
                    children: [
                      Icon(_zDecimals == 0 ? Icons.check : null),
                      const SizedBox(width: 8),
                      Text(l10n.zDecimals(0)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'z_decimals_1',
                  child: Row(
                    children: [
                      Icon(_zDecimals == 1 ? Icons.check : null),
                      const SizedBox(width: 8),
                      Text(l10n.zDecimals(1)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'z_decimals_2',
                  child: Row(
                    children: [
                      Icon(_zDecimals == 2 ? Icons.check : null),
                      const SizedBox(width: 8),
                      Text(l10n.zDecimals(2)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'z_decimals_3',
                  child: Row(
                    children: [
                      Icon(_zDecimals == 3 ? Icons.check : null),
                      const SizedBox(width: 8),
                      Text(l10n.zDecimals(3)),
                    ],
                  ),
                ),
              ],
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'grid_interval',
                child: Text(l10n.setGridInterval),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child: GestureDetector(
              onTapUp: _handleTapUp,
              onDoubleTapDown: _handleDoubleTapDown,
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              onLongPressStart: _handleLongPress,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final size =
                          min(constraints.maxWidth, constraints.maxHeight) -
                              32.0;
                      return Center(
                        child: SizedBox(
                          width: size + 32.0,
                          height: size + 32.0,
                          child: Stack(
                            children: [
                              if (_activeTool == PlotTool.pan &&
                                  _snapshot != null)
                                Transform.translate(
                                  offset: _panOffset,
                                  child: Image.memory(_snapshot!),
                                )
                              else
                                RepaintBoundary(
                                  key: _plotKey,
                                  child: _buildPlotWidget(),
                                ),
                              if (_activeTool == PlotTool.zoomBox &&
                                  _zoomBoxStartLocal != null &&
                                  _zoomBoxEndLocal != null)
                                Positioned(
                                  left: min(_zoomBoxStartLocal!.dx,
                                      _zoomBoxEndLocal!.dx),
                                  top: min(_zoomBoxStartLocal!.dy,
                                      _zoomBoxEndLocal!.dy),
                                  child: Container(
                                    width: (_zoomBoxEndLocal!.dx -
                                            _zoomBoxStartLocal!.dx)
                                        .abs(),
                                    height: (_zoomBoxEndLocal!.dy -
                                            _zoomBoxStartLocal!.dy)
                                        .abs(),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 2,
                                      ),
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                    child: !_isZoomBoxValid
                                        ? const Center(
                                            child: Text(
                                              'Too small',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(179),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First row of controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.open_with,
                    color: _activeTool == PlotTool.pan
                        ? Colors.blue
                        : Colors.white),
                onPressed: () {
                  setState(() {
                    _activeTool = _activeTool == PlotTool.pan
                        ? PlotTool.none
                        : PlotTool.pan;
                    _isJoinMode = false;
                    _isMeasureMode = false;
                    _clearMeasurements();
                  });
                },
                tooltip: 'Pan Mode - Drag to move view',
              ),
              IconButton(
                icon: Icon(Icons.grid_on,
                    color: _showGrid ? Colors.white : Colors.grey),
                onPressed: () {
                  setState(() {
                    _showGrid = !_showGrid;
                    if (_activeTool == PlotTool.zoomBox) {
                      _activeTool = PlotTool.none;
                      _clearMeasurements();
                    }
                  });
                },
                tooltip: 'Toggle Grid',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.color_lens, color: Colors.white),
                onPressed: () {
                  setState(() {
                    if (_activeTool == PlotTool.zoomBox) {
                      _activeTool = PlotTool.none;
                      _clearMeasurements();
                    }
                  });
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Select Point Color'),
                      content: ColorPicker(
                        pickerColor: _pointColor,
                        onColorChanged: (color) {
                          setState(() {
                            _pointColor = color;
                          });
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Change Point Color',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: () {
                  _zoomOut();
                  _clearMeasurements();
                },
                tooltip: 'Zoom Out',
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  _zoomIn();
                  _clearMeasurements();
                },
                tooltip: 'Zoom In',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Second row of controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.zoom_in,
                    color: _activeTool == PlotTool.zoomBox
                        ? Colors.blue
                        : Colors.white),
                onPressed: () {
                  setState(() {
                    _activeTool = _activeTool == PlotTool.zoomBox
                        ? PlotTool.none
                        : PlotTool.zoomBox;
                    _isJoinMode = false;
                    _isMeasureMode = false;
                    _clearMeasurements();
                    // Reset zoom box state if toggling
                    if (_activeTool != PlotTool.zoomBox) {
                      _zoomBoxStart = null;
                      _zoomBoxEnd = null;
                      _zoomBoxStartLocal = null;
                      _zoomBoxEndLocal = null;
                      _isZoomBoxValid = true;
                    }
                  });
                },
                tooltip:
                    'Zoom Box Mode - Click and drag to select an area to zoom into',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.link,
                    color: _isJoinMode ? Colors.blue : Colors.white),
                onPressed: () {
                  setState(() {
                    _isJoinMode = !_isJoinMode;
                    if (_isJoinMode) {
                      _activeTool = PlotTool.none;
                      _isMeasureMode = false;
                      _clearMeasurements();
                      _firstJoinPoint = null;
                      _secondJoinPoint = null;
                      _firstJoinScreenPosition = null;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.joinModeSelectFirst),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  });
                },
                tooltip:
                    'Join Mode - Double click two points to calculate join',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.straighten,
                    color: _isMeasureMode ? Colors.blue : Colors.white),
                onPressed: () {
                  setState(() {
                    _isMeasureMode = !_isMeasureMode;
                    if (_isMeasureMode) {
                      _activeTool = PlotTool.none;
                      _isJoinMode = false;
                      _firstMeasurePoint = null;
                      _secondMeasurePoint = null;
                      _firstMeasureScreen = null;
                      _secondMeasureScreen = null;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.selectFirstPoint),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    } else {
                      _clearMeasurements();
                    }
                  });
                },
                tooltip:
                    'Measure Mode - Click two points to measure distance and direction',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.zoom_out_map, color: Colors.white),
                onPressed: () {
                  setState(() {
                    if (_activeTool == PlotTool.zoomBox) {
                      _activeTool = PlotTool.none;
                    }
                    _clearMeasurements();
                    _resetView();
                  });
                },
                tooltip: 'Reset View',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _clearMeasurements() {
    _firstMeasurePoint = null;
    _secondMeasurePoint = null;
    _firstMeasureScreen = null;
    _secondMeasureScreen = null;
  }

  void _handlePanStart(DragStartDetails details) {
    if (_activeTool == PlotTool.pan) {
      final RenderBox? renderBox =
          _plotKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        _panStartLocal = renderBox.globalToLocal(details.globalPosition);
        _panStartPlot = PlotCoordinateUtils.screenToPlotYX(
          globalPosition: details.globalPosition,
          renderBox: renderBox,
          viewMinY: _viewMinY,
          viewMaxY: _viewMaxY,
          viewMinX: _viewMinX,
          viewMaxX: _viewMaxX,
        );
      }
      return;
    }
    if (_activeTool == PlotTool.zoomBox) {
      final RenderBox? renderBox =
          _plotKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        if (localPosition.dx >= 16 &&
            localPosition.dx <= renderBox.size.width - 16 &&
            localPosition.dy >= 16 &&
            localPosition.dy <= renderBox.size.height - 16) {
          setState(() {
            _zoomBoxStart = details.globalPosition;
            _zoomBoxEnd = null;
            _zoomBoxStartLocal = localPosition;
            _zoomBoxEndLocal = null;
            _isZoomBoxValid = true;
          });
        }
      }
      return;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_activeTool == PlotTool.pan &&
        _panStartLocal != null &&
        _panStartPlot != null) {
      final RenderBox? renderBox =
          _plotKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final plotYX = PlotCoordinateUtils.screenToPlotYX(
          globalPosition: details.globalPosition,
          renderBox: renderBox,
          viewMinY: _viewMinY,
          viewMaxY: _viewMaxY,
          viewMinX: _viewMinX,
          viewMaxX: _viewMaxX,
        );
        final dx = plotYX.dy - _panStartPlot!.dy;
        final dy = plotYX.dx - _panStartPlot!.dx;
        setState(() {
          _minX -= dx;
          _maxX -= dx;
          _minY -= dy;
          _maxY -= dy;
          _updateVisiblePoints();
        });
        _panStartLocal = localPosition;
        _panStartPlot = plotYX;
      }
      return;
    }
    if (_activeTool == PlotTool.zoomBox) {
      final RenderBox? renderBox =
          _plotKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        final constrainedX =
            localPosition.dx.clamp(16.0, renderBox.size.width - 16.0);
        final constrainedY =
            localPosition.dy.clamp(16.0, renderBox.size.height - 16.0);
        final constrainedGlobal =
            renderBox.localToGlobal(Offset(constrainedX, constrainedY));
        setState(() {
          _zoomBoxEnd = constrainedGlobal;
          _zoomBoxEndLocal = Offset(constrainedX, constrainedY);
          if (_zoomBoxStartLocal != null) {
            final width = (_zoomBoxEndLocal!.dx - _zoomBoxStartLocal!.dx).abs();
            final height =
                (_zoomBoxEndLocal!.dy - _zoomBoxStartLocal!.dy).abs();
            _isZoomBoxValid =
                width >= _minZoomBoxSize && height >= _minZoomBoxSize;
          }
        });
      }
      return;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_activeTool == PlotTool.pan) {
      _panStartLocal = null;
      _panStartPlot = null;
      return;
    }
    if (_activeTool == PlotTool.zoomBox &&
        _zoomBoxStart != null &&
        _zoomBoxEnd != null &&
        _isZoomBoxValid) {
      final RenderBox? renderBox =
          _plotKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final startPlot = PlotCoordinateUtils.screenToPlotYX(
          globalPosition: _zoomBoxStart!,
          renderBox: renderBox,
          viewMinY: _viewMinY,
          viewMaxY: _viewMaxY,
          viewMinX: _viewMinX,
          viewMaxX: _viewMaxX,
        );
        final endPlot = PlotCoordinateUtils.screenToPlotYX(
          globalPosition: _zoomBoxEnd!,
          renderBox: renderBox,
          viewMinY: _viewMinY,
          viewMaxY: _viewMaxY,
          viewMinX: _viewMinX,
          viewMaxX: _viewMaxX,
        );
        final minY = min(startPlot.dx, endPlot.dx);
        final maxY = max(startPlot.dx, endPlot.dx);
        final minX = min(startPlot.dy, endPlot.dy);
        final maxX = max(startPlot.dy, endPlot.dy);
        final side = min(maxY - minY, maxX - minX);
        final newMinY = minY;
        final newMinX = minX;
        final newMaxY = minY + side;
        final newMaxX = minX + side;
        setState(() {
          _minY = newMinY;
          _maxY = newMaxY;
          _minX = newMinX;
          _maxX = newMaxX;
          _zoomBoxStart = null;
          _zoomBoxEnd = null;
          _zoomBoxStartLocal = null;
          _zoomBoxEndLocal = null;
          _isZoomBoxValid = true;
          _updateVisiblePoints();
        });
      }
      return;
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isJoinMode) return;

    final RenderBox? renderBox =
        _plotKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final plotYX = PlotCoordinateUtils.screenToPlotYX(
      globalPosition: details.globalPosition,
      renderBox: renderBox,
      viewMinY: _viewMinY,
      viewMaxY: _viewMaxY,
      viewMinX: _viewMinX,
      viewMaxX: _viewMaxX,
    );

    if (_isMeasureMode) {
      setState(() {
        if (_firstMeasurePoint == null) {
          _firstMeasurePoint = plotYX;
          _firstMeasureScreen = renderBox.globalToLocal(details.globalPosition);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.selectSecondPoint),
              duration: const Duration(seconds: 1),
            ),
          );
        } else if (_secondMeasurePoint == null) {
          _secondMeasurePoint = plotYX;
          _secondMeasureScreen =
              renderBox.globalToLocal(details.globalPosition);
        } else {
          // Clear measurement on third tap
          _firstMeasurePoint = null;
          _secondMeasurePoint = null;
          _firstMeasureScreen = null;
          _secondMeasureScreen = null;
        }
      });
      return;
    }

    final now = DateTime.now();
    if (_lastTappedPosition != null && _lastTapTime != null) {
      final timeDiff = now.difference(_lastTapTime!);
      if (timeDiff.inMilliseconds < 500) {
        // Consider it a double tap - find closest point and edit
        Point? closest;
        double minDistance = double.infinity;
        for (var point in _points) {
          final dy = point.y - plotYX.dx;
          final dx = point.x - plotYX.dy;
          final distance = dx * dx + dy * dy;
          if (distance < minDistance) {
            minDistance = distance;
            closest = point;
          }
        }
        if (closest != null) {
          _editPoint(closest);
        }
      } else {
        // Show quick distance dialog
        showDialog(
          context: context,
          builder: (context) => QuickDistanceDialog(
            firstPoint: _lastTappedPosition!,
            secondPoint: plotYX,
            viewMinY: _viewMinY,
            viewMaxY: _viewMaxY,
            viewMinX: _viewMinX,
            viewMaxX: _viewMaxX,
          ),
        );
      }
      _lastTappedPosition = null;
      _lastTapTime = null;
    } else {
      _lastTappedPosition = plotYX;
      _lastTapTime = now;
    }
  }

  void _handleLongPress(LongPressStartDetails details) {
    if (_isJoinMode) return; // Don't handle long press in join mode

    final RenderBox? renderBox =
        _plotKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final plotYX = PlotCoordinateUtils.screenToPlotYX(
      globalPosition: details.globalPosition,
      renderBox: renderBox,
      viewMinY: _viewMinY,
      viewMaxY: _viewMaxY,
      viewMinX: _viewMinX,
      viewMaxX: _viewMaxX,
    );

    final now = DateTime.now();
    if (_lastTappedPosition != null && _lastTapTime != null) {
      final timeDiff = now.difference(_lastTapTime!);
      if (timeDiff.inMilliseconds < 500) {
        // Consider it a double long press - find closest point and edit
        Point? closest;
        double minDistance = double.infinity;
        for (var point in _points) {
          final dy = point.y - plotYX.dx;
          final dx = point.x - plotYX.dy;
          final distance = dx * dx + dy * dy;
          if (distance < minDistance) {
            minDistance = distance;
            closest = point;
          }
        }
        if (closest != null) {
          _editPoint(closest);
        }
      } else {
        // Show quick distance dialog
        showDialog(
          context: context,
          builder: (context) => QuickDistanceDialog(
            firstPoint: _lastTappedPosition!,
            secondPoint: plotYX,
            viewMinY: _viewMinY,
            viewMaxY: _viewMaxY,
            viewMinX: _viewMinX,
            viewMaxX: _viewMaxX,
          ),
        );
      }
      _lastTappedPosition = null;
      _lastTapTime = null;
    } else {
      _lastTappedPosition = plotYX;
      _lastTapTime = now;
      // Show feedback that first point is recorded
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.firstPointSelected('Coordinate')),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildPlotWidget() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _PointsPlotPainter(
              points: _visiblePointsCache,
              pointColor: _pointColor,
              showGrid: _showGrid,
              gridSpacing: _gridSpacing,
              minX: _viewMinX,
              maxX: _viewMaxX,
              minY: _viewMinY,
              maxY: _viewMaxY,
              showComment: _showComment,
              showDescriptor: _showDescriptor,
              showZ: _showZ,
              zDecimals: _zDecimals,
            ),
          ),
          // Draw measurement line and labels
          if (_firstMeasurePoint != null && _secondMeasurePoint != null)
            CustomPaint(
              size: Size.infinite,
              painter: _MeasurementLinePainter(
                firstPoint: _firstMeasureScreen!,
                secondPoint: _secondMeasureScreen!,
                firstPlotPoint: _firstMeasurePoint!,
                secondPlotPoint: _secondMeasurePoint!,
              ),
            ),
          // Draw first join point indicator
          if (_isJoinMode && _firstJoinScreenPosition != null)
            Positioned(
              left: _firstJoinScreenPosition!.dx - 8,
              top: _firstJoinScreenPosition!.dy - 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
              ),
            ),
          // Add scale indicator at bottom left
          Positioned(
            left: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: -0, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Scale: ${(_viewMaxY - _viewMinY).round()}m',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGridIntervalDialog() {
    final controller =
        TextEditingController(text: _gridSpacing.toInt().toString());
    showDialog(
      context: context,
      builder: (context) {
        // Add a post-frame callback to select all text
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        });

        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.setGridInterval),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.gridSpacing),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0) {
                  setState(() {
                    _gridSpacing = value.toDouble();
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.isSelectionMode) {
      final RenderBox? renderBox =
          _plotKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;
      final plotYX = PlotCoordinateUtils.screenToPlotYX(
        globalPosition: details.globalPosition,
        renderBox: renderBox,
        viewMinY: _viewMinY,
        viewMaxY: _viewMaxY,
        viewMinX: _viewMinX,
        viewMaxX: _viewMaxX,
      );
      // Find closest point and return it
      Point? closest;
      double minDistance = double.infinity;
      for (var point in _points) {
        final dy = point.y - plotYX.dx;
        final dx = point.x - plotYX.dy;
        final distance = dx * dx + dy * dy;
        if (distance < minDistance) {
          minDistance = distance;
          closest = point;
        }
      }
      if (closest != null) {
        Navigator.of(context).pop(closest);
      }
      return;
    }

    if (!_isJoinMode) {
      final RenderBox? renderBox =
          _plotKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;
      final plotYX = PlotCoordinateUtils.screenToPlotYX(
        globalPosition: details.globalPosition,
        renderBox: renderBox,
        viewMinY: _viewMinY,
        viewMaxY: _viewMaxY,
        viewMinX: _viewMinX,
        viewMaxX: _viewMaxX,
      );
      // Find closest point and open edit dialog
      Point? closest;
      double minDistance = double.infinity;
      for (var point in _points) {
        final dy = point.y - plotYX.dx;
        final dx = point.x - plotYX.dy;
        final distance = dx * dx + dy * dy;
        if (distance < minDistance) {
          minDistance = distance;
          closest = point;
        }
      }
      if (closest != null) {
        _editPoint(closest);
      }
      return;
    }

    // Handle join mode
    final RenderBox? renderBox =
        _plotKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final plotYX = PlotCoordinateUtils.screenToPlotYX(
      globalPosition: details.globalPosition,
      renderBox: renderBox,
      viewMinY: _viewMinY,
      viewMaxY: _viewMaxY,
      viewMinX: _viewMinX,
      viewMaxX: _viewMaxX,
    );
    // Find closest point
    Point? closest;
    double minDistance = double.infinity;
    for (var point in _points) {
      final dy = point.y - plotYX.dx;
      final dx = point.x - plotYX.dy;
      final distance = dx * dx + dy * dy;
      if (distance < minDistance) {
        minDistance = distance;
        closest = point;
      }
    }
    if (closest != null) {
      setState(() {
        if (_firstJoinPoint == null) {
          _firstJoinPoint = closest;
          // Calculate screen position for the point
          final screenX = renderBox.size.width -
              ((closest!.y - _viewMinY) / (_viewMaxY - _viewMinY)) *
                  renderBox.size.width;
          final screenY = ((closest.x - _viewMinX) / (_viewMaxX - _viewMinX)) *
              renderBox.size.height;
          _firstJoinScreenPosition = Offset(screenX, screenY);
          debugPrint(
              'First join point screen position: $_firstJoinScreenPosition');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.firstPointSelected(
                  closest.descriptor ?? closest.comment)),
              duration: const Duration(seconds: 1),
            ),
          );
        } else if (_secondJoinPoint == null) {
          _secondJoinPoint = closest;
          _calculateJoin();
        }
      });
    }
  }

  void _calculateJoin() {
    if (_firstJoinPoint != null && _secondJoinPoint != null) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => SingleJoinView(
            jobName: _jobService.currentJobName.value!,
            initialFirstPoint: _firstJoinPoint,
            initialSecondPoint: _secondJoinPoint,
            fromPlotScreen: true,
          ),
        ),
      )
          .then((_) {
        // Reset join points but keep join mode active
        setState(() {
          _firstJoinPoint = null;
          _secondJoinPoint = null;
          _firstJoinScreenPosition = null;
          // Keep _isJoinMode true
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.joinModeSelectFirst),
              duration: const Duration(seconds: 1),
            ),
          );
        });
      });
    }
  }
}

class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.pickerColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildColorRow([
          Colors.white,
          Colors.red,
          Colors.green,
          Colors.blue,
          Colors.yellow,
        ]),
        const SizedBox(height: 8),
        _buildColorRow([
          Colors.orange,
          Colors.purple,
          Colors.cyan,
          Colors.pink,
          Colors.brown,
        ]),
        const SizedBox(height: 8),
        _buildColorRow([
          Colors.lime,
          Colors.teal,
          Colors.indigo,
          Colors.amber,
          Colors.grey,
        ]),
      ],
    );
  }

  Widget _buildColorRow(List<Color> colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: colors.map((color) {
        final bool isSelected = _currentColor == color;
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentColor = color;
            });
            widget.onColorChanged(color);
            Navigator.of(context)
                .pop(); // Close the dialog when a color is picked
          },
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.rectangle,
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.black,
                width: isSelected ? 3 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class QuickDistanceDialog extends StatelessWidget {
  final Offset firstPoint;
  final Offset secondPoint;
  final double viewMinY;
  final double viewMaxY;
  final double viewMinX;
  final double viewMaxX;

  const QuickDistanceDialog({
    super.key,
    required this.firstPoint,
    required this.secondPoint,
    required this.viewMinY,
    required this.viewMaxY,
    required this.viewMinX,
    required this.viewMaxX,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dx = secondPoint.dx - firstPoint.dx;
    final dy = secondPoint.dy - firstPoint.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final direction = atan2(dx, dy) * 180 / pi;
    final directionDegrees = (direction + 360) % 360;

    return AlertDialog(
      title: Text(l10n.quickDistance),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l10n.distance}: ${distance.toStringAsFixed(3)}m'),
          const SizedBox(height: 8),
          Text('${l10n.direction}: ${directionDegrees.toStringAsFixed(1)}°'),
          const SizedBox(height: 16),
          Text(
              '${l10n.fromPoint}: (${firstPoint.dx.toStringAsFixed(3)}, ${firstPoint.dy.toStringAsFixed(3)})'),
          Text(
              '${l10n.toPoint}: (${secondPoint.dx.toStringAsFixed(3)}, ${secondPoint.dy.toStringAsFixed(3)})'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _MeasurementLinePainter extends CustomPainter {
  final Offset firstPoint;
  final Offset secondPoint;
  final Offset firstPlotPoint;
  final Offset secondPlotPoint;

  _MeasurementLinePainter({
    required this.firstPoint,
    required this.secondPoint,
    required this.firstPlotPoint,
    required this.secondPlotPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw line
    final paint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(firstPoint, secondPoint, paint);

    // Calculate distance and direction
    final dx = secondPlotPoint.dx - firstPlotPoint.dx;
    final dy = secondPlotPoint.dy - firstPlotPoint.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final direction = atan2(dx, dy) * 180 / pi;
    final directionDegrees = (direction + 360) % 360;

    // Convert to degrees, minutes, seconds
    final degrees = directionDegrees.floor();
    final minutes = ((directionDegrees - degrees) * 60).floor();
    final seconds =
        ((directionDegrees - degrees - minutes / 60) * 3600).round();

    // Draw distance and direction labels
    final distanceText = '${distance.toStringAsFixed(3)}m';
    final directionText = '$degrees° $minutes\' $seconds"';

    // Calculate line angle for text rotation
    final lineAngle =
        atan2(secondPoint.dy - firstPoint.dy, secondPoint.dx - firstPoint.dx);

    // Position labels along the line
    final midPoint = Offset(
      (firstPoint.dx + secondPoint.dx) / 2,
      (firstPoint.dy + secondPoint.dy) / 2,
    );

    // Draw distance label
    final distancePainter = TextPainter(
      text: TextSpan(
        text: distanceText,
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 18, // Increased font size
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Draw direction label
    final directionPainter = TextPainter(
      text: TextSpan(
        text: directionText,
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 18, // Increased font size
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Calculate perpendicular offset for labels (reduced from 30 to 20)
    final dx2 = secondPoint.dx - firstPoint.dx;
    final dy2 = secondPoint.dy - firstPoint.dy;
    final length = sqrt(dx2 * dx2 + dy2 * dy2);
    final perpDx = -dy2 / length * 20;
    final perpDy = dx2 / length * 20;

    // Draw labels with background and rotation
    final drawLabel = (TextPainter painter, Offset offset, bool isAbove) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(lineAngle);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: painter.width + 8,
        height: painter.height + 4,
      );
      final bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, bgPaint);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    };

    drawLabel(distancePainter, midPoint + Offset(perpDx, perpDy), true);
    drawLabel(directionPainter, midPoint - Offset(perpDx, perpDy), false);
  }

  @override
  bool shouldRepaint(covariant _MeasurementLinePainter oldDelegate) {
    return firstPoint != oldDelegate.firstPoint ||
        secondPoint != oldDelegate.secondPoint ||
        firstPlotPoint != oldDelegate.firstPlotPoint ||
        secondPlotPoint != oldDelegate.secondPlotPoint;
  }
}
