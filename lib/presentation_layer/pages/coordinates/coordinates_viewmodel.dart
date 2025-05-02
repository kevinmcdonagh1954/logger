import 'package:flutter/foundation.dart';
import '../../../domain_layer/coordinates/point.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../core/base_viewmodel.dart';

class CoordinatesViewModel extends BaseViewModel {
  final JobService _jobService;
  final ValueNotifier<String> _coordinateFormat = ValueNotifier<String>('YXZ');

  CoordinatesViewModel(this._jobService);

  ValueListenable<List<Point>> get points => _jobService.points;
  ValueListenable<String?> get currentJobName => _jobService.currentJobName;
  ValueNotifier<String> get coordinateFormat => _coordinateFormat;

  Future<void> init() async {
    await runBusyFuture(_jobService.loadPoints());
    await _loadCoordinateFormat();
  }

  Future<void> _loadCoordinateFormat() async {
    try {
      final jobDefaults = await _jobService.getJobDefaults();
      if (jobDefaults != null) {
        _coordinateFormat.value = jobDefaults.coordinateFormat ?? 'YXZ';
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
