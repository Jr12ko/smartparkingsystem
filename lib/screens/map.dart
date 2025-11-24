import 'package:flutter/material.dart';
import '../widgets/navigation.dart';

const startAlignment = Alignment.topLeft;
const endAlignment = Alignment.bottomRight;

class MapScreen extends StatefulWidget {
  const MapScreen(this.color1, this.color2, {super.key});

  final Color color1;
  final Color color2;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<Map<String, dynamic>> _parkingSpots = [
    {'id': 'A1', 'top': 141.0, 'left': 170.0, 'status': 'available'},
    {'id': 'A2', 'top': 173.0, 'left': 170.0, 'status': 'taken'},
    {'id': 'A3', 'top': 207.0, 'left': 170.0, 'status': 'taken'},
    {'id': 'A4', 'top': 241.0, 'left': 170.0, 'status': 'taken'},
    {'id': 'A5', 'top': 141.0, 'left': 240.0, 'status': 'available'},
    {'id': 'A6', 'top': 173.0, 'left': 240.0, 'status': 'available'},
    {'id': 'A7', 'top': 207.0, 'left': 240.0, 'status': 'available'},
    {'id': 'A8', 'top': 241.0, 'left': 240.0, 'status': 'available'},
  ];

  final Map<String, List<Map<String, dynamic>>> _routes = {
    'A1': [
      {
        'icon': Icons.turn_left,
        'distance': '120 m',
        'instruction': 'Turn Left'
      },
      {
        'icon': Icons.turn_right,
        'distance': '80 m',
        'instruction': 'Turn Right'
      },
      {'icon': Icons.turn_left, 'distance': '40 m', 'instruction': 'Turn Left'},
      {
        'icon': Icons.local_parking,
        'distance': 'You have arrived',
        'instruction': 'Park at slot A1'
      },
    ],
    'A5': [
      {
        'icon': Icons.turn_left,
        'distance': '120 m',
        'instruction': 'Turn Left'
      },
      {
        'icon': Icons.straight,
        'distance': '80 m',
        'instruction': 'Go Straight'
      },
      {'icon': Icons.turn_left, 'distance': '60 m', 'instruction': 'Turn Left'},
      {
        'icon': Icons.local_parking,
        'distance': 'You have arrived',
        'instruction': 'Park at slot A5'
      },
    ],
    'A6': [
      {
        'icon': Icons.straight,
        'distance': '150 m',
        'instruction': 'Go straight'
      },
      {
        'icon': Icons.turn_right,
        'distance': '50 m',
        'instruction': 'Turn Right'
      },
      {
        'icon': Icons.straight,
        'distance': '10 m',
        'instruction': 'Go straight'
      },
      {
        'icon': Icons.local_parking,
        'distance': 'You have arrived',
        'instruction': 'Park at slot A6'
      },
    ],
    'A7': [
      {
        'icon': Icons.straight,
        'distance': '150 m',
        'instruction': 'Go straight'
      },
      {
        'icon': Icons.turn_right,
        'distance': '50 m',
        'instruction': 'Turn Right'
      },
      {
        'icon': Icons.straight,
        'distance': '10 m',
        'instruction': 'Go straight'
      },
      {
        'icon': Icons.local_parking,
        'distance': 'You have arrived',
        'instruction': 'Park at slot A7'
      },
    ],
  };

  List<Map<String, dynamic>> _currentRoute = [];
  int _currentStepIndex = 0;
  String? _selectedSpotId;

  IconData _currentIcon = Icons.info;
  String _currentDistance = "Welcome!";
  String _currentInstruction = "Please select a parking spot";

  void _startNavigationForSpot(String spotId) {
    if (_routes.containsKey(spotId)) {
      setState(() {
        _selectedSpotId = spotId;
        _currentRoute = _routes[spotId]!;
        _currentStepIndex = 0;
        _updateNavigationUi();
      });
    }
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

  List<Widget> _buildParkingSpots() {
    return _parkingSpots.map((spot) {
      return Positioned(
        top: spot['top'],
        left: spot['left'],
        child: GestureDetector(
          onTap: () {
            if (spot['status'] == 'available') {
              print('Spot ${spot['id']} selected!');
              _startNavigationForSpot(spot['id']);
            } else {
              print('Spot ${spot['id']} is taken.');
            }
          },
          child: Icon(
            Icons.circle,
            size: 20,
            color: spot['status'] == 'available'
                ? (_selectedSpotId == spot['id']
                    ? Colors.blueAccent
                    : Colors.green)
                : Colors.red,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Map'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _currentRoute.isNotEmpty ? _nextStep : null,
        child: const Icon(Icons.arrow_forward),
        backgroundColor: _currentRoute.isNotEmpty
            ? Theme.of(context).primaryColor
            : Colors.grey,
      ),
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [widget.color1, widget.color2],
          begin: startAlignment,
          end: endAlignment,
        )),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NavigationWidget(
                icon: _currentIcon,
                distance: _currentDistance,
                instruction: _currentInstruction),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.asset(
                        'assets/map.png',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    ..._buildParkingSpots(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
