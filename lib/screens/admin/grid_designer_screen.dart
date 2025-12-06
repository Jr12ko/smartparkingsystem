import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/parking_grid.dart';
import '../../models/parking_spot.dart';
import '../../models/road.dart';
import '../../models/obstacle.dart';
import '../../widgets/fade_slide_transition.dart';
import 'designer_toolbar.dart';
import 'properties_panel.dart';
import 'grid_painter.dart';

// Conditional import for web
import 'grid_designer_web.dart' if (dart.library.io) 'grid_designer_io.dart'
    as file_ops;

/// Main grid designer screen for creating/editing parking layouts
class GridDesignerScreen extends StatefulWidget {
  final String? gridId;

  const GridDesignerScreen({super.key, this.gridId});

  @override
  State<GridDesignerScreen> createState() => _GridDesignerScreenState();
}

class _GridDesignerScreenState extends State<GridDesignerScreen> {
  late ParkingGrid _grid;
  DesignerTool _currentTool = DesignerTool.select;
  SpotType _selectedSpotType = SpotType.regular;
  ObstacleType _selectedObstacleType = ObstacleType.pillar;
  final Set<String> _selectedSpotIds = {};
  final Set<String> _selectedRoadIds = {};
  final Set<String> _selectedObstacleIds = {};

  // Drag selection state
  Offset? _dragStart;
  Offset? _dragEnd;

  // Road drawing state
  Offset? _roadDrawStart;
  Offset? _roadDrawEnd;

  final TransformationController _transformController =
      TransformationController();

  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  Offset? _rulerStart;
  Offset? _rulerEnd;
  Offset? _cursorPosition;
  bool _isHoveringRuler = false;
  String? _draggingSpotId;
  Offset? _spotDragOffset;
  String? _draggingRoadId;
  Offset? _roadDragOffset;
  String? _draggingObstacleId;
  Offset? _obstacleDragOffset;

  // Clipboard for copy/paste
  List<ParkingSpot> _clipboardSpots = [];
  List<Road> _clipboardRoads = [];
  List<Obstacle> _clipboardObstacles = [];

  @override
  void initState() {
    super.initState();
    _grid = ParkingGrid.empty(name: 'New Parking Grid');
    _saveState();

    // Center the canvas view after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCanvas();
    });
  }

  void _centerCanvas() {
    // Reset to identity matrix to center the view
    _transformController.value = Matrix4.identity();
  }

  void _saveState() {
    _undoStack.add(_grid.toJsonString());
    _redoStack.clear();
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.length > 1) {
      setState(() {
        _redoStack.add(_undoStack.removeLast());
        _grid = ParkingGrid.fromJsonString(_undoStack.last);
        _selectedSpotIds.clear();
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        final state = _redoStack.removeLast();
        _undoStack.add(state);
        _grid = ParkingGrid.fromJsonString(state);
        _selectedSpotIds.clear();
      });
    }
  }

  void _addSpotAt(double x, double y) {
    // Create a temporary spot to get its dimensions
    final tempSpot = ParkingSpot(
      id: '',
      x: 0,
      y: 0,
      type: _selectedSpotType,
    );

    // Center the spot on the click position by offsetting by half the dimensions
    final centeredX = x - tempSpot.width / 2;
    final centeredY = y - tempSpot.height / 2;

    // Snap the centered position to grid
    var snappedX = _grid.snapToGrid(centeredX);
    var snappedY = _grid.snapToGrid(centeredY);

    // Clamp position to keep spot within canvas bounds
    snappedX = snappedX.clamp(0, _grid.canvasWidth - tempSpot.width);
    snappedY = snappedY.clamp(0, _grid.canvasHeight - tempSpot.height);

    // Check if the spot would be completely outside the canvas
    if (snappedX + tempSpot.width <= 0 ||
        snappedX >= _grid.canvasWidth ||
        snappedY + tempSpot.height <= 0 ||
        snappedY >= _grid.canvasHeight) {
      return; // Don't place spot outside canvas
    }

    final spot = ParkingSpot(
      id: _grid.generateSpotId(),
      x: snappedX,
      y: snappedY,
      type: _selectedSpotType,
    );

    setState(() {
      _grid.addSpot(spot);
      _selectedSpotIds.clear();
      _selectedSpotIds.add(spot.id);
    });
    _saveState();
  }

  /// Find a spot at the given position
  String? _findSpotAt(double x, double y) {
    // Search in reverse order to find top-most spot
    for (int i = _grid.spots.length - 1; i >= 0; i--) {
      final spot = _grid.spots[i];
      if (x >= spot.x &&
          x <= spot.x + spot.width &&
          y >= spot.y &&
          y <= spot.y + spot.height) {
        return spot.id;
      }
    }
    return null;
  }

  String? _findRoadAt(double x, double y) {
    for (int i = _grid.roads.length - 1; i >= 0; i--) {
      final road = _grid.roads[i];
      if (x >= road.x &&
          x <= road.x + road.width &&
          y >= road.y &&
          y <= road.y + road.height) {
        return road.id;
      }
    }
    return null;
  }

  String? _findObstacleAt(double x, double y) {
    for (int i = _grid.obstacles.length - 1; i >= 0; i--) {
      final obstacle = _grid.obstacles[i];
      if (x >= obstacle.x &&
          x <= obstacle.x + obstacle.width &&
          y >= obstacle.y &&
          y <= obstacle.y + obstacle.height) {
        return obstacle.id;
      }
    }
    return null;
  }

  void _addRoadAt(double x, double y, {double? endX, double? endY}) {
    // Calculate dimensions if drawing a road segment
    double roadWidth = 80;
    double roadHeight = 200;

    if (endX != null && endY != null) {
      // Road was drawn with drag - calculate dimensions from start/end
      final dx = (endX - x).abs();
      final dy = (endY - y).abs();
      if (dx > dy) {
        // Horizontal road
        roadWidth = dx.clamp(40, _grid.canvasWidth);
        roadHeight = 60;
      } else {
        // Vertical road
        roadWidth = 60;
        roadHeight = dy.clamp(40, _grid.canvasHeight);
      }
      // Adjust position to start from min coordinates
      x = x < endX ? x : endX;
      y = y < endY ? y : endY;
    }

    var snappedX = _grid.snapToGrid(x);
    var snappedY = _grid.snapToGrid(y);

    snappedX = snappedX.clamp(0, _grid.canvasWidth - roadWidth);
    snappedY = snappedY.clamp(0, _grid.canvasHeight - roadHeight);

    final road = Road(
      id: _grid.generateRoadId(),
      x: snappedX,
      y: snappedY,
      width: roadWidth,
      height: roadHeight,
    );

    setState(() {
      _grid.addRoad(road);
      _selectedRoadIds.clear();
      _selectedRoadIds.add(road.id);
      _selectedSpotIds.clear();
      _selectedObstacleIds.clear();
    });
    _saveState();
  }

  void _addObstacleAt(double x, double y) {
    final tempObstacle = Obstacle(
      id: '',
      x: 0,
      y: 0,
      type: _selectedObstacleType,
    );

    final centeredX = x - tempObstacle.width / 2;
    final centeredY = y - tempObstacle.height / 2;

    var snappedX = _grid.snapToGrid(centeredX);
    var snappedY = _grid.snapToGrid(centeredY);

    snappedX = snappedX.clamp(0, _grid.canvasWidth - tempObstacle.width);
    snappedY = snappedY.clamp(0, _grid.canvasHeight - tempObstacle.height);

    final obstacle = Obstacle(
      id: _grid.generateObstacleId(),
      x: snappedX,
      y: snappedY,
      type: _selectedObstacleType,
    );

    setState(() {
      _grid.addObstacle(obstacle);
      _selectedObstacleIds.clear();
      _selectedObstacleIds.add(obstacle.id);
      _selectedSpotIds.clear();
      _selectedRoadIds.clear();
    });
    _saveState();
  }

  /// Select an element (spot, road, or obstacle) at the given position
  void _selectElementAt(double x, double y) {
    // Check spots first (top layer)
    final spotId = _findSpotAt(x, y);
    if (spotId != null) {
      setState(() {
        _clearAllSelections();
        _selectedSpotIds.add(spotId);
      });
      return;
    }

    // Check roads
    final roadId = _findRoadAt(x, y);
    if (roadId != null) {
      setState(() {
        _clearAllSelections();
        _selectedRoadIds.add(roadId);
      });
      return;
    }

    // Check obstacles
    final obstacleId = _findObstacleAt(x, y);
    if (obstacleId != null) {
      setState(() {
        _clearAllSelections();
        _selectedObstacleIds.add(obstacleId);
      });
      return;
    }

    // Clicked on empty area - clear selection
    setState(() {
      _clearAllSelections();
    });
  }

  /// Delete a spot immediately at the clicked position
  void _deleteSpotAt(double x, double y) {
    final foundId = _findSpotAt(x, y);
    if (foundId != null) {
      // Find the index for direct removal (faster than removeWhere)
      final index = _grid.spots.indexWhere((s) => s.id == foundId);
      if (index != -1) {
        setState(() {
          _grid.spots.removeAt(index);
          _selectedSpotIds.remove(foundId);
        });
        _saveState();
        return;
      }
    }
    // Try deleting a road
    final roadId = _findRoadAt(x, y);
    if (roadId != null) {
      _deleteRoadAt(roadId);
      return;
    }
    // Try deleting an obstacle
    final obstacleId = _findObstacleAt(x, y);
    if (obstacleId != null) {
      _deleteObstacleAt(obstacleId);
    }
  }

  void _deleteRoadAt(String roadId) {
    final index = _grid.roads.indexWhere((r) => r.id == roadId);
    if (index != -1) {
      setState(() {
        _grid.roads.removeAt(index);
        _selectedRoadIds.remove(roadId);
      });
      _saveState();
    }
  }

  void _deleteObstacleAt(String obstacleId) {
    final index = _grid.obstacles.indexWhere((o) => o.id == obstacleId);
    if (index != -1) {
      setState(() {
        _grid.obstacles.removeAt(index);
        _selectedObstacleIds.remove(obstacleId);
      });
      _saveState();
    }
  }

  void _deleteSelectedSpot() {
    if (_selectedSpotIds.isNotEmpty) {
      setState(() {
        _grid.spots.removeWhere((s) => _selectedSpotIds.contains(s.id));
        _selectedSpotIds.clear();
      });
      _saveState();
    }
  }

  void _clearAllSelections() {
    _selectedSpotIds.clear();
    _selectedRoadIds.clear();
    _selectedObstacleIds.clear();
  }

  /// Copy selected elements to clipboard
  void _copySelected() {
    _clipboardSpots = _grid.spots
        .where((s) => _selectedSpotIds.contains(s.id))
        .map((s) => ParkingSpot(
              id: s.id,
              x: s.x,
              y: s.y,
              width: s.width,
              height: s.height,
              rotation: s.rotation,
              type: s.type,
              label: s.label,
            ))
        .toList();

    _clipboardRoads = _grid.roads
        .where((r) => _selectedRoadIds.contains(r.id))
        .map((r) => Road(
              id: r.id,
              x: r.x,
              y: r.y,
              width: r.width,
              height: r.height,
            ))
        .toList();

    _clipboardObstacles = _grid.obstacles
        .where((o) => _selectedObstacleIds.contains(o.id))
        .map((o) => Obstacle(
              id: o.id,
              x: o.x,
              y: o.y,
              width: o.width,
              height: o.height,
              type: o.type,
            ))
        .toList();

    if (_clipboardSpots.isNotEmpty ||
        _clipboardRoads.isNotEmpty ||
        _clipboardObstacles.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Copied ${_clipboardSpots.length} spots, ${_clipboardRoads.length} roads, ${_clipboardObstacles.length} obstacles'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// Paste elements from clipboard with offset
  void _pasteFromClipboard() {
    if (_clipboardSpots.isEmpty &&
        _clipboardRoads.isEmpty &&
        _clipboardObstacles.isEmpty) {
      return;
    }

    const pasteOffset = 20.0;

    setState(() {
      _clearAllSelections();

      // Paste spots
      for (final spot in _clipboardSpots) {
        final newSpot = ParkingSpot(
          id: _grid.generateSpotId(),
          x: (spot.x + pasteOffset).clamp(0, _grid.canvasWidth - spot.width),
          y: (spot.y + pasteOffset).clamp(0, _grid.canvasHeight - spot.height),
          width: spot.width,
          height: spot.height,
          rotation: spot.rotation,
          type: spot.type,
          label: spot.label,
        );
        _grid.addSpot(newSpot);
        _selectedSpotIds.add(newSpot.id);
      }

      // Paste roads
      for (final road in _clipboardRoads) {
        final newRoad = Road(
          id: _grid.generateRoadId(),
          x: (road.x + pasteOffset).clamp(0, _grid.canvasWidth - road.width),
          y: (road.y + pasteOffset).clamp(0, _grid.canvasHeight - road.height),
          width: road.width,
          height: road.height,
        );
        _grid.addRoad(newRoad);
        _selectedRoadIds.add(newRoad.id);
      }

      // Paste obstacles
      for (final obstacle in _clipboardObstacles) {
        final newObstacle = Obstacle(
          id: _grid.generateObstacleId(),
          x: (obstacle.x + pasteOffset)
              .clamp(0, _grid.canvasWidth - obstacle.width),
          y: (obstacle.y + pasteOffset)
              .clamp(0, _grid.canvasHeight - obstacle.height),
          width: obstacle.width,
          height: obstacle.height,
          type: obstacle.type,
        );
        _grid.addObstacle(newObstacle);
        _selectedObstacleIds.add(newObstacle.id);
      }
    });

    _saveState();
  }

  /// Select all elements on canvas
  void _selectAll() {
    setState(() {
      _selectedSpotIds.clear();
      _selectedRoadIds.clear();
      _selectedObstacleIds.clear();

      for (final spot in _grid.spots) {
        _selectedSpotIds.add(spot.id);
      }
      for (final road in _grid.roads) {
        _selectedRoadIds.add(road.id);
      }
      for (final obstacle in _grid.obstacles) {
        _selectedObstacleIds.add(obstacle.id);
      }
    });
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Elements?'),
        content: const Text(
            'This will remove all spots, roads, and obstacles from the grid.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _grid.spots.clear();
                _grid.roads.clear();
                _grid.obstacles.clear();
                _selectedSpotIds.clear();
                _selectedRoadIds.clear();
                _selectedObstacleIds.clear();
              });
              _saveState();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToJson() async {
    final jsonString = _grid.toJsonString();
    final fileName = '${_grid.name.replaceAll(' ', '_')}.json';

    if (kIsWeb) {
      file_ops.downloadFileWeb(jsonString, fileName);
    } else {
      // For non-web platforms, use file_picker to save
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Parking Grid',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        file_ops.saveFileDesktop(result, jsonString);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grid exported successfully!')),
      );
    }
  }

  Future<void> _importFromJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      try {
        final jsonString = utf8.decode(result.files.single.bytes!);
        final importedGrid = ParkingGrid.fromJsonString(jsonString);

        setState(() {
          _grid = importedGrid;
          _selectedSpotIds.clear();
        });
        _saveState();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loaded: ${_grid.name}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading file: $e')),
          );
        }
      }
    }
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _grid.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Grid'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Grid Name',
            hintText: 'Enter grid name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() => _grid.name = value.trim());
              _saveState();
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _grid.name = controller.text.trim());
                _saveState();
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

          // Ctrl+Z for undo
          if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyZ) {
            if (_undoStack.length > 1) {
              _undo();
              return KeyEventResult.handled;
            }
          }
          // Ctrl+Y for redo (industry standard)
          else if (isCtrlPressed &&
              event.logicalKey == LogicalKeyboardKey.keyY) {
            if (_redoStack.isNotEmpty) {
              _redo();
              return KeyEventResult.handled;
            }
          }
          // Ctrl+C for copy
          else if (isCtrlPressed &&
              event.logicalKey == LogicalKeyboardKey.keyC) {
            _copySelected();
            return KeyEventResult.handled;
          }
          // Ctrl+V for paste
          else if (isCtrlPressed &&
              event.logicalKey == LogicalKeyboardKey.keyV) {
            _pasteFromClipboard();
            return KeyEventResult.handled;
          }
          // Ctrl+S for save/export
          else if (isCtrlPressed &&
              event.logicalKey == LogicalKeyboardKey.keyS) {
            _exportToJson();
            return KeyEventResult.handled;
          }
          // Ctrl+A for select all
          else if (isCtrlPressed &&
              event.logicalKey == LogicalKeyboardKey.keyA) {
            _selectAll();
            return KeyEventResult.handled;
          }
          // Escape key to clear ruler or deselect
          else if (event.logicalKey == LogicalKeyboardKey.escape) {
            if (_rulerStart != null || _rulerEnd != null) {
              _clearRuler();
              return KeyEventResult.handled;
            } else if (_selectedSpotIds.isNotEmpty ||
                _selectedRoadIds.isNotEmpty ||
                _selectedObstacleIds.isNotEmpty) {
              setState(() => _clearAllSelections());
              return KeyEventResult.handled;
            }
          }
          // Delete key to delete selected spots
          else if (event.logicalKey == LogicalKeyboardKey.delete) {
            if (_selectedSpotIds.isNotEmpty) {
              _deleteSelectedSpot();
              return KeyEventResult.handled;
            }
          }
          // R key to rotate selected spots by 90 degrees
          else if (event.logicalKey == LogicalKeyboardKey.keyR) {
            if (_selectedSpotIds.isNotEmpty) {
              _rotateSelectedSpots();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: InkWell(
            onTap: _showRenameDialog,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_grid.name),
                  const SizedBox(width: 8),
                  Icon(Icons.edit, size: 16, color: Colors.white70),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undoStack.length > 1 ? _undo : null,
              tooltip: 'Undo (Ctrl+Z)',
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: _redoStack.isNotEmpty ? _redo : null,
              tooltip: 'Redo (Ctrl+Y)',
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.file_upload),
              onPressed: _importFromJson,
              tooltip: 'Import JSON',
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _exportToJson,
              tooltip: 'Export JSON',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(
          children: [
            // Left toolbar
            FadeSlideTransition(
              index: 0,
              child: DesignerToolbar(
                currentTool: _currentTool,
                selectedSpotType: _selectedSpotType,
                selectedObstacleType: _selectedObstacleType,
                onToolChanged: (tool) => setState(() => _currentTool = tool),
                onSpotTypeChanged: (type) =>
                    setState(() => _selectedSpotType = type),
                onObstacleTypeChanged: (type) =>
                    setState(() => _selectedObstacleType = type),
                onClearAll: _clearAll,
              ),
            ),
            // Main canvas
            Expanded(
              child: FadeSlideTransition(
                index: 1,
                child: _buildCanvas(),
              ),
            ),
            // Right properties panel
            if (_selectedSpotIds.isNotEmpty)
              FadeSlideTransition(
                index: 2,
                child: PropertiesPanel(
                  selectedSpotIds: _selectedSpotIds,
                  grid: _grid,
                  onDeleteSelected: _deleteSelectedSpot,
                  onRotateSelected: _rotateSelectedSpots,
                  onRotateSpot: _rotateSpot,
                  onStateChanged: () {
                    setState(() {});
                    _saveState();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Canvas area
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return MouseRegion(
                    onHover: (event) {
                      final localPosition =
                          _transformController.toScene(event.localPosition);
                      setState(() {
                        _cursorPosition = localPosition;
                        // Check if hovering over ruler with delete tool
                        _isHoveringRuler = _currentTool ==
                                DesignerTool.delete &&
                            _isNearRuler(localPosition.dx, localPosition.dy);
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _cursorPosition = null;
                        _isHoveringRuler = false;
                      });
                    },
                    child: Listener(
                      onPointerDown: (event) {
                        final localPosition =
                            _transformController.toScene(event.localPosition);
                        if (_currentTool == DesignerTool.select) {
                          // Check if clicking on an existing spot to drag it
                          final spotId =
                              _findSpotAt(localPosition.dx, localPosition.dy);
                          if (spotId != null) {
                            // Start dragging this spot
                            final spot = _grid.findSpot(spotId);
                            if (spot != null) {
                              setState(() {
                                _draggingSpotId = spotId;
                                // Calculate offset from spot origin to click point
                                _spotDragOffset = Offset(
                                  localPosition.dx - spot.x,
                                  localPosition.dy - spot.y,
                                );
                                // Auto-select the spot being dragged
                                if (!_selectedSpotIds.contains(spotId)) {
                                  _clearAllSelections();
                                  _selectedSpotIds.add(spotId);
                                }
                              });
                            }
                          } else {
                            // Check if clicking on a road
                            final roadId =
                                _findRoadAt(localPosition.dx, localPosition.dy);
                            if (roadId != null) {
                              final road = _grid.findRoad(roadId);
                              if (road != null) {
                                setState(() {
                                  _draggingRoadId = roadId;
                                  _roadDragOffset = Offset(
                                    localPosition.dx - road.x,
                                    localPosition.dy - road.y,
                                  );
                                  if (!_selectedRoadIds.contains(roadId)) {
                                    _clearAllSelections();
                                    _selectedRoadIds.add(roadId);
                                  }
                                });
                              }
                            } else {
                              // Check if clicking on an obstacle
                              final obstacleId = _findObstacleAt(
                                  localPosition.dx, localPosition.dy);
                              if (obstacleId != null) {
                                final obstacle = _grid.findObstacle(obstacleId);
                                if (obstacle != null) {
                                  setState(() {
                                    _draggingObstacleId = obstacleId;
                                    _obstacleDragOffset = Offset(
                                      localPosition.dx - obstacle.x,
                                      localPosition.dy - obstacle.y,
                                    );
                                    if (!_selectedObstacleIds
                                        .contains(obstacleId)) {
                                      _clearAllSelections();
                                      _selectedObstacleIds.add(obstacleId);
                                    }
                                  });
                                }
                              } else {
                                // Start box selection on empty area
                                setState(() {
                                  _dragStart = localPosition;
                                  _dragEnd = localPosition;
                                });
                              }
                            }
                          }
                        } else if (_currentTool == DesignerTool.addSpot) {
                          _addSpotAt(localPosition.dx, localPosition.dy);
                        } else if (_currentTool == DesignerTool.delete) {
                          // Check if clicking near the ruler first
                          if (_isNearRuler(
                              localPosition.dx, localPosition.dy)) {
                            _clearRuler();
                          } else {
                            _deleteSpotAt(localPosition.dx, localPosition.dy);
                          }
                        } else if (_currentTool == DesignerTool.ruler) {
                          setState(() {
                            _rulerStart = localPosition;
                            _rulerEnd = localPosition;
                          });
                        } else if (_currentTool == DesignerTool.rotate) {
                          // Rotate the clicked spot by 90 degrees
                          final spotId =
                              _findSpotAt(localPosition.dx, localPosition.dy);
                          if (spotId != null) {
                            _rotateSpot(spotId);
                          }
                        } else if (_currentTool == DesignerTool.addRoad) {
                          // Start drawing a road
                          setState(() {
                            _roadDrawStart = localPosition;
                            _roadDrawEnd = localPosition;
                          });
                        } else if (_currentTool == DesignerTool.addObstacle) {
                          // Place an obstacle at click position
                          _addObstacleAt(localPosition.dx, localPosition.dy);
                        }
                      },
                      onPointerMove: (event) {
                        final localPosition =
                            _transformController.toScene(event.localPosition);
                        if (_currentTool == DesignerTool.select) {
                          if (_draggingSpotId != null &&
                              _spotDragOffset != null) {
                            // Dragging a spot - move it
                            final spot = _grid.findSpot(_draggingSpotId!);
                            if (spot != null) {
                              setState(() {
                                // Calculate new position
                                final newX =
                                    localPosition.dx - _spotDragOffset!.dx;
                                final newY =
                                    localPosition.dy - _spotDragOffset!.dy;
                                // Snap to grid and clamp within canvas bounds
                                spot.x = _grid
                                    .snapToGrid(newX)
                                    .clamp(0, _grid.canvasWidth - spot.width);
                                spot.y = _grid
                                    .snapToGrid(newY)
                                    .clamp(0, _grid.canvasHeight - spot.height);
                              });
                            }
                          } else if (_draggingRoadId != null &&
                              _roadDragOffset != null) {
                            // Dragging a road - move it
                            final road = _grid.findRoad(_draggingRoadId!);
                            if (road != null) {
                              setState(() {
                                final newX =
                                    localPosition.dx - _roadDragOffset!.dx;
                                final newY =
                                    localPosition.dy - _roadDragOffset!.dy;
                                road.x = _grid
                                    .snapToGrid(newX)
                                    .clamp(0, _grid.canvasWidth - road.width);
                                road.y = _grid
                                    .snapToGrid(newY)
                                    .clamp(0, _grid.canvasHeight - road.height);
                              });
                            }
                          } else if (_draggingObstacleId != null &&
                              _obstacleDragOffset != null) {
                            // Dragging an obstacle - move it
                            final obstacle =
                                _grid.findObstacle(_draggingObstacleId!);
                            if (obstacle != null) {
                              setState(() {
                                final newX =
                                    localPosition.dx - _obstacleDragOffset!.dx;
                                final newY =
                                    localPosition.dy - _obstacleDragOffset!.dy;
                                obstacle.x = _grid.snapToGrid(newX).clamp(
                                    0, _grid.canvasWidth - obstacle.width);
                                obstacle.y = _grid.snapToGrid(newY).clamp(
                                    0, _grid.canvasHeight - obstacle.height);
                              });
                            }
                          } else if (_dragStart != null) {
                            // Box selection
                            setState(() {
                              _dragEnd = localPosition;
                            });
                          }
                        } else if (_currentTool == DesignerTool.ruler &&
                            _rulerStart != null) {
                          setState(() {
                            _rulerEnd = localPosition;
                          });
                        } else if (_currentTool == DesignerTool.addRoad &&
                            _roadDrawStart != null) {
                          // Update road preview
                          setState(() {
                            _roadDrawEnd = localPosition;
                          });
                        }
                      },
                      onPointerUp: (event) {
                        if (_currentTool == DesignerTool.select) {
                          if (_draggingSpotId != null) {
                            // Finished dragging a spot
                            setState(() {
                              _draggingSpotId = null;
                              _spotDragOffset = null;
                            });
                            _saveState();
                          } else if (_draggingRoadId != null) {
                            // Finished dragging a road
                            setState(() {
                              _draggingRoadId = null;
                              _roadDragOffset = null;
                            });
                            _saveState();
                          } else if (_draggingObstacleId != null) {
                            // Finished dragging an obstacle
                            setState(() {
                              _draggingObstacleId = null;
                              _obstacleDragOffset = null;
                            });
                            _saveState();
                          } else if (_dragStart != null) {
                            // Box selection
                            final localPosition = _transformController
                                .toScene(event.localPosition);
                            final dragDistance =
                                (_dragStart! - localPosition).distance;
                            if (dragDistance < 5) {
                              _selectElementAt(
                                  localPosition.dx, localPosition.dy);
                            } else {
                              _updateSelectionFromDrag();
                            }
                            setState(() {
                              _dragStart = null;
                              _dragEnd = null;
                            });
                          }
                        } else if (_currentTool == DesignerTool.addRoad &&
                            _roadDrawStart != null) {
                          // Complete road creation
                          final localPosition =
                              _transformController.toScene(event.localPosition);
                          final dragDistance =
                              (_roadDrawStart! - localPosition).distance;
                          if (dragDistance > 20) {
                            // Minimum drag distance for road
                            _addRoadAt(
                              _roadDrawStart!.dx,
                              _roadDrawStart!.dy,
                              endX: localPosition.dx,
                              endY: localPosition.dy,
                            );
                          } else {
                            // Click without drag - place default road
                            _addRoadAt(localPosition.dx, localPosition.dy);
                          }
                          setState(() {
                            _roadDrawStart = null;
                            _roadDrawEnd = null;
                          });
                        }
                        // Ruler keeps its position after pointer up (doesn't reset)
                      },
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        panEnabled: _currentTool == DesignerTool.pan,
                        scaleEnabled: _currentTool == DesignerTool.pan,
                        constrained: false,
                        minScale: 0.5,
                        maxScale: 3.0,
                        boundaryMargin: const EdgeInsets.all(500),
                        child: Center(
                          child: Container(
                            width: _grid.canvasWidth,
                            height: _grid.canvasHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D0D1A),
                              border: Border.all(
                                color: Colors.white24,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              size: Size(_grid.canvasWidth, _grid.canvasHeight),
                              painter: GridPainter(
                                grid: _grid,
                                selectedSpotIds: _selectedSpotIds,
                                selectedRoadIds: _selectedRoadIds,
                                selectedObstacleIds: _selectedObstacleIds,
                                dragStart: _dragStart,
                                dragEnd: _dragEnd,
                                rulerStart: _rulerStart,
                                rulerEnd: _rulerEnd,
                                isHoveringRuler: _isHoveringRuler,
                                roadDrawStart: _roadDrawStart,
                                roadDrawEnd: _roadDrawEnd,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Info bar
          _buildInfoBar(),
        ],
      ),
    );
  }

  /// Check if a point is near the ruler (for deletion)
  bool _isNearRuler(double x, double y) {
    if (_rulerStart == null || _rulerEnd == null) return false;

    final clickPoint = Offset(x, y);
    const hitRadius = 15.0; // Pixels threshold for hit detection

    // Check if near start point
    if ((clickPoint - _rulerStart!).distance <= hitRadius) {
      return true;
    }

    // Check if near end point
    if ((clickPoint - _rulerEnd!).distance <= hitRadius) {
      return true;
    }

    // Check if near the line itself
    // Calculate distance from point to line segment
    final lineLength = (_rulerEnd! - _rulerStart!).distance;
    if (lineLength < 0.001) return false; // Avoid division by zero

    // Vector from start to end
    final dx = _rulerEnd!.dx - _rulerStart!.dx;
    final dy = _rulerEnd!.dy - _rulerStart!.dy;

    // Normalized parameter along the line (0 = start, 1 = end)
    final t = ((x - _rulerStart!.dx) * dx + (y - _rulerStart!.dy) * dy) /
        (lineLength * lineLength);

    // Clamp t to [0, 1] to stay within the line segment
    final tClamped = t.clamp(0.0, 1.0);

    // Find the closest point on the line
    final closestX = _rulerStart!.dx + tClamped * dx;
    final closestY = _rulerStart!.dy + tClamped * dy;
    final closestPoint = Offset(closestX, closestY);

    // Check if the click is close to this point
    return (clickPoint - closestPoint).distance <= hitRadius;
  }

  void _clearRuler() {
    setState(() {
      _rulerStart = null;
      _rulerEnd = null;
    });
  }

  /// Rotate a single spot by 90 degrees
  void _rotateSpot(String spotId) {
    final spot = _grid.findSpot(spotId);
    if (spot != null) {
      setState(() {
        // Rotate by 90 degrees (add 90, wrap at 360)
        spot.rotation = (spot.rotation + 90) % 360;
        // Swap width and height for 90/270 degree rotations
        final oldWidth = spot.width;
        spot.width = spot.height;
        spot.height = oldWidth;
        // Auto-select the rotated spot
        _selectedSpotIds.clear();
        _selectedSpotIds.add(spotId);
      });
      _saveState();
    }
  }

  /// Rotate all selected spots by 90 degrees
  void _rotateSelectedSpots() {
    if (_selectedSpotIds.isEmpty) return;
    setState(() {
      for (final spotId in _selectedSpotIds) {
        final spot = _grid.findSpot(spotId);
        if (spot != null) {
          // Rotate by 90 degrees (add 90, wrap at 360)
          spot.rotation = (spot.rotation + 90) % 360;
          // Swap width and height for 90/270 degree rotations
          final oldWidth = spot.width;
          spot.width = spot.height;
          spot.height = oldWidth;
        }
      }
    });
    _saveState();
  }

  Widget _buildInfoBar() {
    final rulerDistance = (_rulerStart != null && _rulerEnd != null)
        ? (_rulerEnd! - _rulerStart!).distance
        : null;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Canvas dimensions
          Icon(Icons.crop_square, size: 14, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            '${_grid.canvasWidth.toInt()} × ${_grid.canvasHeight.toInt()} px',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 16),
          // Grid size
          Icon(Icons.grid_4x4, size: 14, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            '${_grid.gridSize.toInt()} px',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          // Cursor position
          if (_cursorPosition != null) ...[
            Icon(Icons.my_location, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Text(
              '${_cursorPosition!.dx.toInt()}, ${_cursorPosition!.dy.toInt()}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 16),
          ],
          if (rulerDistance != null) ...[
            Icon(Icons.straighten, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              '${rulerDistance.toStringAsFixed(1)} px',
              style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _clearRuler,
              borderRadius: BorderRadius.circular(4),
              child: Tooltip(
                message: 'Clear Ruler (Esc)',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _updateSelectionFromDrag() {
    if (_dragStart == null || _dragEnd == null) return;

    final rect = Rect.fromPoints(_dragStart!, _dragEnd!);
    final newSpotSelection = <String>{};
    final newRoadSelection = <String>{};
    final newObstacleSelection = <String>{};

    // Select spots that overlap with the drag rectangle
    for (final spot in _grid.spots) {
      final spotRect = Rect.fromLTWH(spot.x, spot.y, spot.width, spot.height);
      if (rect.overlaps(spotRect)) {
        newSpotSelection.add(spot.id);
      }
    }

    // Select roads that overlap with the drag rectangle
    for (final road in _grid.roads) {
      final roadRect = Rect.fromLTWH(road.x, road.y, road.width, road.height);
      if (rect.overlaps(roadRect)) {
        newRoadSelection.add(road.id);
      }
    }

    // Select obstacles that overlap with the drag rectangle
    for (final obstacle in _grid.obstacles) {
      final obstacleRect = Rect.fromLTWH(
          obstacle.x, obstacle.y, obstacle.width, obstacle.height);
      if (rect.overlaps(obstacleRect)) {
        newObstacleSelection.add(obstacle.id);
      }
    }

    setState(() {
      _clearAllSelections();
      _selectedSpotIds.addAll(newSpotSelection);
      _selectedRoadIds.addAll(newRoadSelection);
      _selectedObstacleIds.addAll(newObstacleSelection);
    });
  }
}
