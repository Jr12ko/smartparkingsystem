/// Enum for different obstacle types
enum ObstacleType {
  pillar,
  wall,
  barrier,
}

/// Model representing an obstacle/pillar in the parking lot
class Obstacle {
  final String id;
  double x;
  double y;
  double width;
  double height;
  ObstacleType type;
  String? label;

  Obstacle({
    required this.id,
    required this.x,
    required this.y,
    this.width = 40,
    this.height = 40,
    this.type = ObstacleType.pillar,
    this.label,
  });

  /// Create a copy of this obstacle with optional overrides
  Obstacle copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    ObstacleType? type,
    String? label,
  }) {
    return Obstacle(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      type: type ?? this.type,
      label: label ?? this.label,
    );
  }

  /// Convert obstacle to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'type': type.name,
      'label': label,
    };
  }

  /// Create obstacle from JSON
  factory Obstacle.fromJson(Map<String, dynamic> json) {
    return Obstacle(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 40,
      height: (json['height'] as num?)?.toDouble() ?? 40,
      type: ObstacleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ObstacleType.pillar,
      ),
      label: json['label'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Obstacle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
