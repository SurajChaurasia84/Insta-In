import 'package:flutter/material.dart';
import 'package:insta_in/core/theme.dart';
import 'package:insta_in/features/auth/auth_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Avatar & Info
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: const Icon(LucideIcons.user, size: 50, color: AppTheme.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.pencil, size: 14, color: Colors.white),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Suraj Chaurasia',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'suraj@example.com',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Statistics Row
            Row(
              children: [
                _buildStatItem(context, '5', 'Campaigns'),
                const SizedBox(width: 12),
                _buildStatItem(context, '42', 'Completed'),
                const SizedBox(width: 12),
                _buildStatItem(context, '340', 'Earned'),
              ],
            ),
            const SizedBox(height: 32),

            // Menu Items Card
            Card(
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: LucideIcons.user,
                    title: 'Edit Profile',
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildMenuItem(
                    icon: LucideIcons.history,
                    title: 'Activity History',
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildMenuItem(
                    icon: LucideIcons.helpCircle,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildMenuItem(
                    icon: LucideIcons.logOut,
                    title: 'Log Out',
                    color: AppTheme.error,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color ?? Colors.white,
        ),
      ),
      trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
