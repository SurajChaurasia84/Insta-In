import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:insta_in/core/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AddSponsorAdScreen extends StatefulWidget {
  const AddSponsorAdScreen({super.key});

  @override
  State<AddSponsorAdScreen> createState() => _AddSponsorAdScreenState();
}

class _AddSponsorAdScreenState extends State<AddSponsorAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  
  int _selectedPackage = 0; // 0 for Starter Promo (150 Rs), 1 for Business Grow (400 Rs)
  bool _isCreating = false;

  int get _totalCost => _selectedPackage == 0 ? 150 : 400;
  int get _quantity => _selectedPackage == 0 ? 100 : 250;

  @override
  void dispose() {
    _businessNameController.dispose();
    _headlineController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _createSponsorAd() async {
    if (!_formKey.currentState!.validate()) return;

    final String businessName = _businessNameController.text.trim();
    final String headline = _headlineController.text.trim();
    final String description = _descriptionController.text.trim();
    final String link = _linkController.text.trim();
    final int cost = _totalCost;
    final int quantity = _quantity;

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
      final sponsorRef = FirebaseFirestore.instance.collection('sponsor_ads').doc();
      final activityRef = userRef.collection('activities').doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          throw Exception('User profile not found in database.');
        }

        final double currentCoins = (userSnapshot.data()?['coins'] ?? 0).toDouble();
        if (currentCoins < cost) {
          throw Exception('Insufficient balance! You need ₹$cost.');
        }

        final int currentCampaigns = ((userSnapshot.data()?['campaignsCount'] ?? userSnapshot.data()?['campaigns'] ?? 0) as num).toInt();

        // Deduct coins and update campaignsCount
        transaction.update(userRef, {
          'coins': currentCoins - cost,
          'campaignsCount': currentCampaigns + 1,
        });

        // Create Sponsor Ad
        transaction.set(sponsorRef, {
          'id': sponsorRef.id,
          'userId': user.uid,
          'businessName': businessName,
          'headline': headline,
          'description': description,
          'websiteLink': link,
          'quantity': quantity,
          'completedCount': 0,
          'totalCost': cost,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'viewedUsers': [],
        });

        // Record activity log
        transaction.set(activityRef, {
          'id': activityRef.id,
          'title': 'Sponsor Ad Launched',
          'description': 'Promoted: $businessName | Qty: $quantity',
          'coins': cost,
          'type': 'spent',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Sponsor Ad Launched Successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
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
        title: const Text('Sponsor Your Business', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.megaphone, color: AppTheme.primary, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Promote your shop, website, restaurant or brand directly to active users. They will visit your business and earn rewards.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Business Name Input
              const Text('Business / Shop Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Sharma Sweets & Cafe',
                  prefixIcon: Icon(LucideIcons.store),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter business name';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Headline Input
              const Text('Ad Headline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _headlineController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'e.g. Get 20% off on all sweets today!',
                  prefixIcon: Icon(LucideIcons.sparkles),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter a short ad headline';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description Input
              const Text('Description / Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe your business or offer in detail...',
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter details';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Link Input
              const Text('Website or Location Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  hintText: 'Enter or paste URL',
                  prefixIcon: Icon(LucideIcons.navigation),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter link to your shop/website';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Choose Package
              const Text('Select Ad Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                                'Starter Promo',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '100 Real Visits\n(Guaranteed)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(LucideIcons.indianRupee, color: AppTheme.primary, size: 16),
                                const Text(
                                  '150',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
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
                                'Business Grow',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '250 Real Visits\n(Guaranteed)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(LucideIcons.indianRupee, color: AppTheme.primary, size: 16),
                                const Text(
                                  '400',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary),
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

              // Total Cost Card
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
                      const Text('Total Cost', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(LucideIcons.indianRupee, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 6),
                          Text('$_totalCost', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isCreating ? null : _createSponsorAd,
                child: _isCreating
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Pay & Publish Ad'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
