import 'package:flutter/foundation.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../core/base_viewmodel.dart';
import '../../../application_layer/core/logging_service.dart';
import '../../../domain_layer/jobs/job_defaults.dart';
import 'package:get_it/get_it.dart';

/// ViewModel for creating new jobs
class CreateJobViewModel extends BaseViewModel {
  final LoggingService _logger = GetIt.instance<LoggingService>();
  static const String _logName = 'CreateJobViewModel';

  // The service that this ViewModel depends on (injected via constructor)
  final JobService _jobService;

  // ValueNotifier for the job name
  final ValueNotifier<String> _jobName = ValueNotifier<String>('');

  // ValueNotifier for existing job names (to check for duplicates)
  final ValueNotifier<List<String>> _existingJobNames =
      ValueNotifier<List<String>>([]);

  // ValueNotifier for error message
  @override
  final ValueNotifier<String> errorMessage = ValueNotifier<String>('');

  // Regex for allowed characters in job names
  final RegExp _validJobNameChars = RegExp(r'^[a-zA-Z0-9_\-]+$');

  // List of illegal characters (for documentation/reference)
  // These characters are not allowed in Windows filenames:
  // < > : " / \ | ? * . and spaces

  // Getters for the ValueNotifiers so views can listen to them
  ValueNotifier<String> get jobName => _jobName;
  ValueNotifier<List<String>> get existingJobNames => _existingJobNames;

  // Constructor that injects the service
  CreateJobViewModel(this._jobService) {
    // Listen to changes in the jobs from the service
    _jobService.allJobs.addListener(_updateExistingJobNames);

    // Initial load
    _updateExistingJobNames();
  }

  /// Initialize the ViewModel
  Future<void> init() async {
    await runBusyFuture(_jobService.loadAllJobs());
  }

  /// Set the job name with real-time validation
  void setJobName(String value, {bool isEditMode = false}) {
    // The TextInputFormatter has already filtered out illegal characters,
    // so we can directly set the value without additional sanitization
    _jobName.value = value;

    // Validate the job name as the user types
    isJobNameValid(isEditMode: isEditMode);
  }

  /// Check if a job name is valid
  bool isJobNameValid({bool isEditMode = false}) {
    final String name = _jobName.value.trim();

    // Check if name is not empty
    if (name.isEmpty) {
      setError('Job name cannot be empty');
      return false;
    }

    // Check if name contains invalid characters
    if (!_validJobNameChars.hasMatch(name)) {
      setError(
          'Job name can only contain letters, numbers, underscores, and hyphens');
      return false;
    }

    // Check if name already exists - skip this check when in edit mode
    if (!isEditMode && _existingJobNames.value.contains(name)) {
      setError('A job with this name already exists');
      return false;
    }

    clearError();
    return true;
  }

  /// Create a new job with validation
  Future<bool> createJob() async {
    // Validate job name is not empty
    if (_jobName.value.trim().isEmpty) {
      const errorMsg = 'Job name cannot be empty';
      _logger.error(_logName, errorMsg);
      setError(errorMsg);
      return false;
    }

    // Set busy state
    isBusy.value = true;

    try {
      _logger.info(_logName, 'Creating new job with name: ${_jobName.value}');

      // Create job and save settings
      final result =
          await runBusyFuture(_jobService.createJob(_jobName.value.trim()));

      if (result) {
        _logger.info(_logName, 'Job created successfully: ${_jobName.value}');
        clearError();
      } else {
        _logger.error(_logName, 'Failed to create job: ${_jobName.value}');
        if (_jobService.errorMessage.value != null) {
          setError('Failed to create job: ${_jobService.errorMessage.value}');
        } else {
          setError(
              'Failed to create job. Check file permissions and try again.');
        }
      }

      return result;
    } catch (e) {
      _logger.error(_logName, 'Exception creating job: $e');
      setError('Error creating job: $e');
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  /// Update job defaults for an existing job
  Future<bool> updateJobDefaults(
      String jobName, Map<String, dynamic> jobDefaultsMap) async {
    try {
      // Convert map to JobDefaults object
      final jobDefaults = JobDefaults.fromMap(jobDefaultsMap);

      // Call the job service to save the job defaults
      await runBusyFuture(_jobService.saveJobDefaults(jobDefaults));
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Update the list of existing job names
  void _updateExistingJobNames() {
    _existingJobNames.value = _jobService.allJobs.value;
  }

  /// Override setError to also update errorMessage ValueNotifier
  @override
  void setError(String message) {
    super.setError(message);
    errorMessage.value = message;
  }

  /// Override clearError to also clear errorMessage ValueNotifier
  @override
  void clearError() {
    super.clearError();
    errorMessage.value = '';
  }

  @override
  void dispose() {
    _jobService.allJobs.removeListener(_updateExistingJobNames);
    _jobName.dispose();
    _existingJobNames.dispose();
    errorMessage.dispose();
    super.dispose();
  }
}
