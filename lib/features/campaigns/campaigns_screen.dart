import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:insta_in/core/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  StreamSubscription? _campaignsSubscription;
  StreamSubscription? _sponsorsSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToCampaignsAndSponsors();
  }

  @override
  void dispose() {
    _campaignsSubscription?.cancel();
    _sponsorsSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToCampaignsAndSponsors() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<Map<String, dynamic>> campaignsList = [];
    List<Map<String, dynamic>> sponsorsList = [];

    void updateCombinedList() {
      final combined = [...campaignsList, ...sponsorsList];
      // Sort locally by creation timestamp descending to avoid compound index requirements
      combined.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _items = combined;
          _isLoading = false;
        });
      }
    }

    _campaignsSubscription = FirebaseFirestore.instance
        .collection('campaigns')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      campaignsList = snapshot.docs.where((doc) {
        final data = doc.data();
        return (data['goal'] ?? '') == 'followers';
      }).map((doc) {
        final data = doc.data();
        data['isSponsor'] = false;
        return data;
      }).toList();
      updateCombinedList();
    });

    _sponsorsSubscription = FirebaseFirestore.instance
        .collection('sponsor_ads')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      sponsorsList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['isSponsor'] = true;
        return data;
      }).toList();
      updateCombinedList();
    });
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
        title: const Text('My Campaigns', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _items.isEmpty
              ? Center(
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
                          child: const Icon(LucideIcons.rocket, size: 48, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No campaigns created yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Switch to the "Add" tab to launch your first Instagram campaign or Sponsor Ad!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final data = _items[index];
                    final bool isSponsor = data['isSponsor'] ?? false;

                    final String title = isSponsor 
                        ? (data['businessName'] ?? 'Sponsor Ad')
                        : 'Instagram Followers';
                    final String subtitle = isSponsor
                        ? (data['websiteLink'] ?? '')
                        : (data['instagramLink'] ?? '');
                    final int current = data['completedCount'] ?? 0;
                    final int target = data['quantity'] ?? 100;
                    final String status = data['status'] ?? 'active';

                    final double progress = (target > 0) ? (current / target).clamp(0.0, 1.0) : 0.0;

                    final IconData icon = isSponsor ? LucideIcons.megaphone : LucideIcons.userPlus;
                    final Color iconBgColor = isSponsor 
                        ? const Color(0xFF10B981).withOpacity(0.1) 
                        : AppTheme.primary.withOpacity(0.1);
                    final Color iconColor = isSponsor 
                        ? const Color(0xFF10B981) 
                        : AppTheme.primary;

                    final isCompleted = status == 'completed' || current >= target;
                    final String progressLabel = isSponsor ? 'visits' : 'followers';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: iconBgColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isCompleted ? AppTheme.success : iconColor).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isCompleted ? 'Completed' : 'Active',
                                    style: TextStyle(
                                      color: isCompleted ? AppTheme.success : iconColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progress',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                                ),
                                Text(
                                  '$current / $target $progressLabel',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: iconColor.withOpacity(0.1),
                              color: isCompleted ? AppTheme.success : iconColor,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
