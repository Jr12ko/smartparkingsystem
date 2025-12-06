import 'dart:convert';
import 'parking_spot.dart';
import 'road.dart';
import 'obstacle.dart';

/// Model representing an entire parking grid layout
class ParkingGrid {
  String name;
  double canvasWidth;
  double canvasHeight;
  double gridSize;
  List<ParkingSpot> spots;
  List<Road> roads;
  List<Obstacle> obstacles;
  DateTime createdAt;
  DateTime? updatedAt;

  ParkingGrid({
    required this.name,
    this.canvasWidth = 800,
    this.canvasHeight = 600,
    this.gridSize = 20,
    List<ParkingSpot>? spots,
    List<Road>? roads,
    List<Obstacle>? obstacles,
    DateTime? createdAt,
    this.updatedAt,
  })  : spots = spots ?? [],
        roads = roads ?? [],
        obstacles = obstacles ?? [],
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

  /// Add a new road to the grid
  void addRoad(Road road) {
    roads.add(road);
    updatedAt = DateTime.now();
  }

  /// Remove a road from the grid
  bool removeRoad(String roadId) {
    final lengthBefore = roads.length;
    roads.removeWhere((r) => r.id == roadId);
    if (roads.length != lengthBefore) {
      updatedAt = DateTime.now();
      return true;
    }
    return false;
  }

  /// Find a road by ID
  Road? findRoad(String roadId) {
    try {
      return roads.firstWhere((r) => r.id == roadId);
    } catch (_) {
      return null;
    }
  }

  /// Add a new obstacle to the grid
  void addObstacle(Obstacle obstacle) {
    obstacles.add(obstacle);
    updatedAt = DateTime.now();
  }

  /// Remove an obstacle from the grid
  bool removeObstacle(String obstacleId) {
    final lengthBefore = obstacles.length;
    obstacles.removeWhere((o) => o.id == obstacleId);
    if (obstacles.length != lengthBefore) {
      updatedAt = DateTime.now();
      return true;
    }
    return false;
  }

  /// Find an obstacle by ID
  Obstacle? findObstacle(String obstacleId) {
    try {
      return obstacles.firstWhere((o) => o.id == obstacleId);
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

  /// Generate a unique road ID
  String generateRoadId() {
    int maxNum = 0;
    for (final road in roads) {
      final match = RegExp(r'^R(\d+)$').firstMatch(road.id);
      if (match != null) {
        final num = int.tryParse(match.group(1)!) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }
    return 'R${maxNum + 1}';
  }

  /// Generate a unique obstacle ID
  String generateObstacleId() {
    int maxNum = 0;
    for (final obstacle in obstacles) {
      final match = RegExp(r'^O(\d+)$').firstMatch(obstacle.id);
      if (match != null) {
        final num = int.tryParse(match.group(1)!) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }
    return 'O${maxNum + 1}';
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
      'roads': roads.map((r) => r.toJson()).toList(),
      'obstacles': obstacles.map((o) => o.toJson()).toList(),
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
      roads: (json['roads'] as List<dynamic>?)
              ?.map((r) => Road.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      obstacles: (json['obstacles'] as List<dynamic>?)
              ?.map((o) => Obstacle.fromJson(o as Map<String, dynamic>))
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
