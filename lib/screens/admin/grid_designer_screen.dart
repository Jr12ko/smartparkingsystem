import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/parking_grid.dart';
import '../../models/parking_spot.dart';
import '../../widgets/fade_slide_transition.dart';

// Conditional import for web
import 'grid_designer_web.dart' if (dart.library.io) 'grid_designer_io.dart'
    as file_ops;

/// Tool modes for the grid designer
enum DesignerTool { select, pan, addSpot, delete, ruler, rotate }

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
  final Set<String> _selectedSpotIds = {};

  // Drag selection state
  Offset? _dragStart;
  Offset? _dragEnd;

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

  void _selectSpotAt(double x, double y, {bool isMultiSelect = false}) {
    final spotId = _findSpotAt(x, y);
    setState(() {
      if (!isMultiSelect) {
        _selectedSpotIds.clear();
      }
      if (spotId != null) {
        if (isMultiSelect && _selectedSpotIds.contains(spotId)) {
          _selectedSpotIds.remove(spotId);
        } else {
          _selectedSpotIds.add(spotId);
        }
      }
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
      }
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

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Spots?'),
        content:
            const Text('This will remove all parking spots from the grid.'),
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
                _selectedSpotIds.clear();
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
          // Escape key to clear ruler
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            if (_rulerStart != null || _rulerEnd != null) {
              _clearRuler();
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
              tooltip: 'Undo',
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: _redoStack.isNotEmpty ? _redo : null,
              tooltip: 'Redo',
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
              child: _buildToolbar(),
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
                child: _buildPropertiesPanel(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      width: 80,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildToolButton(
            icon: Icons.mouse,
            label: 'Select',
            tool: DesignerTool.select,
          ),
          const SizedBox(height: 8),
          _buildToolButton(
            icon: Icons.pan_tool,
            label: 'Pan',
            tool: DesignerTool.pan,
          ),
          const SizedBox(height: 8),
          _buildToolButton(
            icon: Icons.add_box,
            label: 'Add',
            tool: DesignerTool.addSpot,
          ),
          const SizedBox(height: 8),
          _buildToolButton(
            icon: Icons.delete,
            label: 'Delete',
            tool: DesignerTool.delete,
          ),
          const SizedBox(height: 8),
          _buildToolButton(
            icon: Icons.straighten,
            label: 'Ruler',
            tool: DesignerTool.ruler,
          ),
          const SizedBox(height: 8),
          _buildToolButton(
            icon: Icons.rotate_right,
            label: 'Rotate (R)',
            tool: DesignerTool.rotate,
          ),
          const Divider(height: 32),
          _buildSpotTypeButton(
              SpotType.regular, Icons.local_parking, 'Regular'),
          const SizedBox(height: 8),
          _buildSpotTypeButton(
              SpotType.handicapped, Icons.accessible, 'Accessible'),
          const SizedBox(height: 8),
          _buildSpotTypeButton(SpotType.evCharging, Icons.ev_station, 'EV'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: _clearAll,
            tooltip: 'Clear All',
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required DesignerTool tool,
  }) {
    final isSelected = _currentTool == tool;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => setState(() => _currentTool = tool),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
          ),
          child: Icon(
            icon,
            color: isSelected ? Theme.of(context).primaryColor : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildSpotTypeButton(SpotType type, IconData icon, String label) {
    final isSelected = _selectedSpotType == type;
    final color = _getSpotColor(type);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => setState(() => _selectedSpotType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Icon(icon, color: color),
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
                                  _selectedSpotIds.clear();
                                  _selectedSpotIds.add(spotId);
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
                          } else if (_dragStart != null) {
                            // Box selection
                            final localPosition = _transformController
                                .toScene(event.localPosition);
                            final dragDistance =
                                (_dragStart! - localPosition).distance;
                            if (dragDistance < 5) {
                              _selectSpotAt(localPosition.dx, localPosition.dy,
                                  isMultiSelect: false);
                            } else {
                              _updateSelectionFromDrag();
                            }
                            setState(() {
                              _dragStart = null;
                              _dragEnd = null;
                            });
                          }
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
                                dragStart: _dragStart,
                                dragEnd: _dragEnd,
                                rulerStart: _rulerStart,
                                rulerEnd: _rulerEnd,
                                isHoveringRuler: _isHoveringRuler,
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
    final newSelection = <String>{};

    for (final spot in _grid.spots) {
      final spotRect = Rect.fromLTWH(spot.x, spot.y, spot.width, spot.height);
      if (rect.overlaps(spotRect)) {
        newSelection.add(spot.id);
      }
    }

    _selectedSpotIds.clear();
    _selectedSpotIds.addAll(newSelection);
  }

  Widget _buildPropertiesPanel() {
    if (_selectedSpotIds.isEmpty) return const SizedBox.shrink();

    // If only one spot is selected, show full details
    if (_selectedSpotIds.length == 1) {
      final spot = _grid.findSpot(_selectedSpotIds.first);
      if (spot == null) return const SizedBox.shrink();
      return _buildSingleSpotProperties(spot);
    }

    // If multiple spots are selected, show bulk edit options
    return _buildMultiSpotProperties();
  }

  Widget _buildSingleSpotProperties(ParkingSpot spot) {
    return Container(
      width: 200,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Spot Properties',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildTextField('ID', spot.id, (val) {
            // ID editing logic...
          }, enabled: false, key: ValueKey('id_${spot.id}')),
          const SizedBox(height: 8),
          _buildNumberField('X', spot.x, (val) {
            setState(() => spot.x = val);
            _saveState();
          }, key: ValueKey('x_${spot.id}')),
          const SizedBox(height: 8),
          _buildNumberField('Y', spot.y, (val) {
            setState(() => spot.y = val);
            _saveState();
          }, key: ValueKey('y_${spot.id}')),
          const SizedBox(height: 8),
          _buildNumberField('Width', spot.width, (val) {
            setState(() => spot.width = val);
            _saveState();
          }, key: ValueKey('w_${spot.id}')),
          const SizedBox(height: 8),
          _buildNumberField('Height', spot.height, (val) {
            setState(() => spot.height = val);
            _saveState();
          }, key: ValueKey('h_${spot.id}')),
          const SizedBox(height: 8),
          Text('Type: ${spot.type.name}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          DropdownButton<SpotType>(
            value: spot.type,
            isExpanded: true,
            dropdownColor: Theme.of(context).cardTheme.color,
            items: SpotType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.name),
              );
            }).toList(),
            onChanged: (newType) {
              if (newType != null) {
                setState(() {
                  spot.type = newType;
                });
                _saveState();
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rotateSpot(spot.id),
                  icon: const Icon(Icons.rotate_right, size: 18),
                  label: const Text('Rotate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _deleteSelectedSpot,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSpotProperties() {
    return Container(
      width: 200,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_selectedSpotIds.length} Spots Selected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Bulk Edit',
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButton<SpotType>(
            isExpanded: true,
            hint: const Text("Change Type"),
            dropdownColor: Theme.of(context).cardTheme.color,
            items: SpotType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.name),
              );
            }).toList(),
            onChanged: (newType) {
              if (newType != null) {
                setState(() {
                  for (final id in _selectedSpotIds) {
                    final spot = _grid.findSpot(id);
                    if (spot != null) spot.type = newType;
                  }
                });
                _saveState();
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _rotateSelectedSpots,
            icon: const Icon(Icons.rotate_right, size: 18),
            label: const Text('Rotate All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _deleteSelectedSpot,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete Selected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value, Function(String) onChanged,
      {bool enabled = true, Key? key}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        SizedBox(
          height: 30,
          child: TextFormField(
            key: key,
            initialValue: value,
            enabled: enabled,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(
      String label, double value, Function(double) onChanged,
      {Key? key}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        SizedBox(
          height: 30,
          child: TextFormField(
            key: key,
            initialValue: value.toString(),
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              final num = double.tryParse(val);
              if (num != null) onChanged(num);
            },
          ),
        ),
      ],
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
}

/// Custom painter for rendering the parking grid
class GridPainter extends CustomPainter {
  final ParkingGrid grid;
  final Set<String> selectedSpotIds;
  final Offset? dragStart;
  final Offset? dragEnd;
  final Offset? rulerStart;
  final Offset? rulerEnd;
  final bool isHoveringRuler;
  final int spotCount; // Track spot count to detect deletions

  GridPainter({
    required this.grid,
    required this.selectedSpotIds,
    this.dragStart,
    this.dragEnd,
    this.rulerStart,
    this.rulerEnd,
    this.isHoveringRuler = false,
  }) : spotCount = grid.spots.length;

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

    // Draw parking spots
    for (final spot in grid.spots) {
      final isSelected = selectedSpotIds.contains(spot.id);
      _drawSpot(canvas, spot, isSelected);
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
        !setEquals(selectedSpotIds, oldDelegate.selectedSpotIds) ||
        dragStart != oldDelegate.dragStart ||
        dragEnd != oldDelegate.dragEnd ||
        rulerStart != oldDelegate.rulerStart ||
        rulerEnd != oldDelegate.rulerEnd ||
        isHoveringRuler != oldDelegate.isHoveringRuler;
  }
}
