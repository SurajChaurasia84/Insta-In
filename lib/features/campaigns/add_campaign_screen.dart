import 'package:flutter/material.dart';
import 'package:insta_in/core/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AddCampaignScreen extends StatefulWidget {
  const AddCampaignScreen({super.key});

  @override
  State<AddCampaignScreen> createState() => _AddCampaignScreenState();
}

class _AddCampaignScreenState extends State<AddCampaignScreen> {
  String _selectedGoal = 'views';
  double _quantity = 100;

  final Map<String, int> _costPerItem = {
    'views': 1,
    'likes': 5,
    'followers': 10,
  };

  int get _totalCost => (_quantity * _costPerItem[_selectedGoal]!).toInt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Link Input
            const Text('Instagram Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'https://instagram.com/p/...',
                prefixIcon: Icon(LucideIcons.link),
              ),
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Campaign Created Successfully!')),
                );
              },
              child: const Text('Pay & Create Campaign'),
            )
          ],
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
