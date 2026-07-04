// lib/features/home/data/dashboard_service.dart
// All Supabase queries for the dashboard — no UI logic here.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────

class DonorStats {
  final int total;
  final int available;
  final Map<String, int> byBloodGroup;
  final double avgDaysSinceLastDonation;

  const DonorStats({
    required this.total,
    required this.available,
    required this.byBloodGroup,
    required this.avgDaysSinceLastDonation,
  });
}

class RequestsSummary {
  final int totalActive;
  final Map<String, int> byUrgency;
  final int totalUnitsNeeded;
  final int totalUnitsCollected;
  final String mostRequestedBloodGroup;
  final List<Map<String, dynamic>> activeRequests;

  const RequestsSummary({
    required this.totalActive,
    required this.byUrgency,
    required this.totalUnitsNeeded,
    required this.totalUnitsCollected,
    required this.mostRequestedBloodGroup,
    required this.activeRequests,
  });
}

class BloodBankStock {
  final int total;
  final Map<String, int> byStockStatus;
  final List<String> cities;

  const BloodBankStock({
    required this.total,
    required this.byStockStatus,
    required this.cities,
  });
}

class DonationSubmission {
  final String id;
  final String? donorName;
  final String? bankCode;
  final String status;
  final DateTime createdAt;

  const DonationSubmission({
    required this.id,
    this.donorName,
    this.bankCode,
    required this.status,
    required this.createdAt,
  });

  factory DonationSubmission.fromJson(Map<String, dynamic> j) =>
      DonationSubmission(
        id: j['id']?.toString() ?? '',
        donorName: j['donors']?['full_name'] as String? ?? j['donor_name'] as String?,
        bankCode: j['bank_code'] as String? ?? j['blood_banks']?['bank_code'] as String?,
        status: j['status'] as String? ?? 'Pending',
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class HospitalOverview {
  final int total;
  final Map<String, int> byCity;
  final double avgMonthlyRequests;

  const HospitalOverview({
    required this.total,
    required this.byCity,
    required this.avgMonthlyRequests,
  });
}

// ─────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(Supabase.instance.client);
});

class DashboardService {
  final SupabaseClient _db;
  DashboardService(this._db);

  // ── 1. Donor Stats ──────────────────────────────────────────
  Future<DonorStats> getDonorStats() async {
    final rows = await _db.from('donors').select(
      'blood_group, availability, days_since_last_donation',
    );

    final total = rows.length;
    final available = rows.where((r) => (r['availability'] as String?)?.toLowerCase() == 'yes').length;

    final Map<String, int> byBloodGroup = {};
    double sumDays = 0;
    int dayCount = 0;
    for (final r in rows) {
      final bg = r['blood_group'] as String? ?? 'Unknown';
      byBloodGroup[bg] = (byBloodGroup[bg] ?? 0) + 1;
      final d = (r['days_since_last_donation'] as num?)?.toDouble();
      if (d != null) { sumDays += d; dayCount++; }
    }

    return DonorStats(
      total: total,
      available: available,
      byBloodGroup: byBloodGroup,
      avgDaysSinceLastDonation: dayCount > 0 ? sumDays / dayCount : 0,
    );
  }

  // ── 2. Blood Requests Summary (one-time) ───────────────────
  Future<RequestsSummary> getRequestsSummary() async {
    final rows = await _db
        .from('blood_requests')
        .select('blood_group, urgency, units_needed, units_collected, status')
        .or('status.eq.Active,status.eq.Pending,status.eq.active,status.eq.pending');

    final activeRows = rows;
    final Map<String, int> byUrgency = {};
    final Map<String, int> bgCount = {};
    int totalUnitsNeeded = 0, totalUnitsCollected = 0;

    for (final r in activeRows) {
      final urg = r['urgency'] as String? ?? 'Normal';
      byUrgency[urg] = (byUrgency[urg] ?? 0) + 1;
      final bg = r['blood_group'] as String? ?? 'Unknown';
      bgCount[bg] = (bgCount[bg] ?? 0) + 1;
      totalUnitsNeeded += (r['units_needed'] as num?)?.toInt() ?? 0;
      totalUnitsCollected += (r['units_collected'] as num?)?.toInt() ?? 0;
    }

    final mostRequested = bgCount.isEmpty
        ? 'N/A'
        : bgCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // Also fetch top 3 active for ML fulfillment card
    final top3 = await _db
        .from('blood_requests')
        .select('id, blood_group, urgency, units_needed, status')
        .or('status.eq.Active,status.eq.active')
        .order('urgency', ascending: false)
        .limit(3);

    return RequestsSummary(
      totalActive: activeRows.length,
      byUrgency: byUrgency,
      totalUnitsNeeded: totalUnitsNeeded,
      totalUnitsCollected: totalUnitsCollected,
      mostRequestedBloodGroup: mostRequested,
      activeRequests: List<Map<String, dynamic>>.from(top3),
    );
  }

  // ── 3. Blood Bank Stock ────────────────────────────────────
  Future<BloodBankStock> getBloodBankStock() async {
    final rows = await _db.from('blood_banks').select('city, stock_status');

    final Map<String, int> byStatus = {};
    final Set<String> cities = {};
    for (final r in rows) {
      final s = r['stock_status'] as String? ?? 'Unknown';
      byStatus[s] = (byStatus[s] ?? 0) + 1;
      final city = r['city'] as String?;
      if (city != null) cities.add(city);
    }

    return BloodBankStock(
      total: rows.length,
      byStockStatus: byStatus,
      cities: cities.toList()..sort(),
    );
  }

  // ── 4. Recent Donation Submissions ─────────────────────────
  Future<List<DonationSubmission>> getRecentSubmissions() async {
    try {
      final rows = await _db
          .from('donation_submissions')
          .select('id, status, created_at, bank_code, donor_name')
          .order('created_at', ascending: false)
          .limit(5);
      return (rows as List).map((r) => DonationSubmission.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {
      // Table may not have all columns — graceful fallback
      return [];
    }
  }

  // ── 5. Hospital Overview ───────────────────────────────────
  Future<HospitalOverview> getHospitalOverview() async {
    final rows = await _db.from('hospitals').select('city, avg_monthly_blood_requests');

    final Map<String, int> byCity = {};
    double sumRequests = 0;
    int reqCount = 0;
    for (final r in rows) {
      final city = r['city'] as String? ?? 'Unknown';
      byCity[city] = (byCity[city] ?? 0) + 1;
      final avg = (r['avg_monthly_blood_requests'] as num?)?.toDouble();
      if (avg != null) { sumRequests += avg; reqCount++; }
    }

    return HospitalOverview(
      total: rows.length,
      byCity: byCity,
      avgMonthlyRequests: reqCount > 0 ? sumRequests / reqCount : 0,
    );
  }

  // ── Real-time stream for blood_requests ───────────────────
  Stream<RequestsSummary> watchRequestsSummary() {
    return _db
        .from('blood_requests')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final Map<String, int> byUrgency = {};
          final Map<String, int> bgCount = {};
          int needed = 0, collected = 0;
          final active = rows.where((r) {
            final s = (r['status'] as String?)?.toLowerCase() ?? '';
            return s == 'active' || s == 'pending';
          }).toList();

          for (final r in active) {
            final urg = r['urgency'] as String? ?? 'Normal';
            byUrgency[urg] = (byUrgency[urg] ?? 0) + 1;
            final bg = r['blood_group'] as String? ?? 'Unknown';
            bgCount[bg] = (bgCount[bg] ?? 0) + 1;
            needed += (r['units_needed'] as num?)?.toInt() ?? 0;
            collected += (r['units_collected'] as num?)?.toInt() ?? 0;
          }

          final mostRequested = bgCount.isEmpty
              ? 'N/A'
              : bgCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

          return RequestsSummary(
            totalActive: active.length,
            byUrgency: byUrgency,
            totalUnitsNeeded: needed,
            totalUnitsCollected: collected,
            mostRequestedBloodGroup: mostRequested,
            activeRequests: List<Map<String, dynamic>>.from(active.take(3)),
          );
        });
  }

  // ── Top available donors for ML scoring ──────────────────
  Future<List<Map<String, dynamic>>> getTopAvailableDonors({int limit = 10}) async {
    final rows = await _db
        .from('donors')
        .select(
          'id, full_name, blood_group, age, city, gender, bmi, '
          'total_donations, days_since_last_donation, '
          'months_since_first_donation, avg_response_time_hours, availability',
        )
        .or('availability.eq.Yes,availability.eq.yes')
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }
}

// ─────────────────────────────────────────────────────────────
// RIVERPOD PROVIDERS
// ─────────────────────────────────────────────────────────────

final donorStatsProvider = FutureProvider<DonorStats>((ref) {
  return ref.read(dashboardServiceProvider).getDonorStats();
});

final requestsSummaryProvider = StreamProvider<RequestsSummary>((ref) {
  return ref.read(dashboardServiceProvider).watchRequestsSummary();
});

final bloodBankStockProvider = FutureProvider<BloodBankStock>((ref) {
  return ref.read(dashboardServiceProvider).getBloodBankStock();
});

final recentSubmissionsProvider = FutureProvider<List<DonationSubmission>>((ref) {
  return ref.read(dashboardServiceProvider).getRecentSubmissions();
});

final hospitalOverviewProvider = FutureProvider<HospitalOverview>((ref) {
  return ref.read(dashboardServiceProvider).getHospitalOverview();
});

final topAvailableDonorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(dashboardServiceProvider).getTopAvailableDonors();
});
