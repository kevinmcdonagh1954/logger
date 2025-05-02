/// Represents the default settings for a job
class JobDefaults {
  final String? jobDescription;
  final String databaseFileName; // Required, max 20 chars, read-only
  final String? coordinateFormat; // YXZ, ENZ, or MPC
  final String? instrument; // Various options like Sokkia, Leica, etc.
  final String? dualCapture; // Y/N
  final String? scaleFactor; // Default = 1
  final String? heightAboveMSL;
  final String? meanYValue;
  final String? verticalAngleIndexError; // Default = 0
  final String? spotShotTolerance; // Default = 1.0 metres
  final String? delayAndRetry; // Default = 4 seconds
  final String? timeout; // Default = 10 seconds
  final String? precision; // mm or cm, Default = mm
  final String? commsBaudRate; // Default = 9600 bps
  final String? horizontalAlignmentOffsetTolerance; // Default = 50 metres
  final String? maximumSearchDistanceFromCL; // Default = 50 metres
  final String? angularMeasurement; // degrees or grads, Default = degrees

  /// Creates a new job defaults instance
  JobDefaults({
    this.jobDescription,
    required this.databaseFileName,
    this.coordinateFormat = 'YXZ',
    this.instrument,
    this.dualCapture = 'N',
    this.scaleFactor = '1',
    this.heightAboveMSL,
    this.meanYValue,
    this.verticalAngleIndexError = '0',
    this.spotShotTolerance = '1.0',
    this.delayAndRetry = '4',
    this.timeout = '10',
    this.precision = 'mm',
    this.commsBaudRate = '9600',
    this.horizontalAlignmentOffsetTolerance = '50',
    this.maximumSearchDistanceFromCL = '50',
    this.angularMeasurement = 'degrees',
  });

  /// Convert a map to a JobDefaults object
  factory JobDefaults.fromMap(Map<String, dynamic> map) {
    return JobDefaults(
      databaseFileName: map['databaseFileName'] as String,
      jobDescription: map['jobDescription'] as String? ?? '',
      coordinateFormat: map['coordinateFormat'] as String? ?? 'YXZ',
      instrument: map['instrument'] as String? ?? 'MANUAL',
      dualCapture: map['dualCapture'] as String? ?? 'N',
      scaleFactor: map['scaleFactor'] as String? ?? '1',
      heightAboveMSL: map['heightAboveMSL'] as String? ?? '0',
      meanYValue: map['meanYValue'] as String? ?? '0',
      verticalAngleIndexError: map['verticalAngleIndexError'] as String? ?? '0',
      spotShotTolerance: map['spotShotTolerance'] as String? ?? '1.0',
      delayAndRetry: map['delayAndRetry'] as String? ?? '4',
      timeout: map['timeout'] as String? ?? '10',
      precision: map['precision'] as String? ?? 'mm',
      commsBaudRate: map['commsBaudRate'] as String? ?? '9600',
      horizontalAlignmentOffsetTolerance:
          map['horizontalAlignmentOffsetTolerance'] as String? ?? '50',
      maximumSearchDistanceFromCL:
          map['maximumSearchDistanceFromCL'] as String? ?? '50',
      angularMeasurement: map['angularMeasurement'] as String? ?? 'degrees',
    );
  }

  /// Convert JobDefaults object to a map
  Map<String, dynamic> toMap() {
    return {
      'databaseFileName': databaseFileName,
      'jobDescription': jobDescription,
      'coordinateFormat': coordinateFormat,
      'instrument': instrument,
      'dualCapture': dualCapture,
      'scaleFactor': scaleFactor,
      'heightAboveMSL': heightAboveMSL,
      'meanYValue': meanYValue,
      'verticalAngleIndexError': verticalAngleIndexError,
      'spotShotTolerance': spotShotTolerance,
      'delayAndRetry': delayAndRetry,
      'timeout': timeout,
      'precision': precision,
      'commsBaudRate': commsBaudRate,
      'horizontalAlignmentOffsetTolerance': horizontalAlignmentOffsetTolerance,
      'maximumSearchDistanceFromCL': maximumSearchDistanceFromCL,
      'angularMeasurement': angularMeasurement,
    };
  }

  /// Creates a copy of this job defaults instance with the given fields replaced with new values
  JobDefaults copyWith({
    String? jobDescription,
    String? databaseFileName,
    String? coordinateFormat,
    String? instrument,
    String? dualCapture,
    String? scaleFactor,
    String? heightAboveMSL,
    String? meanYValue,
    String? verticalAngleIndexError,
    String? spotShotTolerance,
    String? delayAndRetry,
    String? timeout,
    String? precision,
    String? commsBaudRate,
    String? horizontalAlignmentOffsetTolerance,
    String? maximumSearchDistanceFromCL,
    String? angularMeasurement,
  }) {
    return JobDefaults(
      jobDescription: jobDescription ?? this.jobDescription,
      databaseFileName: databaseFileName ?? this.databaseFileName,
      coordinateFormat: coordinateFormat ?? this.coordinateFormat,
      instrument: instrument ?? this.instrument,
      dualCapture: dualCapture ?? this.dualCapture,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      heightAboveMSL: heightAboveMSL ?? this.heightAboveMSL,
      meanYValue: meanYValue ?? this.meanYValue,
      verticalAngleIndexError:
          verticalAngleIndexError ?? this.verticalAngleIndexError,
      spotShotTolerance: spotShotTolerance ?? this.spotShotTolerance,
      delayAndRetry: delayAndRetry ?? this.delayAndRetry,
      timeout: timeout ?? this.timeout,
      precision: precision ?? this.precision,
      commsBaudRate: commsBaudRate ?? this.commsBaudRate,
      horizontalAlignmentOffsetTolerance: horizontalAlignmentOffsetTolerance ??
          this.horizontalAlignmentOffsetTolerance,
      maximumSearchDistanceFromCL:
          maximumSearchDistanceFromCL ?? this.maximumSearchDistanceFromCL,
      angularMeasurement: angularMeasurement ?? this.angularMeasurement,
    );
  }

  /// Returns a string representation of this job defaults instance
  @override
  String toString() {
    return 'JobDefaults{jobDescription: $jobDescription, databaseFileName: $databaseFileName, '
        'coordinateFormat: $coordinateFormat, instrument: $instrument, dualCapture: $dualCapture, '
        'scaleFactor: $scaleFactor, heightAboveMSL: $heightAboveMSL, meanYValue: $meanYValue, '
        'verticalAngleIndexError: $verticalAngleIndexError, spotShotTolerance: $spotShotTolerance, '
        'delayAndRetry: $delayAndRetry, timeout: $timeout, precision: $precision, '
        'commsBaudRate: $commsBaudRate, horizontalAlignmentOffsetTolerance: $horizontalAlignmentOffsetTolerance, '
        'maximumSearchDistanceFromCL: $maximumSearchDistanceFromCL, angularMeasurement: $angularMeasurement}';
  }
}
