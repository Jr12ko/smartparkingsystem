import 'package:flutter/material.dart';
import '../widgets/fade_slide_transition.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlideTransition(
              index: 0,
              child: Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideTransition(
              index: 1,
              child: _buildAdminOption(
                context,
                icon: Icons.people_alt_rounded,
                title: 'User Management',
                subtitle: 'Manage users and roles',
                color: Colors.blueAccent,
                onTap: () {
                  // TODO: Navigate to User Management
                },
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideTransition(
              index: 2,
              child: _buildAdminOption(
                context,
                icon: Icons.local_parking_rounded,
                title: 'Parking Spots',
                subtitle: 'Manage parking availability',
                color: Colors.greenAccent,
                onTap: () {
                  // TODO: Navigate to Parking Management
                },
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideTransition(
              index: 3,
              child: _buildAdminOption(
                context,
                icon: Icons.analytics_rounded,
                title: 'System Logs',
                subtitle: 'View system activity',
                color: Colors.orangeAccent,
                onTap: () {
                  // TODO: Navigate to System Logs
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).cardTheme.color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
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
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
