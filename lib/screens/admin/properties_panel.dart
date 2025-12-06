import 'package:flutter/material.dart';
import '../../models/parking_spot.dart';
import '../../models/parking_grid.dart';

/// Callback signatures for properties panel actions
typedef SpotUpdateCallback = void Function(ParkingSpot spot);
typedef VoidCallback = void Function();
typedef RotateSpotCallback = void Function(String spotId);

/// Properties panel widget for editing selected parking spots
class PropertiesPanel extends StatelessWidget {
  final Set<String> selectedSpotIds;
  final ParkingGrid grid;
  final VoidCallback onDeleteSelected;
  final VoidCallback onRotateSelected;
  final RotateSpotCallback onRotateSpot;
  final VoidCallback onStateChanged;

  const PropertiesPanel({
    super.key,
    required this.selectedSpotIds,
    required this.grid,
    required this.onDeleteSelected,
    required this.onRotateSelected,
    required this.onRotateSpot,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedSpotIds.isEmpty) return const SizedBox.shrink();

    // If only one spot is selected, show full details
    if (selectedSpotIds.length == 1) {
      final spot = grid.findSpot(selectedSpotIds.first);
      if (spot == null) return const SizedBox.shrink();
      return _buildSingleSpotProperties(context, spot);
    }

    // If multiple spots are selected, show bulk edit options
    return _buildMultiSpotProperties(context);
  }

  Widget _buildSingleSpotProperties(BuildContext context, ParkingSpot spot) {
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
          _buildTextField(context, 'ID', spot.id, (val) {
            // ID editing logic...
          }, enabled: false, key: ValueKey('id_${spot.id}')),
          const SizedBox(height: 8),
          _buildNumberField(context, 'X', spot.x, (val) {
            spot.x = val;
            onStateChanged();
          }, key: ValueKey('x_${spot.id}')),
          const SizedBox(height: 8),
          _buildNumberField(context, 'Y', spot.y, (val) {
            spot.y = val;
            onStateChanged();
          }, key: ValueKey('y_${spot.id}')),
          const SizedBox(height: 8),
          _buildNumberField(context, 'Width', spot.width, (val) {
            spot.width = val;
            onStateChanged();
          }, key: ValueKey('w_${spot.id}')),
          const SizedBox(height: 8),
          _buildNumberField(context, 'Height', spot.height, (val) {
            spot.height = val;
            onStateChanged();
          }, key: ValueKey('h_${spot.id}')),
          const SizedBox(height: 8),
          Text('Type: ${spot.type.name}',
              style: Theme.of(context).textTheme.bodySmall),
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
                spot.type = newType;
                onStateChanged();
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onRotateSpot(spot.id),
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
            onPressed: onDeleteSelected,
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

  Widget _buildMultiSpotProperties(BuildContext context) {
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
            '${selectedSpotIds.length} Spots Selected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Bulk Edit',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.bold),
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
                for (final id in selectedSpotIds) {
                  final spot = grid.findSpot(id);
                  if (spot != null) spot.type = newType;
                }
                onStateChanged();
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRotateSelected,
            icon: const Icon(Icons.rotate_right, size: 18),
            label: const Text('Rotate All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onDeleteSelected,
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

  Widget _buildTextField(BuildContext context, String label, String value,
      Function(String) onChanged,
      {bool enabled = true, Key? key}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
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

  Widget _buildNumberField(BuildContext context, String label, double value,
      Function(double) onChanged,
      {Key? key}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
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
}
