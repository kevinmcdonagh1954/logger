/// Helper class for degrees, minutes, seconds representation
class DMS {
  final int degrees;
  final int minutes;
  final double seconds;

  DMS(this.degrees, this.minutes, this.seconds);
}

/// Class representing an observation in a fixing routine
class Observation {
  /// The point name
  final String pointName;

  /// Whether this is a known point
  final bool isKnownPoint;

  /// The Y coordinate of the observed point
  double y;

  /// The X coordinate of the observed point
  double x;

  /// The Z coordinate of the observed point
  double z;

  /// The Y coordinate held for this point
  final double yHeld;

  /// The X coordinate held for this point
  final double xHeld;

  /// The Z coordinate held for this point
  final double zHeld;

  /// The horizontal angle of the observation (in degrees)
  double? horizontalAngle;

  /// The vertical angle of the observation (in degrees)
  double? verticalAngle;

  /// The horizontal distance of the observation (in meters)
  double? horizontalDistance;

  /// The slope distance of the observation (in meters)
  double? slopeDistance;

  /// The target height of the observation (in meters)
  double? targetHeight;

  /// The height of the observation point
  final double height;

  /// The distance string representation
  final String distanceString;

  /// The direction string representation
  final String directionString;

  /// The timestamp of the observation
  final DateTime timestamp;

  /// Constructor
  Observation({
    required this.pointName,
    required this.isKnownPoint,
    required this.y,
    required this.x,
    required this.z,
    required this.yHeld,
    required this.xHeld,
    required this.zHeld,
    this.horizontalAngle,
    this.verticalAngle,
    this.horizontalDistance,
    this.slopeDistance,
    this.targetHeight,
    required this.height,
    required this.distanceString,
    required this.directionString,
    required this.timestamp,
  });

  /// Creates an empty observation (equivalent to the Psion initialization)
  factory Observation.empty() {
    return Observation(
      pointName: " ",
      isKnownPoint: false,
      y: 0.0,
      x: 0.0,
      z: 0.0,
      yHeld: 0.0,
      xHeld: 0.0,
      zHeld: 0.0,
      height: 0.0,
      distanceString: "",
      directionString: "",
      timestamp: DateTime.now(),
    );
  }

  /// Creates an observation for a known control point
  factory Observation.knownPoint({
    required String pointName,
    required double y,
    required double x,
    double z = 0.0,
  }) {
    return Observation(
      pointName: pointName,
      isKnownPoint: true,
      y: y,
      x: x,
      z: z,
      yHeld: y, // For known points, held values are same as coordinates
      xHeld: x,
      zHeld: z,
      height: 0.0,
      distanceString: "",
      directionString: "",
      timestamp: DateTime.now(),
    );
  }

  /// Creates an observation to an unknown point that needs to be fixed
  factory Observation.toUnknownPoint({
    required String pointName,
    double? horizontalAngle,
    double? verticalAngle,
    double? slopeDistance,
    double? targetHeight,
  }) {
    return Observation(
      pointName: pointName,
      isKnownPoint: false,
      y: 0.0, // Initialize with zero coordinates for unknown points
      x: 0.0,
      z: 0.0,
      yHeld: 0.0,
      xHeld: 0.0,
      zHeld: 0.0,
      horizontalAngle: horizontalAngle,
      verticalAngle: verticalAngle,
      slopeDistance: slopeDistance,
      targetHeight: targetHeight,
      height: 0.0,
      distanceString: slopeDistance?.toStringAsFixed(3) ?? "",
      directionString: horizontalAngle?.toStringAsFixed(3) ?? "",
      timestamp: DateTime.now(),
    );
  }

  /// Creates a list of empty observations
  static List<Observation> createEmptyList(int count) {
    return List.generate(count, (index) => Observation.empty());
  }

  /// Formats the observation data for fieldbook display
  String toFieldbookString() {
    final sb = StringBuffer();
    sb.writeln('Point: $pointName');

    if (isKnownPoint) {
      sb.writeln('Y: ${y.toStringAsFixed(3)}');
      sb.writeln('X: ${x.toStringAsFixed(3)}');
      if (z != 0.0) sb.writeln('Z: ${z.toStringAsFixed(3)}');
    }

    if (horizontalAngle != null) {
      // Convert decimal degrees to DMS for display
      final dms = _decimalToDMS(horizontalAngle!);
      sb.writeln(
          'Hz: ${dms.degrees}°${dms.minutes}\'${dms.seconds.toStringAsFixed(1)}"');
    }

    if (verticalAngle != null) {
      final dms = _decimalToDMS(verticalAngle!);
      sb.writeln(
          'V: ${dms.degrees}°${dms.minutes}\'${dms.seconds.toStringAsFixed(1)}"');
    }

    if (slopeDistance != null) {
      sb.writeln('SD: ${slopeDistance!.toStringAsFixed(3)}m');
    }

    if (targetHeight != null) {
      sb.writeln('th: ${targetHeight!.toStringAsFixed(3)}m');
    }

    return sb.toString();
  }

  /// Converts decimal degrees to degrees, minutes, seconds
  DMS _decimalToDMS(double decimal) {
    var deg = decimal.abs().floor();
    var minDecimal = (decimal.abs() - deg) * 60;
    var min = minDecimal.floor();
    var sec = (minDecimal - min) * 60;

    // Handle negative angles
    if (decimal < 0) deg = -deg;

    return DMS(deg, min, sec);
  }

  /// Checks if this observation has enough data to contribute to a fix
  bool hasUsableData() {
    // Must have either a distance or an angle
    return slopeDistance != null || horizontalAngle != null;
  }

  /// Returns a copy of this observation with updated coordinates
  Observation copyWithCoordinates({
    required double y,
    required double x,
    double? z,
  }) {
    return Observation(
      pointName: pointName,
      isKnownPoint: isKnownPoint,
      y: y,
      x: x,
      z: z ?? this.z,
      horizontalAngle: horizontalAngle,
      verticalAngle: verticalAngle,
      slopeDistance: slopeDistance,
      targetHeight: targetHeight,
      timestamp: timestamp,
      yHeld: yHeld,
      xHeld: xHeld,
      zHeld: zHeld,
      horizontalDistance: horizontalDistance,
      height: height,
      distanceString: distanceString,
      directionString: directionString,
    );
  }

  /// Create a copy of this observation with optional new values
  Observation copyWith({
    String? pointName,
    bool? isKnownPoint,
    double? y,
    double? x,
    double? z,
    double? yHeld,
    double? xHeld,
    double? zHeld,
    double? horizontalAngle,
    double? verticalAngle,
    double? horizontalDistance,
    double? slopeDistance,
    double? targetHeight,
    double? height,
    String? distanceString,
    String? directionString,
    DateTime? timestamp,
  }) {
    return Observation(
      pointName: pointName ?? this.pointName,
      isKnownPoint: isKnownPoint ?? this.isKnownPoint,
      y: y ?? this.y,
      x: x ?? this.x,
      z: z ?? this.z,
      yHeld: yHeld ?? this.yHeld,
      xHeld: xHeld ?? this.xHeld,
      zHeld: zHeld ?? this.zHeld,
      horizontalAngle: horizontalAngle ?? this.horizontalAngle,
      verticalAngle: verticalAngle ?? this.verticalAngle,
      horizontalDistance: horizontalDistance ?? this.horizontalDistance,
      slopeDistance: slopeDistance ?? this.slopeDistance,
      targetHeight: targetHeight ?? this.targetHeight,
      height: height ?? this.height,
      distanceString: distanceString ?? this.distanceString,
      directionString: directionString ?? this.directionString,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert observation to a map
  Map<String, dynamic> toMap() {
    return {
      'pointName': pointName,
      'isKnownPoint': isKnownPoint,
      'y': y,
      'x': x,
      'z': z,
      'yHeld': yHeld,
      'xHeld': xHeld,
      'zHeld': zHeld,
      'horizontalAngle': horizontalAngle,
      'verticalAngle': verticalAngle,
      'horizontalDistance': horizontalDistance,
      'slopeDistance': slopeDistance,
      'targetHeight': targetHeight,
      'height': height,
      'distanceString': distanceString,
      'directionString': directionString,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create an observation from a map
  factory Observation.fromMap(Map<String, dynamic> map) {
    return Observation(
      pointName: map['pointName'] as String,
      isKnownPoint: map['isKnownPoint'] as bool,
      y: map['y'] as double,
      x: map['x'] as double,
      z: map['z'] as double,
      yHeld: map['yHeld'] as double,
      xHeld: map['xHeld'] as double,
      zHeld: map['zHeld'] as double,
      horizontalAngle: map['horizontalAngle'] as double?,
      verticalAngle: map['verticalAngle'] as double?,
      horizontalDistance: map['horizontalDistance'] as double?,
      slopeDistance: map['slopeDistance'] as double?,
      targetHeight: map['targetHeight'] as double?,
      height: map['height'] as double,
      distanceString: map['distanceString'] as String,
      directionString: map['directionString'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
