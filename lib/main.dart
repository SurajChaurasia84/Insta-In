import 'package:flutter/material.dart';
import 'package:insta_in/core/theme.dart';
import 'package:insta_in/features/auth/auth_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insta In',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthScreen(),
    );
  }
}
