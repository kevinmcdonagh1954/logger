import 'package:flutter/foundation.dart';
import '../../../domain_layer/coordinates/point.dart';
import '../../../domain_layer/jobs/job_defaults.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../core/base_viewmodel.dart';

/// ViewModel for the job details screen
class JobDetailsViewModel extends BaseViewModel {
  // The service that this ViewModel depends on (injected via constructor)
  final JobService _jobService;

  // ValueNotifier for the search query
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  // ValueNotifier for the filtered points
  final ValueNotifier<List<Point>> _filteredPoints =
      ValueNotifier<List<Point>>([]);

  // ValueNotifier for job defaults
  final ValueNotifier<JobDefaults?> _jobDefaults =
      ValueNotifier<JobDefaults?>(null);

  // Getters for the ValueNotifiers so views can listen to them
  ValueNotifier<String> get searchQuery => _searchQuery;
  ValueNotifier<List<Point>> get filteredPoints => _filteredPoints;
  ValueNotifier<List<Point>> get allPoints => _jobService.points;
  ValueNotifier<String?> get jobName => _jobService.currentJobName;
  ValueNotifier<JobDefaults?> get jobDefaults => _jobDefaults;

  // Constructor that injects the service
  JobDetailsViewModel(this._jobService) {
    // Listen to changes in the points from the service
    _jobService.points.addListener(_updateFilteredPoints);

    // Initial load
    _updateFilteredPoints();
  }

  /// Initialize the ViewModel
  Future<void> init() async {
    await runBusyFuture(Future.wait([
      _jobService.loadPoints(),
      _loadJobDefaults(),
    ]));
  }

  /// Load job defaults
  Future<void> _loadJobDefaults() async {
    try {
      final defaults = await _jobService.getJobDefaults();
      _jobDefaults.value = defaults;
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Save job defaults
  Future<void> saveJobDefaults(JobDefaults defaults) async {
    await runBusyFuture(_jobService.saveJobDefaults(defaults));
    _jobDefaults.value = defaults;
  }

  /// Import points from CSV
  Future<Map<String, dynamic>> importPointsFromCSV() async {
    final Map<String, dynamic> result =
        await runBusyFuture(_jobService.importPointsFromCSV());
    return result;
  }

  /// Export points to CSV
  Future<String?> exportPointsToCSV() async {
    return runBusyFuture<String?>(_jobService.exportPointsToCSV());
  }

  /// Set the search query
  void setSearchQuery(String query) {
    _searchQuery.value = query;
    _updateFilteredPoints();
  }

  /// Update the filtered points based on the search query
  void _updateFilteredPoints() {
    final List<Point> points = _jobService.points.value;

    // Apply search query if not empty
    if (_searchQuery.value.isNotEmpty) {
      final String query = _searchQuery.value.toLowerCase();
      _filteredPoints.value = points
          .where((point) =>
              (point.comment.toLowerCase()).contains(query) ||
              (point.descriptor?.toLowerCase() ?? '').contains(query))
          .toList();
    } else {
      _filteredPoints.value = points;
    }
  }

  @override
  void dispose() {
    // Remove listener to prevent memory leaks
    _jobService.points.removeListener(_updateFilteredPoints);

    // Dispose of all ValueNotifiers
    _searchQuery.dispose();
    _filteredPoints.dispose();
    _jobDefaults.dispose();

    // Clear any error states before disposal
    hasError.value = false;
    errorMessage.value = null;

    super.dispose();
  }
}
