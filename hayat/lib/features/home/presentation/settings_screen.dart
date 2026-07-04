import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/premium_background.dart';
import '../../auth/data/auth_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Settings", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const PremiumBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader("Account").animate().fadeIn(),
                _buildSettingsTile(
                  icon: Icons.person_outline, 
                  title: "Edit Profile", 
                  onTap: () => context.go('/donor-home')
                ).animate().fadeIn(delay: 100.ms).slideX(),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined, 
                  title: "Notifications", 
                  trailing: Switch(value: true, onChanged: (v) {}, activeColor: AppTheme.primaryRed)
                ).animate().fadeIn(delay: 200.ms).slideX(),
                _buildSettingsTile(
                  icon: Icons.language, 
                  title: "Language", 
                  subtitle: "English",
                  onTap: () {}
                ).animate().fadeIn(delay: 300.ms).slideX(),
                
                const SizedBox(height: 24),
                _buildSectionHeader("Security").animate().fadeIn(delay: 400.ms),
                _buildSettingsTile(icon: Icons.lock_outline, title: "Change Password", onTap: () {}).animate().fadeIn(delay: 500.ms).slideX(),
                _buildSettingsTile(icon: Icons.privacy_tip_outlined, title: "Privacy Policy", onTap: () {}).animate().fadeIn(delay: 600.ms).slideX(),

                const SizedBox(height: 24),
                _buildSettingsTile(
                  icon: Icons.logout, 
                  title: "Log Out", 
                  color: Colors.redAccent,
                  onTap: () {
                     ref.read(authRepositoryProvider).signOut();
                     context.go('/');
                  }
                ).animate().fadeIn(delay: 700.ms).slideX(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.white70),
        title: Text(title, style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
        onTap: onTap,
      ),
    );
  }
}
