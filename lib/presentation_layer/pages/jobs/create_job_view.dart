import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../application_layer/core/service_locator.dart';
import 'create_job_viewmodel.dart';
import 'jobs_viewmodel.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../../application_layer/core/logging_service.dart';
import 'jobs_view.dart';
import 'package:get_it/get_it.dart';
import '../../../l10n/app_localizations.dart';

/// View for creating new jobs
class CreateJobView extends StatefulWidget {
  final String? jobNameToEdit;
  final bool isEditMode;

  const CreateJobView({
    super.key,
    this.jobNameToEdit,
    this.isEditMode = false,
  });

  @override
  State<CreateJobView> createState() => _CreateJobViewState();
}

class _CreateJobViewState extends State<CreateJobView> {
  final LoggingService _logger = GetIt.instance<LoggingService>();
  static const String _logName = 'CreateJobView';

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
  final List<String> _dualCaptureOptions = ['Yes', 'No'];
  final List<String> _precisionOptions = ['Meters', 'Feet'];
  final List<String> _angularMeasurementOptions = ['degrees', 'grads'];
  String _selectedCoordinateFormat = 'YXZ';
  String _selectedBaudRate = '9600';
  String _selectedInstrument = 'MANUAL';
  String _selectedDualCapture = 'No';
  String _selectedPrecision = 'Meters';
  String _selectedAngularMeasurement = 'degrees';

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

          // Instrument - ensure MANUAL is treated as a regular option
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
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label == 'Job Name'
                  ? '${localizations?.jobName ?? 'Job Name'} (15 Char)'
                  : label,
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
                readOnly:
                    readOnly || (label == 'Job Name' && widget.isEditMode),
                style: const TextStyle(fontSize: 13),
                autofocus: label == 'Job Name' && !widget.isEditMode,
                textCapitalization: label == 'Job Name'
                    ? TextCapitalization.words
                    : TextCapitalization.none,
                keyboardType: _isNumericField(label)
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: [
                  if (maxLength != null)
                    LengthLimitingTextInputFormatter(maxLength),
                  if (label == 'Job Name') FilenameInputFormatter(),
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
                      ? Colors.grey[200]
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
          if (hasClearButton && !(label == 'Job Name' && widget.isEditMode))
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
    final localizations = AppLocalizations.of(context);
    final numericFields = [
      localizations?.scaleFactor ?? 'Scale Factor',
      localizations?.heightAboveMSL ?? 'Height Above MSL',
      localizations?.meanYValue ?? 'Mean Y Value',
      localizations?.verticalAngleIndexError ?? 'Vertical Angle Index Error',
      localizations?.spotShotTolerance ?? 'Spot Shot Tolerance',
      localizations?.horizontalAlignmentOffsetTolerance ??
          'Horizontal Alignment Offset Tolerance',
      localizations?.maximumSearchDistanceFromCL ??
          'Maximum Search Distance From CL',
      localizations?.numberOfRetries ?? 'Number of Retries',
      localizations?.timeout ?? 'Timeout'
    ];
    return numericFields.contains(label);
  }

  // Helper method to create section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 8),
        ],
      ),
    );
  }

//  Banner header for Create A New Job
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const JobsView()),
            );
          },
        ),
        title: Text(widget.isEditMode
            ? localizations?.jobSettings ?? 'Job Settings'
            : localizations?.createNewJob ?? 'Create New Job'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Name and Description section
              _buildInputRow(
                localizations?.jobName ?? 'Job Name',
                _jobNameController,
                hasClearButton: true,
                onClear: () {
                  _jobNameController.clear();
                  _viewModel.setJobName('');
                },
                maxLength: 15,
              ),

              _buildInputRow(
                localizations?.jobDescription ?? 'Job Description',
                _jobDescriptionController,
                hasClearButton: true,
                onClear: () => _jobDescriptionController.clear(),
                maxLength: 20,
              ),

              // Add error display
              ValueListenableBuilder<bool>(
                valueListenable: _viewModel.hasError,
                builder: (context, hasError, child) {
                  if (!hasError) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _viewModel.errorMessage.value,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),

              _buildInputRow(
                localizations?.coordinateFormat ?? 'Coordinate Format',
                _coordinateFormatController,
                hasDropdown: true,
                dropdownItems: _coordinateFormatOptions,
                selectedValue: _selectedCoordinateFormat,
                onDropdownChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedCoordinateFormat = value;
                      _coordinateFormatController.text = value;
                    });
                  }
                },
              ),

              // Instrument Settings section
              _buildSectionHeader(
                  localizations?.instrumentSettings ?? 'Instrument Settings'),

              // Instrument dropdown (custom, not using _buildInputRow)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        localizations?.instrument ?? 'Instrument',
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          isDense: true,
                        ),
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
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
                                  ? (localizations?.manualInstrument ??
                                      'MANUAL')
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
                localizations?.dualCapture ?? 'Dual Capture',
                TextEditingController(text: _selectedDualCapture),
                hasDropdown: true,
                dropdownItems: _dualCaptureOptions,
                selectedValue: _selectedDualCapture,
                onDropdownChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedDualCapture = value;
                    });
                  }
                },
              ),

              _buildInputRow(
                localizations?.measurementUnits ?? 'Measurement Units',
                TextEditingController(text: _selectedPrecision),
                hasDropdown: true,
                dropdownItems: _precisionOptions,
                selectedValue: _selectedPrecision,
                onDropdownChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedPrecision = value;
                    });
                  }
                },
              ),

              _buildInputRow(
                localizations?.angularMeasurement ?? 'Angular Measurement',
                TextEditingController(text: _selectedAngularMeasurement),
                hasDropdown: true,
                dropdownItems: _angularMeasurementOptions,
                selectedValue: _selectedAngularMeasurement,
                onDropdownChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedAngularMeasurement = value;
                    });
                  }
                },
              ),

              _buildInputRow(
                localizations?.commsBaudRate ?? 'Comms Baud Rate',
                TextEditingController(text: _selectedBaudRate),
                hasDropdown: true,
                dropdownItems: _baudRateOptions,
                selectedValue: _selectedBaudRate,
                onDropdownChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedBaudRate = value;
                    });
                  }
                },
              ),

              // Calculation Settings section
              _buildSectionHeader(
                  localizations?.calculationSettings ?? 'Calculation Settings'),

              _buildInputRow(localizations?.scaleFactor ?? 'Scale Factor',
                  _scaleFactorController),
              _buildInputRow(
                  localizations?.heightAboveMSL ?? 'Height Above MSL',
                  _heightAboveMSLController),
              _buildInputRow(localizations?.meanYValue ?? 'Mean Y Value',
                  _meanYValueController),
              _buildInputRow(
                  localizations?.verticalAngleIndexError ??
                      'Vertical Angle Index Error',
                  _verticalAngleIndexErrorController),

              // Tolerance Settings section
              _buildSectionHeader(
                  localizations?.toleranceSettings ?? 'Tolerance Settings'),

              _buildInputRow(
                  localizations?.spotShotTolerance ?? 'Spot Shot Tolerance',
                  _spotShotToleranceController),
              _buildInputRow(
                  localizations?.horizontalAlignmentOffsetTolerance ??
                      'Horizontal Alignment Offset Tolerance',
                  _horizontalAlignmentOffsetController),
              _buildInputRow(
                  localizations?.maximumSearchDistanceFromCL ??
                      'Maximum Search Distance From CL',
                  _maxSearchDistanceController),

              // Timing Settings section
              _buildSectionHeader(
                  localizations?.timingSettings ?? 'Timing Settings'),

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
                              localizations?.numberOfRetries ??
                                  'Number of Retries',
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
                            localizations?.timeout ?? 'Timeout',
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

              // Create Job button at the bottom
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                child: Center(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _viewModel.isBusy,
                    builder: (context, isBusy, child) {
                      return ValueListenableBuilder<String>(
                        valueListenable: _viewModel.jobName,
                        builder: (context, jobName, child) {
                          final bool hasName = jobName.isNotEmpty;
                          final bool noErrors = !_viewModel.hasError.value;
                          final bool isValid = hasName && noErrors;

                          if (widget.isEditMode) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Cancel button
                                ElevatedButton(
                                  onPressed: isBusy
                                      ? null
                                      : () {
                                          Navigator.of(context).pop();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D47A1),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 12,
                                    ),
                                  ),
                                  child:
                                      Text(localizations?.cancel ?? 'Cancel'),
                                ),

                                // Save Changes button
                                ElevatedButton(
                                  onPressed: isBusy ? null : _updateJobDefaults,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D47A1),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: isBusy
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(localizations?.save ?? 'Save'),
                                ),
                              ],
                            );
                          }

                          // Create job button for normal mode
                          return ElevatedButton(
                            onPressed: (isBusy || !isValid)
                                ? null
                                : _createJobAndGoToDefaults,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isValid
                                  ? Colors.green[600]
                                  : Colors.grey[400],
                              foregroundColor:
                                  isValid ? Colors.white : Colors.grey[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: isBusy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(localizations?.createNewJob ??
                                    'Create New Job'),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Create a new job and go back to Job Options
  Future<void> _createJobAndGoToDefaults() async {
    final jobName = _jobNameController.text.trim();
    final success = await _viewModel.createJob();

    if (success && mounted) {
      // Save job defaults before opening the job
      try {
        // Create a map of all the job defaults to be saved
        final Map<String, dynamic> jobDefaults = {
          'databaseFileName': jobName,
          'jobDescription': _jobDescriptionController.text,
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

        _logger.debug(_logName, 'Saving job defaults: $jobDefaults');

        // Save the job defaults to the database
        await _viewModel.updateJobDefaults(jobName, jobDefaults);
      } catch (e) {
        _logger.error(_logName, 'Error saving job defaults: $e');
        // Continue with opening the job even if saving defaults fails
      }

      // Open the newly created job
      final jobService = locator<JobService>();
      final opened = await jobService.openJob(jobName);

      if (opened) {
        // Get the JobsViewModel to ensure the new job is selected
        final jobsViewModel = locator<JobsViewModel>();
        jobsViewModel.selectJob(jobName);

        // Ensure UI is updated to reflect this job as current
        jobsViewModel.notifyJobUpdated();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Job "$jobName" created and opened successfully'),
              duration: const Duration(milliseconds: 500),
            ),
          );
        }

        // Return to Job Options page
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to open the newly created job: ${jobService.errorMessage.value ?? "Unknown error"}'),
              duration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    } else if (mounted) {
      // Show error message for job creation failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.hasError.value
              ? _viewModel.errorMessage.value
              : 'Failed to create job. Check file permissions and try again.'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  /// Update job defaults for an existing job
  void _updateJobDefaults() async {
    // Set the job name from the existing one
    final jobName = widget.jobNameToEdit!;

    // Show loading state
    _viewModel.isBusy.value = true;

    try {
      // Update job defaults similar to _createJob method
      // but without creating a new job directory
      await _saveJobDefaults(jobName);

      // Navigate back to previous screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating job defaults: $e'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } finally {
      if (mounted) {
        _viewModel.isBusy.value = false;
      }
    }
  }

  /// Save job defaults to a file
  Future<void> _saveJobDefaults(String jobName) async {
    try {
      // Create a map of all the job defaults to be saved
      final Map<String, dynamic> jobDefaults = {
        'databaseFileName': jobName,
        'jobDescription': _jobDescriptionController.text,
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

      _logger.debug(_logName, 'Saving job defaults: $jobDefaults');

      // Save the job defaults to the database
      await _viewModel.updateJobDefaults(jobName, jobDefaults);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job defaults updated successfully'),
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      _logger.error(_logName, 'Error saving job defaults: $e');
      // Error is handled in the calling method
      rethrow;
    }
  }
}

/// Custom TextInputFormatter that replaces invalid filename characters with underscores
class FilenameInputFormatter extends TextInputFormatter {
  // Regex for valid filename characters (letters, numbers, underscore, and hyphen)
  final RegExp _validCharacters = RegExp(r'[a-zA-Z0-9_\-]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Replace invalid characters with underscores
    final String sanitizedText = newValue.text.split('').map((char) {
      return _validCharacters.hasMatch(char) ? char : '_';
    }).join('');

    // If no changes were made, return the original value
    if (sanitizedText == newValue.text) {
      return newValue;
    }

    // Keep the cursor position since we're replacing characters one-for-one
    return TextEditingValue(
      text: sanitizedText,
      selection: newValue.selection,
    );
  }
}
