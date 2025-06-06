import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../../application_layer/core/service_locator.dart';
import '../../core/coordinate_formatter.dart';
import '../startup/home_page_view.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../../domain_layer/coordinates/point.dart';
import '../../core/angle_validator.dart';
import '../../core/dialogs/point_dialog.dart';
import '../../core/dropdowns/comment_dropdown.dart';
import '../../core/bearing_formatter.dart';
import '../../core/bearing_format.dart';
import '../../core/angle_converter.dart';
import '../../../domain_layer/calculations/slope_calculator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../jobs/jobs_viewmodel.dart';
import '../../core/vertical_angle.dart';

class PolarView extends StatefulWidget {
  final String jobName;
  const PolarView({super.key, required this.jobName});

  @override
  State<PolarView> createState() => _PolarViewState();
}

class _PolarViewState extends State<PolarView> with RouteAware {
  late final JobService _jobService;
  String _coordinateFormat = 'YXZ'; // Default format
  String _selectedPrecision = 'Meters'; // Default measurement units
// Default to DMS, will be updated from job defaults
  double _scaleFactor = 1.0; // Default scale factor
  bool _useCurvatureAndRefraction = false; // Default to off

  // Controllers for text fields
  final TextEditingController _firstPointController = TextEditingController();
  final TextEditingController _nextPointController = TextEditingController();
  final TextEditingController _slopeDistanceController =
      TextEditingController(text: "0.000");
  final TextEditingController _verticalAngleController =
      TextEditingController(text: "0.0000");
  final TextEditingController _targetHeightController =
      TextEditingController(text: "0.000");
  final TextEditingController _instrumentHeightController =
      TextEditingController(text: "0.000");
  final TextEditingController _horizontalAngleController =
      TextEditingController(text: "0.0000");

  // Controllers for first point coordinates
  final TextEditingController _firstPointYController = TextEditingController();
  final TextEditingController _firstPointXController = TextEditingController();
  final TextEditingController _firstPointZController = TextEditingController();

  // Controllers for second point coordinates
  final TextEditingController _secondPointYController = TextEditingController();
  final TextEditingController _secondPointXController = TextEditingController();
  final TextEditingController _secondPointZController = TextEditingController();

  // Add search controller
  final TextEditingController _searchController = TextEditingController();

  // Add filtered points list
  List<Point> _filteredPoints = [];

  // Add state variables for coordinates
  Map<String, double> _firstPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
  Map<String, double> _secondPointCoords = {'Y': 0, 'X': 0, 'Z': 0};

  // Result variables
  double slopeAngle = 0.0;
  double gradeI = 0.0;
  double gradePercent = 0.0;

  // Add focus nodes
  final FocusNode _firstPointFocus = FocusNode();
  final FocusNode _nextPointFocus = FocusNode();

  // Comment dropdown managers
  final LayerLink _firstPointLayerLink = LayerLink();
  final LayerLink _nextPointLayerLink = LayerLink();
  late CommentDropdown _firstPointDropdown;
  late CommentDropdown _nextPointDropdown;

  // Add focus nodes for input fields
  final FocusNode _slopeDistanceFocus = FocusNode();
  final FocusNode _verticalAngleFocus = FocusNode();
  final FocusNode _targetHeightFocus = FocusNode();
  final FocusNode _instrumentHeightFocus = FocusNode();
  final FocusNode _horizontalAngleFocus = FocusNode();

  // Add state variable for up arrow visibility
  bool _showUpArrow = false;

  // Add bearing format state for angle formatting
  BearingFormat _selectedAngleFormat = BearingFormat.dmsSymbols;
  String angle = "0° 00' 00\""; // Add formatted angle string

  @override
  void initState() {
    super.initState();
    _jobService = locator<JobService>();
    _loadJobDefaultsFor(widget.jobName);

    // Initialize second point coordinates as empty
    _secondPointYController.text = "";
    _secondPointXController.text = "";
    _secondPointZController.text = "";

    // Initialize dropdown managers
    _firstPointDropdown = CommentDropdown(layerLink: _firstPointLayerLink);
    _nextPointDropdown = CommentDropdown(layerLink: _nextPointLayerLink);

    // Listen for job changes
    locator<JobsViewModel>().currentJobName.addListener(_onJobChanged);
  }

  void _onJobChanged() {
    final newJobName = locator<JobsViewModel>().currentJobName.value;
    if (newJobName != null && newJobName != widget.jobName) {
      _loadJobDefaultsFor(newJobName);
    }
  }

  Future<void> _loadJobDefaultsFor(String jobName) async {
    try {
      final defaults = await _jobService.getJobDefaults();
      if (!context.mounted) return;
      setState(() {
        _coordinateFormat = defaults?.coordinateFormat ?? 'YXZ';
        _selectedPrecision = defaults?.precision ?? 'Meters';
        _scaleFactor = double.tryParse(defaults?.scaleFactor ?? '1') ?? 1.0;
      });
    } catch (e) {
      debugPrint('Error loading job defaults: $e');
    }
  }

  @override
  void dispose() {
    // Dispose of dropdowns
    _firstPointDropdown.dispose();
    _nextPointDropdown.dispose();

    // Remove job change listener
    locator<JobsViewModel>().currentJobName.removeListener(_onJobChanged);

    // Dispose of controllers
    _firstPointController.dispose();
    _nextPointController.dispose();
    _slopeDistanceController.dispose();
    _verticalAngleController.dispose();
    _targetHeightController.dispose();
    _instrumentHeightController.dispose();
    _horizontalAngleController.dispose();
    _firstPointYController.dispose();
    _firstPointXController.dispose();
    _firstPointZController.dispose();
    _secondPointYController.dispose();
    _secondPointXController.dispose();
    _secondPointZController.dispose();
    _searchController.dispose();

    // Dispose of focus nodes
    _firstPointFocus.dispose();
    _nextPointFocus.dispose();
    _slopeDistanceFocus.dispose();
    _verticalAngleFocus.dispose();
    _targetHeightFocus.dispose();
    _instrumentHeightFocus.dispose();
    _horizontalAngleFocus.dispose();

    super.dispose();
  }

  void _updatePointCoordinates(Point point, bool isFirstPoint) {
    if (!mounted) return;
    setState(() {
      if (isFirstPoint) {
        _firstPointCoords = {
          'Y': point.y,
          'X': point.x,
          'Z': point.z,
        };
        // When first point changes, recalculate second point using current input values
        if (_isInputValid()) {
          _calculateSecondPoint();
        } else {
          // If inputs aren't valid, reset second point
          _secondPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
          _showUpArrow = false;
        }
      } else {
        _secondPointCoords = {
          'Y': point.y,
          'X': point.x,
          'Z': point.z,
        };
        // Only show up arrow if coordinates are non-zero and point name is valid
        _showUpArrow = _hasValidCoordinates() && _hasValidPointName();
      }
    });
  }

  Widget _buildCoordinatesRow(bool isFirstPoint) {
    final coords = isFirstPoint ? _firstPointCoords : _secondPointCoords;

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
                coords['Y']!.toStringAsFixed(3),
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
                coords['X']!.toStringAsFixed(3),
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
                coords['Z']!.toStringAsFixed(3),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSearchResults(
      String query, bool isFirstPoint, BuildContext context) {
    // Hide both dropdowns first to avoid potential conflicts
    if (isFirstPoint) {
      _nextPointDropdown.hideDropdown();
      _firstPointDropdown.showDropdown(
        context: context,
        query: query,
        points: _jobService.points.value,
        onSelected: (point) {
          _firstPointController.text = point.comment;
          _updatePointCoordinates(point, true);
          _calculateSecondPoint(); // Recalculate when point is selected from dropdown
        },
        isSelectable: true,
      );
    } else {
      _firstPointDropdown.hideDropdown();
      // Show dropdown for reference only, with disabled selection
      _nextPointDropdown.showDropdown(
        context: context,
        query: query,
        points: _jobService.points.value,
        onSelected: (_) {}, // Empty function as selection is not allowed
        isSelectable: false, // Explicitly mark as not selectable
      );
    }
  }

  void _hideSearchResults() {
    _firstPointDropdown.hideDropdown();
    _nextPointDropdown.hideDropdown();
  }

  Future<void> _showSearchDialog(bool isStartPoint) async {
    // Hide all dropdowns before showing dialog
    _hideSearchResults();

    _searchController.clear();
    _filteredPoints = _jobService.points.value;

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.searchFirstPoint),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchByIdOrComment,
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
                    const SizedBox(height: 10),
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredPoints.length,
                          itemBuilder: (context, index) {
                            final point = _filteredPoints[index];
                            return ListTile(
                              title: Text('Point ${point.id}'),
                              subtitle: Text(point.comment),
                              onTap: () {
                                if (isStartPoint) {
                                  _firstPointController.text = point.comment;
                                  _updatePointCoordinates(point, true);
                                  _calculateSecondPoint(); // Recalculate when point is selected from dialog
                                } else {
                                  _nextPointController.text = point.comment;
                                  _updatePointCoordinates(point, false);
                                }
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddPointDialog(
      BuildContext context, bool isFirstPoint) async {
    // Hide all dropdowns before showing dialog
    _hideSearchResults();

    // Get the existing text from the appropriate controller
    final existingText =
        isFirstPoint ? _firstPointController.text : _nextPointController.text;

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
          if (isFirstPoint) {
            _firstPointController.text = point.comment;
            _updatePointCoordinates(point, true);
            _calculateSecondPoint(); // Recalculate when new point is added
          } else {
            _nextPointController.text = point.comment;
            _updatePointCoordinates(point, false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final currentContext = context;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // Add method to validate input fields
  bool _isInputValid() {
    final slopeDistance = double.tryParse(_slopeDistanceController.text) ?? 0;
    final verticalAngle = double.tryParse(_verticalAngleController.text) ?? 0;

    return slopeDistance > 0 && verticalAngle > 0;
  }

  // Add method to check if coordinates are valid for showing up arrow
  bool _hasValidCoordinates() {
    return _secondPointCoords['Y'] != 0 || _secondPointCoords['X'] != 0;
  }

  bool _hasValidPointName() {
    return _nextPointController.text.isNotEmpty &&
        _nextPointController.text.toLowerCase() != 'next point';
  }

  // Add method to calculate second point coordinates
  Future<void> _calculateSecondPoint() async {
    if (!mounted) return;
    if (!_isInputValid()) return;

    try {
      final slopeDistance = double.parse(_slopeDistanceController.text);
      var verticalDecimal =
          AngleValidator.parseFromDMS(_verticalAngleController.text) ?? 0.0;
      final horizontalDecimal =
          AngleValidator.parseFromDMS(_horizontalAngleController.text) ?? 0.0;
      final targetHeight = double.parse(_targetHeightController.text);

      // If vertical angle is 0, assume 90° (level)
      if (verticalDecimal == 0) {
        verticalDecimal = 90.0;
      }

      // Constants
      const double earthRadius = 6370000.0; // Earth radius in meters
      const double refractiveCoeff = 0.87; // Refractive coefficient

      // Calculate corrected vertical angle using the VerticalAngle class
      final correctedVerticalAngle =
          VerticalAngle.calculateVerticalAngle(verticalDecimal);

      // Convert corrected vertical angle to radians
      final verticalRad = correctedVerticalAngle * (pi / 180);
      final planDistance =
          (slopeDistance * cos(verticalRad)).abs() * _scaleFactor;
      final heightDifference = (slopeDistance * cos(verticalRad)).abs();

      // Calculate height difference with optional curvature and refraction
      final heightDiff = heightDifference * tan(verticalRad) +
          (_useCurvatureAndRefraction
              ? (heightDifference * heightDifference) *
                  (refractiveCoeff / (2 * earthRadius))
              : 0) +
          0 -
          targetHeight; // Htinst (instrument height) is 0

      // Calculate horizontal angle in radians
      final horizontalRad = horizontalDecimal * (pi / 180);

      // Calculate Y2 and X2 using plan distance
      final y2 = _firstPointCoords['Y']! + sin(horizontalRad) * planDistance;
      final x2 = _firstPointCoords['X']! + cos(horizontalRad) * planDistance;

      if (!mounted) return;
      setState(() {
        _secondPointCoords = {
          'Y': y2,
          'X': x2,
          'Z': _firstPointCoords['Z']! + heightDiff,
        };

        // Only show up arrow if we have valid coordinates and point name
        _showUpArrow = _hasValidCoordinates() && _hasValidPointName();

        // Calculate slope results
        if (planDistance != 0) {
          // Use SlopeCalculator for consistent calculations
          final slopeResults = SlopeCalculator.calculate(
            distance: planDistance,
            z1: _firstPointCoords['Z']!,
            z2: _secondPointCoords['Z']!,
          );

          // Update state with calculated values
          gradeI = double.parse(slopeResults['grade']!);
          gradePercent = double.parse(slopeResults['gradePercent']!);
          slopeAngle = double.parse(slopeResults['angle']!);

          // Update the displayed angle format immediately
          angle =
              BearingFormatter.format(slopeAngle.abs(), _selectedAngleFormat);
        } else {
          final defaultValues = SlopeCalculator.getDefaultValues();
          slopeAngle = double.parse(defaultValues['angle']!);
          gradeI = double.parse(defaultValues['grade']!);
          gradePercent = double.parse(defaultValues['gradePercent']!);
          angle = BearingFormatter.format(0, _selectedAngleFormat);
        }
      });
    } catch (e) {
      debugPrint('Error calculating second point: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error in calculations'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 1000),
        ),
      );
    }
  }

  // Add method to swap points
  void _swapPoints() {
    if (!mounted) return;
    setState(() {
      // Swap coordinates
      _firstPointCoords = _secondPointCoords;
      _secondPointCoords = {'Y': 0, 'X': 0, 'Z': 0};

      // Swap comments
      _firstPointController.text = _nextPointController.text;
      _nextPointController.text = '';

      // Hide up arrow
      _showUpArrow = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
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
            title: Text(l10n.polar),
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          body: Container(
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPointInputRow(true),
                    const SizedBox(height: 10),
                    _buildCoordinatesRow(true),
                    const SizedBox(height: 10),
                    _buildInputRow(
                      _selectedPrecision == 'Meters'
                          ? l10n.instrumentHeightWithUnitMeters
                          : l10n.instrumentHeightWithUnitFeet,
                      _instrumentHeightController,
                      false,
                      allowNegative: false,
                      l10n: l10n,
                      hint: l10n.instrumentHeightHint,
                    ),
                    const Divider(height: 20),
                    _buildPointInputRow(false),
                    const SizedBox(height: 10),
                    _buildCoordinatesRow(false),
                    const SizedBox(height: 10),
                    _buildInputRow(
                      l10n.slopeDistanceWithUnit,
                      _slopeDistanceController,
                      false,
                      allowNegative: false,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 8),
                    _buildInputRow(
                      l10n.verticalAngle,
                      _verticalAngleController,
                      true,
                      allowNegative: false,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 8),
                    _buildInputRow(
                      l10n.targetHeightWithUnit,
                      _targetHeightController,
                      false,
                      allowNegative: true,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 8),
                    _buildInputRow(
                      l10n.horizontalAngle,
                      _horizontalAngleController,
                      true,
                      allowNegative: false,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _useCurvatureAndRefraction,
                          onChanged: (bool? value) {
                            if (!mounted) return;
                            setState(() {
                              _useCurvatureAndRefraction = value ?? false;
                              _calculateSecondPoint();
                            });
                          },
                        ),
                        Text(l10n.useCurvatureAndRefraction,
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    const Divider(),
                    _buildResultRow(l10n.gradeSlope, gradeI.toStringAsFixed(3)),
                    const SizedBox(height: 8),
                    _buildResultRow(l10n.gradeSlopePercent,
                        gradePercent.toStringAsFixed(3)),
                    const SizedBox(height: 8),
                    _buildSlopeAngleRow(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNavButton(l10n.quit),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow(
    String label,
    TextEditingController controller,
    bool isAngle, {
    bool allowNegative = false,
    required AppLocalizations l10n,
    String? hint,
  }) {
    // Determine which focus node to use
    final FocusNode focusNode = switch (label) {
      'Slope Distance (m)' => _slopeDistanceFocus,
      'Vertical Angle' => _verticalAngleFocus,
      'Target Height (m)' => _targetHeightFocus,
      'Horizontal Angle' => _horizontalAngleFocus,
      _ => FocusNode(),
    };

    String displayLabel = label;
    if (label.contains('(m)') || label.contains('(Ft)')) {
      displayLabel = label;
    }

    final bool disabled = !_areBothPointsValid();

    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Tooltip(
            message: hint ?? '',
            child: Text(
              displayLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 0),
        SizedBox(
          width: 100,
          height: 30,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !disabled,
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
              if (controller.text.isEmpty) {
                controller.text = "0.000";
              }
              FocusScope.of(context).nextFocus();
              if (label == l10n.horizontalAngle) {
                setState(() {}); // Only update results for horizontal angle
              }
            },
            onChanged: (value) {
              if (!mounted) return;
              if (label == l10n.horizontalAngle) {
                setState(() {}); // Only update results for horizontal angle
              }
              if (label == l10n.slopeDistanceWithUnit && value.isNotEmpty) {
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
              } else if (label == l10n.verticalAngle && value.isNotEmpty) {
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
            },
            inputFormatters: [
              if (isAngle)
                AngleValidator()
              else
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) return newValue;
                  if (newValue.text == '-') {
                    return allowNegative ? newValue : oldValue;
                  }
                  if (newValue.text.contains('.') &&
                      newValue.text.indexOf('.') !=
                          newValue.text.lastIndexOf('.')) {
                    return oldValue;
                  }
                  try {
                    final number = double.parse(newValue.text);
                    if (!allowNegative && number < 0) return oldValue;
                    return newValue;
                  } catch (e) {
                    return oldValue;
                  }
                }),
            ],
            style: TextStyle(
                fontSize: 14, color: disabled ? Colors.red : Colors.black),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              isDense: true,
              filled: true,
              fillColor: disabled ? Colors.red.withAlpha(26) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, dynamic value) {
    String displayValue;
    if (value is double) {
      displayValue = value.toStringAsFixed(3);
    } else {
      displayValue = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(displayValue),
        ],
      ),
    );
  }

  Widget _buildSlopeAngleRow() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.slopeAngle,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              // Only show format dropdown if not in Grads mode
              if (AngleConverter.gradsFactor == 1.0) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: 120, // Fixed narrow width
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(254, 247, 255, 1.0),
                      border: Border(
                        bottom:
                            BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                    ),
                    child: DropdownButton<BearingFormat>(
                      value: _selectedAngleFormat,
                      isDense: true,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.black54),
                      items: _buildAngleFormatItems(),
                      onChanged: (BearingFormat? newFormat) {
                        if (newFormat != null) {
                          setState(() {
                            _selectedAngleFormat = newFormat;
                            _updateAngleFormat();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(angle),
        ],
      ),
    );
  }

  List<DropdownMenuItem<BearingFormat>> _buildAngleFormatItems() {
    return [
      DropdownMenuItem(
        value: BearingFormat.dms,
        child: Text(
          'D.M.S (${BearingFormatter.format(slopeAngle.abs(), BearingFormat.dms)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsCompact,
        child: Text(
          'D.MS (${BearingFormatter.format(slopeAngle.abs(), BearingFormat.dmsCompact)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dm,
        child: Text(
          'D.M (${BearingFormatter.format(slopeAngle.abs(), BearingFormat.dm)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsNoSeparator,
        child: Text(
          'DMS (${BearingFormatter.format(slopeAngle.abs(), BearingFormat.dmsNoSeparator)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsSymbols,
        child: Text(
          'D M S (${BearingFormatter.format(slopeAngle.abs(), BearingFormat.dmsSymbols)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsSymbolsCompact,
        child: Text(
          'DMS (${BearingFormatter.format(slopeAngle.abs(), BearingFormat.dmsSymbolsCompact)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    ];
  }

  void _updateAngleFormat() {
    if (!mounted) return;
    setState(() {
      String sign = slopeAngle < 0 ? '-' : '';
      angle = sign +
          BearingFormatter.format(slopeAngle.abs(), _selectedAngleFormat);
    });
  }

  Widget _buildNavButton(String label) {
    final l10n = AppLocalizations.of(context)!;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {
        if (label == l10n.quit) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      },
      child: Text(label),
    );
  }

  Widget _buildPointInputRow(bool isFirstPoint) {
    final l10n = AppLocalizations.of(context)!;
    final controller =
        isFirstPoint ? _firstPointController : _nextPointController;
    final focusNode = isFirstPoint ? _firstPointFocus : _nextPointFocus;
    final layerLink = isFirstPoint ? _firstPointLayerLink : _nextPointLayerLink;
    final label = isFirstPoint ? l10n.firstPoint : l10n.secondPoint;
    final hintText = isFirstPoint ? l10n.firstPointHint : l10n.nextPointHint;

    // Add validation color for second point
    Color? getBorderColor() {
      if (isFirstPoint) return null;

      // Empty input or "Next Point" is invalid
      if (!_hasValidPointName()) return Colors.red[100];

      // Check if point name exists in points list
      bool isDuplicate = _jobService.points.value.any((point) =>
          point.comment.toLowerCase() == controller.text.toLowerCase());

      return isDuplicate ? Colors.red[100] : Colors.green[100];
    }

    return Row(
      children: [
        SizedBox(
          width: 80,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        CompositedTransformTarget(
          link: layerLink,
          child: SizedBox(
            width: 160,
            height: 36,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: !isFirstPoint,
                fillColor: getBorderColor(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
              onChanged: (value) {
                if (isFirstPoint) {
                  // When first point changes, find the point and update coordinates
                  final point = _jobService.points.value.firstWhere(
                    (p) => p.comment.toLowerCase() == value.toLowerCase(),
                    orElse: () =>
                        const Point(id: 0, comment: '', y: 0, x: 0, z: 0),
                  );
                  _updatePointCoordinates(point, true);
                } else {
                  // Update up arrow visibility when second point name changes
                  if (!mounted) return;
                  setState(() {
                    _showUpArrow =
                        _hasValidCoordinates() && _hasValidPointName();
                  });
                }
                if (!mounted) return;
                setState(() {}); // Trigger rebuild to update colors
                _showSearchResults(value, isFirstPoint, context);
              },
              onTap: () {
                if (controller.text.isNotEmpty) {
                  _showSearchResults(controller.text, isFirstPoint, context);
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
            controller.clear();
            if (!mounted) return;
            setState(() {
              if (isFirstPoint) {
                _firstPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
                _calculateSecondPoint();
              } else {
                _secondPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
                _showUpArrow = false;
                // Use default values from SlopeCalculator when clearing
                final defaultValues = SlopeCalculator.getDefaultValues();
                slopeAngle = double.parse(defaultValues['angle']!);
                gradeI = double.parse(defaultValues['grade']!);
                gradePercent = double.parse(defaultValues['gradePercent']!);
                angle = BearingFormatter.format(0, _selectedAngleFormat);
              }
            });
            _hideSearchResults();
          },
        ),
        if (isFirstPoint) ...[
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: 8),
                    Text(l10n.searchPoint),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text(l10n.addPoint),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              switch (value) {
                case 'search':
                  _showSearchDialog(isFirstPoint);
                  break;
                case 'add':
                  _showAddPointDialog(context, isFirstPoint);
                  break;
              }
            },
          ),
        ] else if (_showUpArrow) ...[
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.arrow_upward, color: Colors.black),
            onPressed: _swapPoints,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (_canSavePoint()) ...[
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _savePoint,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('SAVE'),
            ),
          ],
        ],
      ],
    );
  }

  // Add method to check if point can be saved
  bool _canSavePoint() {
    if (_nextPointController.text.isEmpty) return false;

    // Check if point name exists in points list
    bool isDuplicate = _jobService.points.value.any((point) =>
        point.comment.toLowerCase() == _nextPointController.text.toLowerCase());

    // Check if coordinates are non-zero
    bool hasValidCoordinates =
        _secondPointCoords['Y'] != 0 || _secondPointCoords['X'] != 0;

    return !isDuplicate && hasValidCoordinates;
  }

  // Add save point method
  Future<void> _savePoint() async {
    if (!mounted) return;
    try {
      final newPoint = Point(
        id: 0,
        comment: _nextPointController.text,
        y: _secondPointCoords['Y']!,
        x: _secondPointCoords['X']!,
        z: _secondPointCoords['Z']!,
      );

      await _jobService.addPoint(newPoint);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Point saved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 1000),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving point: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _areBothPointsValid() {
    return _isInputValid() && _hasValidCoordinates();
  }
}
