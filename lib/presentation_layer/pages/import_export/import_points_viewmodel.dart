import 'package:flutter/foundation.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../core/base_viewmodel.dart';
import 'package:flutter/material.dart';
import 'dart:io';
//import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../pages/jobs/jobs_viewmodel.dart';
import '../../../application_layer/core/service_locator.dart';
import '../../../application_layer/core/logging_service.dart';
import '../../../application_layer/core/file_service.dart';

/// ViewModel for importing points from CSV
class ImportPointsViewModel extends BaseViewModel {
  // The service that this ViewModel depends on (injected via constructor)
  final JobService _jobService;
  final LoggingService _logger;
  final FileService _fileService;

  // Get the JobsViewModel to update the point count
  final JobsViewModel _jobsViewModel = locator<JobsViewModel>();

  // Get the logger
  static const String _logName = 'ImportPointsViewModel';

  // ValueNotifier for the import status message
  final ValueNotifier<String> _statusMessage = ValueNotifier<String>('');

  // ValueNotifier for the import count
  final ValueNotifier<int> _importCount = ValueNotifier<int>(0);

  // ValueNotifier for the error count
  final ValueNotifier<int> _errorCount = ValueNotifier<int>(0);

  // ValueNotifier for the error log path
  final ValueNotifier<String?> _errorLogPath = ValueNotifier<String?>(null);

  // Getters for the ValueNotifiers so views can listen to them
  ValueNotifier<String> get statusMessage => _statusMessage;
  ValueNotifier<int> get importCount => _importCount;
  ValueNotifier<int> get errorCount => _errorCount;
  ValueNotifier<String?> get errorLogPath => _errorLogPath;
  ValueNotifier<String?> get jobName => _jobService.currentJobName;

  // Constructor that injects the service
  ImportPointsViewModel({
    JobService? jobService,
    LoggingService? logger,
    FileService? fileService,
  })  : _jobService = jobService ?? locator<JobService>(),
        _logger = logger ?? locator<LoggingService>(),
        _fileService = fileService ?? locator<FileService>();

  /// Check if error log file exists
  Future<void> checkErrorLogExists() async {
    try {
      final String? loggerJobsPath = await _getLoggerJobsPath();
      _logger.debug(_logName, "Logger jobs path: $loggerJobsPath");

      if (loggerJobsPath == null) {
        _logger.warning(_logName, "Logger jobs path is null");
        return;
      }

      final String errorLogPath = '$loggerJobsPath/Coordinate Import Error.log';
      _logger.debug(_logName, "Checking for error log at: $errorLogPath");

      final File errorLogFile = File(errorLogPath);
      if (await errorLogFile.exists()) {
        _logger.debug(_logName, "Error log file exists");
        _errorLogPath.value = errorLogPath;
      } else {
        _logger.warning(
            _logName, "Error log file does not exist at $errorLogPath");
      }
    } catch (e) {
      _logger.error(_logName, "Error checking for error log: $e");
    }
  }

  /// Get the Logger_Jobs directory path
  Future<String?> _getLoggerJobsPath() async {
    try {
      if (Platform.isWindows) {
        return 'D:/Logger_Jobs';
      } else {
        final appDir = await _fileService.getApplicationDirectory();
        return appDir.path;
      }
    } catch (e) {
      _logger.error(_logName, "Error getting Logger Jobs path: $e");
      return null;
    }
  }

  /// Open the error log file
  Future<bool> openErrorLog() async {
    try {
      final String? errorLogPath = _errorLogPath.value;
      if (errorLogPath == null || errorLogPath.isEmpty) {
        _logger.warning(_logName, "No error log path available");
        statusMessage.value = 'No error log available';
        return false;
      }

      _logger.debug(_logName, "Opening error log at: $errorLogPath");

      // Check if file exists first
      final File file = File(errorLogPath);
      if (!await file.exists()) {
        _logger.warning(
            _logName, "Error log file does not exist: $errorLogPath");
        statusMessage.value = 'Error log file not found';
        return false;
      }

      // Use URL launcher to open the file
      final Uri fileUri = Uri.file(errorLogPath);
      _logger.debug(_logName, "Launching file URI: $fileUri");

      final result = await launchUrl(fileUri);

      if (!result) {
        _logger.error(_logName, "Failed to open error log file: $errorLogPath");
        statusMessage.value = 'Failed to open error log file';
        return false;
      }

      _logger.debug(_logName, "Successfully opened error log file");
      return true;
    } catch (e) {
      _logger.error(_logName, "Exception opening error log: $e");
      statusMessage.value = 'Error opening log file: $e';
      return false;
    }
  }

  /// Import points from CSV
  Future<bool> importPointsFromCSV() async {
    try {
      isBusy.value = true;
      statusMessage.value = 'Reading CSV file...';

      final Map<String, dynamic> result =
          await _jobService.importPointsFromCSV();

      _logger.debug(_logName, "Import service returned: $result");

      final int count = result['count'] as int;
      final int errors = result['errorCount'] as int;
      final bool success = result['success'] as bool;
      final String message = result['message'] as String;
      final String? errorLogPathResult = result['errorLogPath'] as String?;

      _importCount.value = count;
      _errorCount.value = errors;

      _logger.debug(_logName,
          "Updated import count: $_importCount, errors: $_errorCount");

      // Update error log path if provided
      if (errorLogPathResult != null && errorLogPathResult.isNotEmpty) {
        _logger.debug(_logName, "Setting error log path: $errorLogPathResult");
        _errorLogPath.value = errorLogPathResult;
      } else if (errors > 0) {
        // Fallback to checking if error log exists
        _logger.debug(
            _logName, "Error log path not provided, checking manually");
        await checkErrorLogExists();
      }

      // Force update of any UI that listens to the points list
      if (count > 0) {
        _logger.debug(_logName, "Reloading points to refresh UI...");
        await _jobService.loadPoints(); // Reload points to ensure UI updates

        // Manually trigger a notification that points have changed to ensure UI updates
        _logger.debug(_logName,
            "Points after reload: ${_jobService.points.value.length}");

        // Force update the point count in the JobsViewModel
        _jobsViewModel.forceUpdatePointCount();
      }

      if (success && count > 0) {
        statusMessage.value = message;
        return true;
      } else {
        errorMessage.value = message;
        return false;
      }
    } catch (e) {
      _logger.error(_logName, "Exception in importPointsFromCSV: $e");
      errorMessage.value = 'Failed to import points: $e';

      // For database exceptions, set a reasonable import count of 0
      _importCount.value = 0;

      return false;
    } finally {
      isBusy.value = false;
    }
  }

  /// Reset the import status
  void resetStatus() {
    _statusMessage.value = '';
    _importCount.value = 0;
    _errorCount.value = 0;
    clearError();
  }

  @override
  void dispose() {
    _statusMessage.dispose();
    _importCount.dispose();
    _errorCount.dispose();
    _errorLogPath.dispose();
    super.dispose();
  }
}
