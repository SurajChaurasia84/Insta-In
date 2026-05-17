import 'package:flutter/material.dart';
import 'package:insta_in/core/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EarnScreen extends StatelessWidget {
  const EarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data for MVP
    final tasks = [
      {'title': 'Like this Post', 'reward': 5, 'type': 'like', 'icon': LucideIcons.heart},
      {'title': 'Watch this Reel', 'reward': 10, 'type': 'view', 'icon': LucideIcons.playCircle},
      {'title': 'Follow this Creator', 'reward': 20, 'type': 'follow', 'icon': LucideIcons.userPlus},
      {'title': 'Like and Comment', 'reward': 15, 'type': 'like', 'icon': LucideIcons.messageCircle},
      {'title': 'Watch 3 Reels', 'reward': 30, 'type': 'view', 'icon': LucideIcons.playCircle},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Chip(
              backgroundColor: AppTheme.primary.withOpacity(0.2),
              avatar: const Icon(LucideIcons.coins, color: Colors.amber, size: 18),
              label: const Text('150', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
              side: BorderSide.none,
            ),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // Mock action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening Instagram for: ${task['title']}...')),
                );
              },
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
                      child: Icon(task['icon'] as IconData, color: AppTheme.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'] as String,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to complete task',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Reward', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.coins, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '+${task['reward']}',
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
      ),
    );
  }
}
