import 'package:flutter/foundation.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../core/base_viewmodel.dart';
import '../../../domain_layer/jobs/job_defaults.dart';
import 'job_sort_order.dart';
import '../../../application_layer/core/logging_service.dart';
import 'package:get_it/get_it.dart';

export 'job_sort_order.dart';

/// ViewModel for the jobs list screen
class JobsViewModel extends BaseViewModel {
  // The service that this ViewModel depends on (injected via constructor)
  final JobService _jobService;
  final LoggingService _logger = GetIt.instance<LoggingService>();
  static const String _logName = 'JobsViewModel';

  // ValueNotifier for the search query
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  // ValueNotifier for the filtered jobs
  final ValueNotifier<List<String>> _filteredJobs =
      ValueNotifier<List<String>>([]);

  // ValueNotifier for the current sort method
  final ValueNotifier<JobSortMethod> _sortMethod =
      ValueNotifier<JobSortMethod>(JobSortMethod.dateModifiedNewest);

  // ValueNotifier for the selected job
  final ValueNotifier<String?> _selectedJob = ValueNotifier<String?>(null);

  // ValueNotifier for the point count
  final ValueNotifier<int> _pointCount = ValueNotifier<int>(0);

  // Getters for the ValueNotifiers so views can listen to them
  ValueNotifier<String> get searchQuery => _searchQuery;
  ValueNotifier<List<String>> get filteredJobs => _filteredJobs;
  ValueNotifier<List<String>> get allJobs => _jobService.allJobs;
  ValueNotifier<String?> get currentJobName => _jobService.currentJobName;
  ValueNotifier<JobSortMethod> get sortMethod => _sortMethod;
  ValueNotifier<String?> get selectedJob => _selectedJob;
  ValueNotifier<int> get pointCount => _pointCount;
  ValueNotifier<int> get currentJobPointsCount => _pointCount;

  /// Get the most recent job (first in the sorted list when sorted by date modified newest)
  String? get mostRecentJob =>
      _filteredJobs.value.isNotEmpty ? _filteredJobs.value[0] : null;

  // Constructor that injects the service
  JobsViewModel(this._jobService) {
    // Listen to changes in the jobs from the service
    _jobService.allJobs.addListener(_updateFilteredJobs);

    // Listen to changes in current job name
    _jobService.currentJobName.addListener(_updateSelectedJob);

    // Listen to changes in points
    _jobService.points.addListener(_updatePointCount);

    // Initial load
    _updateFilteredJobs();
    _updatePointCount();
  }

  /// Initialize the ViewModel
  Future<void> init() async {
    await runBusyFuture(_jobService.init());
  }

  /// Refresh the jobs list
  /// This method reloads the jobs list from disk without reinitializing the entire service
  Future<void> refreshJobsList() async {
    _logger.info(_logName, 'Refreshing jobs list');
    await runBusyFuture(_jobService.loadAllJobs());
    _logger.info(_logName, 'Jobs list refreshed successfully');
  }

  /// Create a new job
  Future<void> createJob(String jobName) async {
    await runBusyFuture(_jobService.createJob(jobName));
  }

  /// Open an existing job
  Future<bool> openJob(String jobName) async {
    final result = await runBusyFuture(_jobService.openJob(jobName));
    if (result) {
      // Set the job as selected when it's opened successfully
      selectJob(jobName);
    }
    return result;
  }

  /// Delete a job
  Future<bool> deleteJob(String jobName) async {
    final result = await runBusyFuture(_jobService.deleteJob(jobName));

    // Make sure the filtered jobs list is updated
    if (result) {
      await refreshJobsList();
    }

    return result;
  }

  /// Rename a job
  Future<bool> renameJob(String oldJobName, String newJobName) async {
    final bool result =
        await runBusyFuture(_jobService.renameJob(oldJobName, newJobName));

    // Update selection if the renamed job was selected
    if (result && _selectedJob.value == oldJobName) {
      _selectedJob.value = newJobName;
    }

    return result;
  }

  /// Backup a job to a specified location
  Future<String?> backupJob(String jobName, String destinationPath) async {
    return await runBusyFuture(_jobService.backupJob(jobName, destinationPath));
  }

  /// Backup a job to the default Backups directory
  Future<String?> backupJobToDefaultLocation(String jobName) async {
    return await runBusyFuture(_jobService.backupJobToDefaultLocation(jobName));
  }

  /// Backup and delete a job
  Future<Map<String, dynamic>> backupAndDeleteJob(String jobName) async {
    final result = await runBusyFuture(_jobService.backupAndDeleteJob(jobName));

    // Make sure the filtered jobs list is updated
    await refreshJobsList();

    return result;
  }

  /// Close the current job
  Future<bool> closeJob() async {
    return await runBusyFuture(_jobService.closeJob());
  }

  /// Clean up UI-related resources without closing the job
  void cleanupUIResources() {
    // Clear selection when leaving the view
    _selectedJob.value = null;

    // Remove the listener to prevent memory leaks
    _jobService.allJobs.removeListener(_updateFilteredJobs);

    // Clear any search/filter state
    if (_searchQuery.value.isNotEmpty) {
      _searchQuery.value = '';
    }
  }

  /// Import points from CSV
  Future<Map<String, dynamic>> importPointsFromCSV() async {
    final Map<String, dynamic> result =
        await runBusyFuture(_jobService.importPointsFromCSV());
    return result;
  }

  /// Export points to CSV
  Future<String?> exportPointsToCSV() async {
    final String? result = await runBusyFuture(_jobService.exportPointsToCSV());
    return result;
  }

  /// Set the search query
  void setSearchQuery(String query) {
    _searchQuery.value = query;
    _updateFilteredJobs();
  }

  /// Set the sort method
  void setSortMethod(JobSortMethod method) {
    // Update the sort method
    final currentMethod = _sortMethod.value;
    _sortMethod.value = method;

    // Only update if the method actually changed
    if (currentMethod != method) {
      // Update filtered jobs based on new sort
      _updateFilteredJobs();
    }
  }

  /// Toggle the sort direction
  void toggleSortDirection() {
    final newMethod = switch (_sortMethod.value) {
      JobSortMethod.dateModifiedNewest => JobSortMethod.dateModifiedOldest,
      JobSortMethod.dateModifiedOldest => JobSortMethod.dateModifiedNewest,
      JobSortMethod.alphabeticalAtoZ => JobSortMethod.alphabeticalZtoA,
      JobSortMethod.alphabeticalZtoA => JobSortMethod.alphabeticalAtoZ,
    };

    _sortMethod.value = newMethod;
    _updateFilteredJobs();
  }

  /// Select a job
  void selectJob(String? jobName) {
    _selectedJob.value = jobName;
  }

  /// Update the filtered jobs based on the search query and sort method
  void _updateFilteredJobs() {
    List<String> jobs = _jobService.allJobs.value;

    // Filter out jobs with "DELETED" or "BACKUPS" in their name
    jobs = jobs
        .where((job) =>
            !job.toUpperCase().contains("DELETED") &&
            !job.toUpperCase().contains("BACKUPS"))
        .toList();

    // Apply search query if not empty
    if (_searchQuery.value.isNotEmpty) {
      jobs = jobs
          .where((job) =>
              job.toLowerCase().contains(_searchQuery.value.toLowerCase()))
          .toList();
    }

    // Apply sorting
    switch (_sortMethod.value) {
      case JobSortMethod.dateModifiedNewest:
        // Jobs are already sorted by the database service in this order
        break;
      case JobSortMethod.dateModifiedOldest:
        // Reverse the order from the database service
        jobs = jobs.reversed.toList();
        break;
      case JobSortMethod.alphabeticalAtoZ:
        jobs.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        break;
      case JobSortMethod.alphabeticalZtoA:
        jobs.sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));
        break;
    }

    _filteredJobs.value = jobs;

    // If the current job is open, make sure it's selected
    if (_jobService.currentJobName.value != null &&
        jobs.contains(_jobService.currentJobName.value)) {
      _selectedJob.value = _jobService.currentJobName.value;
    }
    // Otherwise, if there are jobs and no job is currently selected, select the first one
    else if (jobs.isNotEmpty && _selectedJob.value == null) {
      _selectedJob.value = jobs[0];
    } else if (jobs.isEmpty) {
      _selectedJob.value = null;
    } else if (!jobs.contains(_selectedJob.value)) {
      // If the selected job is no longer in the filtered list, select the first one
      _selectedJob.value = jobs[0];
    }
  }

  /// Get information about a job (location, dates, size)
  Future<Map<String, dynamic>> getJobInfo(String jobName) async {
    return await runBusyFuture(_jobService.getJobInfo(jobName));
  }

  /// Get job defaults for a job
  Future<JobDefaults?> getJobDefaults(String jobName) async {
    try {
      _logger.info(_logName, 'Getting job defaults for job: $jobName');

      // Open the job if it's not already open
      _logger.debug(_logName, 'Opening job: $jobName');
      await openJob(jobName);

      _logger.debug(_logName, 'Retrieving job defaults');
      final jobDefaults = await _jobService.getJobDefaults();
      _logger.debug(
          _logName, 'Job defaults retrieved: ${jobDefaults?.coordinateFormat}');

      return jobDefaults;
    } catch (e) {
      _logger.error(_logName, 'Error getting job defaults: $e');
      return null;
    }
  }

  /// Save job defaults for a job
  Future<void> saveJobDefaults(String jobName, JobDefaults defaults) async {
    try {
      hasError.value = false;
      errorMessage.value = null;

      // Open the job
      await _jobService.openJob(jobName);

      // Save job defaults
      await _jobService.saveJobDefaults(defaults);

      _logger.info('JobsViewModel', 'Job defaults saved successfully');
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to save job defaults: ${e.toString()}';
      _logger.error('JobsViewModel', 'Error saving job defaults', e);
      rethrow;
    }
  }

  /// Force a UI update when a job is opened
  void notifyJobUpdated() {
    _updateFilteredJobs();
    _updatePointCount();
  }

  /// Update the point count
  void _updatePointCount() {
    final newCount = _jobService.points.value.length;
    _logger.debug(_logName,
        "Updating point count: $newCount (was: ${_pointCount.value})");
    _pointCount.value = newCount;
  }

  /// Force update the point count (can be called from other view models)
  void forceUpdatePointCount() {
    _logger.debug(_logName, "Force updating point count");
    _updatePointCount();
  }

  // Update selected job when current job changes
  void _updateSelectedJob() {
    if (_jobService.currentJobName.value != null) {
      selectJob(_jobService.currentJobName.value);
    }
  }

  @override
  void dispose() {
    // Ensure listener is removed
    _jobService.allJobs.removeListener(_updateFilteredJobs);
    _jobService.currentJobName.removeListener(_updateSelectedJob);
    _jobService.points.removeListener(_updatePointCount);

    // Dispose of ValueNotifiers
    _searchQuery.dispose();
    _filteredJobs.dispose();
    _sortMethod.dispose();
    _selectedJob.dispose();
    _pointCount.dispose();

    super.dispose();
  }
}
