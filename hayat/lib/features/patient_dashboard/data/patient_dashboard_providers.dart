// lib/features/patient_dashboard/data/patient_dashboard_providers.dart
// Riverpod providers for the Patient ML Dashboard.
// Fetches the *current user's* profile and enriches it with ML predictions.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/ml_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../home/data/ml_dashboard_providers.dart';
import '../../home/data/dashboard_service.dart';

// ─────────────────────────────────────────────────────────────
// 1. Current User's Donor Profile (from Supabase)
// ─────────────────────────────────────────────────────────────

final myDonorProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) return null;

  try {
    final row = await Supabase.instance.client
        .from('donors')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return row;
  } catch (_) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────
// 2. My Donor Score (ML prediction)
// ─────────────────────────────────────────────────────────────

final myDonorScoreProvider =
    FutureProvider<DonorScoreResult?>((ref) async {
  final profile = await ref.watch(myDonorProfileProvider.future);
  if (profile == null) return null;

  final ml = ref.read(mlServiceProvider);

  const validCities = [
    'Amman', 'Zarqa', 'Irbid', 'Aqaba', 'Madaba', 'Jerash'
  ];
  const validBg = ['O+', 'A+', 'B+', 'AB+', 'O-', 'A-', 'B-', 'AB-'];

  final city = profile['city'] as String? ?? 'Amman';
  final bg = profile['blood_group'] as String? ?? 'O+';

  try {
    return await ml.scoreDonor(
      donorId: profile['id']?.toString(),
      totalDonations: (profile['total_donations'] as num?)?.toInt() ?? 0,
      daysSinceLastDonation:
          (profile['days_since_last_donation'] as num?)?.toDouble() ?? 120,
      monthsSinceFirstDonation:
          (profile['months_since_first_donation'] as num?)?.toInt() ?? 0,
      avgResponseTimeHours:
          (profile['avg_response_time_hours'] as num?)?.toDouble() ?? 4.0,
      age: (profile['age'] as num?)?.toInt() ?? 30,
      bmi: (profile['bmi'] as num?)?.toDouble() ?? 24.0,
      city: validCities.contains(city) ? city : 'Other',
      bloodGroup: validBg.contains(bg) ? bg : 'O+',
      gender: profile['gender'] as String? ?? 'Male',
    );
  } catch (_) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────
// 3. My Active Request + Fulfillment Estimate
// ─────────────────────────────────────────────────────────────

class MyRequestWithEstimate {
  final Map<String, dynamic> request;
  final FulfillmentTimeResult? estimate;

  const MyRequestWithEstimate({required this.request, this.estimate});

  String get bloodGroup => request['blood_group'] as String? ?? '?';
  String get urgency => request['urgency'] as String? ?? 'Medium';
  int get unitsNeeded => (request['units_needed'] as num?)?.toInt() ?? 1;
  String get status => request['status'] as String? ?? 'Pending';
}

final myActiveRequestProvider =
    FutureProvider<MyRequestWithEstimate?>((ref) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null) return null;

  try {
    // Try to find the user's active request
    final rows = await Supabase.instance.client
        .from('blood_requests')
        .select('id, blood_group, urgency, units_needed, units_collected, status, created_at')
        .eq('requester_id', user.id)
        .or('status.eq.Active,status.eq.Pending,status.eq.active,status.eq.pending')
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;

    final req = rows.first as Map<String, dynamic>;
    final ml = ref.read(mlServiceProvider);
    final now = DateTime.now();

    final validUrgency = ['Low', 'Medium', 'High', 'Critical'];
    final rawUrg = req['urgency'] as String? ?? 'Medium';
    final normalizedUrg = validUrgency.contains(rawUrg) ? rawUrg : 'Medium';

    try {
      final estimate = await ml.estimateFulfillmentTime(
        requestId: req['id']?.toString(),
        urgency: normalizedUrg,
        bloodGroup: req['blood_group'] as String? ?? 'O+',
        unitsNeeded: (req['units_needed'] as num?)?.toInt() ?? 1,
        hourOfDay: now.hour,
        dayOfWeek: now.weekday - 1,
        month: now.month,
        isWeekend: now.weekday >= 6,
      );
      return MyRequestWithEstimate(request: req, estimate: estimate);
    } catch (_) {
      return MyRequestWithEstimate(request: req);
    }
  } catch (_) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────
// 4. Demand Forecast for My Blood Type
// ─────────────────────────────────────────────────────────────

final myBloodTypeDemandProvider =
    FutureProvider<DemandForecastResult?>((ref) async {
  final profile = await ref.watch(myDonorProfileProvider.future);
  final bloodGroup = profile?['blood_group'] as String? ?? 'O+';

  final ml = ref.read(mlServiceProvider);
  final now = DateTime.now();

  try {
    return await ml.predictDemand(
      bloodGroup: bloodGroup,
      hospitalId: 'HOS001',
      dayOfWeekToday: now.weekday - 1,
      month: now.month,
      weekOfYear: _weekOfYear(now),
    );
  } catch (_) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────

int _weekOfYear(DateTime date) {
  final startOfYear = DateTime(date.year, 1, 1);
  final diff = date.difference(startOfYear).inDays;
  return (diff / 7).ceil() + 1;
}
