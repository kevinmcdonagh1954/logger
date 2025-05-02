import 'package:flutter/material.dart';
import '../../presentation_layer/pages/jobs/jobs_viewmodel.dart';
import '../../presentation_layer/pages/jobs/job_info_dialog.dart';
import '../../presentation_layer/pages/jobs/job_delete_dialog.dart';
import '../../presentation_layer/pages/jobs/create_job_view.dart';
import '../../presentation_layer/pages/jobs/job_defaults_view.dart';
import '../core/logging_service.dart';
import 'package:get_it/get_it.dart';

/// Service class that handles job-related actions
class JobActionsService {
  final JobsViewModel _viewModel;
  final BuildContext _context;
  final LoggingService _logger = GetIt.instance<LoggingService>();

  JobActionsService(this._viewModel, this._context) {
    _logger.debug('JobActionsService', 'Initialized with context');
  }

  /// Open a job
  Future<void> openJob(String jobName) async {
    // Select the job
    _viewModel.selectJob(jobName);

    // Only open the job if it's not already the current job
    final bool isAlreadyCurrentJob = _viewModel.currentJobName.value == jobName;
    if (!isAlreadyCurrentJob) {
      final bool success = await _viewModel.openJob(jobName);
      if (!success) {
        if (_context.mounted) {
          ScaffoldMessenger.of(_context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open job'),
              duration: Duration(milliseconds: 500),
            ),
          );
        }
        return;
      }
    }

    // Return to navigation bar instead of pushing to JobDetailsView
    if (_context.mounted) {
      Navigator.of(_context)
          .pop(); // This will pop back to the navigation drawer

      // Show success message
      ScaffoldMessenger.of(_context).showSnackBar(
        SnackBar(
          content: Text('Job "$jobName" opened successfully'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  /// Select a job
  Future<void> selectJob(String jobName) async {
    // Select the job in the ViewModel
    _viewModel.selectJob(jobName);
  }

  /// Show job info dialog
  Future<void> showJobInfo(String jobName) async {
    if (_context.mounted) {
      await JobInfoDialog.show(
        _context,
        jobName: jobName,
        getJobInfoFunction: _viewModel.getJobInfo,
      );
    }
  }

  /// Show dialog to confirm job deletion
  Future<void> deleteJob(String jobName) async {
    if (_context.mounted) {
      await JobDeleteDialog.show(
        _context,
        jobName: jobName,
        deleteJobFunction: _viewModel.deleteJob,
        refreshJobsListFunction: _viewModel.refreshJobsList,
        openJobFunction: _viewModel.openJob,
        selectJobFunction: _viewModel.selectJob,
        updateUIFunction: () {
          if (_context.mounted) {
            (_context.findAncestorStateOfType<State>() as dynamic)
                .setState(() {});
          }
        },
        notifyJobUpdatedFunction: _viewModel.notifyJobUpdated,
        currentJobNameNotifier: _viewModel.currentJobName,
        filteredJobsNotifier: _viewModel.filteredJobs,
      );
    }
  }

  /// Open job settings
  Future<void> openJobSettings(String jobName) async {
    _logger.debug('JobActionsService', 'Opening job settings for: $jobName');

    if (_context.mounted) {
      _logger.debug('JobActionsService',
          'Context is mounted, proceeding with navigation');

      // First, ensure the job is selected and opened
      _viewModel.selectJob(jobName);
      final bool success = await _viewModel.openJob(jobName);

      if (!success) {
        _logger.error(
            'JobActionsService', 'Failed to open job before showing settings');
        if (_context.mounted) {
          ScaffoldMessenger.of(_context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open job settings'),
              duration: Duration(milliseconds: 500),
            ),
          );
        }
        return;
      }

      _logger.debug('JobActionsService',
          'Job opened successfully, navigating to JobDefaultsView');

      if (_context.mounted) {
        await Navigator.push(
          _context,
          MaterialPageRoute(
            builder: (context) =>
                JobDefaultsView(jobNameToEdit: jobName, isEditMode: true),
          ),
        );

        // Refresh the jobs list when returning from edit screen
        await _viewModel.refreshJobsList();
      }
    } else {
      _logger.error(
          'JobActionsService', 'Context not mounted, cannot open settings');
    }
  }

  /// Import points for a job
  Future<void> importPoints(String jobName) async {
    // First select the job and open it if not already open
    _viewModel.selectJob(jobName);
    final bool isAlreadyCurrentJob = _viewModel.currentJobName.value == jobName;
    if (!isAlreadyCurrentJob) {
      final bool success = await _viewModel.openJob(jobName);
      if (!success) {
        if (_context.mounted) {
          ScaffoldMessenger.of(_context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open job for importing'),
              duration: Duration(milliseconds: 500),
            ),
          );
        }
        return;
      }
    }

    if (_context.mounted) {
      showDialog(
        context: _context,
        builder: (context) => const AlertDialog(
          title: Text('Importing Points'),
          content: SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Perform the import operation
      final Map<String, dynamic> result =
          await _viewModel.importPointsFromCSV();
      final int count = result['count'] as int;
      final int errorCount = result['errorCount'] as int;
      final bool success = result['success'] as bool;
      final String message = result['message'] as String;

      // Close the loading dialog
      if (_context.mounted) {
        Navigator.pop(_context);
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Imported $count points to $jobName'
                : message + (errorCount > 0 ? ' ($errorCount errors)' : '')),
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
    }
  }

  /// Export points for a job
  Future<void> exportPoints(String jobName) async {
    // First select the job and open it if not already open
    _viewModel.selectJob(jobName);
    final bool isAlreadyCurrentJob = _viewModel.currentJobName.value == jobName;
    if (!isAlreadyCurrentJob) {
      final bool success = await _viewModel.openJob(jobName);
      if (!success) {
        if (_context.mounted) {
          ScaffoldMessenger.of(_context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open job for exporting'),
              duration: Duration(milliseconds: 500),
            ),
          );
        }
        return;
      }
    }

    if (_context.mounted) {
      showDialog(
        context: _context,
        builder: (context) => const AlertDialog(
          title: Text('Exporting Points'),
          content: SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Perform the export operation
      final String? filePath = await _viewModel.exportPointsToCSV();

      // Close the loading dialog
      if (_context.mounted) {
        Navigator.pop(_context);
        if (filePath != null) {
          ScaffoldMessenger.of(_context).showSnackBar(
            SnackBar(
              content: Text('Exported points to: $filePath'),
              duration: const Duration(milliseconds: 500),
            ),
          );
        } else {
          ScaffoldMessenger.of(_context).showSnackBar(
            const SnackBar(
              content: Text('No points to export'),
              duration: Duration(milliseconds: 500),
            ),
          );
        }
      }
    }
  }

  /// Backup a job
  Future<void> backupJob(String jobName) async {
    if (!_context.mounted) return;

    try {
      // Show backup in progress dialog
      showDialog(
        context: _context,
        barrierDismissible: false,
        builder: (BuildContext context) => const AlertDialog(
          title: Text('Creating Backup'),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Creating backup... Please wait"),
            ],
          ),
        ),
      );

      // Automatically use the default backup location
      final String? backupPath =
          await _viewModel.backupJobToDefaultLocation(jobName);

      // Check if still mounted before showing UI
      if (!_context.mounted) return;

      // Close the backup progress dialog
      Navigator.of(_context, rootNavigator: true).pop();

      // Show success or failure message
      if (backupPath != null) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text('Job "$jobName" backed up successfully'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text('Failed to backup job "$jobName"'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (!_context.mounted) return;

      // Close the loading dialog if open
      Navigator.of(_context, rootNavigator: true).pop();

      // Show error message
      ScaffoldMessenger.of(_context).showSnackBar(
        SnackBar(
          content: Text('Error during backup: ${e.toString()}'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  /// Create a new job
  Future<void> createNewJob() async {
    if (_context.mounted) {
      await Navigator.push(
        _context,
        MaterialPageRoute(builder: (context) => const CreateJobView()),
      );

      // Refresh job list when returning from create job view
      await _viewModel.refreshJobsList();

      // If there are jobs after refreshing, ensure one is selected and active
      if (_viewModel.filteredJobs.value.isNotEmpty) {
        // Get the first job in the list (or keep current job if it exists)
        final String jobToSelect = _viewModel.currentJobName.value ??
            _viewModel.filteredJobs.value.first;

        // Select and open the job to make it the current job
        _viewModel.selectJob(jobToSelect);
        await _viewModel.openJob(jobToSelect);

        // Force UI update
        _viewModel.notifyJobUpdated();

        // If we're in the mounted context (not popping back from dialog already)
        if (_context.mounted) {
          // Force a rebuild of the JobsView
          (_context.findAncestorStateOfType<State>() as dynamic)
              .setState(() {});
        }
      }
    }
  }
}
