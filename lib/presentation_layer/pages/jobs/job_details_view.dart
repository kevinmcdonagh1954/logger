import 'package:flutter/material.dart';
import '../../../domain_layer/coordinates/point.dart';
import '../../../domain_layer/jobs/job_defaults.dart';
import '../../../application_layer/core/service_locator.dart';
import 'job_details_viewmodel.dart';
import '../import_export/import_points_view.dart';
import '../../l10n/app_localizations.dart';

/// View for displaying job details
class JobDetailsView extends StatefulWidget {
  final String jobName;

  const JobDetailsView({super.key, required this.jobName});

  @override
  State<JobDetailsView> createState() => _JobDetailsViewState();
}

class _JobDetailsViewState extends State<JobDetailsView> {
  // Get the ViewModel from the service locator
  late final JobDetailsViewModel _viewModel = locator<JobDetailsViewModel>();

  @override
  void initState() {
    super.initState();
    _viewModel.init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job: ${widget.jobName}'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem<String>(
                value: 'import',
                child: Text('Import Points'),
              ),
              const PopupMenuItem<String>(
                value: 'export',
                child: Text('Export Points'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search points...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _viewModel.setSearchQuery,
            ),
          ),

          // Loading indicator
          ValueListenableBuilder<bool>(
            valueListenable: _viewModel.isBusy,
            builder: (context, isBusy, child) {
              return isBusy
                  ? const LinearProgressIndicator()
                  : const SizedBox(height: 4);
            },
          ),

          // Error message
          ValueListenableBuilder<bool>(
            valueListenable: _viewModel.hasError,
            builder: (context, hasError, child) {
              return hasError
                  ? ValueListenableBuilder<String?>(
                      valueListenable: _viewModel.errorMessage,
                      builder: (context, errorMessage, child) {
                        return Container(
                          color: Colors.red.shade100,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            errorMessage ?? 'An error occurred',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink();
            },
          ),

          // Points list
          Expanded(
            child: ValueListenableBuilder<List<Point>>(
              valueListenable: _viewModel.filteredPoints,
              builder: (context, points, child) {
                if (points.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('No points found'),
                        SizedBox(height: 16),
                        Text('Import points from the menu to get started',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: points.length,
                  itemBuilder: (context, index) {
                    final point = points[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(point.comment),
                        subtitle:
                            Text('Y: ${point.y}, X: ${point.x}, Z: ${point.z}'),
                        trailing: Text(point.descriptor ?? ''),
                        onTap: () => _showPointDetails(point),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Show job settings dialog
  void _showJobSettings() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<JobDefaults?>(
          valueListenable: _viewModel.jobDefaults,
          builder: (context, defaults, child) {
            if (defaults == null) {
              return const AlertDialog(
                title: Text('Job Settings'),
                content: Center(child: CircularProgressIndicator()),
              );
            }

            // Controllers for text fields
            final jobDescriptionController =
                TextEditingController(text: defaults.jobDescription);
            final coordinateFormatController =
                TextEditingController(text: defaults.coordinateFormat);
            final instrumentController =
                TextEditingController(text: defaults.instrument);
            final dualCaptureController =
                TextEditingController(text: defaults.dualCapture);
            final scaleFactorController =
                TextEditingController(text: defaults.scaleFactor);
            final heightAboveMSLController =
                TextEditingController(text: defaults.heightAboveMSL);
            final meanYValueController =
                TextEditingController(text: defaults.meanYValue);
            final verticalAngleIndexErrorController =
                TextEditingController(text: defaults.verticalAngleIndexError);
            final spotShotToleranceController =
                TextEditingController(text: defaults.spotShotTolerance);
            final delayAndRetryController =
                TextEditingController(text: defaults.delayAndRetry);
            final timeoutController =
                TextEditingController(text: defaults.timeout);
            final precisionController =
                TextEditingController(text: defaults.precision);
            final commsBaudRateController =
                TextEditingController(text: defaults.commsBaudRate);
            final horizontalAlignmentOffsetToleranceController =
                TextEditingController(
                    text: defaults.horizontalAlignmentOffsetTolerance);
            final maximumSearchDistanceFromCLController = TextEditingController(
                text: defaults.maximumSearchDistanceFromCL);
            final angularMeasurementController =
                TextEditingController(text: defaults.angularMeasurement);

            return AlertDialog(
              title: const Text('Job Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _settingsTextField(
                        'Job Description', jobDescriptionController),
                    _settingsTextField(
                        'Coordinate Format', coordinateFormatController),
                    _settingsTextField('Instrument', instrumentController),
                    _settingsTextField('Dual Capture', dualCaptureController),
                    _settingsTextField('Scale Factor', scaleFactorController),
                    _settingsTextField(
                        'Height Above MSL', heightAboveMSLController),
                    _settingsTextField('Mean Y Value', meanYValueController),
                    _settingsTextField('Vertical Angle Index Error',
                        verticalAngleIndexErrorController),
                    _settingsTextField(
                        'Spot Shot Tolerance', spotShotToleranceController),
                    _settingsTextField(
                        'Number of Retries', delayAndRetryController),
                    _settingsTextField('Timeout (seconds)', timeoutController),
                    _settingsTextField(
                        'Measurement Units', precisionController),
                    _settingsTextField(
                        'Comms Baud Rate', commsBaudRateController),
                    _settingsTextField(
                        'Horizontal Alignment Offset Tolerance (m)',
                        horizontalAlignmentOffsetToleranceController),
                    _settingsTextField('Maximum Search Distance from CL (m)',
                        maximumSearchDistanceFromCLController),
                    _settingsTextField(
                        'Angular Measurement', angularMeasurementController),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    final newDefaults = JobDefaults(
                      databaseFileName: defaults.databaseFileName,
                      jobDescription: jobDescriptionController.text,
                      coordinateFormat: coordinateFormatController.text,
                      instrument: instrumentController.text,
                      dualCapture: dualCaptureController.text,
                      scaleFactor: scaleFactorController.text,
                      heightAboveMSL: heightAboveMSLController.text,
                      meanYValue: meanYValueController.text,
                      verticalAngleIndexError:
                          verticalAngleIndexErrorController.text,
                      spotShotTolerance: spotShotToleranceController.text,
                      delayAndRetry: delayAndRetryController.text,
                      timeout: timeoutController.text,
                      precision: precisionController.text,
                      commsBaudRate: commsBaudRateController.text,
                      horizontalAlignmentOffsetTolerance:
                          horizontalAlignmentOffsetToleranceController.text,
                      maximumSearchDistanceFromCL:
                          maximumSearchDistanceFromCLController.text,
                      angularMeasurement: angularMeasurementController.text,
                    );
                    _viewModel.saveJobDefaults(newDefaults);
                    Navigator.pop(context);
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Create a settings text field
  Widget _settingsTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  /// Handle menu selection
  void _handleMenuSelection(String value) async {
    switch (value) {
      case 'settings':
        _showJobSettings();
        break;
      case 'import':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ImportPointsView()),
        );
        // Refresh points after importing
        _viewModel.init();
        break;
      case 'export':
        _exportPoints();
        break;
    }
  }

  /// Export points to CSV
  void _exportPoints() async {
    final String? filePath = await _viewModel.exportPointsToCSV();

    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Points exported to: $filePath'),
          duration: const Duration(seconds: 5),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No points to export'),
        ),
      );
    }
  }

  /// Show point details dialog
  void _showPointDetails(Point point) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Point: ${point.comment}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Comment', point.comment),
                _detailRow('Y', point.y.toString()),
                _detailRow('X', point.x.toString()),
                _detailRow('Z', point.z.toString()),
                _detailRow('Descriptor', point.descriptor ?? 'N/A'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Create a detail row
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
