import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../application_layer/core/service_locator.dart';
import '../../core/coordinate_formatter.dart';
import '../startup/home_page_view.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../../application_layer/fixing/fixing_service.dart';
import '../../../domain_layer/coordinates/point.dart';
import '../../core/angle_validator.dart';
import '../../core/dialogs/point_dialog.dart';
import '../../core/dropdowns/comment_dropdown.dart';
import '../../core/bearing_formatter.dart';
import '../../core/bearing_format.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../jobs/jobs_viewmodel.dart';
import '../../../domain_layer/calculations/bearing_calculator.dart';

class FixingPageView extends StatefulWidget {
  const FixingPageView({super.key});

  @override
  State<FixingPageView> createState() => _FixingPageViewState();
}

class _FixingPageViewState extends State<FixingPageView> with RouteAware {
  late final JobService _jobService;
  late final FixingService _fixingService;
  String _coordinateFormat = 'YXZ';
  String _selectedPrecision = 'Meters';

  final TextEditingController _firstPointController = TextEditingController();
  final TextEditingController _nextPointController = TextEditingController();
  final TextEditingController _slopeDistanceController =
      TextEditingController(text: "0.000");
  final TextEditingController _verticalAngleController =
      TextEditingController(text: "0.0000");
  final TextEditingController _targetHeightController =
      TextEditingController(text: "0.000");
  final TextEditingController _horizontalAngleController =
      TextEditingController(text: "0.0000");

  final TextEditingController _firstPointYController = TextEditingController();
  final TextEditingController _firstPointXController = TextEditingController();
  final TextEditingController _firstPointZController = TextEditingController();
  final TextEditingController _secondPointYController = TextEditingController();
  final TextEditingController _secondPointXController = TextEditingController();
  final TextEditingController _secondPointZController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Point> _filteredPoints = [];
  Map<String, double> _firstPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
  Map<String, double> _secondPointCoords = {'Y': 0, 'X': 0, 'Z': 0};

  double slopeAngle = 0.0;
  double gradeI = 0.0;
  double gradePercent = 0.0;

  final FocusNode _firstPointFocus = FocusNode();
  final FocusNode _nextPointFocus = FocusNode();

  final LayerLink _firstPointLayerLink = LayerLink();
  final LayerLink _nextPointLayerLink = LayerLink();
  late CommentDropdown _firstPointDropdown;
  late CommentDropdown _nextPointDropdown;

  final FocusNode _slopeDistanceFocus = FocusNode();
  final FocusNode _verticalAngleFocus = FocusNode();
  final FocusNode _targetHeightFocus = FocusNode();
  final FocusNode _horizontalAngleFocus = FocusNode();

  bool _showUpArrow = false;
  String angle = "0° 00' 00\"";
  BearingFormat _selectedBearingFormat = BearingFormat.dmsSymbols;

  // Add flags for input validity

  @override
  void initState() {
    super.initState();
    _jobService = locator<JobService>();
    _fixingService = locator<FixingService>();
    _loadJobDefaultsFor(locator<JobsViewModel>().currentJobName.value ?? '');
    _secondPointYController.text = "";
    _secondPointXController.text = "";
    _secondPointZController.text = "";
    _firstPointDropdown = CommentDropdown(layerLink: _firstPointLayerLink);
    _nextPointDropdown = CommentDropdown(layerLink: _nextPointLayerLink);
    locator<JobsViewModel>().currentJobName.addListener(_onJobChanged);
  }

  void _onJobChanged() {
    final newJobName = locator<JobsViewModel>().currentJobName.value;
    if (newJobName != null) {
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
      });
    } catch (e) {
      debugPrint('Error loading job defaults: $e');
    }
  }

  @override
  void dispose() {
    _firstPointDropdown.dispose();
    _nextPointDropdown.dispose();
    locator<JobsViewModel>().currentJobName.removeListener(_onJobChanged);
    _firstPointController.dispose();
    _nextPointController.dispose();
    _slopeDistanceController.dispose();
    _verticalAngleController.dispose();
    _targetHeightController.dispose();
    _horizontalAngleController.dispose();
    _firstPointYController.dispose();
    _firstPointXController.dispose();
    _firstPointZController.dispose();
    _secondPointYController.dispose();
    _secondPointXController.dispose();
    _secondPointZController.dispose();
    _searchController.dispose();
    _firstPointFocus.dispose();
    _nextPointFocus.dispose();
    _slopeDistanceFocus.dispose();
    _verticalAngleFocus.dispose();
    _targetHeightFocus.dispose();
    _horizontalAngleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
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
            title: Text(l10n.fixes),
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          body: Container(
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPointInputRow(true),
                          const SizedBox(height: 10),
                          _buildCoordinatesRow(true),
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 16),
                          _buildFixesResults(l10n),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
    );
  }

  void _hideSearchResults() {
    _firstPointDropdown.hideDropdown();
    _nextPointDropdown.hideDropdown();
  }

  void _showSearchResults(
      String query, bool isFirstPoint, BuildContext context) {
    if (isFirstPoint) {
      _nextPointDropdown.hideDropdown();
      _firstPointDropdown.showDropdown(
        context: context,
        query: query,
        points: _jobService.points.value,
        onSelected: (point) {
          _firstPointController.text = point.comment;
          _updatePointCoordinates(point, true);
          _firstPointDropdown.hideDropdown();
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        isSelectable: true,
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
          _nextPointDropdown.hideDropdown();
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        isSelectable: true,
      );
    }
  }

  Future<void> _showSearchDialog(bool isStartPoint) async {
    _hideSearchResults();
    _searchController.clear();
    _filteredPoints = _jobService.points.value;
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title:
                  Text(isStartPoint ? l10n.searchFirstPoint : l10n.searchPoint),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchByIdOrComment,
                        prefixIcon: const Icon(Icons.search),
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
                            bool isDuplicate = false;
                            if (isStartPoint) {
                              isDuplicate = point.comment.toLowerCase() ==
                                  _nextPointController.text.toLowerCase();
                            } else {
                              isDuplicate = point.comment.toLowerCase() ==
                                  _firstPointController.text.toLowerCase();
                            }
                            return ListTile(
                              title: Text('Point ${point.id}'),
                              subtitle: Text(point.comment),
                              enabled: !isDuplicate,
                              tileColor: isDuplicate ? Colors.grey[200] : null,
                              onTap: isDuplicate
                                  ? null
                                  : () async {
                                      final selectedPoint = point;
                                      Navigator.of(context).pop();

                                      if (isStartPoint) {
                                        _firstPointController.text =
                                            selectedPoint.comment;
                                        if (selectedPoint.y != 0 ||
                                            selectedPoint.x != 0 ||
                                            selectedPoint.z != 0) {
                                          await Future.delayed(const Duration(
                                              milliseconds: 100));
                                          if (mounted) {
                                            _updatePointCoordinates(
                                                selectedPoint, true);
                                          }
                                        }
                                      } else {
                                        _nextPointController.text =
                                            selectedPoint.comment;
                                        _updatePointCoordinates(
                                            selectedPoint, false);
                                      }
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
                  onPressed: () => Navigator.of(context).pop(),
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
    _hideSearchResults();
    final existingText =
        isFirstPoint ? _firstPointController.text : _nextPointController.text;
    final otherPointText =
        isFirstPoint ? _nextPointController.text : _firstPointController.text;

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
        // Check for duplicate point selection
        if (point.comment.toLowerCase() == otherPointText.toLowerCase()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Cannot use the same point for both Setup At and Next Point'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

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
        final currentContext = context;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  bool _hasValidCoordinates() {
    return _secondPointCoords['Y'] != 0 || _secondPointCoords['X'] != 0;
  }

  bool _hasValidPointName() {
    return _nextPointController.text.isNotEmpty &&
        _nextPointController.text.toLowerCase() != 'next point';
  }

  Widget _buildPointInputRow(bool isFirstPoint) {
    final l10n = AppLocalizations.of(context)!;
    final controller =
        isFirstPoint ? _firstPointController : _nextPointController;
    final focusNode = isFirstPoint ? _firstPointFocus : _nextPointFocus;
    final layerLink = isFirstPoint ? _firstPointLayerLink : _nextPointLayerLink;
    final label = isFirstPoint ? l10n.setupAt : l10n.secondPoint;
    final hintText = isFirstPoint ? l10n.setupAt : l10n.nextPointHint;
    final otherController =
        isFirstPoint ? _nextPointController : _firstPointController;

    // Validation logic
    bool isValid = false;
    if (controller.text.isNotEmpty) {
      final exists = _jobService.points.value
          .any((p) => p.comment.toLowerCase() == controller.text.toLowerCase());
      final isDuplicate =
          controller.text.toLowerCase() == otherController.text.toLowerCase();
      isValid = exists && !isDuplicate;
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
            width: 130,
            height: 36,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: isValid
                    ? Colors.green.withValues(alpha: 38)
                    : Colors.red.withValues(alpha: 38),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isValid ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isValid ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                if (isFirstPoint) {
                  final point = _jobService.points.value.firstWhere(
                    (p) => p.comment.toLowerCase() == value.toLowerCase(),
                    orElse: () =>
                        const Point(id: 0, comment: '', y: 0, x: 0, z: 0),
                  );
                  if (point.id != 0) {
                    _updatePointCoordinates(point, true);
                    setState(() {});
                  } else {
                    _firstPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
                    setState(() {});
                  }
                } else {
                  final point = _jobService.points.value.firstWhere(
                    (p) => p.comment.toLowerCase() == value.toLowerCase(),
                    orElse: () =>
                        const Point(id: 0, comment: '', y: 0, x: 0, z: 0),
                  );
                  if (point.id != 0) {
                    _updatePointCoordinates(point, false);
                    setState(() {});
                  } else {
                    setState(() {
                      _secondPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
                    });
                  }
                }
                setState(() {});
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
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () {
            controller.clear();
            if (!mounted) return;
            setState(() {
              if (isFirstPoint) {
                _firstPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
                _showUpArrow = false;
              } else {
                _secondPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
              }
            });
            _hideSearchResults();
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
        if (!isFirstPoint && _showUpArrow) ...[
          // (No widgets here)
        ],
      ],
    );
  }

  Widget _buildCoordinatesRow(bool isFirstPoint) {
    final coords = isFirstPoint ? _firstPointCoords : _secondPointCoords;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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

  bool _areBothPointsValid() {
    final setupAtValid = _firstPointCoords['Y'] != 0 ||
        _firstPointCoords['X'] != 0 ||
        _firstPointCoords['Z'] != 0;
    final nextPointValid = _secondPointCoords['Y'] != 0 ||
        _secondPointCoords['X'] != 0 ||
        _secondPointCoords['Z'] != 0;
    return setupAtValid && nextPointValid;
  }

  Widget _buildInputRow(
    String label,
    TextEditingController controller,
    bool isAngle, {
    bool allowNegative = false,
    required AppLocalizations l10n,
  }) {
    FocusNode focusNode;
    if (label == l10n.slopeDistanceWithUnit) {
      focusNode = _slopeDistanceFocus;
    } else if (label == l10n.verticalAngle) {
      focusNode = _verticalAngleFocus;
    } else if (label == l10n.targetHeightWithUnit) {
      focusNode = _targetHeightFocus;
    } else if (label == l10n.horizontalAngle) {
      focusNode = _horizontalAngleFocus;
    } else {
      focusNode = FocusNode(); // fallback, but should not happen
    }
    String displayLabel = label;
    if (label == 'Slope Distance (m)' || label == 'Target Height (m)') {
      displayLabel = label.replaceAll(
          '(m)', '(${_selectedPrecision == 'Meters' ? 'm' : 'Ft'})');
    }
    final bool disabled = !_areBothPointsValid();
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            displayLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
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

  void _updatePointCoordinates(Point point, bool isFirstPoint) {
    if (!mounted) return;
    setState(() {
      if (isFirstPoint) {
        _firstPointCoords = {
          'Y': point.y,
          'X': point.x,
          'Z': point.z,
        };
        _showUpArrow = false;

        // Show setup options if point has coordinates
        if (point.y != 0 || point.x != 0 || point.z != 0) {
          _showSetupOptionsDialog(point);
        }
      } else {
        // Allow Next Point to be updated anytime
        _secondPointCoords = {
          'Y': point.y,
          'X': point.x,
          'Z': point.z,
        };
        _showUpArrow = _hasValidCoordinates() && _hasValidPointName();
      }
    });
  }

  /// Show dialog with setup options when a point with coordinates is selected
  void _showSetupOptionsDialog(Point point) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => _buildSetupOptionsDialog(point),
    );
  }

  Widget _buildSetupOptionsDialog(Point point) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.setupOptions),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l10n.comment}: ${point.comment}'),
          const SizedBox(height: 8),
          Text('Y: ${point.y.toStringAsFixed(3)}'),
          Text('X: ${point.x.toStringAsFixed(3)}'),
          Text('Z: ${point.z.toStringAsFixed(3)}'),
          const SizedBox(height: 16),
          Text(l10n.selectSetupMethod),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _fixingService.setSetupPointStatus(SetupPointStatus.fixed);
            Navigator.of(context).pop();
          },
          child: Text(l10n.acceptFixedPoint),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _firstPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
              _fixingService.setSetupPointStatus(SetupPointStatus.provisional);
            });
            Navigator.of(context).pop();
          },
          child: Text(l10n.acceptProvisionalFix),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _firstPointCoords = {'Y': 0, 'X': 0, 'Z': 0};
              _fixingService.setSetupPointStatus(SetupPointStatus.redefine);
            });
            Navigator.of(context).pop();
          },
          child: Text(l10n.redefineSetupPoint),
        ),
      ],
    );
  }

  Widget _buildFixesResults(AppLocalizations l10n) {
    // Only show if both points are valid and horizontal angle is entered
    final hasPoints =
        _firstPointCoords['Y'] != 0 || _firstPointCoords['X'] != 0;
    final hasNext =
        _secondPointCoords['Y'] != 0 || _secondPointCoords['X'] != 0;
    final angleText = _horizontalAngleController.text;
    final hasAngle =
        angleText.isNotEmpty && AngleValidator.parseFromDMS(angleText) != null;
    if (!hasPoints || !hasNext || !hasAngle) return const SizedBox.shrink();

    // Use the established join direction routine
    double computedAzimuth = BearingCalculator.calculate(
      _firstPointCoords['Y']!,
      _firstPointCoords['X']!,
      _secondPointCoords['Y']!,
      _secondPointCoords['X']!,
    );
    String formattedAzimuth =
        BearingFormatter.format(computedAzimuth, _selectedBearingFormat);

    // Parse entered direction as D.MMSS (DMS)
    final enteredDirection = AngleValidator.parseFromDMS(angleText) ?? 0.0;
    String formattedEntered =
        BearingFormatter.format(enteredDirection, _selectedBearingFormat);

    // Difference (correction)
    double difference = enteredDirection - computedAzimuth;
    // Normalize to [-180, 180]
    if (difference > 180) difference -= 360;
    if (difference < -180) difference += 360;
    String formattedDifference =
        BearingFormatter.format(difference, _selectedBearingFormat);

    return Card(
      color: Colors.blue[50],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.resultsSection,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 16),
                DropdownButton<BearingFormat>(
                  value: _selectedBearingFormat,
                  onChanged: (format) {
                    if (format != null) {
                      setState(() => _selectedBearingFormat = format);
                    }
                  },
                  items: _buildBearingFormatItemsForFix(computedAzimuth),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${l10n.computedDirection}:   $formattedAzimuth'),
            Text('${l10n.enteredDirection}:   $formattedEntered'),
            Text('${l10n.difference}:         $formattedDifference'),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<BearingFormat>> _buildBearingFormatItemsForFix(
      double bearing) {
    return [
      DropdownMenuItem(
        value: BearingFormat.dms,
        child: Text(
            'D.M.S (${BearingFormatter.format(bearing, BearingFormat.dms)})',
            style: const TextStyle(fontSize: 12)),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsCompact,
        child: Text(
            'D.MS (${BearingFormatter.format(bearing, BearingFormat.dmsCompact)})',
            style: const TextStyle(fontSize: 12)),
      ),
      DropdownMenuItem(
        value: BearingFormat.dm,
        child: Text(
            'D.M (${BearingFormatter.format(bearing, BearingFormat.dm)})',
            style: const TextStyle(fontSize: 12)),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsNoSeparator,
        child: Text(
            'DMS (${BearingFormatter.format(bearing, BearingFormat.dmsNoSeparator)})',
            style: const TextStyle(fontSize: 12)),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsSymbols,
        child: Text(
            'D M S (${BearingFormatter.format(bearing, BearingFormat.dmsSymbols)})',
            style: const TextStyle(fontSize: 12)),
      ),
      DropdownMenuItem(
        value: BearingFormat.dmsSymbolsCompact,
        child: Text(
            'DMS (${BearingFormatter.format(bearing, BearingFormat.dmsSymbolsCompact)})',
            style: const TextStyle(fontSize: 12)),
      ),
    ];
  }
}
