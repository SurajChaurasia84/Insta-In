import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:insta_in/core/theme.dart';
import 'package:insta_in/features/auth/onboarding_screen.dart';
import 'package:insta_in/features/profile/edit_profile_screen.dart';
import 'package:insta_in/features/profile/app_info_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _logout() async {
    try {
      // 1. Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // 2. Sign out from Google
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      if (mounted) {
        // 3. Navigate back to OnboardingScreen (which holds the Google Login)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToEditProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (updated == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

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
                      GestureDetector(
                        onTap: _navigateToEditProfile,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withOpacity(0.2),
                          ),
                          child: ClipOval(
                            child: user?.photoURL != null
                                ? Image.network(
                                    user!.photoURL!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primary,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        LucideIcons.user,
                                        size: 50,
                                        color: AppTheme.primary,
                                      );
                                    },
                                  )
                                : const Icon(
                                    LucideIcons.user,
                                    size: 50,
                                    color: AppTheme.primary,
                                  ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToEditProfile,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.pencil, size: 14, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'Insta In User',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'user@instain.com',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
                    onTap: _navigateToEditProfile,
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
                    icon: LucideIcons.shield,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildMenuItem(
                    icon: LucideIcons.share2,
                    title: 'Share App',
                    onTap: () {},
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildMenuItem(
                    icon: LucideIcons.info,
                    title: 'App Info',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AppInfoScreen()),
                      );
                    },
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  _buildMenuItem(
                    icon: LucideIcons.logOut,
                    title: 'Log Out',
                    color: AppTheme.error,
                    onTap: _logout,
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
