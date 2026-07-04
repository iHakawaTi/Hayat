// lib/features/donor/presentation/donor_home_screen.dart
// Full Data-Driven Dashboard — Supabase + ML API
// Replaces the previous placeholder content with live widgets.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../../core/presentation/widgets/premium_background.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../home/presentation/scaffold_with_nav_bar.dart';
import '../../home/data/dashboard_service.dart';
import '../../home/presentation/widgets/dashboard_widgets.dart';
import '../../home/presentation/widgets/ai_insights_widgets.dart';

// ── Keep the existing urgentRequestsProvider for backwards-compat ──
import '../../patient/data/request_repository.dart';

final urgentRequestsProvider = FutureProvider<List<BloodRequest>>((ref) async {
  return ref.read(requestRepositoryProvider).getUrgentRequests();
});

class DonorHomeScreen extends ConsumerWidget {
  const DonorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;

    // Watch all Supabase providers
    final donorStats = ref.watch(donorStatsProvider);
    final requestsSummary = ref.watch(requestsSummaryProvider);
    final bloodBankStock = ref.watch(bloodBankStockProvider);
    final recentSubmissions = ref.watch(recentSubmissionsProvider);
    final hospitalOverview = ref.watch(hospitalOverviewProvider);

    final String displayName = user?.email?.split('@').first ?? 'Hero';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Hayat',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => shellScaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white70),
            tooltip: 'Refresh data',
            onPressed: () {
              ref.invalidate(donorStatsProvider);
              ref.invalidate(bloodBankStockProvider);
              ref.invalidate(recentSubmissionsProvider);
              ref.invalidate(hospitalOverviewProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
              context.go('/');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const PremiumBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: AppTheme.primaryRed,
              backgroundColor: const Color(0xFF1E1E1E),
              onRefresh: () async {
                ref.invalidate(donorStatsProvider);
                ref.invalidate(bloodBankStockProvider);
                ref.invalidate(recentSubmissionsProvider);
                ref.invalidate(hospitalOverviewProvider);
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HERO GREETING ──────────────────────────────
                    _HeroGreetingCard(displayName: displayName)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.04),

                    const SizedBox(height: 28),

                    // ── SECTION: DASHBOARD ─────────────────────────
                    _sectionLabel('Platform Overview'),
                    const SizedBox(height: 14),

                    // 1. Donor Stats
                    DonorStatsCard(
                      data: donorStats,
                      onRetry: () => ref.invalidate(donorStatsProvider),
                    ),
                    const SizedBox(height: 14),

                    // 2. Blood Requests (live stream)
                    BloodRequestsSummaryCard(
                      data: requestsSummary,
                      onRetry: () => ref.invalidate(requestsSummaryProvider),
                    ),
                    const SizedBox(height: 14),

                    // 3. Blood Bank Stock
                    BloodBankStockCard(
                      data: bloodBankStock,
                      onRetry: () => ref.invalidate(bloodBankStockProvider),
                    ),
                    const SizedBox(height: 14),

                    // 4. Recent Submissions
                    RecentSubmissionsCard(
                      data: recentSubmissions,
                      onRetry: () => ref.invalidate(recentSubmissionsProvider),
                    ),
                    const SizedBox(height: 14),

                    // 5. Hospital Overview
                    HospitalOverviewCard(
                      data: hospitalOverview,
                      onRetry: () => ref.invalidate(hospitalOverviewProvider),
                    ),

                    const SizedBox(height: 32),

                    // ── SECTION: AI INSIGHTS ───────────────────────
                    const AiInsightsSectionHeader(),
                    const SizedBox(height: 14),

                    // AI 1: Demand Forecast
                    const DemandForecastCard(),
                    const SizedBox(height: 14),

                    // AI 2: Top Reliable Donors
                    const TopDonorsCard(),
                    const SizedBox(height: 14),

                    // AI 3: Fulfillment Estimates
                    const FulfillmentEstimatesCard(),

                    const SizedBox(height: 32),

                    // ── QUICK ACTION BUTTONS ───────────────────────
                    _QuickActions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.45),
          letterSpacing: 1.2,
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// HERO GREETING CARD (Glassmorphism)
// ═══════════════════════════════════════════════════════════════

class _HeroGreetingCard extends StatelessWidget {
  final String displayName;
  const _HeroGreetingCard({required this.displayName});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryRed.withOpacity(0.8),
                AppTheme.darkRed.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              // Animated drop icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop, size: 32, color: Colors.white)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                        duration: 800.ms,
                        begin: const Offset(1, 1),
                        end: const Offset(1.15, 1.15),
                        curve: Curves.easeInOut),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white70),
                    ),
                    Text(
                      displayName,
                      style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Live Dashboard  ·  Updated just now',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.white70),
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

// ═══════════════════════════════════════════════════════════════
// QUICK ACTION BUTTONS
// ═══════════════════════════════════════════════════════════════

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.45),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.favorite,
                label: 'Donate',
                color: AppTheme.primaryRed,
                onTap: () => context.push('/donor-home/pre-donation/MOH'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.medical_services_outlined,
                label: 'Request',
                color: Colors.blueAccent,
                onTap: () => context.push('/create-request'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.auto_awesome,
                label: 'AI Chat',
                color: Colors.purpleAccent,
                onTap: () => context.push('/chat'),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.06);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
