import 'package:flutter/foundation.dart';
import 'package:stacked/stacked.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../../domain_layer/coordinates/point.dart';

class CoordinatesViewModel extends BaseViewModel {
  final JobService _jobService;
  final ValueNotifier<String> _coordinateFormat = ValueNotifier<String>('YXZ');
  bool _isInitialized = false;

  CoordinatesViewModel(this._jobService);

  ValueListenable<List<Point>> get points => _jobService.points;
  ValueListenable<String?> get currentJobName => _jobService.currentJobName;
  ValueNotifier<String> get coordinateFormat => _coordinateFormat;

  Future<void> init() async {
    if (_isInitialized) {
      // If already initialized, just reload points
      await runBusyFuture(_jobService.loadPoints());
      return;
    }

    try {
      await runBusyFuture(_jobService.loadPoints());
      await _loadCoordinateFormat();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing CoordinatesViewModel: $e');
      rethrow;
    }
  }

  Future<void> _loadCoordinateFormat() async {
    try {
      final jobDefaults = await _jobService.getJobDefaults();
      if (jobDefaults != null) {
        final defaults = jobDefaults.toMap();
        _coordinateFormat.value =
            defaults['coordinateFormat']?.toString() ?? 'YXZ';
      }
    } catch (e) {
      // If there's an error, we'll keep the default YXZ format
      debugPrint('Error loading coordinate format: $e');
    }
  }

  Future<void> deletePoint(int id) async {
    await runBusyFuture(_jobService.deletePoint(id));
  }

  Future<void> addPoint(Point point) async {
    await runBusyFuture(_jobService.addPoint(point));
  }

  Future<void> updatePoint(Point point) async {
    await runBusyFuture(_jobService.updatePoint(point));
  }

  @override
  void dispose() {
    _coordinateFormat.dispose();
    super.dispose();
  }
}
