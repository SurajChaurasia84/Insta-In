import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:insta_in/core/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'jaswantsingh777705@gmail.com',
      queryParameters: {
        'subject': 'Insta In Support Request',
      },
    );
    try {
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Info', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
          final String appName = snapshot.data?.appName ?? 'Insta In';
          final String version = snapshot.data?.version ?? '1.0.0';
          final String buildNumber = snapshot.data?.buildNumber ?? '1';

          String platformName = 'Unknown';
          if (Platform.isAndroid) {
            platformName = 'Android';
          } else if (Platform.isIOS) {
            platformName = 'iOS';
          } else if (Platform.isMacOS) {
            platformName = 'macOS';
          } else if (Platform.isWindows) {
            platformName = 'Windows';
          } else if (Platform.isLinux) {
            platformName = 'Linux';
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glowing App Logo / Visual Representation
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow Effect
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      // Gradient Logo Container
                      Container(
                        width: 110,
                        height: 110,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primary,
                              AppTheme.secondary,
                            ],
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.instagram,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // App Name & Tagline
                Text(
                  appName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Grow Your Instagram Community',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),

                // App Build and Version Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildInfoRow(context, 'App Name', appName, isLoading),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow(context, 'Version', version, isLoading),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow(context, 'Build Number', buildNumber, isLoading),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow(context, 'Platform', platformName, false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Description Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About App',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Boost your Instagram presence! Insta In helps creators easily gain authentic likes, views, and real followers through our active peer-to-peer engagement community.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary.withOpacity(0.9),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Social & Support Links Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(LucideIcons.mail, color: AppTheme.primary, size: 20),
                          title: const Text('Contact Support', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: const Text('ja*****@gmail.com', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.textSecondary),
                          onTap: _launchEmail,
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        ListTile(
                          leading: const Icon(LucideIcons.globe, color: AppTheme.secondary, size: 20),
                          title: const Text('Visit Website', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: const Text('instain-app.web.app', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.textSecondary),
                          onTap: () => _launchURL('https://instain-app.web.app'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Footer Text
                const Text(
                  'Made with ❤️ for Creators',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '© 2026 Insta In. All rights reserved.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white24,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              )
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ],
    );
  }
}
