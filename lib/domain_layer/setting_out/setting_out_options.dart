import 'package:logger/domain_layer/coordinates/point.dart';

/// Enum representing different types of setting out tasks
enum SettingOutTask {
  /// Pipeline setting out
  pipeline(1),

  /// Reserved for future use
  reserved2(2),

  /// Reserved for future use
  reserved3(3),

  /// Reserved for future use
  reserved4(4),

  /// Reference line setting out
  referenceLine(5),

  /// Profile poles setting out (YLine=Height Difference, XLine=Travel)
  profilePoles(6),

  /// Cadastral setting out
  cadastral(7),

  /// Cadastral short version
  cadastralShort(201),

  /// Z-only setting out
  zOnly(8),

  /// Setout/check YXZ
  setoutCheckYXZ(12);

  final int value;
  const SettingOutTask(this.value);
}

/// Class representing all options for setting out operations
class SettingOutOptions {
  /// Point identifier or chainage
  final String pointId;

  /// New Y coordinate value to be placed
  final double y;

  /// New X coordinate value to be placed
  final double x;

  /// New Z coordinate value to be placed
  final double z;

  /// Y line value (start line Y value or height difference)
  final double yLine;

  /// X line value (start line X value or travel)
  final double xLine;

  /// Straight direction for Y1-X1
  final double straightDirection;

  /// Type of setting out task
  final SettingOutTask task;

  /// Prompt message (e.g., "Place" or "Check")
  final String prompt;

  /// Running chainage of pipeline
  final double runningChainage;

  /// Offset distance from centerline
  final double offset;

  /// Start value for reference line
  final double startValue;

  const SettingOutOptions({
    required this.pointId,
    required this.y,
    required this.x,
    required this.z,
    required this.yLine,
    required this.xLine,
    required this.straightDirection,
    required this.task,
    required this.prompt,
    required this.runningChainage,
    required this.offset,
    required this.startValue,
  });

  /// Creates a [Point] object from the Y, X, Z coordinates
  Point toPoint() {
    return Point(
      y: y,
      x: x,
      z: z,
      comment: pointId,
    );
  }

  /// Creates a [SettingOutOptions] from a [Point] and additional parameters
  factory SettingOutOptions.fromPoint({
    required Point point,
    required double yLine,
    required double xLine,
    required double straightDirection,
    required SettingOutTask task,
    required String prompt,
    required double runningChainage,
    required double offset,
    required double startValue,
  }) {
    return SettingOutOptions(
      pointId: point.comment,
      y: point.y,
      x: point.x,
      z: point.z,
      yLine: yLine,
      xLine: xLine,
      straightDirection: straightDirection,
      task: task,
      prompt: prompt,
      runningChainage: runningChainage,
      offset: offset,
      startValue: startValue,
    );
  }
}
