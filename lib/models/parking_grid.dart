import 'dart:convert';
import 'parking_spot.dart';

/// Model representing an entire parking grid layout
class ParkingGrid {
  String name;
  double canvasWidth;
  double canvasHeight;
  double gridSize;
  List<ParkingSpot> spots;
  DateTime createdAt;
  DateTime? updatedAt;

  ParkingGrid({
    required this.name,
    this.canvasWidth = 800,
    this.canvasHeight = 600,
    this.gridSize = 20,
    List<ParkingSpot>? spots,
    DateTime? createdAt,
    this.updatedAt,
  })  : spots = spots ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Add a new spot to the grid
  void addSpot(ParkingSpot spot) {
    spots.add(spot);
    updatedAt = DateTime.now();
  }

  /// Remove a spot from the grid
  bool removeSpot(String spotId) {
    final lengthBefore = spots.length;
    spots.removeWhere((s) => s.id == spotId);
    if (spots.length != lengthBefore) {
      updatedAt = DateTime.now();
      return true;
    }
    return false;
  }

  /// Find a spot by ID
  ParkingSpot? findSpot(String spotId) {
    try {
      return spots.firstWhere((s) => s.id == spotId);
    } catch (_) {
      return null;
    }
  }

  /// Generate a unique spot ID
  String generateSpotId() {
    int maxNum = 0;
    for (final spot in spots) {
      final match = RegExp(r'^S(\d+)$').firstMatch(spot.id);
      if (match != null) {
        final num = int.tryParse(match.group(1)!) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }
    return 'S${maxNum + 1}';
  }

  /// Snap a position to the grid
  double snapToGrid(double value) {
    return (value / gridSize).round() * gridSize;
  }

  /// Convert grid to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
      'gridSize': gridSize,
      'spots': spots.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to JSON string (for export)
  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  /// Create grid from JSON
  factory ParkingGrid.fromJson(Map<String, dynamic> json) {
    return ParkingGrid(
      name: json['name'] as String? ?? 'Untitled',
      canvasWidth: (json['canvasWidth'] as num?)?.toDouble() ?? 800,
      canvasHeight: (json['canvasHeight'] as num?)?.toDouble() ?? 600,
      gridSize: (json['gridSize'] as num?)?.toDouble() ?? 20,
      spots: (json['spots'] as List<dynamic>?)
              ?.map((s) => ParkingSpot.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Create grid from JSON string
  factory ParkingGrid.fromJsonString(String jsonString) {
    return ParkingGrid.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Create an empty grid with default settings
  factory ParkingGrid.empty({String name = 'New Parking Grid'}) {
    return ParkingGrid(name: name);
  }
}
