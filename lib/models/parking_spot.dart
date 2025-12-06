/// Enum for different parking spot types
enum SpotType {
  regular,
  handicapped,
  evCharging,
}

/// Model representing a single parking spot
class ParkingSpot {
  final String id;
  double x;
  double y;
  double width;
  double height;
  double rotation;
  SpotType type;
  String? label;

  ParkingSpot({
    required this.id,
    required this.x,
    required this.y,
    this.width = 60,
    this.height = 100,
    this.rotation = 0,
    this.type = SpotType.regular,
    this.label,
  });

  /// Create a copy of this spot with optional overrides
  ParkingSpot copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    SpotType? type,
    String? label,
  }) {
    return ParkingSpot(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      type: type ?? this.type,
      label: label ?? this.label,
    );
  }

  /// Convert spot to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'type': type.name,
      'label': label,
    };
  }

  /// Create spot from JSON
  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 60,
      height: (json['height'] as num?)?.toDouble() ?? 100,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      type: SpotType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SpotType.regular,
      ),
      label: json['label'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingSpot &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
