import 'package:flutter/material.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({
    super.key,
    required this.mediaVolume,
    required this.onMediaVolumeUpdate,
  });

  final int mediaVolume;
  final Function(int) onMediaVolumeUpdate;

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late int _currentVolume;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentVolume = widget.mediaVolume;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Enable Notifications',
                    style: TextStyle(fontSize: 16)),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Media Volume: $_currentVolume',
                style: const TextStyle(fontSize: 16)),
            Slider(
              value: _currentVolume.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: _currentVolume.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentVolume = value.round();
                });
              },
              onChangeEnd: (double value) {
                widget.onMediaVolumeUpdate(value.round());
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
