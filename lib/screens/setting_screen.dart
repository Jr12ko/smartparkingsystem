import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:smart_parking_system/services/auth_service.dart';
import 'admin_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({
    super.key,
  });

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  void initState() {
    super.initState();
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
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
              ),
              onPressed: () async {
                final isAdmin = await AuthService().isAdmin();
                if (context.mounted) {
                  if (isAdmin) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdminScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Access Denied: Admins only'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Admin Panel'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Log Out'),
            )
          ],
        ),
      ),
    );
  }
}
