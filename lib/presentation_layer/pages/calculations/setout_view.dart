import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../application_layer/core/service_locator.dart';
import '../../core/coordinate_formatter.dart';
import '../startup/home_page_view.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../../domain_layer/coordinates/point.dart';
import '../../core/dialogs/point_dialog.dart';
import '../../core/dropdowns/comment_dropdown.dart';
import '../../core/angle_validator.dart';
import 'dart:math';
import 'polar_view.dart';
import '../../core/angle_converter.dart';
import '../../l10n/app_localizations.dart';

class SetoutView extends StatefulWidget {
  final String jobName;
  const SetoutView({super.key, required this.jobName});

  @override
  State<SetoutView> createState() => _SetoutViewState();
}

class _SetoutViewState extends State<SetoutView> with RouteAware {
  late final JobService _jobService;
  String _coordinateFormat = 'YXZ'; // Default format
  String _angularMeasurement = 'degrees'; // Default format
  String _selectedPrecision = 'Meters'; // Default measurement units

  // Add these calculated values to the state
  Map<String, double> _calculatedCoords = {'Y': 0, 'X': 0, 'Z': 0};
  double _calculatedDistance = 0.000;
  double _calculatedDirection = 0.000;

  // Controllers for text fields
  final TextEditingController _setupPointNameController =
      TextEditingController();
  final TextEditingController _pointNameController = TextEditingController();
  final TextEditingController _slopeDistanceController =
      TextEditingController(text: "0.000");
  final TextEditingController _verticalAngleController =
      TextEditingController(text: "0.0000");
  final TextEditingController _horizontalAngleController =
      TextEditingController(text: "0.0000");
  final TextEditingController _targetHeightController =
      TextEditingController(text: "0.000");

  // Add focus nodes
  final FocusNode _setupPointNameFocus = FocusNode();
  final FocusNode _pointNameFocus = FocusNode();

  // Add search controller
  final TextEditingController _searchController = TextEditingController();

  // Add filtered points list
  List<Point> _filteredPoints = [];

  // Add state variables for coordinates
  Map<String, double> _setupPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
  Map<String, double> _pointCoords = {'Y': 0, 'X': 0, 'Z': 0};

  // Result variables
  double moveBack = 0.000;
  double moveRight = 0.000;
  double moveUp = 0.000;

  // Comment dropdown managers
  final LayerLink _setupPointLayerLink = LayerLink();
  final LayerLink _pointLayerLink = LayerLink();
  late CommentDropdown _setupPointDropdown;
  late CommentDropdown _pointDropdown;

  // Add focus nodes for input fields
  final FocusNode _slopeDistanceFocus = FocusNode();
  final FocusNode _verticalAngleFocus = FocusNode();
  final FocusNode _targetHeightFocus = FocusNode();
  final FocusNode _horizontalAngleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _jobService = locator<JobService>();
    _loadJobDefaults();

    // Initialize dropdown managers
    _setupPointDropdown = CommentDropdown(layerLink: _setupPointLayerLink);
    _pointDropdown = CommentDropdown(layerLink: _pointLayerLink);
  }

  Future<void> _loadJobDefaults() async {
    try {
      final defaults = await _jobService.getJobDefaults();
      if (!context.mounted) return;
      setState(() {
        _coordinateFormat = defaults?.coordinateFormat ?? 'YXZ';
        _angularMeasurement = defaults?.angularMeasurement ?? 'degrees';
        _selectedPrecision = defaults?.precision ?? 'Meters';
      });
    } catch (e) {
      debugPrint('Error loading job defaults: $e');
    }
  }

  @override
  void dispose() {
    // Dispose of controllers
    _setupPointNameController.dispose();
    _pointNameController.dispose();
    _slopeDistanceController.dispose();
    _verticalAngleController.dispose();
    _horizontalAngleController.dispose();
    _targetHeightController.dispose();
    _searchController.dispose();

    // Dispose of focus nodes
    _setupPointNameFocus.dispose();
    _pointNameFocus.dispose();
    _slopeDistanceFocus.dispose();
    _verticalAngleFocus.dispose();
    _targetHeightFocus.dispose();
    _horizontalAngleFocus.dispose();

    // Dispose of dropdowns
    _setupPointDropdown.dispose();
    _pointDropdown.dispose();

    super.dispose();
  }

  void _hideSearchResults() {
    _setupPointDropdown.hideDropdown();
    _pointDropdown.hideDropdown();
  }

  void _showSearchResults(
      String query, BuildContext context, bool isSetupPoint) {
    final dropdown = isSetupPoint ? _setupPointDropdown : _pointDropdown;
    dropdown.showDropdown(
      context: context,
      query: query,
      points: _jobService.points.value,
      onSelected: (point) {
        if (isSetupPoint) {
          _setupPointNameController.text = point.comment;
          _updateSetupPointCoordinates(point);
        } else {
          _pointNameController.text = point.comment;
          _updatePointCoordinates(point);
        }
      },
      isSelectable: true,
    );
  }

  void _updateSetupPointCoordinates(Point point) {
    setState(() {
      _setupPointCoords = {
        'Y': point.y,
        'X': point.x,
        'Z': point.z,
      };
    });
  }

  void _updatePointCoordinates(Point point) {
    setState(() {
      _pointCoords = {
        'Y': point.y,
        'X': point.x,
        'Z': point.z,
      };
    });
  }

  void _calculatePolarCoordinates() {
    if (_setupPointCoords['Y'] == 0 && _setupPointCoords['X'] == 0) {
      return; // No setup point selected
    }

    final slopeDistance = double.tryParse(_slopeDistanceController.text) ?? 0;
    double verticalAngle = double.tryParse(_verticalAngleController.text) ?? 0;
    var horizontalAngle = double.tryParse(_horizontalAngleController.text) ?? 0;
    final targetHeight = double.tryParse(_targetHeightController.text) ?? 0;

    if (slopeDistance == 0 || verticalAngle == 0) {
      return; // Invalid input values
    }

    // Use VerticalAngle class for calculation checks 0-180 and 270-360
    verticalAngle = VerticalAngle.calculateVerticalAngle(verticalAngle);

    // Decimalise horizontal angle (convert from D.MMSS to decimal degrees)
    final horizontalDegrees = horizontalAngle.floor();
    final minutesDecimal = (horizontalAngle - horizontalDegrees) * 100;
    final minutes = minutesDecimal.floor();
    final seconds = ((minutesDecimal - minutes) * 100).round();
    horizontalAngle = horizontalDegrees + minutes / 60 + seconds / 3600;

    // Convert angles to radians using AngleConverter
    final bool isGrads = _angularMeasurement == 'grads';
    final verticalRad = AngleConverter.toRadians(verticalAngle, isGrads);
    final horizontalRad = AngleConverter.toRadians(horizontalAngle, isGrads);

    // Calculate horizontal distance (reduced polar distance)
    final reducedPolarDistance = slopeDistance * cos(verticalRad);

    // Calculate height difference including target height
    final heightDiff = slopeDistance * sin(verticalRad) + targetHeight;

    // Calculate temporary point coordinates using measured angles
    final tempY =
        _setupPointCoords['Y']! + reducedPolarDistance * sin(horizontalRad);
    final tempX =
        _setupPointCoords['X']! + reducedPolarDistance * cos(horizontalRad);
    final tempZ = _setupPointCoords['Z']! + heightDiff;

    setState(() {
      _calculatedCoords = {
        'Y': tempY,
        'X': tempX,
        'Z': tempZ,
      };

      // Calculate distance and direction to target point
      if (_pointCoords['Y'] != 0 ||
          _pointCoords['X'] != 0 ||
          _pointCoords['Z'] != 0) {
        // Calculate vectors from setup point to target point
        final targetDeltaY = _pointCoords['Y']! - _setupPointCoords['Y']!;
        final targetDeltaX = _pointCoords['X']! - _setupPointCoords['X']!;

        // Calculate distances
        final leftOrRightDistance = reducedPolarDistance;
        final setOutDistance =
            sqrt(pow(targetDeltaY, 2) + pow(targetDeltaX, 2));

        // Calculate theoretical direction in radians and convert to degrees
        final theoreticalDirectionRad = atan2(targetDeltaY, targetDeltaX);
        var theoreticalDirection = theoreticalDirectionRad * 180 / pi;
        if (theoreticalDirection < 0) {
          theoreticalDirection += 360;
        }

        // Calculate angle difference using decimalised angles
        var angleDiff = theoreticalDirection - horizontalAngle;

        // Normalize angle to -180 to 180 degrees
        while (angleDiff > 180) {
          angleDiff -= 360;
        }
        while (angleDiff < -180) {
          angleDiff += 360;
        }

        // Convert angle difference to radians for tan calculation
        final angleDiffRad = angleDiff * pi / 180;

        // Calculate move distances
        moveBack = reducedPolarDistance - setOutDistance;
        moveRight = leftOrRightDistance * tan(angleDiffRad);
        moveUp = tempZ - _pointCoords['Z']!;

        // Set calculated distance and direction for display
        _calculatedDistance = reducedPolarDistance;
        _calculatedDirection = theoreticalDirection;
      } else {
        moveBack = 0.0;
        moveRight = 0.0;
        moveUp = 0.0;
        _calculatedDistance = reducedPolarDistance;
        _calculatedDirection = 0.0;
      }
    });
  }

  Widget _buildCalculatedResults() {
    if (_calculatedDistance == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calculated Position:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCoordDisplay(
                CoordinateFormatter.getCoordinateLabel('Y', _coordinateFormat),
                _calculatedCoords['Y']!),
            _buildCoordDisplay(
                CoordinateFormatter.getCoordinateLabel('X', _coordinateFormat),
                _calculatedCoords['X']!),
            _buildCoordDisplay(
                CoordinateFormatter.getCoordinateLabel('Z', _coordinateFormat),
                _calculatedCoords['Z']!),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCoordDisplay(
                'Dist (${_selectedPrecision == 'Meters' ? 'm' : 'Ft'})',
                _calculatedDistance),
            _buildCoordDisplay(
                'Dirn (${_angularMeasurement == 'degrees' ? '°' : 'g'})',
                _calculatedDirection),
          ],
        ),
      ],
    );
  }

  Widget _buildCoordDisplay(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          value.toStringAsFixed(3),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSetupPointInputRow() {
    return Row(
      children: [
        const SizedBox(
          width: 80,
          child:
              Text('Setup At', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        CompositedTransformTarget(
          link: _setupPointLayerLink,
          child: SizedBox(
            width: 160,
            height: 36,
            child: TextField(
              controller: _setupPointNameController,
              focusNode: _setupPointNameFocus,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Point Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
              onChanged: (value) {
                _showSearchResults(value, context, true);
              },
              onTap: () {
                if (_setupPointNameController.text.isNotEmpty) {
                  _showSearchResults(
                      _setupPointNameController.text, context, true);
                }
              },
              onSubmitted: (_) {
                _hideSearchResults();
                FocusScope.of(context).nextFocus();
              },
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            _setupPointNameController.clear();
            setState(() {
              _setupPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
            });
            _hideSearchResults();
          },
        ),
        PopupMenuButton<String>(
          tooltip: 'Options',
          icon: const Icon(Icons.more_vert),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'values',
              child: Row(
                children: [
                  const Icon(Icons.grid_on, size: 20),
                  const SizedBox(width: 8),
                  Text('${_coordinateFormat == 'YXZ' ? 'YXZ' : 'ENZ'} Values'),
                ],
              ),
            ),
          ],
          onSelected: (String value) {
            if (value == 'values') {
              _showSetupValuesDialog();
            }
          },
        ),
      ],
    );
  }

  Future<void> _showSetupValuesDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '${_coordinateFormat == 'YXZ' ? 'YXZ' : 'ENZ'} Values',
            style: const TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildValueRow(
                _coordinateFormat == 'YXZ' ? 'Y' : 'E',
                _setupPointCoords['Y']!,
              ),
              const SizedBox(height: 8),
              _buildValueRow(
                _coordinateFormat == 'YXZ' ? 'X' : 'N',
                _setupPointCoords['X']!,
              ),
              const SizedBox(height: 8),
              _buildValueRow('Z', _setupPointCoords['Z']!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildValueRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          value.toStringAsFixed(3),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPointInputRow() {
    return Row(
      children: [
        const SizedBox(
          width: 80,
          child: Text('Setout', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        CompositedTransformTarget(
          link: _pointLayerLink,
          child: SizedBox(
            width: 150,
            height: 36,
            child: TextField(
              controller: _pointNameController,
              focusNode: _pointNameFocus,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Point Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
              onChanged: (value) {
                _showSearchResults(value, context, false);
              },
              onTap: () {
                if (_pointNameController.text.isNotEmpty) {
                  _showSearchResults(_pointNameController.text, context, false);
                }
              },
              onSubmitted: (_) {
                _hideSearchResults();
                FocusScope.of(context).nextFocus();
              },
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            _pointNameController.clear();
            setState(() {
              _pointCoords = {'Y': 0, 'X': 0, 'Z': 0};
            });
            _hideSearchResults();
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search, size: 20),
                  SizedBox(width: 8),
                  Text('Search Point'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'add',
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Add Point'),
                ],
              ),
            ),
          ],
          onSelected: (String value) {
            switch (value) {
              case 'search':
                _showSearchDialog(true);
                break;
              case 'add':
                _showPointDialog(true);
                break;
            }
          },
        ),
      ],
    );
  }

  Widget _buildCoordinatesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Y coordinate
        Expanded(
          child: Column(
            children: [
              Text(
                CoordinateFormatter.getCoordinateLabel('Y', _coordinateFormat),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _pointCoords['Y']!.toStringAsFixed(3),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),

        // X coordinate
        Expanded(
          child: Column(
            children: [
              Text(
                CoordinateFormatter.getCoordinateLabel('X', _coordinateFormat),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _pointCoords['X']!.toStringAsFixed(3),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),

        // Z coordinate
        Expanded(
          child: Column(
            children: [
              Text(
                CoordinateFormatter.getCoordinateLabel('Z', _coordinateFormat),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _pointCoords['Z']!.toStringAsFixed(3),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow(
    String label,
    TextEditingController controller,
    bool isAngle, {
    bool allowNegative = false,
  }) {
    // Determine which focus node to use
    final FocusNode focusNode = switch (label) {
      'Slope Distance (m)' => _slopeDistanceFocus,
      'Vertical Angle' => _verticalAngleFocus,
      'Target Height (m)' => _targetHeightFocus,
      'Horizontal Angle' => _horizontalAngleFocus,
      _ => FocusNode(),
    };

    // Get validation color
    Color? getValidationColor() {
      if (label == 'Target Height (m)' || label == 'Horizontal Angle') {
        return null;
      }

      final value = double.tryParse(controller.text) ?? 0;
      return value == 0 ? Colors.red[100] : null;
    }

    // Format the label based on type
    String getFormattedLabel() {
      if (label.startsWith('Slope Distance') ||
          label.startsWith('Target Height')) {
        return '${label.split(' ')[0]} ${label.split(' ')[1]} (${_selectedPrecision == 'Meters' ? 'm' : 'Ft'})';
      } else if (isAngle) {
        return '${label.split(' ')[0]} ${label.split(' ')[1]} (${_angularMeasurement == 'degrees' ? '°' : 'g'})';
      }
      return label;
    }

    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            getFormattedLabel(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 100,
          height: 36,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            onTap: () {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            },
            onSubmitted: (_) {
              FocusScope.of(context).nextFocus();
            },
            onChanged: (value) {
              setState(() {}); // Trigger rebuild to update colors
              if (label == 'Slope Distance (m)' && value.isNotEmpty) {
                final distance = double.tryParse(value);
                if (distance == 0) {
                  final currentContext = context;
                  if (!currentContext.mounted) return;
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Slope Distance cannot be zero'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else if (label == 'Vertical Angle' && value.isNotEmpty) {
                final angle = double.tryParse(value);
                if (angle == 0) {
                  final currentContext = context;
                  if (!currentContext.mounted) return;
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Vertical Angle cannot be zero'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
              _calculatePolarCoordinates(); // Calculate new values when input changes
            },
            inputFormatters: [
              if (isAngle)
                AngleValidator()
              else
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) return newValue;

                  // Handle negative sign
                  if (newValue.text == '-') {
                    return allowNegative ? newValue : oldValue;
                  }

                  // Only allow one decimal point
                  if (newValue.text.contains('.') &&
                      newValue.text.indexOf('.') !=
                          newValue.text.lastIndexOf('.')) {
                    return oldValue;
                  }

                  // Validate the number format
                  try {
                    final number = double.parse(newValue.text);
                    if (!allowNegative && number < 0) return oldValue;
                    return newValue;
                  } catch (e) {
                    return oldValue;
                  }
                }),
            ],
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              isDense: true,
              filled: true,
              fillColor: getValidationColor(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showSearchDialog(bool isStartPoint) async {
    _hideSearchResults();
    _searchController.clear();
    _filteredPoints = _jobService.points.value;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Search ${isStartPoint ? 'First' : 'Second'} Point'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by ID or comment',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            _filteredPoints = _jobService.points.value;
                          } else {
                            _filteredPoints =
                                _jobService.points.value.where((point) {
                              return point.id.toString().contains(value) ||
                                  (point.comment
                                      .toLowerCase()
                                      .contains(value.toLowerCase()));
                            }).toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: _filteredPoints.length,
                        itemBuilder: (context, index) {
                          final point = _filteredPoints[index];
                          return ListTile(
                            title: Text(point.comment),
                            subtitle: Text(
                                'Y: ${point.y.toStringAsFixed(3)}, X: ${point.x.toStringAsFixed(3)}, Z: ${point.z.toStringAsFixed(3)}'),
                            onTap: () {
                              if (isStartPoint) {
                                _setupPointNameController.text = point.comment;
                                _updateSetupPointCoordinates(point);
                              } else {
                                _pointNameController.text = point.comment;
                                _updatePointCoordinates(point);
                              }
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showPointDialog(bool isFirstPoint) async {
    _hideSearchResults();

    final existingText = _pointNameController.text;

    try {
      final point = await PointDialog.showAddEditPointDialog(
        context: context,
        jobService: _jobService,
        coordinateFormat: _coordinateFormat,
        allowUseWithoutSaving: true,
        initialComment: existingText.isNotEmpty ? existingText : null,
        onSuccess: () {
          if (mounted) {
            setState(() {});
          }
        },
      );

      if (point != null && mounted) {
        setState(() {
          _pointNameController.text = point.comment;
          _updatePointCoordinates(point);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildResultRow(String label, double value) {
    String displayLabel;
    final l10n = AppLocalizations.of(context);

    if (label.startsWith('Move Back')) {
      displayLabel = value > 0 ? l10n!.moveForward : l10n!.moveBack;
    } else if (label.startsWith('Move Right')) {
      if (value.abs().toStringAsFixed(3) == '0.000') {
        displayLabel = l10n!.onLine;
      } else {
        displayLabel = value > 0 ? l10n!.moveRight : l10n!.moveLeft;
      }
    } else if (label.startsWith('Move Up')) {
      displayLabel = value > 0 ? l10n!.moveDown : l10n!.moveUp;
    } else {
      displayLabel = label;
    }

    // Add units unless it's "On Line"
    if (!(label.startsWith('Move Right') &&
        value.abs().toStringAsFixed(3) == '0.000')) {
      displayLabel += ' (${_selectedPrecision == 'Meters' ? 'm' : 'Ft'})';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(displayLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value.abs().toStringAsFixed(3)),
      ],
    );
  }

  Widget _buildNavButton(String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {
        if (label == 'Quit') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      },
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        return false;
      },
      child: GestureDetector(
        onTap: _hideSearchResults,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomePage()),
              ),
            ),
            title: Text(AppLocalizations.of(context)!.setout),
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Setup Point Input Row
                _buildSetupPointInputRow(),
                const SizedBox(height: 24),
                const Divider(),

                // Point Input Row
                _buildPointInputRow(),
                const SizedBox(height: 16),
                // Coordinates display
                _buildCoordinatesRow(),
                const SizedBox(height: 24),
                const Divider(),

                // Input Fields Section
                _buildInputRow(
                  'Slope Distance (m)',
                  _slopeDistanceController,
                  false,
                  allowNegative: false,
                ),
                const SizedBox(height: 8),
                _buildInputRow(
                  'Vertical Angle',
                  _verticalAngleController,
                  true,
                  allowNegative: false,
                ),
                const SizedBox(height: 8),
                _buildInputRow(
                  'Target Height (m)',
                  _targetHeightController,
                  false,
                  allowNegative: true,
                ),
                const SizedBox(height: 8),
                _buildInputRow(
                  'Horizontal Angle',
                  _horizontalAngleController,
                  true,
                  allowNegative: false,
                ),
                const SizedBox(height: 10),
                const Divider(),

                // Calculated Results Section
                _buildCalculatedResults(),
                const SizedBox(height: 16),
                const Divider(),

                // Results Section with compact layout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResultRow('Move Back ', moveBack),
                      const SizedBox(height: 8),
                      _buildResultRow('Move Right ', moveRight),
                      const SizedBox(height: 8),
                      _buildResultRow('Move Up ', moveUp),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Bottom Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNavButton('Quit'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
