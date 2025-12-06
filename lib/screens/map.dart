import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/parking_grid.dart';
import '../models/parking_spot.dart';
import '../widgets/navigation.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late ParkingGrid _grid;
  final TransformationController _transformController =
      TransformationController();

  // Spot availability status (in real app, this would come from backend)
  final Map<String, bool> _spotAvailability = {};

  String? _selectedSpotId;
  List<Map<String, dynamic>> _currentRoute = [];
  int _currentStepIndex = 0;

  IconData _currentIcon = Icons.info;
  String _currentDistance = "Welcome!";
  String _currentInstruction = "Please select a parking spot";

  @override
  void initState() {
    super.initState();
    _initializeGrid();
  }

  void _initializeGrid() {
    // Create a sample grid (in real app, load from JSON/backend)
    _grid = ParkingGrid.empty(name: 'Main Parking Lot');

    // Add sample spots
    final spots = [
      ParkingSpot(id: 'A1', x: 50, y: 50, type: SpotType.regular),
      ParkingSpot(id: 'A2', x: 50, y: 160, type: SpotType.regular),
      ParkingSpot(id: 'A3', x: 50, y: 270, type: SpotType.regular),
      ParkingSpot(id: 'A4', x: 50, y: 380, type: SpotType.handicapped),
      ParkingSpot(id: 'B1', x: 180, y: 50, type: SpotType.regular),
      ParkingSpot(id: 'B2', x: 180, y: 160, type: SpotType.evCharging),
      ParkingSpot(id: 'B3', x: 180, y: 270, type: SpotType.regular),
      ParkingSpot(id: 'B4', x: 180, y: 380, type: SpotType.regular),
    ];

    for (final spot in spots) {
      _grid.addSpot(spot);
      // Random availability for demo (in real app, from backend)
      _spotAvailability[spot.id] = spot.id.hashCode % 3 != 0;
    }
  }

  void _onSpotTapped(String spotId) {
    final isAvailable = _spotAvailability[spotId] ?? false;

    if (isAvailable) {
      developer.log('Spot $spotId selected!');
      setState(() {
        _selectedSpotId = spotId;
        _startNavigationForSpot(spotId);
      });
    } else {
      developer.log('Spot $spotId is taken.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Spot $spotId is currently occupied'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _startNavigationForSpot(String spotId) {
    // Generate simple navigation route
    _currentRoute = [
      {
        'icon': Icons.straight,
        'distance': '100 m',
        'instruction': 'Go straight'
      },
      {
        'icon': Icons.turn_right,
        'distance': '50 m',
        'instruction': 'Turn right'
      },
      {
        'icon': Icons.local_parking,
        'distance': 'Arrived',
        'instruction': 'Park at spot $spotId'
      },
    ];
    _currentStepIndex = 0;
    _updateNavigationUi();
  }

  void _nextStep() {
    if (_currentRoute.isNotEmpty &&
        _currentStepIndex < _currentRoute.length - 1) {
      setState(() {
        _currentStepIndex++;
        _updateNavigationUi();
      });
    }
  }

  void _updateNavigationUi() {
    _currentIcon = _currentRoute[_currentStepIndex]['icon'];
    _currentDistance = _currentRoute[_currentStepIndex]['distance'];
    _currentInstruction = _currentRoute[_currentStepIndex]['instruction'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_grid.name),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _currentRoute.isNotEmpty ? _nextStep : null,
        backgroundColor: _currentRoute.isNotEmpty
            ? Theme.of(context).primaryColor
            : Colors.grey,
        child: const Icon(Icons.arrow_forward),
      ),
      body: Column(
        children: [
          NavigationWidget(
            icon: _currentIcon,
            distance: _currentDistance,
            instruction: _currentInstruction,
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  transformationController: _transformController,
                  constrained: false,
                  minScale: 0.5,
                  maxScale: 3.0,
                  boundaryMargin: const EdgeInsets.all(100),
                  child: GestureDetector(
                    onTapUp: (details) {
                      final localPos =
                          _transformController.toScene(details.localPosition);
                      _handleTap(localPos.dx, localPos.dy);
                    },
                    child: Container(
                      width: _grid.canvasWidth,
                      height: _grid.canvasHeight,
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: CustomPaint(
                        size: Size(_grid.canvasWidth, _grid.canvasHeight),
                        painter: UserGridPainter(
                          grid: _grid,
                          spotAvailability: _spotAvailability,
                          selectedSpotId: _selectedSpotId,
                          isDarkMode:
                              Theme.of(context).brightness == Brightness.dark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  void _handleTap(double x, double y) {
    // Find spot at tap position
    for (final spot in _grid.spots) {
      if (x >= spot.x &&
          x <= spot.x + spot.width &&
          y >= spot.y &&
          y <= spot.y + spot.height) {
        _onSpotTapped(spot.id);
        return;
      }
    }
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(Colors.green, 'Available'),
          _legendItem(Colors.red, 'Occupied'),
          _legendItem(Colors.blue, 'Selected'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Simple painter for user-facing parking grid
class UserGridPainter extends CustomPainter {
  final ParkingGrid grid;
  final Map<String, bool> spotAvailability;
  final String? selectedSpotId;
  final bool isDarkMode;

  UserGridPainter({
    required this.grid,
    required this.spotAvailability,
    this.selectedSpotId,
    this.isDarkMode = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid lines
    final gridLineColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final gridPaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 1;

    for (double x = 0; x <= grid.canvasWidth; x += grid.gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, grid.canvasHeight), gridPaint);
    }
    for (double y = 0; y <= grid.canvasHeight; y += grid.gridSize) {
      canvas.drawLine(Offset(0, y), Offset(grid.canvasWidth, y), gridPaint);
    }

    // Draw parking spots
    for (final spot in grid.spots) {
      _drawSpot(canvas, spot);
    }
  }

  void _drawSpot(Canvas canvas, ParkingSpot spot) {
    final isAvailable = spotAvailability[spot.id] ?? false;
    final isSelected = spot.id == selectedSpotId;

    // Determine color based on status
    Color color;
    if (isSelected) {
      color = Colors.blue;
    } else if (isAvailable) {
      color = Colors.green;
    } else {
      color = Colors.red;
    }

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
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      borderPaint,
    );

    // Spot type icon indicator (small colored dot in corner)
    final typeColor = _getTypeColor(spot.type);
    if (spot.type != SpotType.regular) {
      final iconPaint = Paint()
        ..color = typeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(spot.x + spot.width - 10, spot.y + 10),
        6,
        iconPaint,
      );
    }

    // ID label
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final textPainter = TextPainter(
      text: TextSpan(
        text: spot.id,
        style: TextStyle(
          color: textColor,
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

  Color _getTypeColor(SpotType type) {
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
  bool shouldRepaint(covariant UserGridPainter oldDelegate) {
    return selectedSpotId != oldDelegate.selectedSpotId ||
        grid.spots.length != oldDelegate.grid.spots.length ||
        isDarkMode != oldDelegate.isDarkMode;
  }
}
