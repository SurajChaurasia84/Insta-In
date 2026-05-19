import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:insta_in/core/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:insta_in/features/earn/add_sponsor_ad_screen.dart';
import 'package:insta_in/features/wallet/wallet_screen.dart';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  bool _isClaiming = false;
  double _coins = 0.0;
  bool _hasSeenFollowWarning = false;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  final PageController _bannerController = PageController(viewportFraction: 0.9);
  int _currentBannerPage = 0;

  @override
  void initState() {
    super.initState();
    _loadCachedCoins();
    _subscribeToUserCoins();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedCoins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _coins = prefs.getDouble('cache_coins_${user.uid}') ?? 0.0;
          _hasSeenFollowWarning = prefs.getBool('has_seen_follow_warning') ?? false;
        });
      }
    } catch (_) {}
  }

  void _subscribeToUserCoins() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          final double coins = (snapshot.data()!['coins'] ?? 0).toDouble();
          if (mounted) {
            setState(() {
              _coins = coins;
            });
          }
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setDouble('cache_coins_${user.uid}', coins);
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open sponsor link: $e')),
        );
      }
    }
  }

  Future<void> _claimReward(Map<String, dynamic> taskData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String campaignId = taskData['id'];
    final String goal = taskData['goal'] ?? 'views';
    
    double reward = 1.0;
    if (goal == 'likes') {
      reward = 4.0;
    } else if (goal == 'followers') {
      reward = 0.20;
    }

    setState(() {
      _isClaiming = true;
    });

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final campaignRef = FirebaseFirestore.instance.collection('campaigns').doc(campaignId);
      final activityRef = userRef.collection('activities').doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final campaignSnapshot = await transaction.get(campaignRef);

        if (!userSnapshot.exists) {
          throw Exception('User profile not found.');
        }
        if (!campaignSnapshot.exists) {
          throw Exception('Campaign no longer exists.');
        }

        final campaignData = campaignSnapshot.data()!;
        final int currentCompleted = campaignData['completedCount'] ?? 0;
        final int targetQuantity = campaignData['quantity'] ?? 100;

        if (currentCompleted >= targetQuantity) {
          throw Exception('This campaign is already completed!');
        }

        final double currentCoins = (userSnapshot.data()?['coins'] ?? 0).toDouble();
        final int totalCompleted = userSnapshot.data()?['completedCount'] ?? userSnapshot.data()?['completed'] ?? 0;

        // 1. Reward the viewer
        transaction.update(userRef, {
          'coins': currentCoins + reward,
          'completedCount': totalCompleted + 1,
        });

        // 2. Increment completedCount on the campaign
        final int newCompleted = currentCompleted + 1;
        transaction.update(campaignRef, {
          'completedCount': newCompleted,
          'status': newCompleted >= targetQuantity ? 'completed' : 'active',
        });

        // 3. Log user activity
        transaction.set(activityRef, {
          'id': activityRef.id,
          'title': 'Completed Task',
          'description': 'Reward earned for Instagram ${goal.toUpperCase()}',
          'coins': reward,
          'type': 'earned',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Claimed +₹${reward.toStringAsFixed(2)} successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }

  Future<void> _claimSponsorReward(Map<String, dynamic> adData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final String userDayKey = "${user.uid}_$dateStr";

    final String adId = adData['id'];
    const int reward = 1; // ₹1 reward for sponsor visits

    setState(() {
      _isClaiming = true;
    });

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final adRef = FirebaseFirestore.instance.collection('sponsor_ads').doc(adId);
      final activityRef = userRef.collection('activities').doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final adSnapshot = await transaction.get(adRef);

        if (!userSnapshot.exists) {
          throw Exception('User profile not found.');
        }
        if (!adSnapshot.exists) {
          throw Exception('Ad no longer exists.');
        }

        final adDataMap = adSnapshot.data()!;
        final List viewedUsers = adDataMap['viewedUsers'] ?? [];
        if (viewedUsers.contains(userDayKey)) {
          throw Exception('You have already claimed reward for this ad today.');
        }

        final int currentCompleted = adDataMap['completedCount'] ?? 0;
        final int targetQuantity = adDataMap['quantity'] ?? 100;

        if (currentCompleted >= targetQuantity) {
          throw Exception('This campaign has completed its budget!');
        }

        final int currentCoins = userSnapshot.data()?['coins'] ?? 0;
        final int totalCompleted = userSnapshot.data()?['completedCount'] ?? userSnapshot.data()?['completed'] ?? 0;

        // 1. Reward the user
        transaction.update(userRef, {
          'coins': currentCoins + reward,
          'completedCount': totalCompleted + 1,
        });

        // 2. Increment completedCount & add to viewedUsers on the Ad
        final int newCompleted = currentCompleted + 1;
        transaction.update(adRef, {
          'completedCount': newCompleted,
          'viewedUsers': FieldValue.arrayUnion([userDayKey]),
          'status': newCompleted >= targetQuantity ? 'completed' : 'active',
        });

        // 3. Log user activity
        transaction.set(activityRef, {
          'id': activityRef.id,
          'title': 'Sponsor Ad Reward',
          'description': 'Earned for visiting ${adDataMap['businessName']}',
          'coins': reward,
          'type': 'earned',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        Navigator.pop(context); // Close dialog/sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Claimed +₹1 successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }

  void _showVerificationDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      barrierDismissible: !_isClaiming,
      builder: (context) {
        final String goal = task['goal'] ?? 'views';
        double reward = 1.0;
        if (goal == 'likes') {
          reward = 4.0;
        } else if (goal == 'followers') {
          reward = 0.20;
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Verify Task Completion', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 1: Open Instagram and complete the task.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _launchURL(task['instagramLink'] ?? ''),
                    icon: const Icon(LucideIcons.instagram, color: AppTheme.secondary),
                    label: const Text('Open Instagram Link', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Step 2: Confirm after completion to claim your reward.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(LucideIcons.indianRupee, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Reward: +₹${reward.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isClaiming ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: _isClaiming
                      ? null
                      : () async {
                          setDialogState(() {
                            _isClaiming = true;
                          });
                          await _claimReward(task);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  child: _isClaiming
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Claim Reward'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showFollowWarningDialog(Map<String, dynamic> task) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: Color(0xFFF59E0B), size: 28),
              SizedBox(width: 10),
              Text(
                'Fair Play Rule! ⚠️',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To maintain a fair community, please read carefully:',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                '• Do not unfollow creators after claiming rewards.\n'
                '• All follows are verified during coin withdrawals.\n'
                '• Fake claims or unfollowing will result in immediate account ban and loss of all earnings.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('has_seen_follow_warning', true);
                if (mounted) {
                  setState(() {
                    _hasSeenFollowWarning = true;
                  });
                }
                Navigator.of(context).pop();
                // Proceed to task
                _launchURL(task['instagramLink'] ?? '');
                _showVerificationDialog(task);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('I Understand & Agree', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showSponsorDetailsDialog(Map<String, dynamic> ad) {
    showDialog(
      context: context,
      barrierDismissible: !_isClaiming,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(LucideIcons.megaphone, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ad['businessName'] ?? 'Sponsored Ad',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad['headline'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ad['description'] ?? '',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Step 1: Click button to open website or map location.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _launchURL(ad['websiteLink'] ?? ''),
                    icon: const Icon(LucideIcons.externalLink, color: AppTheme.secondary, size: 18),
                    label: const Text(
                      'Visit Sponsor Link',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Step 2: Claim your reward after visiting.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(LucideIcons.indianRupee, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 4),
                      const Text(
                        'Reward: +₹1',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 15),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isClaiming ? null : () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: _isClaiming
                      ? null
                      : () async {
                          setDialogState(() {
                            _isClaiming = true;
                          });
                          await _claimSponsorReward(ad);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  child: _isClaiming
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify & Claim'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in first.')),
      );
    }

    final String dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final String userDayKey = "${user.uid}_$dateStr";

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Insta.In ', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WalletScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.indianRupee, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _coins.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Ad Promotion PageView Banner
            StatefulBuilder(
              builder: (context, setBannerState) {
                return Column(
                  children: [
                    SizedBox(
                      height: 165,
                      child: PageView(
                        controller: _bannerController,
                        onPageChanged: (index) {
                          setBannerState(() {
                            _currentBannerPage = index;
                          });
                        },
                        children: [
                          // Banner 1: Promote Your Business
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEC4899).withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Promote Your Business! 📢',
                                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Sponsor your shop, brand, website, or channel and get real local visits.',
                                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const AddSponsorAdScreen()),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF8B5CF6),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Create Sponsor Ad', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Banner 2: Join WhatsApp Channel
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF047857)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Join WhatsApp Channel! 💬',
                                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Join our official channel for updates, bonuses, and priority support.',
                                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () => _launchURL('https://whatsapp.com/channel/0029Va90d6jD38PaeU1vM90U'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF10B981),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Join Now', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Page indicator dots underneath the banners
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentBannerPage == index ? 16 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentBannerPage == index ? AppTheme.primary : AppTheme.textSecondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),

            // Sponsored Ads Row
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sponsor_ads')
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final allAds = snapshot.data!.docs;
                final activeAds = allAds.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final List viewedUsers = data['viewedUsers'] ?? [];
                  final String creatorId = data['userId'] ?? '';
                  final int current = data['completedCount'] ?? 0;
                  final int target = data['quantity'] ?? 0;
                  return creatorId != user.uid && !viewedUsers.contains(userDayKey) && current < target;
                }).toList();

                if (activeAds.isEmpty) return const SizedBox();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Sponsored Offers (Sponsor Ads)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: activeAds.length,
                        itemBuilder: (context, index) {
                          final adDoc = activeAds[index];
                          final adData = adDoc.data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () {
                              _launchURL(adData['websiteLink'] ?? '');
                              _showSponsorDetailsDialog(adData);
                            },
                            child: Container(
                              width: 240,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppTheme.surface, const Color(0xFF1E1E2D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.secondary.withOpacity(0.3), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          adData['businessName'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.primary, width: 1),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(LucideIcons.indianRupee, color: AppTheme.primary, size: 10),
                                            Text(
                                              ' +1',
                                              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    adData['headline'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            // Instagram & Sponsor Tasks Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Available Tasks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('campaigns')
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, campaignSnapshot) {
                if (campaignSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  );
                }

                if (campaignSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: ${campaignSnapshot.error}', style: const TextStyle(color: AppTheme.error)),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('sponsor_ads')
                      .where('status', isEqualTo: 'active')
                      .snapshots(),
                  builder: (context, sponsorSnapshot) {
                    if (sponsorSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error: ${sponsorSnapshot.error}', style: const TextStyle(color: AppTheme.error)),
                        ),
                      );
                    }

                    final allCampaigns = campaignSnapshot.data?.docs ?? [];
                    final allSponsorAds = sponsorSnapshot.data?.docs ?? [];

                    // Filter campaigns locally
                    final campaignTasks = allCampaigns.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String creatorId = data['userId'] ?? '';
                      final int current = data['completedCount'] ?? 0;
                      final int target = data['quantity'] ?? 0;
                      final String goal = data['goal'] ?? '';
                      return creatorId != user.uid && current < target && goal == 'followers';
                    }).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        ...data,
                        'id': doc.id,
                        'isSponsor': false,
                      };
                    }).toList();

                    // Filter sponsor ads locally
                    final sponsorTasks = allSponsorAds.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final List viewedUsers = data['viewedUsers'] ?? [];
                      final String creatorId = data['userId'] ?? '';
                      final int current = data['completedCount'] ?? 0;
                      final int target = data['quantity'] ?? 0;
                      return creatorId != user.uid && !viewedUsers.contains(userDayKey) && current < target;
                    }).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        ...data,
                        'id': doc.id,
                        'isSponsor': true,
                      };
                    }).toList();

                    // Combine tasks
                    final tasks = [...sponsorTasks, ...campaignTasks];

                    if (tasks.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary.withOpacity(0.1),
                                ),
                                child: const Icon(LucideIcons.partyPopper, size: 48, color: AppTheme.primary),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No active tasks available!',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check back later! Other creators will publish new campaigns soon.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final bool isSponsor = task['isSponsor'] ?? false;

                        IconData icon;
                        String title;
                        String subtitle;
                        double reward = 1.0;

                        if (isSponsor) {
                          icon = LucideIcons.megaphone;
                          title = task['businessName'] ?? 'Sponsored Ad';
                          subtitle = task['headline'] ?? 'Visit & earn coins';
                          reward = 1.0;
                        } else {
                          icon = LucideIcons.userPlus;
                          title = 'Follow Instagram Creator';
                          subtitle = 'Tap to complete task';
                          reward = 0.20;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (isSponsor) {
                                _launchURL(task['websiteLink'] ?? '');
                                _showSponsorDetailsDialog(task);
                              } else {
                                if (_hasSeenFollowWarning) {
                                  _launchURL(task['instagramLink'] ?? '');
                                  _showVerificationDialog(task);
                                } else {
                                  _showFollowWarningDialog(task);
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (isSponsor ? AppTheme.secondary : AppTheme.primary).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(icon, color: isSponsor ? AppTheme.secondary : AppTheme.primary, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            if (isSponsor) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.secondary.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppTheme.secondary.withOpacity(0.3), width: 1),
                                                ),
                                                child: Text(
                                                  'Sponsor',
                                                  style: TextStyle(
                                                    color: AppTheme.secondary,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Reward', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.indianRupee, color: AppTheme.primary, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '+₹${reward.toStringAsFixed(2)}',
                                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
