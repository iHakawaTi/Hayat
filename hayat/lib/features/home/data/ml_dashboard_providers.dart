// lib/features/home/data/ml_dashboard_providers.dart
// Riverpod providers that run ML API calls for the AI Insights section.
// All calls are independent — they resolve in parallel.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ml_service.dart';
import 'dashboard_service.dart';

// ─────────────────────────────────────────────────────────────
// Singleton MlService — reads base URL from env / compile-time var
// ─────────────────────────────────────────────────────────────

final mlServiceProvider = Provider<MlService>((ref) => MlService());

// ─────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────

class ScoredDonor {
  final Map<String, dynamic> raw;
  final DonorScoreResult score;

  const ScoredDonor({required this.raw, required this.score});

  String get fullName => raw['full_name'] as String? ?? 'Unknown';
  String get bloodGroup => raw['blood_group'] as String? ?? '?';
  int get daysSince => (raw['days_since_last_donation'] as num?)?.toInt() ?? 0;
}

class RequestWithEstimate {
  final Map<String, dynamic> request;
  final FulfillmentTimeResult? estimate;
  final String? error;

  const RequestWithEstimate({
    required this.request,
    this.estimate,
    this.error,
  });

  String get bloodGroup => request['blood_group'] as String? ?? '?';
  String get urgency => request['urgency'] as String? ?? 'Medium';
  int get unitsNeeded => (request['units_needed'] as num?)?.toInt() ?? 1;
}

// ─────────────────────────────────────────────────────────────
// Provider 1: Demand Forecast
// ─────────────────────────────────────────────────────────────

final demandForecastProvider = FutureProvider<List<DemandForecastDay>?>((ref) async {
  // Get the most requested blood group from Supabase
  // We use ref.watch on the stream provider — pull value when available
  String mostRequested = 'O+';
  try {
    final summaryAsync = ref.watch(requestsSummaryProvider);
    summaryAsync.whenData((s) => mostRequested = s.mostRequestedBloodGroup);
  } catch (_) {
    // fallback
  }

  final ml = ref.read(mlServiceProvider);
  try {
    final now = DateTime.now();
    final result = await ml.predictDemand(
      bloodGroup: mostRequested,
      hospitalId: 'HOS001',
      dayOfWeekToday: now.weekday - 1,
      month: now.month,
      weekOfYear: _weekOfYear(now),
    );
    return result.forecast;
  } catch (_) {
    return null; // ML unavailable — widget will show fallback
  }
});

// ─────────────────────────────────────────────────────────────
// Provider 2: Top Scored Donors
// ─────────────────────────────────────────────────────────────

final topScoredDonorsProvider = FutureProvider<List<ScoredDonor>?>((ref) async {
  final donors = await ref.watch(topAvailableDonorsProvider.future);
  if (donors.isEmpty) return [];

  final ml = ref.read(mlServiceProvider);
  try {
    // Build batch request
    final cityMap = {
      'Amman': 0, 'Zarqa': 1, 'Irbid': 2, 'Aqaba': 3,
      'Madaba': 4, 'Jerash': 5, 'Other': 6,
    };
    final bgMap = {
      'O+': 0, 'A+': 1, 'B+': 2, 'AB+': 3,
      'O-': 4, 'A-': 5, 'B-': 6, 'AB-': 7,
    };

    final scored = <ScoredDonor>[];
    // Score in parallel using Future.wait
    final futures = donors.map((d) async {
      try {
        final city = d['city'] as String? ?? 'Other';
        final bg = d['blood_group'] as String? ?? 'O+';
        final result = await ml.scoreDonor(
          donorId: d['id']?.toString(),
          totalDonations: (d['total_donations'] as num?)?.toInt() ?? 0,
          daysSinceLastDonation: (d['days_since_last_donation'] as num?)?.toDouble() ?? 120,
          monthsSinceFirstDonation: (d['months_since_first_donation'] as num?)?.toInt() ?? 0,
          avgResponseTimeHours: (d['avg_response_time_hours'] as num?)?.toDouble() ?? 4.0,
          age: (d['age'] as num?)?.toInt() ?? 30,
          bmi: (d['bmi'] as num?)?.toDouble() ?? 24.0,
          city: cityMap.containsKey(city) ? city : 'Other',
          bloodGroup: bgMap.containsKey(bg) ? bg : 'O+',
          gender: d['gender'] as String? ?? 'Male',
        );
        return ScoredDonor(raw: d, score: result);
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(futures);
    for (final r in results) {
      if (r != null) scored.add(r);
    }

    // Sort by probability desc, return top 3
    scored.sort((a, b) => b.score.showRateProbability.compareTo(a.score.showRateProbability));
    return scored.take(3).toList();
  } catch (_) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────
// Provider 3: Fulfillment Estimates for Top Active Requests
// ─────────────────────────────────────────────────────────────

final fulfillmentEstimatesProvider = FutureProvider<List<RequestWithEstimate>?>((ref) async {
  final summary = await ref.watch(requestsSummaryProvider.future);
  final requests = summary.activeRequests;
  if (requests.isEmpty) return [];

  final ml = ref.read(mlServiceProvider);
  final now = DateTime.now();

  try {
    final futures = requests.map((req) async {
      try {
        final estimate = await ml.estimateFulfillmentTime(
          requestId: req['id']?.toString(),
          urgency: _normalizeUrgency(req['urgency'] as String? ?? 'Medium'),
          bloodGroup: _normalizeBloodGroup(req['blood_group'] as String? ?? 'O+'),
          unitsNeeded: (req['units_needed'] as num?)?.toInt() ?? 1,
          hourOfDay: now.hour,
          dayOfWeek: now.weekday - 1,
          month: now.month,
          isWeekend: now.weekday >= 6,
        );
        return RequestWithEstimate(request: req, estimate: estimate);
      } catch (e) {
        return RequestWithEstimate(request: req, error: e.toString());
      }
    });

    return await Future.wait(futures);
  } catch (_) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

int _weekOfYear(DateTime date) {
  final startOfYear = DateTime(date.year, 1, 1);
  final diff = date.difference(startOfYear).inDays;
  return (diff / 7).ceil() + 1;
}

String _normalizeUrgency(String raw) {
  final lower = raw.toLowerCase();
  if (lower == 'critical') return 'Critical';
  if (lower == 'high' || lower == 'urgent') return 'High';
  if (lower == 'low') return 'Low';
  return 'Medium';
}

String _normalizeBloodGroup(String raw) {
  const valid = ['O+', 'A+', 'B+', 'AB+', 'O-', 'A-', 'B-', 'AB-'];
  return valid.contains(raw) ? raw : 'O+';
}
