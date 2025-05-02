import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../application_layer/core/service_locator.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../../domain_layer/coordinates/point.dart';
import '../../core/dialogs/point_dialog.dart';
import 'dart:math';

class PlotCoordinatesView extends StatefulWidget {
  const PlotCoordinatesView({super.key});

  @override
  State<PlotCoordinatesView> createState() => _PlotCoordinatesViewState();
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

  // View state
  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;

  // Zoom constants
  static const double _minScale = 1.0;
  static const double _maxScale = 10000.0;
  static const double _zoomIncrement = 1.2;

  // Border constant - 25% of the range
  static const double _borderPercentage = 0.25;

  // Getters for view boundaries

  // Getters for view coordinates
  double get _viewMinX =>
      _minX +
      (_maxX - _minX - (_maxX - _minX) / _currentScale) / 2 -
      _currentOffset.dy;
  double get _viewMaxX =>
      _maxX -
      (_maxX - _minX - (_maxX - _minX) / _currentScale) / 2 -
      _currentOffset.dy;
  double get _viewMinY =>
      _minY +
      (_maxY - _minY - (_maxY - _minY) / _currentScale) / 2 -
      _currentOffset.dx;
  double get _viewMaxY =>
      _maxY -
      (_maxY - _minY - (_maxY - _minY) / _currentScale) / 2 -
      _currentOffset.dx;

  @override
  void initState() {
    super.initState();
    _jobService.points.addListener(_loadPoints);
    _loadPoints();
  }

  @override
  void dispose() {
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
    }
    setState(() {
      _points = points;
      _resetView();
    });
  }

  void _resetView() {
    setState(() {
      _currentScale = 1.0;
      _currentOffset = Offset.zero;
    });
  }

  void _zoomIn() {
    setState(() {
      final newScale =
          (_currentScale * _zoomIncrement).clamp(_minScale, _maxScale);
      if (newScale != _currentScale) {
        _currentScale = newScale;
        _constrainOffset();
      }
    });
  }

  void _zoomOut() {
    setState(() {
      final newScale =
          (_currentScale / _zoomIncrement).clamp(_minScale, _maxScale);
      if (newScale != _currentScale) {
        _currentScale = newScale;
        _constrainOffset();
      }
    });
  }

  void _constrainOffset() {
    final visibleRangeY = (_maxY - _minY) / _currentScale;
    final visibleRangeX = (_maxX - _minX) / _currentScale;
    final visibleRange = max(visibleRangeY, visibleRangeX);

    final maxOffsetY = (_maxY - _minY - visibleRange) / 2;
    final maxOffsetX = (_maxX - _minX - visibleRange) / 2;

    _currentOffset = Offset(_currentOffset.dx.clamp(-maxOffsetY, maxOffsetY),
        _currentOffset.dy.clamp(-maxOffsetX, maxOffsetX));
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (closest!.comment.isNotEmpty)
                  Text('Comment: ${closest.comment}'),
                Text('Y: ${closest.y.toStringAsFixed(3)}'),
                Text('X: ${closest.x.toStringAsFixed(3)}'),
                Text('Z: ${closest.z.toStringAsFixed(3)}'),
                if (closest.descriptor != null)
                  Text('Descriptor: ${closest.descriptor}'),
              ],
            ),
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
      dotPainter: FlDotCirclePainter(
        radius: 2,
        color: _pointColor,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.grid_on,
                    color: _showGrid ? Colors.white : Colors.grey),
                onPressed: () {
                  setState(() {
                    _showGrid = !_showGrid;
                  });
                },
                tooltip: 'Toggle Grid',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.color_lens, color: Colors.white),
                onPressed: () {
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
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${(_currentScale * 100).toInt()}%',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _currentScale < _maxScale ? _zoomIn : null,
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: _currentScale > _minScale ? _zoomOut : null,
            tooltip: 'Zoom Out',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plot Coordinates'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _resetView,
            tooltip: 'Reset View',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child: GestureDetector(
              onTapUp: (TapUpDetails details) {
                final RenderBox renderBox =
                    context.findRenderObject() as RenderBox;
                final Offset localPosition =
                    renderBox.globalToLocal(details.globalPosition);
                final size =
                    min(renderBox.size.width, renderBox.size.height) - 32.0;

                final y = _viewMaxY -
                    (localPosition.dx - 16.0) / size * (_viewMaxY - _viewMinY);
                final x = _viewMinX +
                    (localPosition.dy - 16.0) / size * (_viewMaxX - _viewMinX);

                _handleTap(y, x);
              },
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
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ScatterChart(
                                  ScatterChartData(
                                    scatterSpots: _visiblePoints
                                        .map((point) => _buildSpot(point))
                                        .toList(),
                                    minX: -_viewMaxY,
                                    maxX: -_viewMinY,
                                    minY: -_viewMaxX,
                                    maxY: -_viewMinX,
                                    backgroundColor: Colors.black,
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(
                                      show: _showGrid,
                                      getDrawingHorizontalLine: (value) =>
                                          FlLine(
                                        color: Colors.white30,
                                        strokeWidth: 0.5,
                                      ),
                                      getDrawingVerticalLine: (value) => FlLine(
                                        color: Colors.white30,
                                        strokeWidth: 0.5,
                                      ),
                                      checkToShowHorizontalLine: (value) =>
                                          value % _gridSpacing == 0,
                                      checkToShowVerticalLine: (value) =>
                                          value % _gridSpacing == 0,
                                    ),
                                    titlesData: FlTitlesData(
                                      show: _showGrid,
                                      topTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 50,
                                          interval: _gridSpacing,
                                          getTitlesWidget: (value, meta) {
                                            if (value % _gridSpacing != 0)
                                              return const Text('');
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
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          interval: _gridSpacing,
                                          getTitlesWidget: (value, meta) {
                                            if (value % _gridSpacing != 0)
                                              return const Text('');
                                            return Text(
                                              (-value).toInt().toString(),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 10,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    scatterTouchData: ScatterTouchData(
                                      enabled: true,
                                      handleBuiltInTouches: true,
                                    ),
                                  ),
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
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentColor = color;
            });
            widget.onColorChanged(color);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: _currentColor == color ? Colors.white : Colors.black,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
