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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = 'Insta In User';
  int _campaignsCount = 0;
  int _sponsorAdsCount = 0;
  int _completedCount = 0;
  double _coins = 0.0;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<QuerySnapshot>? _campaignsSubscription;
  StreamSubscription<QuerySnapshot>? _sponsorAdsSubscription;

  @override
  void initState() {
    super.initState();
    _loadCachedUserData();
    _subscribeToUserData();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _campaignsSubscription?.cancel();
    _sponsorAdsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _displayName = prefs.getString('cache_name_${user.uid}') ?? user.displayName ?? 'Insta In User';
          _coins = prefs.getDouble('cache_coins_${user.uid}') ?? 0.0;
          _campaignsCount = prefs.getInt('cache_campaigns_${user.uid}') ?? 0;
          _sponsorAdsCount = prefs.getInt('cache_sponsors_${user.uid}') ?? 0;
          _completedCount = prefs.getInt('cache_completed_${user.uid}') ?? 0;
        });
      }
    } catch (_) {}
  }

  void _subscribeToUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final String name = data['name'] ?? user.displayName ?? 'Insta In User';
          final double coins = (data['coins'] ?? 0).toDouble();
          final int completed = ((data['completedCount'] ?? data['completed'] ?? 0) as num).toInt();

          if (mounted) {
            setState(() {
              _displayName = name;
              _coins = coins;
              _completedCount = completed;
            });
          }

          // Cache the updated values in SharedPreferences
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cache_name_${user.uid}', name);
            await prefs.setDouble('cache_coins_${user.uid}', coins);
            await prefs.setInt('cache_completed_${user.uid}', completed);
          } catch (_) {}
        }
      }, onError: (error) {
        debugPrint('User subscription error: $error');
      });

      _campaignsSubscription = FirebaseFirestore.instance
          .collection('campaigns')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _campaignsCount = snapshot.docs.length;
          });
        }
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('cache_campaigns_${user.uid}', snapshot.docs.length);
        }).catchError((_) {});
      }, onError: (error) {
        debugPrint('Campaigns subscription error: $error');
      });

      _sponsorAdsSubscription = FirebaseFirestore.instance
          .collection('sponsor_ads')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _sponsorAdsCount = snapshot.docs.length;
          });
        }
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('cache_sponsors_${user.uid}', snapshot.docs.length);
        }).catchError((_) {});
      }, onError: (error) {
        debugPrint('Sponsor ads subscription error: $error');
      });
    }
  }

  Future<void> _logout() async {
    try {
      // Cancel subscriptions first to prevent permission-denied exceptions on sign-out
      await _userSubscription?.cancel();
      await _campaignsSubscription?.cancel();
      await _sponsorAdsSubscription?.cancel();
      _userSubscription = null;
      _campaignsSubscription = null;
      _sponsorAdsSubscription = null;

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
          title: Row(
            children: [
              const Icon(LucideIcons.logOut, color: AppTheme.error),
              const SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out from Insta In?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
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
      _loadCachedUserData();
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
    final Uri url = Uri.parse('https://surajchaurasia84.github.io/Insta-In/');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Register dependency to rebuild instantly when theme toggles
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
                    _displayName,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'user@instain.com',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Statistics Grid (2x2)
            Column(
              children: [
                Row(
                  children: [
                    _buildStatItem(context, '$_campaignsCount', 'My Campaigns'),
                    const SizedBox(width: 12),
                    _buildStatItem(context, '$_sponsorAdsCount', 'My Sponsors'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatItem(context, '$_completedCount', 'Completed'),
                    const SizedBox(width: 12),
                    _buildStatItem(context, '₹${_coins.toStringAsFixed(2)}', 'Total Balance'),
                  ],
                ),
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
                  Divider(color: AppTheme.textSecondary.withOpacity(0.1), height: 1),
                  _buildThemeToggleItem(),
                  Divider(color: AppTheme.textSecondary.withOpacity(0.1), height: 1),
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
                  Divider(color: AppTheme.textSecondary.withOpacity(0.1), height: 1),
                  _buildMenuItem(
                    icon: LucideIcons.helpCircle,
                    title: 'Help & Support',
                    onTap: _launchSupportEmail,
                  ),
                  Divider(color: AppTheme.textSecondary.withOpacity(0.1), height: 1),
                  _buildMenuItem(
                    icon: LucideIcons.shield,
                    title: 'Privacy Policy',
                    onTap: _launchPrivacyPolicy,
                  ),
                  Divider(color: AppTheme.textSecondary.withOpacity(0.1), height: 1),
                  _buildMenuItem(
                    icon: LucideIcons.share2,
                    title: 'Share App',
                    onTap: _shareApp,
                  ),
                  Divider(color: AppTheme.textSecondary.withOpacity(0.1), height: 1),
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
                  Divider(color: AppTheme.textSecondary.withOpacity(0.1), height: 1),
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
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleItem() {
    final bool isDark = AppTheme.themeNotifier.value == ThemeMode.dark;
    return ListTile(
      leading: Icon(
        isDark ? LucideIcons.moon : LucideIcons.sun,
        color: AppTheme.textSecondary,
      ),
      title: Text(
        'Dark Mode',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: Switch(
        value: isDark,
        activeColor: AppTheme.primary,
        onChanged: (bool value) async {
          final newMode = value ? ThemeMode.dark : ThemeMode.light;
          AppTheme.themeNotifier.value = newMode;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_light_mode', !value);
          
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: value ? Brightness.light : Brightness.dark,
              statusBarBrightness: value ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: value ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
              systemNavigationBarIconBrightness: value ? Brightness.light : Brightness.dark,
            ),
          );

          if (mounted) {
            setState(() {});
          }
        },
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
          color: color ?? AppTheme.textPrimary,
        ),
      ),
      trailing: Icon(LucideIcons.chevronRight, size: 18, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
