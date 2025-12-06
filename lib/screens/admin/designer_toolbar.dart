import 'package:flutter/material.dart';
import '../../models/parking_spot.dart';
import '../../models/obstacle.dart';

/// Tool modes for the grid designer
enum DesignerTool {
  select,
  pan,
  addSpot,
  addRoad,
  addObstacle,
  delete,
  ruler,
  rotate
}

/// Callback signatures for toolbar actions
typedef ToolChangeCallback = void Function(DesignerTool tool);
typedef SpotTypeChangeCallback = void Function(SpotType type);
typedef ObstacleTypeChangeCallback = void Function(ObstacleType type);
typedef VoidCallback = void Function();

/// Designer toolbar widget for grid designer tools
class DesignerToolbar extends StatelessWidget {
  final DesignerTool currentTool;
  final SpotType selectedSpotType;
  final ObstacleType selectedObstacleType;
  final ToolChangeCallback onToolChanged;
  final SpotTypeChangeCallback onSpotTypeChanged;
  final ObstacleTypeChangeCallback onObstacleTypeChanged;
  final VoidCallback onClearAll;

  const DesignerToolbar({
    super.key,
    required this.currentTool,
    required this.selectedSpotType,
    required this.selectedObstacleType,
    required this.onToolChanged,
    required this.onSpotTypeChanged,
    required this.onObstacleTypeChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildToolButton(
              context,
              icon: Icons.mouse,
              label: 'Select',
              tool: DesignerTool.select,
            ),
            const SizedBox(height: 8),
            _buildToolButton(
              context,
              icon: Icons.pan_tool,
              label: 'Pan',
              tool: DesignerTool.pan,
            ),
            const SizedBox(height: 8),
            _buildToolButton(
              context,
              icon: Icons.add_box,
              label: 'Add Spot',
              tool: DesignerTool.addSpot,
            ),
            const SizedBox(height: 8),
            _buildToolButton(
              context,
              icon: Icons.add_road,
              label: 'Add Road',
              tool: DesignerTool.addRoad,
            ),
            const SizedBox(height: 8),
            _buildToolButton(
              context,
              icon: Icons.view_column,
              label: 'Add Pillar',
              tool: DesignerTool.addObstacle,
            ),
            const SizedBox(height: 8),
            _buildToolButton(
              context,
              icon: Icons.delete,
              label: 'Delete',
              tool: DesignerTool.delete,
            ),
            const SizedBox(height: 8),
            _buildToolButton(
              context,
              icon: Icons.straighten,
              label: 'Ruler',
              tool: DesignerTool.ruler,
            ),
            const SizedBox(height: 8),
            _buildToolButton(
              context,
              icon: Icons.rotate_right,
              label: 'Rotate (R)',
              tool: DesignerTool.rotate,
            ),
            const Divider(height: 32),
            // Spot types (only shown when addSpot is selected)
            if (currentTool == DesignerTool.addSpot) ...[
              _buildSpotTypeButton(
                  context, SpotType.regular, Icons.local_parking, 'Regular'),
              const SizedBox(height: 8),
              _buildSpotTypeButton(context, SpotType.handicapped,
                  Icons.accessible, 'Accessible'),
              const SizedBox(height: 8),
              _buildSpotTypeButton(
                  context, SpotType.evCharging, Icons.ev_station, 'EV'),
              const SizedBox(height: 16),
            ],
            // Obstacle types (only shown when addObstacle is selected)
            if (currentTool == DesignerTool.addObstacle) ...[
              _buildObstacleTypeButton(
                  context, ObstacleType.pillar, Icons.crop_square, 'Pillar'),
              const SizedBox(height: 8),
              _buildObstacleTypeButton(
                  context, ObstacleType.wall, Icons.view_week, 'Wall'),
              const SizedBox(height: 8),
              _buildObstacleTypeButton(
                  context, ObstacleType.barrier, Icons.fence, 'Barrier'),
              const SizedBox(height: 16),
            ],
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: onClearAll,
              tooltip: 'Clear All',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required DesignerTool tool,
  }) {
    final isSelected = currentTool == tool;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => onToolChanged(tool),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
          ),
          child: Icon(
            icon,
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }

  Widget _buildSpotTypeButton(
      BuildContext context, SpotType type, IconData icon, String label) {
    final isSelected = selectedSpotType == type;
    final color = _getSpotColor(type);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => onSpotTypeChanged(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.3)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }

  Widget _buildObstacleTypeButton(
      BuildContext context, ObstacleType type, IconData icon, String label) {
    final isSelected = selectedObstacleType == type;
    final color = _getObstacleColor(type);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => onObstacleTypeChanged(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.3)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Icon(icon, color: color),
        ),
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

  Color _getObstacleColor(ObstacleType type) {
    switch (type) {
      case ObstacleType.pillar:
        return Colors.grey;
      case ObstacleType.wall:
        return Colors.brown;
      case ObstacleType.barrier:
        return Colors.orange;
    }
  }
}
