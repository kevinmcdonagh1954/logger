/// Represents a point in a job
class Point {
  final int? id; // Database id (null when not yet saved)
  final String comment;
  final double y;
  final double x;
  final double z; // Changed to non-nullable, will default to 0.0
  final String? descriptor; // Changed from category to descriptor
  final bool isDeleted; // Add isDeleted field

  const Point({
    this.id,
    required this.comment,
    required this.y,
    required this.x,
    double? z, // Make parameter optional but type nullable
    this.descriptor, // Changed from category to descriptor
    this.isDeleted = false, // Default to false
  }) : z = z ?? 0.0; // Default to 0.0 if z is null

  /// Create a Point from a map (used for database operations)
  factory Point.fromMap(Map<String, dynamic> map) {
    return Point(
      id: map['id'] as int?,
      comment: map['comment'] as String,
      y: map['y'] as double,
      x: map['x'] as double,
      z: (map['z'] as num?)?.toDouble() ??
          0.0, // Convert to double, default to 0.0
      descriptor:
          map['descriptor'] as String?, // Changed from category to descriptor
      isDeleted: (map['isDeleted'] as int?) == 1, // Convert integer to boolean
    );
  }

  /// Create a Point from a CSV record
  factory Point.fromCSV(Map<String, dynamic> record) {
    return Point(
      comment: record['comment']?.toString() ?? '',
      y: double.tryParse(record['y']?.toString() ?? '0') ?? 0.0,
      x: double.tryParse(record['x']?.toString() ?? '0') ?? 0.0,
      z: double.tryParse(record['z']?.toString() ?? '0') ??
          0.0, // Default to 0.0
      descriptor: record['descriptor']
          ?.toString(), // Changed from category to descriptor
      isDeleted: record['isDeleted'] as bool? ?? false,
    );
  }

  /// Convert Point to a map for database operations
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'comment': comment,
      'y': y,
      'x': x,
      'z': z, // Always include z since it's non-nullable
      if (descriptor != null) 'descriptor': descriptor,
      'isDeleted': isDeleted ? 1 : 0, // Convert boolean to integer
    };
  }

  /// Create a copy of this Point with the given fields replaced with new values
  Point copyWith({
    int? id,
    String? comment,
    double? y,
    double? x,
    double? z,
    String? descriptor, // Changed from category to descriptor
    bool? isDeleted,
  }) {
    return Point(
      id: id ?? this.id,
      comment: comment ?? this.comment,
      y: y ?? this.y,
      x: x ?? this.x,
      z: z ?? this.z,
      descriptor:
          descriptor ?? this.descriptor, // Changed from category to descriptor
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'Point{id: $id, comment: $comment, y: $y, x: $x, z: $z, descriptor: $descriptor, isDeleted: $isDeleted}'; // Changed from category to descriptor
  }
}
