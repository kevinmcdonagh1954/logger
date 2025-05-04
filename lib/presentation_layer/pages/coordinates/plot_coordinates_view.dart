import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../application_layer/core/service_locator.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../../domain_layer/coordinates/point.dart';
import '../../core/dialogs/point_dialog.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
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

  // View state
  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;

  // Zoom constants
  static const double _minScale = 0.1;
  static const double _maxScale = 10000.0;
  static const double _zoomIncrement = 1.2;

  // Border constant - 50% of the range for more padding
  static const double _borderPercentage = 0.5;

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
  RenderBox? _lastRenderBox;

  // Store the pending pan end screen position for post-frame recentering
  Offset? _pendingPanEndScreenPos;

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

  Offset? _debugPanStart;
  Offset? _debugPanEnd;
  Offset? _debugPlotStart;
  Offset? _debugPlotEnd;

  // Add fields to store pan start info
  Offset? _panStartScreen;
  Offset? _panStartPlotYX;
  double? _panStartViewMinY;
  double? _panStartViewMaxY;
  double? _panStartViewMinX;
  double? _panStartViewMaxX;

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
    _jobService.points.addListener(_loadPoints);
    _loadPoints();
  }

  @override
  void dispose() {
    _panTimer?.cancel();
    _jobService.points.removeListener(_loadPoints);
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

  Future<void> _editPoint(Point point) async {
    try {
      final updatedPoint = await PointDialog.showAddEditPointDialog(
        context: context,
        jobService: _jobService,
        coordinateFormat: 'YXZ',
        existingPoint: point,
        onSuccess: () {
          if (mounted) {
            _loadPoints();
          }
        },
      );

      if (updatedPoint != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Point updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildPointDetails(Point point) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showComment && point.comment.isNotEmpty)
          Text('Comment: ${point.comment}'),
        Text('Y: ${point.y.toStringAsFixed(3)}'),
        Text('X: ${point.x.toStringAsFixed(3)}'),
        if (_showZ) Text('Z: ${point.z.toStringAsFixed(3)}'),
        if (_showDescriptor && point.descriptor != null)
          Text('Descriptor: ${point.descriptor}'),
      ],
    );
  }

  Future<void> _handleTap(double y, double x) async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tapped Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Y: ${y.toStringAsFixed(3)}'),
              Text('X: ${x.toStringAsFixed(3)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Find Closest Point'),
            ),
          ],
        );
      },
    );

    if (proceed != true || !mounted) return;

    Point? closest;
    double minDistance = double.infinity;

    for (var point in _points) {
      final dy = point.y - y;
      final dx = point.x - x;
      final distance = dx * dx + dy * dy;

      if (distance < minDistance) {
        minDistance = distance;
        closest = point;
      }
    }

    if (!mounted) return;

    if (closest != null) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Found Point'),
            content: _buildPointDetails(closest!),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _editPoint(closest!);
                },
                child: const Text('Edit'),
              ),
            ],
          );
        },
      );
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
    return ScatterSpot(
      -point.y,
      -point.x,
      dotPainter: PointWithLabelsPainter(
        color: _pointColor,
        comment: point.comment,
        elevation: point.z.toStringAsFixed(3),
        showComment: _showComment,
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
    if (_isPanning) return;
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
    _handleTap(plotYX.dx, plotYX.dy);
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
                  case 'z':
                    _showZ = !_showZ;
                    break;
                  case 'descriptor':
                    _showDescriptor = !_showDescriptor;
                    break;
                  case 'grid_interval':
                    _showGridIntervalDialog();
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
                value: 'z',
                checked: _showZ,
                child: const Text('Show Z Values'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'descriptor',
                checked: _showDescriptor,
                child: const Text('Show Descriptors'),
              ),
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
                                        ? Center(
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
      child: ScatterChart(
        ScatterChartData(
          scatterSpots:
              _visiblePoints.map((point) => _buildSpot(point)).toList(),
          minX: -_viewMaxY,
          maxX: -_viewMinY,
          minY: -_viewMaxX,
          maxY: -_viewMinX,
          backgroundColor: Colors.black,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: _showGrid,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white30,
              strokeWidth: 0.5,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.white30,
              strokeWidth: 0.5,
            ),
            checkToShowHorizontalLine: (value) => value % _gridSpacing == 0,
            checkToShowVerticalLine: (value) => value % _gridSpacing == 0,
          ),
          titlesData: FlTitlesData(
            show: _showGrid,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: _gridSpacing,
                getTitlesWidget: (value, meta) {
                  if (value % _gridSpacing != 0) return const Text('');
                  return Transform.rotate(
                    angle: 0,
                    child: Text(
                      (-value).toInt().toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
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
                  return Transform.rotate(
                    angle: -pi / 2,
                    child: Text(
                      (-value).toInt().toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          scatterTouchData: ScatterTouchData(
            enabled: true,
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }

  void _showGridIntervalDialog() {
    final controller = TextEditingController(text: _gridSpacing.toString());
    showDialog(
      context: context,
      builder: (context) {
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
