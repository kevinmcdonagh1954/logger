class Point {
  final int? id;
  final double x;
  final double y;
  final double z;
  final String comment;
  final String? descriptor;

  Point({
    this.id,
    required this.x,
    required this.y,
    required this.z,
    this.comment = '',
    this.descriptor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'z': z,
        'comment': comment,
        'descriptor': descriptor,
      };

  factory Point.fromJson(Map<String, dynamic> json) => Point(
        id: json['id'] as int?,
        x: json['x'] as double,
        y: json['y'] as double,
        z: json['z'] as double,
        comment: json['comment'] as String? ?? '',
        descriptor: json['descriptor'] as String?,
      );
}
