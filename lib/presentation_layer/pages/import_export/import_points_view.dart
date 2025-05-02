import 'package:flutter/material.dart';
import '../../../application_layer/core/service_locator.dart';
import 'import_points_viewmodel.dart';
import '../jobs/jobs_viewmodel.dart';
//import '../../../application_layer/core/logging_service.dart';

/// View for importing points from CSV
class ImportPointsView extends StatefulWidget {
  const ImportPointsView({super.key});

  @override
  State<ImportPointsView> createState() => _ImportPointsViewState();
}

class _ImportPointsViewState extends State<ImportPointsView> {
  // Get the ViewModel from the service locator
  late final ImportPointsViewModel _viewModel =
      locator<ImportPointsViewModel>();

  // Get the logger
  // final LoggingService _logger = locator<LoggingService>();
  // static const String _logName = 'ImportPointsView';

  @override
  void initState() {
    super.initState();
    _viewModel.resetStatus();
  }

  @override
  void dispose() {
    // Ensure the points count gets updated in the main UI
    final jobsViewModel = locator<JobsViewModel>();
    jobsViewModel.forceUpdatePointCount();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Points'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Import Coordinates from CSV File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Job name indicator
            ValueListenableBuilder<String?>(
              valueListenable: _viewModel.jobName,
              builder: (context, jobName, child) {
                return Text(
                  'Current Job: ${jobName ?? 'No job selected'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: jobName != null ? Colors.black : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 32),

            // Import button
            ValueListenableBuilder<bool>(
              valueListenable: _viewModel.isBusy,
              builder: (context, isBusy, child) {
                return ElevatedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () async {
                          await _importPoints();
                        },
                  icon: Icon(
                    isBusy ? Icons.hourglass_empty : Icons.file_upload,
                    color: Colors.white,
                  ),
                  label: Text(
                    isBusy ? 'Importing...' : 'Import CSV File',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Error button - only visible when errors exist
            ValueListenableBuilder<int>(
              valueListenable: _viewModel.errorCount,
              builder: (context, errorCount, child) {
                return Visibility(
                  visible: errorCount > 0,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _viewModel.openErrorLog();
                    },
                    icon: const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                    ),
                    label: Text(
                      'View Errors ($errorCount)',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Status area
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Import Status:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Status message
                    ValueListenableBuilder<String>(
                      valueListenable: _viewModel.statusMessage,
                      builder: (context, status, child) {
                        return Text(
                          status.isEmpty ? 'Ready to import' : status,
                          style: const TextStyle(fontSize: 14),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Error message
                    ValueListenableBuilder<String?>(
                      valueListenable: _viewModel.errorMessage,
                      builder: (context, error, child) {
                        return Visibility(
                          visible: error != null && error.isNotEmpty,
                          child: Text(
                            error ?? '',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Instructions
            const Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CSV File Format:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The CSV file should have the following columns:',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1. Description (text)\n2. Y Coordinate (number)\n3. X Coordinate (number)\n4. Z Coordinate (number)',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The first row is assumed to be a header and will be skipped.',
                      style:
                          TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Import points from CSV
  Future<void> _importPoints() async {
    try {
      // Reset status
      _viewModel.resetStatus();

      // Show a simple loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Importing Points'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Please wait...'),
            ],
          ),
        ),
      );

      // Perform the import
      await _viewModel.importPointsFromCSV();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show simple completion dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Complete'),
            content: Text('Imported ${_viewModel.importCount.value} points.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Just close loading dialog and show error
      if (mounted) {
        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Error'),
            content: Text('Failed to import: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
