import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/premium_background.dart';

class PreDonationFormScreen extends StatefulWidget {
  final String hospitalType;

  const PreDonationFormScreen({super.key, required this.hospitalType});

  @override
  State<PreDonationFormScreen> createState() => _PreDonationFormScreenState();
}

class _PreDonationFormScreenState extends State<PreDonationFormScreen> {
  int _currentStep = 0;
  
  final List<Map<String, dynamic>> _questions = [
    {'q': 'Have you donated blood in the last 3 months?', 'type': 'bool'},
    {'q': 'Are you currently taking any antibiotics?', 'type': 'bool'},
    {'q': 'Have you had a tattoo or piercing in the last 6 months?', 'type': 'bool'},
    {'q': 'Do you have any chronic conditions?', 'type': 'bool'},
  ];

  final Map<int, bool> _answers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Pre-Donation Check", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const PremiumBackground(),
          
          SafeArea(
            child: Column(
              children: [
                // Progress Bar
                LinearProgressIndicator(
                  value: (_currentStep + 1) / (_questions.length + 1),
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _currentStep < _questions.length
                        ? _buildQuestionCard(_questions[_currentStep]['q'])
                        : _buildSuccessCard(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String question) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Question ${_currentStep + 1}", 
          style: GoogleFonts.inter(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, letterSpacing: 1),
        ).animate().fadeIn(),
        const SizedBox(height: 24),
        Text(
          question, 
          style: GoogleFonts.outfit(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(child: _buildOptionBtn("NO", false)),
            const SizedBox(width: 24),
            Expanded(child: _buildOptionBtn("YES", true)),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3)
      ],
    );
  }

  Widget _buildOptionBtn(String label, bool value) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _answers[_currentStep] = value;
          _currentStep++;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.05),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 24),
        side: const BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSuccessCard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.2)),
          child: const Icon(Icons.check, size: 64, color: Colors.green),
        ).animate().scale(),
        const SizedBox(height: 32),
        Text("You are Eligible!", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))
            .animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 16),
        Text(
          "Please proceed to the reception at ${widget.hospitalType == 'DEFAULT' ? 'the hospital' : widget.hospitalType} and show this screen.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white70),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: const Text("Done"),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3)
      ],
    );
  }
}
