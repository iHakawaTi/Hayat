import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/premium_background.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock activity data
    final activities = [
      {'title': 'Donation at King Hussein Cancer Center', 'time': '2 months ago', 'amount': '450ml', 'points': '+50'},
      {'title': 'Blood Request Fulfilled for A+', 'time': '3 months ago', 'amount': '450ml', 'points': '+75'},
      {'title': 'First Donation Milestone!', 'time': '6 months ago', 'amount': '450ml', 'points': '+100'},
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("My Activity", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const PremiumBackground(),
          SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length, 
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: AppTheme.primaryRed),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activity['title']!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                            Text("${activity['time']} • ${activity['amount']}", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(activity['points']!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (100 * index).ms).slideX();
              },
            ),
          ),
        ],
      ),
    );
  }
}
