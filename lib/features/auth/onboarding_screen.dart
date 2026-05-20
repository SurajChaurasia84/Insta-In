import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:insta_in/core/theme.dart';
import 'package:insta_in/features/main_scaffold.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Welcome to Insta In',
      'description': 'Boost your Instagram presence! Easily get likes, views, and real followers from our active community.',
      'icon': LucideIcons.instagram,
      'color': AppTheme.primary,
    },
    {
      'title': 'Support & Get Rewarded',
      'description': 'Support other creators by engaging with their content and get money added to your wallet instantly.',
      'icon': LucideIcons.indianRupee,
      'color': Colors.amber,
    },
    {
      'title': 'Promote Your Profile',
      'description': 'Create your own custom campaigns using your wallet balance to boost your post metrics instantly.',
      'icon': LucideIcons.rocket,
      'color': AppTheme.secondary,
    },
  ];

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 2. Get auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with credential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 5. Save user details to Cloud Firestore
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();

        if (!userDoc.exists) {
          await userDocRef.set({
            'uid': user.uid,
            'name': user.displayName ?? 'Insta In User',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'coins': 0, // No signup bonus, initial balance is 0
          });
        } else {
          await userDocRef.update({
            'name': user.displayName ?? 'Insta In User',
            'photoUrl': user.photoURL ?? '',
          });
        }

        // 6. Save onboarding completed flag to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_completed', true);

        if (mounted) {
          // 7. Go to Main Dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScaffold()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Failed: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.background,
              const Color(0xFF1E1B4B), // Indigo 950
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                  ),
                )
              : Column(
                  children: [
                    // Carousel
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: _slides.length,
                        itemBuilder: (context, index) {
                          final slide = _slides[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: (slide['color'] as Color).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    slide['icon'] as IconData,
                                    size: 100,
                                    color: slide['color'] as Color,
                                  ),
                                ),
                                const SizedBox(height: 48),
                                Text(
                                  slide['title'] as String,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  slide['description'] as String,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppTheme.textSecondary,
                                        height: 1.5,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Indicator Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          height: 8.0,
                          width: _currentPage == index ? 24.0 : 8.0,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? AppTheme.primary : AppTheme.textSecondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Bottom Sign In Area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _signInWithGoogle,
                            icon: Image.asset(
                              'assets/google_logo.png',
                              height: 20,
                              width: 20,
                            ),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 2,
                              shadowColor: Colors.black45,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                           RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(text: 'By signing in, you agree to our '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _launchURL('https://surajchaurasia84.github.io/Insta-In/'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
