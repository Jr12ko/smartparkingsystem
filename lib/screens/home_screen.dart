import 'package:flutter/material.dart';
import '../widgets/fade_slide_transition.dart';
import '../widgets/scale_button.dart';
import 'map.dart';
import 'setting_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.username, super.key, required this.password});

  final String username;
  final String password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideTransition(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      username,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              FadeSlideTransition(
                index: 1,
                child: ScaleButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MapScreen(Colors.deepPurple, Colors.purple),
                      ),
                    );
                  },
                  child: _buildMenuCard(
                    context,
                    icon: Icons.map_rounded,
                    title: 'Find Parking',
                    subtitle: 'Locate nearby spots',
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideTransition(
                index: 2,
                child: ScaleButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsScreen(),
                      ),
                    );
                  },
                  child: _buildMenuCard(
                    context,
                    icon: Icons.bar_chart_rounded,
                    title: 'Statistics',
                    subtitle: 'View usage analytics',
                    color: const Color(0xFFFF6584),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideTransition(
                index: 3,
                child: ScaleButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingScreen(),
                      ),
                    );
                  },
                  child: _buildMenuCard(
                    context,
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    subtitle: 'Manage preferences',
                    color: const Color(0xFF43D0E3),
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  '© Smarpar 2025',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withValues(alpha: 0.3),
            size: 18,
          ),
        ],
      ),
    );
  }
}
