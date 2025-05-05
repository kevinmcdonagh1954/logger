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

class PlotCoordinatesView extends StatefulWidget {
  const PlotCoordinatesView({super.key});

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

class _PlotCoordinatesViewState extends State<PlotCoordinatesView> {
  final JobService _jobService = locator<JobService>();
  List<Point> _points = [];
  double _minY = 0;
  double _maxY = 0;
  double _minX = 0;
  double _maxX = 0;
  Color _pointColor = Colors.white;
  bool _showGrid = true;
  double _gridSpacing = 100.0; // Grid spacing in meters

  // Display options
  bool _showComment = false;
  bool _showZ = false;
  bool _showDescriptor = false;
  int _zDecimals = 2; // Z decimal places, default 3

  // View state
  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;

  // Zoom constants
  static const double _minScale = 0.1;
  static const double _maxScale = 10000.0;
  static const double _zoomIncrement = 1.2;

  // Border constant - 50% of the range for more padding
  static const double _borderPercentage = 0.1;

  // Add temporary offset for smooth panning
  Offset _tempOffset = Offset.zero;

  // Add timer for debouncing
  Timer? _panTimer;
  bool _isPanning = false;

  // Add snapshot controller
  final GlobalKey _plotKey = GlobalKey();
  Uint8List? _snapshot;
  Offset _panOffset = Offset.zero;

  // Store the last valid RenderBox for use in pan end

  // Store the pending pan end screen position for post-frame recentering

  // Getters for view boundaries

  // Getters for view coordinates
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

  // Add a timer for zoom debounce
  Timer? _zoomDebounceTimer;

  // Store original bounds for clamping pan
  double? _origMinY, _origMaxY, _origMinX, _origMaxX;

  // Add zoom box state variables
  bool _isZoomBoxMode = false;
  Offset? _zoomBoxStart;
  Offset? _zoomBoxEnd;

  // Add minimum zoom box size (in pixels)
  static const double _minZoomBoxSize = 20.0;

  // Add zoom box validation state
  bool _isZoomBoxValid = true;

  // Add local positions for zoom box overlay
  Offset? _zoomBoxStartLocal;
  Offset? _zoomBoxEndLocal;

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
      _minY = points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
      _maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
      _minX = points.map((p) => p.x).reduce((a, b) => a < b ? a : b);
      _maxX = points.map((p) => p.x).reduce((a, b) => a > b ? a : b);

      // Calculate ranges
      final rangeY = _maxY - _minY;
      final rangeX = _maxX - _minX;

      // Use the larger range for both axes to maintain square proportions
      final maxRange = max(rangeY, rangeX);

      // Calculate border size based on percentage of the larger range
      final borderSize = maxRange * _borderPercentage;

      // Center the smaller range within the larger one
      if (rangeY > rangeX) {
        // Y range is larger, center X range
        final extraX = (rangeY - rangeX) / 2;
        _minX -= (extraX + borderSize);
        _maxX += (extraX + borderSize);
        _minY -= borderSize;
        _maxY += borderSize;
      } else {
        // X range is larger, center Y range
        final extraY = (rangeX - rangeY) / 2;
        _minY -= (extraY + borderSize);
        _maxY += (extraY + borderSize);
        _minX -= borderSize;
        _maxX += borderSize;
      }

      // Store original bounds for pan clamping
      _origMinY = _minY;
      _origMaxY = _maxY;
      _origMinX = _minX;
      _origMaxX = _maxX;
    }
    setState(() {
      _points = points;
      _resetView();
    });
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
      _isPanning = false;
      _snapshot = null;
      _panOffset = Offset.zero;
      _isZoomBoxMode = false;
      _zoomBoxStart = null;
      _zoomBoxEnd = null;
      _isZoomBoxValid = true;
      _clampViewToBounds();
    });
  }

  void _zoomIn() {
    _zoomDebounceTimer?.cancel();
    final newScale =
        (_currentScale * _zoomIncrement).clamp(_minScale, _maxScale);
    if (newScale != _currentScale) {
      _zoomDebounceTimer = Timer(const Duration(milliseconds: 250), () {
        setState(() {
          _currentScale = newScale;
          _constrainOffset();
          _clampViewToBounds();
        });
      });
    }
  }

  void _zoomOut() {
    _zoomDebounceTimer?.cancel();
    final newScale =
        (_currentScale / _zoomIncrement).clamp(_minScale, _maxScale);
    if (newScale != _currentScale) {
      _zoomDebounceTimer = Timer(const Duration(milliseconds: 250), () {
        setState(() {
          _currentScale = newScale;
          _constrainOffset();
          _clampViewToBounds();
        });
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
            });
          }
        },
      );

      if (updatedPoint != null && mounted) {
        // If only name or Z changed, just replot in place
        if (updatedPoint.y == point.y && updatedPoint.x == point.x) {
          setState(() {
            final idx = _points.indexWhere((p) => p.id == updatedPoint.id);
            if (idx != -1) {
              _points[idx] = updatedPoint;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Point updated successfully')),
          );
          return;
        }
        // If Y or X changed, check if new point is within current bounds
        final inBounds = updatedPoint.y >= _viewMinY &&
            updatedPoint.y <= _viewMaxY &&
            updatedPoint.x >= _viewMinX &&
            updatedPoint.x <= _viewMaxX;
        setState(() {
          final idx = _points.indexWhere((p) => p.id == updatedPoint.id);
          if (idx != -1) {
            _points[idx] = updatedPoint;
          }
        });
        if (!inBounds) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Point moved out of view')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Point updated successfully')),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  List<Point> get _visiblePoints {
    if (_currentScale == 1.0 && _currentOffset == Offset.zero) {
      return _points;
    }

    final visibleRangeY = (_viewMaxY - _viewMinY);
    final visibleRangeX = (_viewMaxX - _viewMinX);
    final visibleRange = max(visibleRangeY, visibleRangeX);

    final centerY = (_viewMaxY + _viewMinY) / 2;
    final centerX = (_viewMaxX + _viewMinX) / 2;

    final halfRange = visibleRange / 2;
    final visibleMinY = centerY - halfRange;
    final visibleMaxY = centerY + halfRange;
    final visibleMinX = centerX - halfRange;
    final visibleMaxX = centerX + halfRange;

    return _points.where((point) {
      return point.y >= visibleMinY &&
          point.y <= visibleMaxY &&
          point.x >= visibleMinX &&
          point.x <= visibleMaxX;
    }).toList();
  }

  ScatterSpot _buildSpot(Point point) {
    // Format label as {comment/descriptor} if both are shown
    String? label;
    if (_showComment &&
        _showDescriptor &&
        point.descriptor != null &&
        point.descriptor!.isNotEmpty) {
      if (point.comment.isNotEmpty) {
        label = '${point.comment}/${point.descriptor}';
      } else {
        label = '{${point.descriptor}}';
      }
    } else if (_showComment && point.comment.isNotEmpty) {
      label = point.comment;
    } else if (_showDescriptor &&
        point.descriptor != null &&
        point.descriptor!.isNotEmpty) {
      label = point.descriptor;
    }
    return ScatterSpot(
      -point.y,
      -point.x,
      dotPainter: PointWithLabelsPainter(
        color: _pointColor,
        comment: label,
        elevation: point.z.toStringAsFixed(_zDecimals),
        showComment: _showComment || _showDescriptor,
        showZ: _showZ,
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.grid_on,
                color: _showGrid ? Colors.white : Colors.grey),
            onPressed: () {
              setState(() {
                _showGrid = !_showGrid;
                if (_isZoomBoxMode) _isZoomBoxMode = false;
              });
            },
            tooltip: 'Toggle Grid',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.color_lens, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isZoomBoxMode) _isZoomBoxMode = false;
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
            onPressed: _zoomOut,
            tooltip: 'Zoom Out',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _zoomIn,
            tooltip: 'Zoom In',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.zoom_in,
                color: _isZoomBoxMode ? Colors.blue : Colors.white),
            onPressed: () {
              setState(() {
                _isZoomBoxMode = !_isZoomBoxMode;
                _zoomBoxStart = null;
                _zoomBoxEnd = null;
                _zoomBoxStartLocal = null;
                _zoomBoxEndLocal = null;
                _isZoomBoxValid = true;
              });
            },
            tooltip:
                'Zoom Box Mode - Click and drag to select an area to zoom into',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.zoom_out_map, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isZoomBoxMode) _isZoomBoxMode = false;
              });
              _resetView();
            },
            tooltip: 'Reset View',
          ),
        ],
      ),
    );
  }

  void _handlePanStart(DragStartDetails details) async {
    if (_isZoomBoxMode) {
      final RenderBox? renderBox =
          _plotKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        // Check if the start position is within the plot area
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
    // Do not allow panning
    // if (_currentScale == 1.0) return;
    // ... rest of pan code is now disabled ...
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isZoomBoxMode) {
      final RenderBox? renderBox =
          _plotKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        // Constrain the end position to the plot area
        final constrainedX =
            localPosition.dx.clamp(16.0, renderBox.size.width - 16.0);
        final constrainedY =
            localPosition.dy.clamp(16.0, renderBox.size.height - 16.0);
        final constrainedGlobal =
            renderBox.localToGlobal(Offset(constrainedX, constrainedY));
        setState(() {
          _zoomBoxEnd = constrainedGlobal;
          _zoomBoxEndLocal = Offset(constrainedX, constrainedY);
          // Check if the zoom box is large enough
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
    // Do not allow panning
    // if (_currentScale == 1.0) return;
    // if (!_isPanning) return;
    // ... rest of pan code is now disabled ...
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isZoomBoxMode &&
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
        // Calculate the plot boundaries based on the zoom box
        final minY = min(startPlot.dx, endPlot.dx);
        final maxY = max(startPlot.dx, endPlot.dx);
        final minX = min(startPlot.dy, endPlot.dy);
        final maxX = max(startPlot.dy, endPlot.dy);
        // Calculate the center of the zoom box
        final centerY = (minY + maxY) / 2;
        final centerX = (minX + maxX) / 2;
        // Calculate the range of the zoom box
        final rangeY = maxY - minY;
        final rangeX = maxX - minX;
        // Use the larger range for both axes to maintain square proportions
        final maxRange = max(rangeY, rangeX);
        // Calculate new boundaries centered on the zoom box
        final newMinY = centerY - maxRange / 2;
        final newMaxY = centerY + maxRange / 2;
        final newMinX = centerX - maxRange / 2;
        final newMaxX = centerX + maxRange / 2;
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
        });
      }
      return;
    }
    // Do not allow panning
    // ... rest of pan end code is now disabled ...
  }

  void _handleTapUp(TapUpDetails details) {
    // No-op (remove test dialog)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: Text('Plot Coordinates - ${_points.length}'),
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
                child: const Text('Show Comments'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'descriptor',
                checked: _showDescriptor,
                child: const Text('Show Descriptors'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'z',
                checked: _showZ,
                child: const Text('Show Z Values'),
              ),
              if (_showZ) ...[
                PopupMenuItem<String>(
                  value: 'z_decimals_0',
                  child: Row(
                    children: [
                      Icon(_zDecimals == 0 ? Icons.check : null),
                      const SizedBox(width: 8),
                      const Text('Z Decimals: 0'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'z_decimals_1',
                  child: Row(
                    children: [
                      Icon(_zDecimals == 1 ? Icons.check : null),
                      const SizedBox(width: 8),
                      const Text('Z Decimals: 1'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'z_decimals_2',
                  child: Row(
                    children: [
                      Icon(_zDecimals == 2 ? Icons.check : null),
                      const SizedBox(width: 8),
                      const Text('Z Decimals: 2'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'z_decimals_3',
                  child: Row(
                    children: [
                      Icon(_zDecimals == 3 ? Icons.check : null),
                      const SizedBox(width: 8),
                      const Text('Z Decimals: 3'),
                    ],
                  ),
                ),
              ],
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'grid_interval',
                child: Text('Set Grid Interval'),
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
              onDoubleTapDown: (details) {
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
              },
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
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
                              if (_isPanning && _snapshot != null)
                                Transform.translate(
                                  offset: _panOffset,
                                  child: Image.memory(_snapshot!),
                                )
                              else
                                RepaintBoundary(
                                  key: _plotKey,
                                  child: _buildPlotWidget(),
                                ),
                              if (_isZoomBoxMode &&
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

  Widget _buildPlotWidget() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          ScatterChart(
            ScatterChartData(
              scatterSpots:
                  _visiblePoints.map((point) => _buildSpot(point)).toList(),
              minX: -_viewMaxY,
              maxX: -_viewMinY,
              minY: -_viewMaxX,
              maxY: -_viewMinX,
              backgroundColor: Colors.black,
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Colors.white,
                  width: 1.0,
                ),
              ),
              gridData: FlGridData(
                show: _showGrid,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: Colors.white30,
                  strokeWidth: 0.5,
                ),
                getDrawingVerticalLine: (value) => const FlLine(
                  color: Colors.white30,
                  strokeWidth: 0.5,
                ),
                checkToShowHorizontalLine: (value) => value % _gridSpacing == 0,
                checkToShowVerticalLine: (value) => value % _gridSpacing == 0,
              ),
              titlesData: FlTitlesData(
                show: _showGrid,
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: _gridSpacing,
                    getTitlesWidget: (value, meta) {
                      if (value % _gridSpacing != 0) return const Text('');
                      return Transform.translate(
                        offset: const Offset(
                            4, 0), // Move right labels left further
                        child: Transform.rotate(
                          angle: 0,
                          child: Text(
                            (-value).toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: _gridSpacing,
                    getTitlesWidget: (value, meta) {
                      if (value % _gridSpacing != 0) return const Text('');
                      return Transform.translate(
                        offset: const Offset(
                            0, 16), // Move bottom labels down further
                        child: Transform.rotate(
                          angle: -pi / 2,
                          child: Text(
                            (-value).toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              scatterTouchData: ScatterTouchData(
                enabled: true,
                handleBuiltInTouches: true,
              ),
            ),
          ),
          // Add scale indicator at bottom left
          Positioned(
            left: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Scale: ${(_viewMaxY - _viewMinY).toInt()}m',
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
          title: const Text('Set Grid Interval'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration:
                const InputDecoration(labelText: 'Grid Spacing (meters)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
