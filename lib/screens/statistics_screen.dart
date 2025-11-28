import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> carCount = {
      '08:00 - 10:00': 112,
      '11:00 - 13:00': 257,
      '14:00 - 16:00': 67,
      '17:00 - 19:00': 98,
    };

    int totalCars = carCount.values.fold(0, (sum, value) => sum + value);

    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Total Cars Today: $totalCars",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: carCount.entries.map((entry) {
                  double percent = entry.value / totalCars;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${entry.key} — ${entry.value} cars",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: percent,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 5),
                      Text("${(percent * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 15),
                    ],
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
