import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../application_layer/core/logging_service.dart';
import '../../../application_layer/core/service_locator.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../../domain_layer/calculations/bearing_calculator.dart';
import '../../../domain_layer/calculations/distance_calculator.dart';
import '../../../domain_layer/calculations/slope_calculator.dart';
import '../../../domain_layer/coordinates/point.dart';
import '../../core/angle_converter.dart';
import '../../core/bearing_format.dart';
import '../../core/bearing_formatter.dart';
import '../../core/coordinate_formatter.dart';
import '../../core/dialogs/point_dialog.dart';
import '../../core/dropdowns/comment_dropdown.dart';
import '../jobs/jobs_viewmodel.dart';
import '../startup/home_page_view.dart';
import '../coordinates/plot_coordinates_view.dart';

class SingleJoinView extends StatefulWidget {
  final String jobName;
  final Point? initialFirstPoint;
  final Point? initialSecondPoint;
  final bool fromPlotScreen;
  const SingleJoinView({
    super.key,
    required this.jobName,
    this.initialFirstPoint,
    this.initialSecondPoint,
    this.fromPlotScreen = false,
  });

  @override
  State<SingleJoinView> createState() => _SingleJoinViewState();
}

class _SingleJoinViewState extends State<SingleJoinView> with RouteAware {
  final LoggingService _logger = GetIt.instance<LoggingService>();
  static const String _logName = 'SingleJoinView';

  late final JobsViewModel _jobsViewModel;
  late final JobService _jobService;
  String _coordinateFormat = 'YXZ'; // Default format
  String _selectedPrecision = 'Meters'; // Default measurement units
// Default to DMS, will be updated from job defaults

  // Controllers for text fields
  final TextEditingController _firstPointController = TextEditingController();
  final TextEditingController _nextPointController = TextEditingController();

  // Add focus nodes
  final FocusNode _firstPointFocus = FocusNode();
  final FocusNode _nextPointFocus = FocusNode();

  // Add search controller
  final TextEditingController _searchController = TextEditingController();

  // Add filtered points list
  List<Point> _filteredPoints = [];

  // Add state variables for coordinates
  Map<String, double> _firstPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
  Map<String, double> _nextPointCoords = {'Y': 0, 'X': 0, 'Z': 0};

  // Result variables
  double slopeAngle = 0.0;
  double gradeI = 0.0;
  double gradePercent = 0.0;
  double slopeDistance = 0.0;
  double distance = 0.0;
  String direction = "0° 00' 00\"";
  double heightDiff = 0.0;
  String angle = "0° 00' 00\"";
  BearingDirection bearing = BearingDirection.north;

  // Comment dropdown managers
  final LayerLink _firstPointLayerLink = LayerLink();
  final LayerLink _nextPointLayerLink = LayerLink();
  late CommentDropdown _firstPointDropdown;
  late CommentDropdown _nextPointDropdown;

  // Add bearing format state
  BearingFormat _selectedBearingFormat = BearingFormat.dmsSymbols;

  // Add a new state variable for angle format
  BearingFormat _selectedAngleFormat = BearingFormat.dmsSymbols;

  @override
  void initState() {
    super.initState();
    _jobsViewModel = locator<JobsViewModel>();
    _jobService = locator<JobService>();
    _loadJobDefaultsFor(widget.jobName);
    _loadAngularMeasurement();

    // Initialize dropdown managers
    _firstPointDropdown = CommentDropdown(layerLink: _firstPointLayerLink);
    _nextPointDropdown = CommentDropdown(layerLink: _nextPointLayerLink);

    // Listen for job changes
    _jobsViewModel.currentJobName.addListener(_onJobChanged);

    // Initialize with provided points if any
    if (widget.initialFirstPoint != null) {
      _firstPointController.text = widget.initialFirstPoint!.comment;
      _updatePointCoordinates(widget.initialFirstPoint!, true);
    }
    if (widget.initialSecondPoint != null) {
      _nextPointController.text = widget.initialSecondPoint!.comment;
      _updatePointCoordinates(widget.initialSecondPoint!, false);
    }
  }

  void _onJobChanged() {
    final newJobName = _jobsViewModel.currentJobName.value;
    if (newJobName != null && newJobName != widget.jobName) {
      _loadJobDefaultsFor(newJobName);
    }
  }

  Future<void> _loadJobDefaultsFor(String jobName) async {
    try {
      _logger.info(_logName, 'Loading job defaults for job: $jobName');

      final bool jobOpened = await _jobsViewModel.openJob(jobName);

      if (!jobOpened) {
        _logger.error(_logName, 'Failed to open job: $jobName');
        if (!context.mounted) return;
        setState(() {
          _coordinateFormat = 'YXZ';
          _selectedPrecision = 'Meters';
        });
        return;
      }

      final jobDefaults = await _jobsViewModel.getJobDefaults(jobName);
      _logger.debug(
          _logName, 'Job defaults loaded: ${jobDefaults?.coordinateFormat}');

      if (!context.mounted) return;
      if (jobDefaults != null) {
        setState(() {
          _coordinateFormat = jobDefaults.coordinateFormat ?? 'YXZ';
          _selectedPrecision = jobDefaults.precision ?? 'Meters';
          _logger.debug(
              _logName, 'Coordinate format set to: $_coordinateFormat');
        });
      } else {
        _logger.debug(
            _logName, 'Job defaults were null, using default format: YXZ');
        setState(() {
          _coordinateFormat = 'YXZ';
          _selectedPrecision = 'Meters';
        });
      }
    } catch (e) {
      _logger.error(_logName, 'Error loading job defaults: $e');
      if (!context.mounted) return;
      setState(() {
        _coordinateFormat = 'YXZ';
        _selectedPrecision = 'Meters';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // Hide dropdowns and clean up
    _firstPointDropdown.dispose();
    _nextPointDropdown.dispose();

    // Remove job change listener
    _jobsViewModel.currentJobName.removeListener(_onJobChanged);

    routeObserver.unsubscribe(this);
    _firstPointController.dispose();
    _nextPointController.dispose();
    _firstPointFocus.dispose();
    _nextPointFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPush() {
    _loadJobDefaultsFor(widget.jobName);
  }

  @override
  void didPopNext() {
    _loadJobDefaultsFor(widget.jobName);
  }

  Future<void> _loadAngularMeasurement() async {
    try {
      if (!context.mounted) return;
      setState(() {
        // The angle converter will be updated by getAngularMeasurement
        // We just need to trigger a rebuild to show/hide the dropdown
      });
    } catch (e) {
      _logger.error(_logName, 'Error loading angular measurement setting', e);
    }
  }

  // Add method to load points

  void _updatePointCoordinates(Point point, bool isFirstPoint) {
    if (!mounted) return;
    setState(() {
      if (isFirstPoint) {
        _firstPointCoords = {
          'Y': point.y,
          'X': point.x,
          'Z': point.z,
        };
      } else {
        _nextPointCoords = {
          'Y': point.y,
          'X': point.x,
          'Z': point.z,
        };
      }

      // Calculate distance and bearing if both points have coordinates and at least one is non-zero
      if (_firstPointCoords['Y'] != null &&
          _firstPointCoords['X'] != null &&
          _nextPointCoords['Y'] != null &&
          _nextPointCoords['X'] != null &&
          (_firstPointCoords['Y'] != 0 ||
              _firstPointCoords['X'] != 0 ||
              _nextPointCoords['Y'] != 0 ||
              _nextPointCoords['X'] != 0)) {
        // Calculate distance
        distance = DistanceCalculator.calculate(
          _firstPointCoords['Y']!,
          _firstPointCoords['X']!,
          _nextPointCoords['Y']!,
          _nextPointCoords['X']!,
        );

        // Calculate bearing
        final bearing = BearingCalculator.calculate(
          _firstPointCoords['Y']!,
          _firstPointCoords['X']!,
          _nextPointCoords['Y']!,
          _nextPointCoords['X']!,
        );

        // Format bearing using selected format
        direction = BearingFormatter.format(
          bearing,
          _selectedBearingFormat,
        );

        // Calculate slope metrics
        final slopeResults = SlopeCalculator.calculate(
          distance: distance,
          z1: _firstPointCoords['Z']!,
          z2: _nextPointCoords['Z']!,
        );

        // Update slope-related fields
        heightDiff = double.parse(slopeResults['heightDifference']!);
        slopeDistance = double.parse(slopeResults['slopeDistance']!);
        gradeI = double.parse(slopeResults['grade']!);
        gradePercent = double.parse(slopeResults['gradePercent']!);
        angle = slopeResults['angleFormatted']!;
      } else {
        // Reset values if either point is missing coordinates or both are zero
        final defaultValues = SlopeCalculator.getDefaultValues();
        distance = 0.0;
        direction = "0° 00' 00\"";
        heightDiff = double.parse(defaultValues['heightDifference']!);
        slopeDistance = double.parse(defaultValues['slopeDistance']!);
        gradeI = double.parse(defaultValues['grade']!);
        gradePercent = double.parse(defaultValues['gradePercent']!);
        angle = defaultValues['angleFormatted']!;
      }
    });
  }

  Widget _buildCoordinatesRow(bool isFirstPoint) {
    final coords = isFirstPoint ? _firstPointCoords : _nextPointCoords;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCoordinateColumn('Y', coords['Y'] ?? 0),
        _buildCoordinateColumn('X', coords['X'] ?? 0),
        _buildCoordinateColumn('Z', coords['Z'] ?? 0),
      ],
    );
  }

  Widget _buildCoordinateColumn(String coordinate, double value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            CoordinateFormatter.getCoordinateLabel(
                coordinate, _coordinateFormat),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value.toStringAsFixed(3),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(
      String query, bool isFirstPoint, BuildContext context) {
    // Hide both dropdowns first
    if (isFirstPoint) {
      _nextPointDropdown.hideDropdown();
      _firstPointDropdown.showDropdown(
        context: context,
        query: query,
        points: _jobService.points.value,
        onSelected: (point) {
          _firstPointController.text = point.comment;
          _updatePointCoordinates(point, true);
        },
      );
    } else {
      _firstPointDropdown.hideDropdown();
      _nextPointDropdown.showDropdown(
        context: context,
        query: query,
        points: _jobService.points.value,
        onSelected: (point) {
          _nextPointController.text = point.comment;
          _updatePointCoordinates(point, false);
        },
      );
    }
  }

  void _hideSearchResults() {
    _firstPointDropdown.hideDropdown();
    _nextPointDropdown.hideDropdown();
  }

  Future<void> _showSearchDialog(bool isFirstPoint) async {
    // Hide dropdowns before showing dialog
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
              title: Text('Search ${isFirstPoint ? 'First' : 'Next'} Point'),
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
                                if (isFirstPoint) {
                                  _firstPointController.text = point.comment;
                                } else {
                                  _nextPointController.text = point.comment;
                                }
                                _updatePointCoordinates(point, isFirstPoint);
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
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        if (widget.fromPlotScreen) {
          Navigator.of(context).pop(); // Return to plot screen
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
        return false;
      },
      child: GestureDetector(
        onTap: _hideSearchResults,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (widget.fromPlotScreen) {
                  Navigator.of(context).pop(); // Return to plot screen
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                }
              },
            ),
            title: Text(l10n.joins),
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First Point Input Row
                _buildPointInputRow(true),
                const SizedBox(height: 16),
                // Coordinates display for first point
                _buildCoordinatesRow(true),
                const SizedBox(height: 24),

                // Second Point Input Row
                _buildPointInputRow(false),
                const SizedBox(height: 16),
                // Coordinates display for second point
                _buildCoordinatesRow(false),
                const SizedBox(height: 24),

                // Results Section
                _buildResultRow(l10n.distance, distance),
                _buildDirectionRow(),
                _buildResultRow(l10n.heightDiff, heightDiff),
                _buildResultRow(l10n.slopeDistanceLabel, slopeDistance),
                _buildResultRow(l10n.gradeSlope, gradeI),
                _buildResultRow(l10n.gradeSlopePercent, gradePercent),
                _buildSlopeAngleRow(),

                const SizedBox(height: 24),
                // Bottom Navigation Buttons
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
    );
  }

  Widget _buildResultRow(String label, dynamic value) {
    // Special handling for Angle which should use _buildAngleRow instead
    if (label == 'SlopeAngle') {
      return _buildAngleRow();
    }

    String displayValue;
    if (value is double) {
      displayValue = value.toStringAsFixed(3);
    } else {
      displayValue = value.toString();
    }

    // Add measurement unit suffix to labels
    String displayLabel = label;
    if (label == 'Distance ' ||
        label == 'Height Diff ' ||
        label == 'Slope Distance ') {
      displayLabel = '$label(${_selectedPrecision == 'Meters' ? 'm' : 'Ft'})';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(displayLabel,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(displayValue),
        ],
      ),
    );
  }

  Widget _buildAngleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('Slope Angle',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              // Only show format dropdown if not in Grads mode
              if (AngleConverter.gradsFactor == 1.0) ...[
                const SizedBox(width: 24),
                SizedBox(
                  height: 30,
                  child: Container(
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
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                      dropdownColor: const Color.fromRGBO(254, 247, 255, 1.0),
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.black54),
                      elevation: 1,
                      onChanged: (BearingFormat? newFormat) {
                        if (newFormat != null) {
                          setState(() {
                            _selectedAngleFormat = newFormat;
                            _updateAngleFormat();
                          });
                        }
                      },
                      items: _buildAngleFormatItems(),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            angle,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<BearingFormat>> _buildAngleFormatItems() {
    // Get the raw angle value from the slope calculator
    double angleValue = 0.0;
    if (_firstPointCoords['Z'] != null && _nextPointCoords['Z'] != null) {
      final slopeResults = SlopeCalculator.calculate(
        distance: distance,
        z1: _firstPointCoords['Z']!,
        z2: _nextPointCoords['Z']!,
      );
      angleValue = double.tryParse(slopeResults['angle']!) ?? 0.0;
      // Preserve the sign
      if (slopeResults['angleFormatted']!.startsWith('-')) {
        angleValue = -angleValue;
      }
    }

    return [
      DropdownMenuItem(
        value: BearingFormat.dms,
        child: Text(
          'D.M.S (${BearingFormatter.format(angleValue.abs(), BearingFormat.dms)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsCompact,
        child: Text(
          'D.MS (${BearingFormatter.format(angleValue.abs(), BearingFormat.dmsCompact)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dm,
        child: Text(
          'D.M (${BearingFormatter.format(angleValue.abs(), BearingFormat.dm)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsNoSeparator,
        child: Text(
          'DMS (${BearingFormatter.format(angleValue.abs(), BearingFormat.dmsNoSeparator)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsSymbols,
        child: Text(
          'D M S (${BearingFormatter.format(angleValue.abs(), BearingFormat.dmsSymbols)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsSymbolsCompact,
        child: Text(
          'DMS (${BearingFormatter.format(angleValue.abs(), BearingFormat.dmsSymbolsCompact)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    ];
  }

  void _updateAngleFormat() {
    if (_firstPointCoords['Z'] != null && _nextPointCoords['Z'] != null) {
      final slopeResults = SlopeCalculator.calculate(
        distance: distance,
        z1: _firstPointCoords['Z']!,
        z2: _nextPointCoords['Z']!,
      );
      if (!mounted) return;
      setState(() {
        double angleValue = double.tryParse(slopeResults['angle']!) ?? 0.0;
        String sign =
            slopeResults['angleFormatted']!.startsWith('-') ? '-' : '';
        angle = sign +
            BearingFormatter.format(angleValue.abs(), _selectedAngleFormat);
      });
    }
  }

  Widget _buildNavButton(String label) {
    final l10n = AppLocalizations.of(context)!;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {
        if (label == l10n.quit) {
          if (widget.fromPlotScreen) {
            Navigator.of(context).pop(); // Return to plot screen
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
      },
      child: Text(label),
    );
  }

  // First Point Input Row
  Widget _buildPointInputRow(bool isFirstPoint) {
    final l10n = AppLocalizations.of(context)!;
    final controller =
        isFirstPoint ? _firstPointController : _nextPointController;
    final focusNode = isFirstPoint ? _firstPointFocus : _nextPointFocus;
    final layerLink = isFirstPoint ? _firstPointLayerLink : _nextPointLayerLink;
    final label = isFirstPoint ? l10n.firstPoint : l10n.secondPoint;
    final hintText = isFirstPoint ? l10n.firstPointHint : l10n.nextPointHint;

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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
              onChanged: (value) {
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
            setState(() {
              if (isFirstPoint) {
                _firstPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
              } else {
                _nextPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
              }
              _resetResults();
            });
            _hideSearchResults();
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'search',
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.searchPoint),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'add',
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.addPoint),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'select_from_plot',
              child: Row(
                children: [
                  const Icon(Icons.map, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.selectFromPlot),
                ],
              ),
            ),
            if (!isFirstPoint)
              PopupMenuItem<String>(
                value: 'up',
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.moveUp),
                  ],
                ),
              ),
          ],
          onSelected: (String value) async {
            switch (value) {
              case 'search':
                _showSearchDialog(isFirstPoint);
                break;
              case 'add':
                _showAddPointDialog(context, isFirstPoint);
                break;
              case 'select_from_plot':
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const PlotCoordinatesView(isSelectionMode: true),
                  ),
                );
                if (result != null && result is Point) {
                  setState(() {
                    if (isFirstPoint) {
                      _firstPointController.text = result.comment;
                      _updatePointCoordinates(result, true);
                    } else {
                      _nextPointController.text = result.comment;
                      _updatePointCoordinates(result, false);
                    }
                  });
                }
                break;
              case 'up':
                setState(() {
                  _firstPointController.text = _nextPointController.text;
                  _firstPointCoords = Map.from(_nextPointCoords);
                  _nextPointController.clear();
                  _nextPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
                });
                _hideSearchResults();
                break;
            }
          },
        ),
      ],
    );
  }

  Future<void> _showAddPointDialog(
      BuildContext dialogContext, bool isFirstPoint) async {
    // Hide dropdowns before showing dialog
    _hideSearchResults();

    // Get the existing text from the appropriate controller
    final existingText =
        isFirstPoint ? _firstPointController.text : _nextPointController.text;

    try {
      final point = await PointDialog.showAddEditPointDialog(
        context: dialogContext,
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
          } else {
            _nextPointController.text = point.comment;
            _updatePointCoordinates(point, false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildDirectionRow() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(l10n.direction,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (AngleConverter.gradsFactor == 1.0) ...[
                const SizedBox(width: 24),
                SizedBox(
                  height: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(254, 247, 255, 1.0),
                      border: Border(
                        bottom:
                            BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                    ),
                    child: DropdownButton<BearingFormat>(
                      value: _selectedBearingFormat,
                      isDense: true,
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                      dropdownColor: const Color.fromRGBO(254, 247, 255, 1.0),
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.black54),
                      elevation: 1,
                      onChanged: (BearingFormat? newFormat) {
                        if (newFormat != null) {
                          setState(() {
                            _selectedBearingFormat = newFormat;
                            _updateDirectionAndDistance();
                          });
                        }
                      },
                      items: _buildBearingFormatItems(),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            direction,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<BearingFormat>> _buildBearingFormatItems() {
    // Calculate bearing only if neither point has all zero coordinates
    double bearing = 0.0;
    bool firstPointAllZero = _firstPointCoords['Y'] == 0 &&
        _firstPointCoords['X'] == 0 &&
        _firstPointCoords['Z'] == 0;
    bool nextPointAllZero = _nextPointCoords['Y'] == 0 &&
        _nextPointCoords['X'] == 0 &&
        _nextPointCoords['Z'] == 0;

    if (_firstPointCoords['Y'] != null &&
        _firstPointCoords['X'] != null &&
        _nextPointCoords['Y'] != null &&
        _nextPointCoords['X'] != null &&
        !firstPointAllZero &&
        !nextPointAllZero) {
      bearing = BearingCalculator.calculate(
        _firstPointCoords['Y']!,
        _firstPointCoords['X']!,
        _nextPointCoords['Y']!,
        _nextPointCoords['X']!,
      );
    }

    return [
      DropdownMenuItem(
        value: BearingFormat.dms,
        child: Text(
          'D.M.S (${BearingFormatter.format(bearing, BearingFormat.dms)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsCompact,
        child: Text(
          'D.MS (${BearingFormatter.format(bearing, BearingFormat.dmsCompact)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dm,
        child: Text(
          'D.M (${BearingFormatter.format(bearing, BearingFormat.dm)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsNoSeparator,
        child: Text(
          'DMS (${BearingFormatter.format(bearing, BearingFormat.dmsNoSeparator)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsSymbols,
        child: Text(
          'D M S (${BearingFormatter.format(bearing, BearingFormat.dmsSymbols)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsSymbolsCompact,
        child: Text(
          'DMS (${BearingFormatter.format(bearing, BearingFormat.dmsSymbolsCompact)})',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    ];
  }

  void _updateDirectionAndDistance() {
    bool firstPointAllZero = _firstPointCoords['Y'] == 0 &&
        _firstPointCoords['X'] == 0 &&
        _firstPointCoords['Z'] == 0;
    bool nextPointAllZero = _nextPointCoords['Y'] == 0 &&
        _nextPointCoords['X'] == 0 &&
        _nextPointCoords['Z'] == 0;

    if (_firstPointCoords['Y'] != null &&
        _firstPointCoords['X'] != null &&
        _nextPointCoords['Y'] != null &&
        _nextPointCoords['X'] != null &&
        !firstPointAllZero &&
        !nextPointAllZero) {
      final bearing = BearingCalculator.calculate(
        _firstPointCoords['Y']!,
        _firstPointCoords['X']!,
        _nextPointCoords['Y']!,
        _nextPointCoords['X']!,
      );
      if (!mounted) return;
      setState(() {
        direction = BearingFormatter.format(
          bearing,
          _selectedBearingFormat,
        );
      });
    } else {
      if (!mounted) return;
      setState(() {
        // Format zero according to the selected format
        direction = BearingFormatter.format(0.0, _selectedBearingFormat);
      });
    }
  }

  Widget _buildSlopeAngleRow() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(l10n.slopeAngle,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (AngleConverter.gradsFactor == 1.0) ...[
                const SizedBox(width: 24),
                SizedBox(
                  height: 30,
                  child: Container(
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
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                      dropdownColor: const Color.fromRGBO(254, 247, 255, 1.0),
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.black54),
                      elevation: 1,
                      onChanged: (BearingFormat? newFormat) {
                        if (newFormat != null) {
                          setState(() {
                            _selectedAngleFormat = newFormat;
                            _updateAngleFormat();
                          });
                        }
                      },
                      items: _buildAngleFormatItems(),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            angle,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _resetResults() {
    if (!mounted) return;
    setState(() {
      distance = 0.0;
      direction = "0° 00' 00\"";
      heightDiff = 0.0;
      slopeDistance = 0.0;
      gradeI = 0.0;
      gradePercent = 0.0;
      angle = "0° 00' 00\"";
      _selectedBearingFormat = BearingFormat.dmsSymbols;
      _selectedAngleFormat = BearingFormat.dmsSymbols;
    });
  }
}

enum BearingDirection { north, south, east, west }
