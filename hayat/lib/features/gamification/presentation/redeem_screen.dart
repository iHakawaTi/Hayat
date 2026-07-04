import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/premium_background.dart';

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  int _userPoints = 200; // Mock initial points

  final rewards = [
    {'title': 'Free Coffee', 'points': 100, 'icon': Icons.coffee, 'partner': 'Starbucks'},
    {'title': 'Movie Ticket', 'points': 250, 'icon': Icons.movie, 'partner': 'Grand Cinemas'},
    {'title': 'Gym Day Pass', 'points': 300, 'icon': Icons.fitness_center, 'partner': 'Fitness First'},
    {'title': 'Restaurant Voucher', 'points': 500, 'icon': Icons.restaurant, 'partner': 'Local Partners'},
    {'title': 'Shopping Discount', 'points': 750, 'icon': Icons.shopping_bag, 'partner': 'City Mall'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Redeem Points", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const PremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                // Points Balance Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryRed, AppTheme.darkRed],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Your Balance", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text("$_userPoints", style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                          Text("points", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                      const Icon(Icons.stars, size: 64, color: Colors.white24),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),

                // Rewards List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rewards.length,
                    itemBuilder: (context, index) {
                      final reward = rewards[index];
                      final rewardPoints = reward['points'] as int;
                      final canAfford = _userPoints >= rewardPoints;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: canAfford ? AppTheme.primaryRed.withOpacity(0.3) : Colors.white10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (canAfford ? AppTheme.primaryRed : Colors.grey).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(reward['icon'] as IconData, color: canAfford ? AppTheme.primaryRed : Colors.grey),
                          ),
                          title: Text(reward['title'] as String, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text(reward['partner'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: canAfford ? AppTheme.primaryRed : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text("$rewardPoints pts", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          onTap: canAfford ? () {
                            _showRedeemDialog(reward['title'] as String, reward['partner'] as String, rewardPoints);
                          } : null,
                        ),
                      ).animate().fadeIn(delay: (100 * index).ms).slideX();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRedeemDialog(String title, String partner, int points) {
    final couponCode = _generateCouponCode();
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.2), blurRadius: 30)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard, size: 48, color: AppTheme.primaryRed),
              ).animate().scale(),
              const SizedBox(height: 16),
              Text("Redeem $title?", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text("at $partner", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              
              // Coupon Code Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Text("YOUR COUPON CODE", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(couponCode, style: GoogleFonts.firaCode(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4)),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: couponCode));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 8),
              Text("-$points points", style: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _userPoints -= points;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("🎉 Redeemed $title! Check your email."), backgroundColor: Colors.green),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Confirm"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }

  String _generateCouponCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
