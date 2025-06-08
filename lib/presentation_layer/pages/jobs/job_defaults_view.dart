import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../application_layer/core/service_locator.dart';
import 'create_job_viewmodel.dart';
import 'jobs_viewmodel.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../../application_layer/core/logging_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// View for editing job defaults
class JobDefaultsView extends StatefulWidget {
  final String? jobNameToEdit;
  final bool isEditMode;

  const JobDefaultsView({
    super.key,
    this.jobNameToEdit,
    this.isEditMode = false,
  });

  @override
  State<JobDefaultsView> createState() => _JobDefaultsViewState();
}

class _JobDefaultsViewState extends State<JobDefaultsView> {
  final LoggingService _logger = GetIt.instance<LoggingService>();
  static const String _logName = 'JobDefaultsView';

  // Get the ViewModel from the service locator
  late final CreateJobViewModel _viewModel = locator<CreateJobViewModel>();

  // Controllers for all fields
  final TextEditingController _jobNameController = TextEditingController();
  final TextEditingController _jobDescriptionController =
      TextEditingController();
  final TextEditingController _coordinateFormatController =
      TextEditingController(text: 'YXZ');
  final TextEditingController _scaleFactorController =
      TextEditingController(text: '1');
  final TextEditingController _heightAboveMSLController =
      TextEditingController(text: '0');
  final TextEditingController _meanYValueController =
      TextEditingController(text: '0');
  final TextEditingController _verticalAngleIndexErrorController =
      TextEditingController(text: '0');
  final TextEditingController _spotShotToleranceController =
      TextEditingController(text: '1.0');
  final TextEditingController _horizontalAlignmentOffsetController =
      TextEditingController(text: '50');
  final TextEditingController _maxSearchDistanceController =
      TextEditingController(text: '50');
  final TextEditingController _delayAndRetryController =
      TextEditingController(text: '4');
  final TextEditingController _timeoutController =
      TextEditingController(text: '10');

  // Dropdown values
  final List<String> _coordinateFormatOptions = ['YXZ', 'ENZ', 'MPC'];
  final List<String> _baudRateOptions = [
    '300',
    '600',
    '1200',
    '2400',
    '4800',
    '9600',
    '19200',
    '38400',
    '57600',
    '115200'
  ];
  final List<String> _instrumentOptions = [
    'MANUAL',
    'Sokkia',
    'Leica',
    'Topcon',
    'South',
    'Nikon',
    'Zeiss',
    'Geodimeter',
    'Leica GPS',
    'Pentax',
    'Precision',
    'Fujiyama',
    'Topcon GPS',
    'Trimble GPS',
    'Gowin',
    'Topshot',
    'Ruide'
  ];
  final List<String> _dualCaptureOptions = ['Yes', 'No'];
  final List<String> _precisionOptions = ['Meters', 'Feet'];
  final List<String> _angularMeasurementOptions = ['degrees', 'grads'];

  String _selectedCoordinateFormat = 'YXZ';
  String _selectedBaudRate = '9600';
  String _selectedInstrument = 'MANUAL';
  String _selectedDualCapture = 'No';
  String _selectedPrecision = 'Meters';
  String _selectedAngularMeasurement = 'degrees';

  @override
  void initState() {
    super.initState();
    _viewModel.init();
    _jobDescriptionController.text = "No Description";

    // Load existing job data if in edit mode
    if (widget.isEditMode && widget.jobNameToEdit != null) {
      _loadExistingJobData(widget.jobNameToEdit!);
    }

    // Listen to job name changes in the ViewModel and update the text field
    _viewModel.jobName.addListener(_updateJobNameTextField);

    // Add listener to job name controller to update ViewModel
    _jobNameController.addListener(() {
      _onJobNameChanged(_jobNameController.text);
    });
  }

  // Method to load existing job data
  void _loadExistingJobData(String jobName) async {
    // Show loading indicator
    _viewModel.isBusy.value = true;

    try {
      // Set job name
      _jobNameController.text = jobName;
      _viewModel.setJobName(jobName, isEditMode: true);

      // Load job defaults from the database
      final jobsViewModel = locator<JobsViewModel>();
      final jobDefaults = await jobsViewModel.getJobDefaults(jobName);

      if (jobDefaults != null) {
        // Update job description
        if (jobDefaults.jobDescription?.isNotEmpty == true) {
          _jobDescriptionController.text =
              jobDefaults.jobDescription ?? 'No Description';
        }

        // Update dropdown selections
        setState(() {
          // Coordinate format
          _selectedCoordinateFormat = jobDefaults.coordinateFormat ?? 'YXZ';
          _coordinateFormatController.text =
              jobDefaults.coordinateFormat ?? 'YXZ';

          // Instrument
          _selectedInstrument = jobDefaults.instrument ?? 'MANUAL';

          // Dual capture
          _selectedDualCapture = jobDefaults.dualCapture == 'Y' ? 'Yes' : 'No';

          // Precision - convert old values to new format
          String precision = jobDefaults.precision ?? 'Meters';
          // Handle old values (mm/cm) and convert to new values (Meters/Feet)
          if (precision == 'mm' || precision == 'cm') {
            precision = 'Meters'; // Default to Meters for old values
          }
          _selectedPrecision = precision;

          // Angular measurement
          _selectedAngularMeasurement =
              jobDefaults.angularMeasurement ?? 'degrees';

          // Baud rate
          _selectedBaudRate = jobDefaults.commsBaudRate ?? '9600';

          // Update text fields
          _scaleFactorController.text = jobDefaults.scaleFactor ?? '1';
          _heightAboveMSLController.text = jobDefaults.heightAboveMSL ?? '0';
          _meanYValueController.text = jobDefaults.meanYValue ?? '0';
          _verticalAngleIndexErrorController.text =
              jobDefaults.verticalAngleIndexError ?? '0';
          _spotShotToleranceController.text =
              jobDefaults.spotShotTolerance ?? '1.0';
          _horizontalAlignmentOffsetController.text =
              jobDefaults.horizontalAlignmentOffsetTolerance ?? '50';
          _maxSearchDistanceController.text =
              jobDefaults.maximumSearchDistanceFromCL ?? '50';
          _delayAndRetryController.text = jobDefaults.delayAndRetry ?? '4';
          _timeoutController.text = jobDefaults.timeout ?? '10';
        });

        _logger.debug(_logName,
            'Loaded job defaults for $jobName: Coordinate format: ${jobDefaults.coordinateFormat}');
      } else {
        _logger.debug(_logName, 'No job defaults found for $jobName');
      }
    } catch (e) {
      _logger.error(_logName, 'Error loading job defaults: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading job settings: $e'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } finally {
      // Hide loading indicator
      _viewModel.isBusy.value = false;
    }
  }

  /// Update the text field when the job name in the ViewModel changes
  void _updateJobNameTextField() {
    final jobName = _viewModel.jobName.value;

    // Only update if the values are different to avoid cursor position reset
    if (_jobNameController.text != jobName) {
      // Since we're now filtering at input time, we can just set the text and position cursor at the end
      _jobNameController.text = jobName;
      _jobNameController.selection = TextSelection.fromPosition(
        TextPosition(offset: jobName.length),
      );
    }
  }

  void _onJobNameChanged(String value) {
    _logger.debug(_logName, 'Job name changed to: $value');
    _viewModel.setJobName(value);
  }

  @override
  void dispose() {
    _jobNameController.removeListener(() {
      _viewModel.setJobName(_jobNameController.text);
    });
    _jobNameController.dispose();
    _jobDescriptionController.dispose();
    _coordinateFormatController.dispose();
    _scaleFactorController.dispose();
    _heightAboveMSLController.dispose();
    _meanYValueController.dispose();
    _verticalAngleIndexErrorController.dispose();
    _spotShotToleranceController.dispose();
    _horizontalAlignmentOffsetController.dispose();
    _maxSearchDistanceController.dispose();
    _delayAndRetryController.dispose();
    _timeoutController.dispose();
    _viewModel.jobName.removeListener(_updateJobNameTextField);
    super.dispose();
  }

  /// Build a row with a label and an input field
  Widget _buildInputRow(
    String label,
    TextEditingController controller, {
    bool hasClearButton = false,
    VoidCallback? onClear,
    bool readOnly = false,
    int? maxLength,
    bool hasDropdown = false,
    String? selectedValue,
    List<String>? dropdownItems,
    void Function(String?)? onDropdownChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label == 'Job Name' ? '${l10n.jobName} (15 Char)' : label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          if (!hasDropdown)
            SizedBox(
              width: 110,
              height: 25,
              child: TextField(
                controller: controller,
                readOnly: readOnly ||
                    (label == 'Job Name' &&
                        widget
                            .isEditMode), // Make job name readonly in edit mode
                style: const TextStyle(fontSize: 13),
                // Add autofocus for job name field
                autofocus: label == 'Job Name' && !widget.isEditMode,
                // Set text capitalization for job name field
                textCapitalization: label == 'Job Name'
                    ? TextCapitalization.words
                    : TextCapitalization.none,
                // Set keyboard type based on field type
                keyboardType: _isNumericField(label)
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: [
                  if (maxLength != null)
                    LengthLimitingTextInputFormatter(maxLength),
                  if (label == 'Job Name') // Only apply to job name field
                    FilenameInputFormatter(),
                  // Add numeric input formatter for numeric fields
                  if (_isNumericField(label))
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
                ],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  isDense: true,
                  errorStyle: const TextStyle(height: 0),
                  counterText: '',
                  fillColor: (label == 'Job Name' && widget.isEditMode)
                      ? Colors.grey[
                          200] // Gray background for read-only job name in edit mode
                      : null,
                  filled: (label == 'Job Name' && widget.isEditMode),
                ),
              ),
            )
          else
            SizedBox(
              width: 110,
              height: 25,
              child: DropdownButtonFormField<String>(
                value: selectedValue,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  isDense: true,
                ),
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
                onChanged: onDropdownChanged,
                items: dropdownItems
                    ?.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                }).toList(),
                menuMaxHeight: 250,
                isDense: true,
              ),
            ),
          if (hasClearButton &&
              !(label == 'Job Name' &&
                  widget
                      .isEditMode)) // Don't show clear button for job name in edit mode
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 15),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClear,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to determine if a field should use numeric input
  bool _isNumericField(String label) {
    // List of fields that should use numeric input
    final numericFields = [
      'Scale Factor',
      'Height Above MSL',
      'Mean Y Value',
      'Vertical Angle Index Error',
      'Spot Shot Tolerance (m)',
      'Horizontal Alignment Offset Tolerance (m)',
      'Maximum Search Distance From CL (m)',
      'Number of Retries',
      'Timeout (seconds)'
    ];
    return numericFields.contains(label);
  }

  // Helper method to create section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? l10n.jobSettings : l10n.createNewJob),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _viewModel.isBusy,
        builder: (context, isBusy, child) {
          if (isBusy) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job Information Section
                      _buildSectionHeader(l10n.jobInformation),
                      _buildInputRow(
                        l10n.jobName,
                        _jobNameController,
                        maxLength: 15,
                      ),
                      _buildInputRow(
                        l10n.jobDescription,
                        _jobDescriptionController,
                      ),
                      _buildInputRow(
                        l10n.coordinateFormat,
                        _coordinateFormatController,
                        hasDropdown: true,
                        selectedValue: _selectedCoordinateFormat,
                        dropdownItems: _coordinateFormatOptions,
                        onDropdownChanged: (value) {
                          setState(() {
                            _selectedCoordinateFormat = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Instrument Settings Section
                      _buildSectionHeader(l10n.instrumentSettings),
                      const Divider(height: 8),
                      // Instrument dropdown (custom, not using _buildInputRow)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 140,
                              child: Text(
                                l10n.instrument,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              height: 25,
                              child: DropdownButtonFormField<String>(
                                value: _selectedInstrument,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  isDense: true,
                                ),
                                icon:
                                    const Icon(Icons.arrow_drop_down, size: 20),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedInstrument = value;
                                    });
                                  }
                                },
                                items: _instrumentOptions.map((value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value == 'MANUAL'
                                          ? (l10n.manualInstrument)
                                          : value,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                menuMaxHeight: 250,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildInputRow(
                        l10n.dualCapture,
                        TextEditingController(),
                        hasDropdown: true,
                        selectedValue: _selectedDualCapture,
                        dropdownItems: _dualCaptureOptions,
                        onDropdownChanged: (value) {
                          setState(() {
                            _selectedDualCapture = value!;
                          });
                        },
                      ),
                      _buildInputRow(
                        l10n.measurementUnits,
                        TextEditingController(),
                        hasDropdown: true,
                        selectedValue: _selectedPrecision,
                        dropdownItems: _precisionOptions,
                        onDropdownChanged: (value) {
                          setState(() {
                            _selectedPrecision = value!;
                          });
                        },
                      ),
                      _buildInputRow(
                        l10n.angularMeasurement,
                        TextEditingController(),
                        hasDropdown: true,
                        selectedValue: _selectedAngularMeasurement,
                        dropdownItems: _angularMeasurementOptions,
                        onDropdownChanged: (value) {
                          setState(() {
                            _selectedAngularMeasurement = value!;
                          });
                        },
                      ),
                      _buildInputRow(
                        l10n.commsBaudRate,
                        TextEditingController(),
                        hasDropdown: true,
                        selectedValue: _selectedBaudRate,
                        dropdownItems: _baudRateOptions,
                        onDropdownChanged: (value) {
                          setState(() {
                            _selectedBaudRate = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Calculation Settings Section
                      _buildSectionHeader(l10n.calculationSettings),
                      const Divider(height: 8),
                      _buildInputRow(
                        l10n.scaleFactor,
                        _scaleFactorController,
                      ),
                      _buildInputRow(
                        l10n.heightAboveMSL,
                        _heightAboveMSLController,
                      ),
                      _buildInputRow(
                        l10n.meanYValue,
                        _meanYValueController,
                      ),
                      _buildInputRow(
                        l10n.verticalAngleIndexError,
                        _verticalAngleIndexErrorController,
                      ),
                      const SizedBox(height: 16),

                      // Tolerance Settings Section
                      _buildSectionHeader(l10n.toleranceSettings),
                      const Divider(height: 8),
                      _buildInputRow(
                        '${l10n.spotShotTolerance} (m)',
                        _spotShotToleranceController,
                      ),
                      _buildInputRow(
                        '${l10n.horizontalAlignmentOffsetTolerance} (m)',
                        _horizontalAlignmentOffsetController,
                      ),
                      _buildInputRow(
                        '${l10n.maximumSearchDistanceFromCL} (m)',
                        _maxSearchDistanceController,
                      ),
                      const SizedBox(height: 16),

                      // Timing Settings Section
                      _buildSectionHeader(l10n.timingSettings),
                      const Divider(height: 8),
                      Row(
                        children: [
                          // Number of Retries input
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      l10n.numberOfRetries,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    height: 25,
                                    child: TextField(
                                      controller: _delayAndRetryController,
                                      style: const TextStyle(fontSize: 13),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9]')),
                                      ],
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 5),
                                        isDense: true,
                                        errorStyle: TextStyle(height: 0),
                                        counterText: '',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Timeout input
                          Expanded(
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    l10n.timeout,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  height: 25,
                                  child: TextField(
                                    controller: _timeoutController,
                                    style: const TextStyle(fontSize: 13),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9]')),
                                    ],
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 5),
                                      isDense: true,
                                      errorStyle: TextStyle(height: 0),
                                      counterText: '',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 40),
                      ),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: !isBusy ? _saveJob : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 40),
                      ),
                      child: Text(
                          widget.isEditMode ? l10n.save : l10n.createNewJob),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveJob() async {
    try {
      final jobName = _jobNameController.text;
      final jobDescription = _jobDescriptionController.text;

      // Show loading indicator
      _viewModel.isBusy.value = true;

      // Create job defaults map
      final Map<String, dynamic> jobDefaults = {
        'jobDescription': jobDescription,
        'coordinateFormat': _selectedCoordinateFormat,
        'instrument': _selectedInstrument,
        'dualCapture': _selectedDualCapture == 'Yes' ? 'Y' : 'N',
        'precision': _selectedPrecision,
        'angularMeasurement': _selectedAngularMeasurement,
        'commsBaudRate': _selectedBaudRate,
        'scaleFactor': _scaleFactorController.text,
        'heightAboveMSL': _heightAboveMSLController.text,
        'meanYValue': _meanYValueController.text,
        'verticalAngleIndexError': _verticalAngleIndexErrorController.text,
        'spotShotTolerance': _spotShotToleranceController.text,
        'horizontalAlignmentOffsetTolerance':
            _horizontalAlignmentOffsetController.text,
        'maximumSearchDistanceFromCL': _maxSearchDistanceController.text,
        'delayAndRetry': _delayAndRetryController.text,
        'timeout': _timeoutController.text,
      };

      // Get the JobService instance
      final jobService = locator<JobService>();

      if (widget.isEditMode) {
        // Update existing job
        await jobService.updateJobDefaults(jobName, jobDefaults);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Job "$jobName" updated successfully'),
              duration: const Duration(milliseconds: 500),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Create new job
        final bool success = await jobService.createJob(jobName);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Job "$jobName" created successfully'),
                duration: const Duration(milliseconds: 500),
              ),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('Failed to create job');
        }
      }
    } catch (e) {
      _logger.error(_logName, 'Error saving job: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving job: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } finally {
      _viewModel.isBusy.value = false;
    }
  }
}

// Custom input formatter for filenames
class FilenameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only alphanumeric characters, spaces, and specific symbols
    String filteredText =
        newValue.text.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-_]'), '');

    return TextEditingValue(
      text: filteredText,
      selection: TextSelection.collapsed(offset: filteredText.length),
    );
  }
}
