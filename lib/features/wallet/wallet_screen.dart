import 'package:flutter/material.dart';
import 'package:insta_in/core/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Transactions
    final transactions = [
      {'title': 'Campaign Created', 'amount': -150, 'date': 'Today, 10:30 AM', 'isEarn': false},
      {'title': 'Watched 3 Reels', 'amount': 30, 'date': 'Yesterday, 4:15 PM', 'isEarn': true},
      {'title': 'Deposit Funds', 'amount': 500, 'date': '12 May 2026', 'isEarn': true},
      {'title': 'Followed User', 'amount': 20, 'date': '10 May 2026', 'isEarn': true},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(LucideIcons.coins, color: Colors.amber, size: 36),
                        SizedBox(width: 12),
                        Text('400', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(LucideIcons.arrowDownToLine, size: 18),
                            label: const Text('Deposit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(LucideIcons.arrowUpFromLine, size: 18),
                            label: const Text('Withdraw'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black26,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            
            // Transactions List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isEarn = tx['isEarn'] as bool;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isEarn ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEarn ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                        color: isEarn ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                    title: Text(tx['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(tx['date'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    trailing: Text(
                      '${isEarn ? '+' : ''}${tx['amount']}',
                      style: TextStyle(
                        color: isEarn ? AppTheme.success : AppTheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
