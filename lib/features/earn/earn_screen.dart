import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:insta_in/core/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  bool _isClaiming = false;
  int _coins = 0;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _loadCachedCoins();
    _subscribeToUserCoins();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedCoins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _coins = prefs.getInt('cache_coins_${user.uid}') ?? 0;
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
          final int coins = snapshot.data()!['coins'] ?? 0;
          if (mounted) {
            setState(() {
              _coins = coins;
            });
          }
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('cache_coins_${user.uid}', coins);
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
          SnackBar(content: Text('Could not open Instagram link: $e')),
        );
      }
    }
  }

  Future<void> _claimReward(Map<String, dynamic> taskData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String campaignId = taskData['id'];
    final String goal = taskData['goal'] ?? 'views';
    
    int reward = 1;
    if (goal == 'likes') {
      reward = 4;
    } else if (goal == 'followers') {
      reward = 8;
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

        final int currentCoins = userSnapshot.data()?['coins'] ?? 0;
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
            content: Text('🎉 Claimed +₹$reward successfully!'),
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
        int reward = 1;
        if (goal == 'likes') {
          reward = 4;
        } else if (goal == 'followers') {
          reward = 8;
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
                      const Icon(LucideIcons.indianRupee, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Reward: +₹$reward',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16),
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in first.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Insta.In ', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
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
                    const Icon(LucideIcons.indianRupee, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_coins',
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
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('campaigns')
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.error)));
          }

          final allCampaigns = snapshot.data?.docs ?? [];
          
          // Filter tasks locally (exclude user's own campaigns and full ones)
          final tasks = allCampaigns.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String creatorId = data['userId'] ?? '';
            final int current = data['completedCount'] ?? 0;
            final int target = data['quantity'] ?? 0;
            return creatorId != user.uid && current < target;
          }).toList();

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
            padding: const EdgeInsets.all(16.0),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final taskDoc = tasks[index];
              final task = taskDoc.data() as Map<String, dynamic>;

              final String goal = task['goal'] ?? 'views';

              IconData icon;
              String title;
              int reward = 1;

              if (goal == 'likes') {
                icon = LucideIcons.heart;
                title = 'Like Instagram Post';
                reward = 4;
              } else if (goal == 'followers') {
                icon = LucideIcons.userPlus;
                title = 'Follow Instagram Creator';
                reward = 8;
              } else {
                icon = LucideIcons.playCircle;
                title = 'Watch Instagram Reel';
                reward = 1;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showVerificationDialog(task),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: AppTheme.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to complete task',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Reward', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(LucideIcons.indianRupee, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '+₹$reward',
                                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
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
      ),
    );
  }
}
