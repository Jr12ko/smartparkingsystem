import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import '../../models/parking_grid.dart';
import '../../models/parking_spot.dart';
import '../../models/road.dart';
import '../../models/obstacle.dart';

/// Custom painter for rendering the parking grid
class GridPainter extends CustomPainter {
  final ParkingGrid grid;
  final Set<String> selectedSpotIds;
  final Set<String> selectedRoadIds;
  final Set<String> selectedObstacleIds;
  final Offset? dragStart;
  final Offset? dragEnd;
  final Offset? rulerStart;
  final Offset? rulerEnd;
  final bool isHoveringRuler;
  final Offset? roadDrawStart;
  final Offset? roadDrawEnd;
  final int spotCount;
  final int roadCount;
  final int obstacleCount;

  GridPainter({
    required this.grid,
    required this.selectedSpotIds,
    this.selectedRoadIds = const {},
    this.selectedObstacleIds = const {},
    this.dragStart,
    this.dragEnd,
    this.rulerStart,
    this.rulerEnd,
    this.isHoveringRuler = false,
    this.roadDrawStart,
    this.roadDrawEnd,
  })  : spotCount = grid.spots.length,
        roadCount = grid.roads.length,
        obstacleCount = grid.obstacles.length;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // Draw grid lines
    for (double x = 0; x <= grid.canvasWidth; x += grid.gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, grid.canvasHeight), gridPaint);
    }
    for (double y = 0; y <= grid.canvasHeight; y += grid.gridSize) {
      canvas.drawLine(Offset(0, y), Offset(grid.canvasWidth, y), gridPaint);
    }

    // Draw roads (behind spots)
    for (final road in grid.roads) {
      final isSelected = selectedRoadIds.contains(road.id);
      _drawRoad(canvas, road, isSelected);
    }

    // Draw obstacles (behind spots)
    for (final obstacle in grid.obstacles) {
      final isSelected = selectedObstacleIds.contains(obstacle.id);
      _drawObstacle(canvas, obstacle, isSelected);
    }

    // Draw parking spots (on top)
    for (final spot in grid.spots) {
      final isSelected = selectedSpotIds.contains(spot.id);
      _drawSpot(canvas, spot, isSelected);
    }

    // Draw road preview during drawing
    if (roadDrawStart != null && roadDrawEnd != null) {
      _drawRoadPreview(canvas, roadDrawStart!, roadDrawEnd!);
    }

    // Draw drag selection rectangle
    if (dragStart != null && dragEnd != null) {
      final selectionRect = Rect.fromPoints(dragStart!, dragEnd!);
      final selectionPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      final selectionBorderPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRect(selectionRect, selectionPaint);
      canvas.drawRect(selectionRect, selectionBorderPaint);
    }

    // Draw ruler measurement line
    if (rulerStart != null && rulerEnd != null) {
      _drawRuler(canvas, rulerStart!, rulerEnd!);
    }
  }

  void _drawRoad(Canvas canvas, Road road, bool isSelected) {
    final rect = Rect.fromLTWH(road.x, road.y, road.width, road.height);

    // Road fill - gray/asphalt color
    final fillPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      fillPaint,
    );

    // Center dashed line (simplified as solid)
    final centerLinePaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    if (road.width > road.height) {
      // Horizontal road
      canvas.drawLine(
        Offset(road.x + 10, road.y + road.height / 2),
        Offset(road.x + road.width - 10, road.y + road.height / 2),
        centerLinePaint,
      );
    } else {
      // Vertical road
      canvas.drawLine(
        Offset(road.x + road.width / 2, road.y + 10),
        Offset(road.x + road.width / 2, road.y + road.height - 10),
        centerLinePaint,
      );
    }

    // Border
    final borderPaint = Paint()
      ..color = isSelected ? Colors.white : Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      borderPaint,
    );

    // ID label
    final textPainter = TextPainter(
      text: TextSpan(
        text: road.id,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(road.x + 4, road.y + 4),
    );
  }

  void _drawObstacle(Canvas canvas, Obstacle obstacle, bool isSelected) {
    final rect =
        Rect.fromLTWH(obstacle.x, obstacle.y, obstacle.width, obstacle.height);
    final color = _getObstacleColor(obstacle.type);

    // Fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      fillPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = isSelected ? Colors.white : color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      borderPaint,
    );

    // ID label
    final textPainter = TextPainter(
      text: TextSpan(
        text: obstacle.id,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        obstacle.x + (obstacle.width - textPainter.width) / 2,
        obstacle.y + (obstacle.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawRoadPreview(Canvas canvas, Offset start, Offset end) {
    // Calculate preview rectangle
    final dx = (end.dx - start.dx).abs();
    final dy = (end.dy - start.dy).abs();
    double width, height;
    if (dx > dy) {
      width = dx;
      height = 60;
    } else {
      width = 60;
      height = dy;
    }
    final x = start.dx < end.dx ? start.dx : end.dx;
    final y = start.dy < end.dy ? start.dy : end.dy;
    final rect = Rect.fromLTWH(x, y, width, height);

    // Preview fill
    final fillPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      fillPaint,
    );

    // Preview border
    final borderPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      borderPaint,
    );
  }

  Color _getObstacleColor(ObstacleType type) {
    switch (type) {
      case ObstacleType.pillar:
        return Colors.grey.shade800;
      case ObstacleType.wall:
        return Colors.brown.shade700;
      case ObstacleType.barrier:
        return Colors.orange.shade800;
    }
  }

  void _drawRuler(Canvas canvas, Offset start, Offset end) {
    final distance = (end - start).distance;

    // Change color to red when hovering with delete tool
    final rulerColor = isHoveringRuler ? Colors.red : Colors.amber;

    // Main line
    final linePaint = Paint()
      ..color = rulerColor
      ..strokeWidth = isHoveringRuler ? 3 : 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, linePaint);

    // Start point circle
    final pointPaint = Paint()
      ..color = rulerColor
      ..style = PaintingStyle.fill;

    final pointRadius = isHoveringRuler ? 8.0 : 6.0;
    canvas.drawCircle(start, pointRadius, pointPaint);
    canvas.drawCircle(end, pointRadius, pointPaint);

    // Inner white circle
    final innerPointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final innerRadius = isHoveringRuler ? 4.0 : 3.0;
    canvas.drawCircle(start, innerRadius, innerPointPaint);
    canvas.drawCircle(end, innerRadius, innerPointPaint);

    // Distance label background
    final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final labelText = isHoveringRuler
        ? 'Click to delete'
        : '${distance.toStringAsFixed(1)} px';

    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw label background
    final labelRect = Rect.fromCenter(
      center: midPoint,
      width: textPainter.width + 12,
      height: textPainter.height + 6,
    );

    final labelBgPaint = Paint()
      ..color = rulerColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
      labelBgPaint,
    );

    // Draw label text
    textPainter.paint(
      canvas,
      Offset(
        midPoint.dx - textPainter.width / 2,
        midPoint.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawSpot(Canvas canvas, ParkingSpot spot, bool isSelected) {
    final color = _getSpotColor(spot.type);
    final rect = Rect.fromLTWH(spot.x, spot.y, spot.width, spot.height);

    // Fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      fillPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = isSelected ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      borderPaint,
    );

    // ID label
    final textPainter = TextPainter(
      text: TextSpan(
        text: spot.id,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        spot.x + (spot.width - textPainter.width) / 2,
        spot.y + (spot.height - textPainter.height) / 2,
      ),
    );
  }

  Color _getSpotColor(SpotType type) {
    switch (type) {
      case SpotType.regular:
        return Colors.green;
      case SpotType.handicapped:
        return Colors.blue;
      case SpotType.evCharging:
        return Colors.orange;
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return spotCount != oldDelegate.spotCount ||
        roadCount != oldDelegate.roadCount ||
        obstacleCount != oldDelegate.obstacleCount ||
        !setEquals(selectedSpotIds, oldDelegate.selectedSpotIds) ||
        !setEquals(selectedRoadIds, oldDelegate.selectedRoadIds) ||
        !setEquals(selectedObstacleIds, oldDelegate.selectedObstacleIds) ||
        dragStart != oldDelegate.dragStart ||
        dragEnd != oldDelegate.dragEnd ||
        rulerStart != oldDelegate.rulerStart ||
        rulerEnd != oldDelegate.rulerEnd ||
        isHoveringRuler != oldDelegate.isHoveringRuler ||
        roadDrawStart != oldDelegate.roadDrawStart ||
        roadDrawEnd != oldDelegate.roadDrawEnd;
  }
}
