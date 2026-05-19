import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:insta_in/core/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AddCampaignScreen extends StatefulWidget {
  const AddCampaignScreen({super.key});

  @override
  State<AddCampaignScreen> createState() => _AddCampaignScreenState();
}

class _AddCampaignScreenState extends State<AddCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();
  
  String _selectedGoal = 'views';
  double _quantity = 100;
  bool _isCreating = false;

  final Map<String, int> _costPerItem = {
    'views': 1,
    'likes': 5,
    'followers': 10,
  };

  int get _totalCost => (_quantity * _costPerItem[_selectedGoal]!).toInt();

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _createCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    final String link = _linkController.text.trim();
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
          throw Exception('Insufficient coins! You need $cost coins.');
        }

        final int currentCampaigns = userSnapshot.data()?['campaignsCount'] ?? userSnapshot.data()?['campaigns'] ?? 0;

        // Deduct coins and update campaignsCount
        transaction.update(userRef, {
          'coins': currentCoins - cost,
          'campaignsCount': currentCampaigns + 1,
        });

        // Save active campaign
        transaction.set(campaignRef, {
          'id': campaignRef.id,
          'userId': user.uid,
          'instagramLink': link,
          'goal': _selectedGoal,
          'quantity': _quantity.toInt(),
          'completedCount': 0,
          'totalCost': cost,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });

        // Record activity log
        transaction.set(activityRef, {
          'id': activityRef.id,
          'title': 'Campaign Created',
          'description': 'Goal: ${_selectedGoal.toUpperCase()} | Qty: ${_quantity.toInt()}',
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
        setState(() {
          _quantity = 100;
        });
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
              // Link Input
              const Text('Instagram Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _linkController,
                style: const TextStyle(color: Colors.white),
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

              // Goal Selection
              const Text('Campaign Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildGoalOption('views', LucideIcons.playCircle, 'Views'),
                  const SizedBox(width: 12),
                  _buildGoalOption('likes', LucideIcons.heart, 'Likes'),
                  const SizedBox(width: 12),
                  _buildGoalOption('followers', LucideIcons.userPlus, 'Followers'),
                ],
              ),
              const SizedBox(height: 32),

              // Quantity Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${_quantity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary)),
                ],
              ),
              Slider(
                value: _quantity,
                min: 50,
                max: 5000,
                divisions: 99,
                activeColor: AppTheme.primary,
                onChanged: (value) {
                  setState(() {
                    _quantity = value;
                  });
                },
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
                          const Icon(LucideIcons.coins, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Text('$_totalCost', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.amber)),
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
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalOption(String id, IconData icon, String label) {
    final isSelected = _selectedGoal == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGoal = id;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
