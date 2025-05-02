import 'package:flutter/foundation.dart';

class UsageSession {
  final int? id;
  final String? jobName;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final double? latitude;
  final double? longitude;

  UsageSession({
    this.id,
    this.jobName,
    required this.startTime,
    this.endTime,
    required this.duration,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobName': jobName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration.inSeconds,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory UsageSession.fromMap(Map<String, dynamic> map) {
    return UsageSession(
      id: map['id'] as int?,
      jobName: map['jobName'] as String?,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
      duration: Duration(seconds: map['duration'] as int),
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
    );
  }

  @override
  String toString() {
    return 'UsageSession(id: $id, jobName: $jobName, startTime: $startTime, endTime: $endTime, duration: $duration, latitude: $latitude, longitude: $longitude)';
  }
}
