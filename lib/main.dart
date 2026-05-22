import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:insta_in/core/theme.dart';
import 'package:insta_in/features/auth/onboarding_screen.dart';
import 'package:insta_in/features/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase
  await Firebase.initializeApp();

  // 2. Check Session, Onboarding status, and Theme preference
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  final bool isLightMode = prefs.getBool('is_light_mode') ?? false;
  AppTheme.themeNotifier.value = isLightMode ? ThemeMode.light : ThemeMode.dark;

  // 3. Configure System Status Bar Style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isLightMode ? Brightness.dark : Brightness.light,
      statusBarBrightness: isLightMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isLightMode ? const Color(0xFFFFFFFF) : const Color(0xFF1E293B), // Matches surface
      systemNavigationBarIconBrightness: isLightMode ? Brightness.dark : Brightness.light,
    ),
  );

  // If onboarding is done AND user is logged in, directly go to Main Dashboard.
  // Otherwise, they MUST go through the Onboarding / Google Sign-In.
  final Widget defaultHome = (onboardingCompleted && currentUser != null)
      ? const MainScaffold()
      : const OnboardingScreen();

  runApp(MyApp(homeWidget: defaultHome));
}

class MyApp extends StatelessWidget {
  final Widget homeWidget;
  const MyApp({super.key, required this.homeWidget});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Instagram.In',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: homeWidget,
        );
      },
    );
  }
}
