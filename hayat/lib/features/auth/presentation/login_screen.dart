import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

import '../../auth/data/auth_repository.dart';
import '../../donor/data/donor_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/premium_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isRegistering = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final auth = ref.read(authRepositoryProvider);

      if (_isRegistering) {
        await auth.signUpWithEmail(email, password);
        if (mounted) {
           _showPremiumDialog(
             title: "Account Created",
             message: "We sent a confirmation link to $email. Please check your inbox to activate your account.",
             icon: Icons.mark_email_read,
           );
           setState(() => _isRegistering = false);
        }
      } else {
        await auth.signInWithEmail(email, password);
        if (mounted) {
          final user = ref.read(authRepositoryProvider).currentUser;
          if (user != null) {
            final profile = await ref.read(donorRepositoryProvider).getDonorProfile(user.id);
            if (profile == null) {
              context.go('/complete-profile');
            } else {
              context.go('/donor-home');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll("AuthException:", "").trim();
        _showErrorSnackBar(msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showPremiumDialog({required String title, required String message, required IconData icon}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(icon, size: 48, color: AppTheme.primaryRed),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
        actions: [
          TextButton(
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const PremiumBackground(),

          // Glassmorphism Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Icon(Icons.bloodtype, size: 64, color: AppTheme.primaryRed)
                              .animate().fadeIn().scale(),
                          const SizedBox(height: 16),
                          Text(
                            'app_title'.tr(),
                            style: Theme.of(context).textTheme.displayMedium,
                          ).animate().fadeIn(delay: 100.ms),
                          Text(
                            _isRegistering ? "Join the movement" : 'welcome_message'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 32),
                          
                          // Inputs
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ).animate().fadeIn(delay: 300.ms).slideX(),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white),
                             decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
                          ).animate().fadeIn(delay: 400.ms).slideX(),
                          
                          const SizedBox(height: 32),
                          
                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading 
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(_isRegistering ? 'Create Account' : 'Login'),
                            ),
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                          
                          const SizedBox(height: 24),
                          
                          // Switcher
                          TextButton(
                            onPressed: () => setState(() => _isRegistering = !_isRegistering),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.grey),
                                children: [
                                  TextSpan(text: _isRegistering ? "Already a hero? " : "New to Hayat? "),
                                  TextSpan(
                                    text: _isRegistering ? "Login" : "Register Now",
                                    style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Language
                           Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _LangButton(label: "EN", onTap: () => context.setLocale(const Locale('en'))),
                              Container(height: 12, width: 1, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 12)),
                              _LangButton(label: "عربي", onTap: () => context.setLocale(const Locale('ar'))),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LangButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}
