import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:insta_in/core/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:insta_in/features/earn/add_sponsor_ad_screen.dart';

class AddCampaignScreen extends StatefulWidget {
  const AddCampaignScreen({super.key});

  @override
  State<AddCampaignScreen> createState() => _AddCampaignScreenState();
}

class _AddCampaignScreenState extends State<AddCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();
  
  int _selectedPackage = 0; // 0 for Combo Pack (75 Rs), 1 for Growth Pack (150 Rs)
  bool _isCreating = false;

  int get _totalCost => _selectedPackage == 0 ? 75 : 150;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _createCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    String link = _linkController.text.trim();
    
    // Normalize link or username to a valid Instagram URL
    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      if (link.contains('instagram.com/')) {
        link = 'https://$link';
      } else {
        // Strip leading '@' if present
        if (link.startsWith('@')) {
          link = link.substring(1);
        }
        link = 'https://instagram.com/$link';
      }
    }

    final int cost = _totalCost;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final campaignRef = FirebaseFirestore.instance.collection('campaigns').doc();
      final activityRef = userRef.collection('activities').doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          throw Exception('User profile not found in database.');
        }

        final int currentCoins = userSnapshot.data()?['coins'] ?? 0;
        if (currentCoins < cost) {
          throw Exception('Insufficient balance! You need ₹$cost.');
        }

        final int currentCampaigns = userSnapshot.data()?['campaignsCount'] ?? userSnapshot.data()?['campaigns'] ?? 0;
        const int campaignIncrement = 1;

        // Deduct coins and update campaignsCount
        transaction.update(userRef, {
          'coins': currentCoins - cost,
          'campaignsCount': currentCampaigns + campaignIncrement,
        });

        final int qty = (_selectedPackage == 0) ? 200 : 500;

        // Create Followers campaign (cost = cost)
        transaction.set(campaignRef, {
          'id': campaignRef.id,
          'userId': user.uid,
          'instagramLink': link,
          'goal': 'followers',
          'quantity': qty,
          'completedCount': 0,
          'totalCost': cost,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });

        // Record activity log
        transaction.set(activityRef, {
          'id': activityRef.id,
          'title': 'Campaign Created',
          'description': _selectedPackage == 0
              ? 'Combo Pack (200 Followers)'
              : 'Growth Pack (500 Followers)',
          'coins': cost,
          'type': 'spent',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Campaign Created Successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        _linkController.clear();
      }
    } catch (e) {
      if (mounted) {
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
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Register dependency to rebuild instantly when theme toggles
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Ad Promotion Banner
              Container(
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
              const SizedBox(height: 24),

              // Link Input
              const Text('Instagram Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  hintText: 'https://instagram.com/p/... or @username',
                  prefixIcon: Icon(LucideIcons.link),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a valid Instagram post or account link';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Choose Package
              const Text('Choose Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPackage = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedPackage == 0 ? AppTheme.primary.withOpacity(0.15) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedPackage == 0 ? AppTheme.primary : AppTheme.primary.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Combo Pack',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                             Text(
                              '200 Followers\n(Likes & Views Free)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(LucideIcons.indianRupee, color: AppTheme.primary, size: 16),
                                const Text(
                                  '75',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPackage = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedPackage == 1 ? AppTheme.primary.withOpacity(0.15) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedPackage == 1 ? AppTheme.primary : AppTheme.primary.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Growth Pack',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                             Text(
                              '500 Followers\n(Likes & Views Free)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(LucideIcons.indianRupee, color: AppTheme.primary, size: 16),
                                 const Text(
                                  '150',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Total Cost Summary
              Card(
                color: AppTheme.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Cost', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(LucideIcons.indianRupee, color: AppTheme.primary, size: 24),
                          const SizedBox(width: 8),
                          Text('$_totalCost', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isCreating ? null : _createCampaign,
                child: _isCreating
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Pay & Create Campaign'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
