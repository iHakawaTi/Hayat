// lib/features/home/presentation/widgets/dashboard_widgets.dart
// All reusable dashboard card widgets: Supabase data + shared skeleton.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/dashboard_service.dart';

// ═══════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════════

/// Glass-morphism card wrapper used by all dashboard cards.
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  const _GlassCard({required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Section header (title + optional icon).
class DashSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;

  const DashSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.primaryRed;
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ]);
  }
}

/// Loading skeleton shimmer block.
Widget _shimmerBox({double height = 20, double? width, double radius = 8}) =>
    Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
          duration: 1200.ms,
          color: Colors.white.withOpacity(0.12),
        );

Widget _skeletonCard() => _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(height: 18, width: 160),
          const SizedBox(height: 16),
          _shimmerBox(height: 40, width: 100, radius: 12),
          const SizedBox(height: 12),
          _shimmerBox(height: 14),
          const SizedBox(height: 8),
          _shimmerBox(height: 14, width: 200),
        ],
      ),
    );

Widget _errorCard(String msg, VoidCallback onRetry) => _GlassCard(
      borderColor: Colors.red.withOpacity(0.3),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 36),
          const SizedBox(height: 8),
          Text(msg,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryRed),
          ),
        ],
      ),
    );

/// A small colored pill badge.
Widget _badge(String text, Color bg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: bg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

/// A stat block: big number + label.
Widget _statBlock(String value, String label, {Color? valueColor}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 11)),
      ],
    );

// ═══════════════════════════════════════════════════════════════
// 1. DONOR STATS CARD
// ═══════════════════════════════════════════════════════════════

class DonorStatsCard extends StatelessWidget {
  final AsyncValue<DonorStats> data;
  final VoidCallback onRetry;

  const DonorStatsCard({super.key, required this.data, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return data.when(
      loading: () => _skeletonCard()
          .animate()
          .fadeIn(duration: 300.ms),
      error: (e, _) => _errorCard('Could not load donor stats', onRetry),
      data: (stats) => _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashSectionHeader(
              title: 'Donor Statistics',
              icon: Icons.people_alt_outlined,
            ),
            const SizedBox(height: 20),
            // Top stats row
            Row(children: [
              Expanded(child: _statBlock('${stats.total}', 'Total Donors')),
              Expanded(
                child: _statBlock(
                  '${stats.available}',
                  'Available Now',
                  valueColor: const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _statBlock(
                  '${stats.avgDaysSinceLastDonation.toStringAsFixed(0)}d',
                  'Avg Since Last',
                  valueColor: Colors.amber,
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Text('By Blood Group',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.byBloodGroup.entries.map((e) {
                final isCommon = e.key == 'O+' || e.key == 'A+';
                return _badge(
                  '${e.key}  ${e.value}',
                  isCommon ? AppTheme.primaryRed : Colors.blueAccent,
                );
              }).toList(),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2. BLOOD REQUESTS SUMMARY CARD (StreamBuilder via Riverpod)
// ═══════════════════════════════════════════════════════════════

class BloodRequestsSummaryCard extends StatelessWidget {
  final AsyncValue<RequestsSummary> data;
  final VoidCallback onRetry;

  const BloodRequestsSummaryCard(
      {super.key, required this.data, required this.onRetry});

  Color _urgencyColor(String u) {
    switch (u.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
      case 'urgent':
        return Colors.orange;
      case 'low':
        return const Color(0xFF10B981);
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return data.when(
      loading: () => _skeletonCard(),
      error: (e, _) => _errorCard('Could not load blood requests', onRetry),
      data: (summary) => _GlassCard(
        borderColor: AppTheme.primaryRed.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const DashSectionHeader(
                  title: 'Blood Requests',
                  icon: Icons.bloodtype,
                ),
                const Spacer(),
                // Live indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat()).scaleXY(
                      end: 1.4,
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(width: 6),
                Text('Live',
                    style: TextStyle(
                        color: const Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: _statBlock(
                  '${summary.totalActive}',
                  'Active Requests',
                  valueColor: AppTheme.primaryRed,
                ),
              ),
              Expanded(
                child: _statBlock(
                  summary.mostRequestedBloodGroup,
                  'Most Needed',
                  valueColor: Colors.amber,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // Units progress bar
            if (summary.totalUnitsNeeded > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Units Progress',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  Text(
                    '${summary.totalUnitsCollected}/${summary.totalUnitsNeeded}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (summary.totalUnitsNeeded > 0)
                      ? (summary.totalUnitsCollected / summary.totalUnitsNeeded)
                          .clamp(0.0, 1.0)
                      : 0,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFF10B981)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (summary.byUrgency.isNotEmpty) ...[
              Text('By Urgency',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: summary.byUrgency.entries.map((e) {
                  return _badge(
                    '${e.key}  ${e.value}',
                    _urgencyColor(e.key),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. BLOOD BANK STOCK CARD
// ═══════════════════════════════════════════════════════════════

class BloodBankStockCard extends StatelessWidget {
  final AsyncValue<BloodBankStock> data;
  final VoidCallback onRetry;

  const BloodBankStockCard(
      {super.key, required this.data, required this.onRetry});

  Color _stockColor(String s) {
    switch (s.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'low':
        return Colors.orange;
      case 'adequate':
      case 'high':
        return const Color(0xFF10B981);
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return data.when(
      loading: () => _skeletonCard(),
      error: (e, _) => _errorCard('Could not load blood bank data', onRetry),
      data: (stock) => _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashSectionHeader(
              title: 'Blood Bank Stock',
              icon: Icons.local_hospital_outlined,
              iconColor: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: _statBlock(
                  '${stock.total}',
                  'Blood Banks',
                  valueColor: Colors.blueAccent,
                ),
              ),
              Expanded(
                child: _statBlock(
                  '${stock.cities.length}',
                  'Cities Covered',
                ),
              ),
            ]),
            const SizedBox(height: 16),
            if (stock.byStockStatus.isNotEmpty) ...[
              Text('Stock Status',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: stock.byStockStatus.entries.map((e) {
                  return _badge('${e.key}  ${e.value}', _stockColor(e.key));
                }).toList(),
              ),
            ],
            if (stock.cities.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Cities',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(
                stock.cities.join(' · '),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 4. RECENT DONATION SUBMISSIONS LIST
// ═══════════════════════════════════════════════════════════════

class RecentSubmissionsCard extends StatelessWidget {
  final AsyncValue<List<DonationSubmission>> data;
  final VoidCallback onRetry;

  const RecentSubmissionsCard(
      {super.key, required this.data, required this.onRetry});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return data.when(
      loading: () => _skeletonCard(),
      error: (e, _) => _errorCard('Could not load submissions', onRetry),
      data: (submissions) {
        if (submissions.isEmpty) {
          return _GlassCard(
            child: Column(
              children: [
                const DashSectionHeader(
                  title: 'Recent Submissions',
                  icon: Icons.history_outlined,
                  iconColor: Colors.purple,
                ),
                const SizedBox(height: 24),
                Icon(Icons.inbox_outlined,
                    size: 48, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 12),
                Text('No submissions yet',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 13)),
              ],
            ),
          );
        }
        return _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashSectionHeader(
                title: 'Recent Submissions',
                icon: Icons.history_outlined,
                iconColor: Colors.purple,
              ),
              const SizedBox(height: 16),
              ...submissions.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                final color = _statusColor(s.status);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withOpacity(0.5)),
                        ),
                        child: Icon(
                          s.status.toLowerCase() == 'approved'
                              ? Icons.check
                              : s.status.toLowerCase() == 'rejected'
                                  ? Icons.close
                                  : Icons.hourglass_top,
                          color: color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.donorName ?? 'Donor',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${s.bankCode ?? 'Bank'}  ·  ${_formatDate(s.createdAt)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _badge(s.status, color),
                    ],
                  ),
                ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.04);
              }),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
      },
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ═══════════════════════════════════════════════════════════════
// 5. HOSPITAL OVERVIEW CARD
// ═══════════════════════════════════════════════════════════════

class HospitalOverviewCard extends StatelessWidget {
  final AsyncValue<HospitalOverview> data;
  final VoidCallback onRetry;

  const HospitalOverviewCard(
      {super.key, required this.data, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return data.when(
      loading: () => _skeletonCard(),
      error: (e, _) => _errorCard('Could not load hospital data', onRetry),
      data: (overview) => _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashSectionHeader(
              title: 'Hospital Network',
              icon: Icons.local_hospital,
              iconColor: Color(0xFF10B981),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: _statBlock(
                  '${overview.total}',
                  'Hospitals',
                  valueColor: const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _statBlock(
                  overview.avgMonthlyRequests.toStringAsFixed(0),
                  'Avg Monthly Requests',
                ),
              ),
            ]),
            if (overview.byCity.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('By City',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: overview.byCity.entries.map((e) {
                  return _badge('${e.key}  ${e.value}', Colors.teal);
                }).toList(),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
    );
  }
}
