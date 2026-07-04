// lib/features/home/presentation/widgets/ai_insights_widgets.dart
// AI Insights section: 3 ML-powered cards with individual loading skeletons
// and graceful degradation when the ML API is unavailable.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/ml_service.dart';
import '../../data/ml_dashboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════════

Widget _mlShimmerBox({double height = 20, double? width, double radius = 8}) =>
    Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
          duration: 1400.ms,
          color: Colors.purple.withOpacity(0.15),
        );

Widget _mlSkeleton() => ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purple.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _mlShimmerBox(height: 16, width: 16, radius: 4),
                const SizedBox(width: 8),
                _mlShimmerBox(height: 16, width: 180),
              ]),
              const SizedBox(height: 16),
              _mlShimmerBox(height: 60),
              const SizedBox(height: 8),
              _mlShimmerBox(height: 14, width: 200),
            ],
          ),
        ),
      ),
    );

Widget _mlUnavailableBox() => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined,
              color: Colors.purple.withOpacity(0.5), size: 18),
          const SizedBox(width: 8),
          Text(
            'AI insights unavailable — ML API offline',
            style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );

class _AiCard extends StatelessWidget {
  final Widget child;
  const _AiCard({required this.child});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.withOpacity(0.25)),
            ),
            child: child,
          ),
        ),
      );
}

class _AiCardHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AiCardHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11),
          ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════
// AI INSIGHTS SECTION HEADER
// ═══════════════════════════════════════════════════════════════

class AiInsightsSectionHeader extends StatelessWidget {
  const AiInsightsSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.3),
              Colors.deepPurple.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 14),
          const SizedBox(width: 6),
          Text(
            'AI Insights (Beta)',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.purpleAccent,
            ),
          ),
        ]),
      ),
    ]).animate().fadeIn(duration: 500.ms);
  }
}

// ═══════════════════════════════════════════════════════════════
// 1. DEMAND FORECAST CARD — mini 7-bar chart
// ═══════════════════════════════════════════════════════════════

class DemandForecastCard extends ConsumerWidget {
  const DemandForecastCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(demandForecastProvider);

    return forecastAsync.when(
      loading: () => _mlSkeleton().animate().fadeIn(duration: 300.ms),
      error: (_, __) => _mlUnavailableBox(),
      data: (forecast) {
        if (forecast == null) return _mlUnavailableBox();
        return _AiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AiCardHeader(
                title: 'Predicted demand — next 7 days',
                subtitle: 'XGBoost model · Most requested blood group',
              ),
              const SizedBox(height: 20),
              _MiniBarChart(forecast: forecast),
              const SizedBox(height: 12),
              Text(
                'Total: ${forecast.fold(0, (sum, d) => sum + d.predictedUnitsRounded)} units predicted',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.06);
      },
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final List<DemandForecastDay> forecast;
  const _MiniBarChart({required this.forecast});

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) return const SizedBox.shrink();
    final maxVal = forecast.map((d) => d.predictedUnits).reduce((a, b) => a > b ? a : b);
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: forecast.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value;
          final ratio = maxVal > 0 ? d.predictedUnits / maxVal : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${d.predictedUnitsRounded}',
                    style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 600 + i * 80),
                    curve: Curves.easeOut,
                    height: (ratio * 50).clamp(4.0, 50.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.deepPurple.shade700],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[i % 7],
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. TOP RELIABLE DONORS CARD
// ═══════════════════════════════════════════════════════════════

class TopDonorsCard extends ConsumerWidget {
  const TopDonorsCard({super.key});

  Color _tierColor(String tier) {
    switch (tier) {
      case 'High':
        return const Color(0xFF10B981);
      case 'Medium':
        return Colors.amber;
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donorsAsync = ref.watch(topScoredDonorsProvider);

    return donorsAsync.when(
      loading: () => _mlSkeleton().animate().fadeIn(duration: 300.ms),
      error: (_, __) => _mlUnavailableBox(),
      data: (donors) {
        if (donors == null) return _mlUnavailableBox();
        if (donors.isEmpty) {
          return _AiCard(
            child: Column(children: [
              const _AiCardHeader(
                title: 'Most reliable donors available now',
                subtitle: 'LightGBM model · Engagement scoring',
              ),
              const SizedBox(height: 20),
              Icon(Icons.person_search_outlined,
                  size: 40, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 8),
              Text('No available donors found',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ]),
          );
        }
        return _AiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AiCardHeader(
                title: 'Most reliable donors available now',
                subtitle: 'LightGBM model · Engagement scoring',
              ),
              const SizedBox(height: 16),
              ...donors.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                final color = _tierColor(d.score.reliabilityTier);
                final pct = (d.score.showRateProbability * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#${i + 1}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Blood group circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.primaryRed.withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text(
                            d.bloodGroup,
                            style: const TextStyle(
                              color: AppTheme.primaryRed,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${d.daysSince}d since last donation',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      // Tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$pct%',
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              d.score.reliabilityTier,
                              style: TextStyle(color: color, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.05),
                );
              }),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.06);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. FULFILLMENT ESTIMATES CARD
// ═══════════════════════════════════════════════════════════════

class FulfillmentEstimatesCard extends ConsumerWidget {
  const FulfillmentEstimatesCard({super.key});

  Color _categoryColor(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('same') || lower.contains('<4')) {
      return const Color(0xFF10B981);
    }
    if (lower.contains('48') || lower.contains('2-3') || lower.contains('day')) {
      return Colors.amber;
    }
    return const Color(0xFFEF4444);
  }

  Color _urgencyColor(String u) {
    switch (u.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return Colors.orange;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estimatesAsync = ref.watch(fulfillmentEstimatesProvider);

    return estimatesAsync.when(
      loading: () => _mlSkeleton().animate().fadeIn(duration: 300.ms),
      error: (_, __) => _mlUnavailableBox(),
      data: (estimates) {
        if (estimates == null) return _mlUnavailableBox();
        if (estimates.isEmpty) {
          return _AiCard(
            child: Column(children: [
              const _AiCardHeader(
                title: 'Active Request Fulfillment Estimates',
                subtitle: 'XGBoost model · Time-to-fulfill prediction',
              ),
              const SizedBox(height: 20),
              Icon(Icons.check_circle_outline,
                  size: 40, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 8),
              Text('No active requests',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ]),
          );
        }
        return _AiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AiCardHeader(
                title: 'Active Request Fulfillment Estimates',
                subtitle: 'XGBoost model · Time-to-fulfill prediction',
              ),
              const SizedBox(height: 16),
              ...estimates.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final est = item.estimate;
                final category = est?.fulfillmentCategory ?? 'Unknown';
                final catColor =
                    item.error != null ? Colors.grey : _categoryColor(category);
                final urgColor = _urgencyColor(item.urgency);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      // Blood group
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: urgColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: urgColor.withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text(
                            item.bloodGroup,
                            style: TextStyle(
                              color: urgColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(
                                item.urgency.toUpperCase(),
                                style: TextStyle(
                                  color: urgColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '· ${item.unitsNeeded} units',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 11),
                              ),
                            ]),
                            if (est != null)
                              Text(
                                'Est. ${est.estimatedFulfillmentHours.toStringAsFixed(1)}h '
                                '(${est.confidenceLowHours.toStringAsFixed(0)}–${est.confidenceHighHours.toStringAsFixed(0)}h)',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: catColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          item.error != null ? 'N/A' : _shortCategory(category),
                          style: TextStyle(
                            color: catColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.05),
                );
              }),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.06);
      },
    );
  }

  String _shortCategory(String cat) {
    if (cat.toLowerCase().contains('same')) return 'Same Day';
    if (cat.toLowerCase().contains('4-24')) return 'Same Day';
    if (cat.toLowerCase().contains('2-3')) return '2-3 Days';
    if (cat.toLowerCase().contains('extended')) return '3+ Days';
    return cat.length > 10 ? cat.substring(0, 10) : cat;
  }
}
