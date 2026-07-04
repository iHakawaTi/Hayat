import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Background Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0F0F), Color(0xFF2D0A14)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        
        // 2. Animated Blobs (Abstract "Cells")
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryRed.withOpacity(0.2),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(duration: 4.seconds, curve: Curves.easeInOut),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple.withOpacity(0.1),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: 0, end: 50, duration: 5.seconds),
        ),
      ],
    );
  }
}
