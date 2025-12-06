/// Model representing a road segment in the parking lot
class Road {
  final String id;
  double x;
  double y;
  double width;
  double height;
  double rotation;
  bool isOneWay;
  String? label;

  Road({
    required this.id,
    required this.x,
    required this.y,
    this.width = 80,
    this.height = 200,
    this.rotation = 0,
    this.isOneWay = false,
    this.label,
  });

  /// Create a copy of this road with optional overrides
  Road copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    bool? isOneWay,
    String? label,
  }) {
    return Road(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      isOneWay: isOneWay ?? this.isOneWay,
      label: label ?? this.label,
    );
  }

  /// Convert road to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'isOneWay': isOneWay,
      'label': label,
    };
  }

  /// Create road from JSON
  factory Road.fromJson(Map<String, dynamic> json) {
    return Road(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 80,
      height: (json['height'] as num?)?.toDouble() ?? 200,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      isOneWay: json['isOneWay'] as bool? ?? false,
      label: json['label'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Road && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
