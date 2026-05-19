import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:insta_in/core/theme.dart';
import 'package:insta_in/features/auth/onboarding_screen.dart';
import 'package:insta_in/features/profile/edit_profile_screen.dart';
import 'package:insta_in/features/profile/app_info_screen.dart';
import 'package:insta_in/features/profile/activity_history_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _showLogoutConfirmationDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.logOut, color: AppTheme.error),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out from Insta In?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _logout();
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

  void _shareApp() {
    Share.share(
      '🚀 Hey! Check out Insta In - the ultimate app to grow your Instagram community, gain active engagement, authentic likes, and real followers.\n\n👇 Download from Google Play Store:\nhttps://play.google.com/store/apps/details?id=com.instain.social.app 🌟',
      subject: 'Boost your Instagram with Insta In!',
    );
  }

  Future<void> _launchSupportEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'jaswantsingh777705@gmail.com',
      queryParameters: {
        'subject': 'Insta In Help & Support Request',
      },
    );
    try {
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://instain-app.web.app/privacy');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          
          final String displayName = userData?['name'] ?? user?.displayName ?? 'Insta In User';
          final int campaignsCount = userData?['campaignsCount'] ?? userData?['campaigns'] ?? 0;
          final int completedCount = userData?['completedCount'] ?? userData?['completed'] ?? 0;
          final int coins = userData?['coins'] ?? 0;

          return SingleChildScrollView(
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
                        displayName,
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
                    _buildStatItem(context, '$campaignsCount', 'Campaigns'),
                    const SizedBox(width: 12),
                    _buildStatItem(context, '$completedCount', 'Completed'),
                    const SizedBox(width: 12),
                    _buildStatItem(context, '$coins', 'Coins'),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ActivityHistoryScreen()),
                          );
                        },
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _buildMenuItem(
                        icon: LucideIcons.helpCircle,
                        title: 'Help & Support',
                        onTap: _launchSupportEmail,
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _buildMenuItem(
                        icon: LucideIcons.shield,
                        title: 'Privacy Policy',
                        onTap: _launchPrivacyPolicy,
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _buildMenuItem(
                        icon: LucideIcons.share2,
                        title: 'Share App',
                        onTap: _shareApp,
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
                        onTap: _showLogoutConfirmationDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
