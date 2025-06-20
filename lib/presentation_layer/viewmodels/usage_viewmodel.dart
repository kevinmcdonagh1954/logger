import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../data_layer/models/usage_session.dart';
import '../../data_layer/services/usage_service.dart';

class UsageViewModel extends ChangeNotifier {
  final UsageService _usageService = UsageService();
  Timer? _timer;
  DateTime? _sessionStartTime;
  String? _currentJobName;
  Duration _currentDuration = Duration.zero;
  UsageSession? _currentSession;
  Position? _currentPosition;

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  Duration get currentDuration => _currentDuration;
  bool get isTracking => _timer != null;
  Position? get currentPosition => _currentPosition;

  Future<void> _getCurrentLocation() async {
    if (_isDisposed) return;
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void startTracking(String? jobName) async {
    if (_timer != null || _isDisposed) return;

    await _getCurrentLocation();
    if (_isDisposed) return;
    _sessionStartTime = DateTime.now();
    _currentJobName = jobName;
    _currentDuration = Duration.zero;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) return;
      _currentDuration = DateTime.now().difference(_sessionStartTime!);
      if (!_isDisposed) notifyListeners();
    });

    _currentSession = UsageSession(
      startTime: _sessionStartTime!,
      jobName: _currentJobName,
      duration: _currentDuration,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
    );

    _usageService.insertSession(_currentSession!).then((id) {
      if (_isDisposed) return;
      _currentSession = UsageSession(
        id: id,
        startTime: _sessionStartTime!,
        jobName: _currentJobName,
        duration: _currentDuration,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );
    });
  }

  Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;

    if (_currentSession != null) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_sessionStartTime!);

      final updatedSession = UsageSession(
        id: _currentSession!.id,
        startTime: _sessionStartTime!,
        endTime: endTime,
        jobName: _currentJobName,
        duration: duration,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      await _usageService.updateSession(updatedSession);
      if (_isDisposed) return;
      _currentSession = null;
      _sessionStartTime = null;
      _currentDuration = Duration.zero;
      _currentPosition = null;
    }

    if (!_isDisposed) notifyListeners();
  }

  Future<List<UsageSession>> getAllSessions() async {
    if (_isDisposed) return [];
    return await _usageService.getAllSessions();
  }

  Future<List<UsageSession>> getSessionsByJob(String jobName) async {
    if (_isDisposed) return [];
    return await _usageService.getSessionsByJob(jobName);
  }

  Future<Duration> getTotalDurationByJob(String jobName) async {
    if (_isDisposed) return Duration.zero;
    return await _usageService.getTotalDurationByJob(jobName);
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
