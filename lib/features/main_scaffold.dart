import 'package:flutter/material.dart';
import 'package:insta_in/features/campaigns/add_campaign_screen.dart';
import 'package:insta_in/features/campaigns/campaigns_screen.dart';
import 'package:insta_in/features/earn/earn_screen.dart';
import 'package:insta_in/features/wallet/wallet_screen.dart';
import 'package:insta_in/features/profile/profile_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    EarnScreen(),
    CampaignsScreen(),
    AddCampaignScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.listStart),
            label: 'Campaigns',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.plusCircle),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
