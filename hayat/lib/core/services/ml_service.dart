// lib/core/services/ml_service.dart
// Hayat ML API Client
// Connects to the blood_donation_ml FastAPI backend.
//
// Base URL: http://localhost:8001 (dev) or your deployed URL (prod)
// Set ML_API_BASE_URL in your .env file.

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base URL for the ML API. Override in production via environment.
const String _kMlBaseUrl =
    String.fromEnvironment('ML_API_BASE_URL', defaultValue: 'http://localhost:8001');

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

/// One day in the 7-day demand forecast.
class DemandForecastDay {
  final int dayOffset;
  final double predictedUnits;
  final int predictedUnitsRounded;

  DemandForecastDay({
    required this.dayOffset,
    required this.predictedUnits,
    required this.predictedUnitsRounded,
  });

  factory DemandForecastDay.fromJson(Map<String, dynamic> j) => DemandForecastDay(
        dayOffset: j['day_offset'] as int,
        predictedUnits: (j['predicted_units'] as num).toDouble(),
        predictedUnitsRounded: j['predicted_units_rounded'] as int,
      );
}

/// 7-day demand forecast result.
class DemandForecastResult {
  final String bloodGroup;
  final String hospitalId;
  final List<DemandForecastDay> forecast;
  final int totalPredictedUnits7d;

  DemandForecastResult({
    required this.bloodGroup,
    required this.hospitalId,
    required this.forecast,
    required this.totalPredictedUnits7d,
  });

  factory DemandForecastResult.fromJson(Map<String, dynamic> j) =>
      DemandForecastResult(
        bloodGroup: j['blood_group'] as String,
        hospitalId: j['hospital_id'] as String,
        forecast: (j['forecast'] as List)
            .map((d) => DemandForecastDay.fromJson(d as Map<String, dynamic>))
            .toList(),
        totalPredictedUnits7d: j['total_predicted_units_7d'] as int,
      );
}

/// Donor engagement / show-rate score result.
class DonorScoreResult {
  final String? donorId;
  final double showRateProbability;
  final String reliabilityTier; // Low | Medium | High
  final bool isReliable;
  final String recommendation;

  DonorScoreResult({
    this.donorId,
    required this.showRateProbability,
    required this.reliabilityTier,
    required this.isReliable,
    required this.recommendation,
  });

  factory DonorScoreResult.fromJson(Map<String, dynamic> j) => DonorScoreResult(
        donorId: j['donor_id'] as String?,
        showRateProbability: (j['show_rate_probability'] as num).toDouble(),
        reliabilityTier: j['reliability_tier'] as String,
        isReliable: j['is_reliable'] as bool,
        recommendation: j['recommendation'] as String,
      );
}

/// Blood request fulfillment time estimate.
class FulfillmentTimeResult {
  final String? requestId;
  final double estimatedFulfillmentHours;
  final double confidenceLowHours;
  final double confidenceHighHours;
  final String fulfillmentCategory;
  final String urgencyNote;

  FulfillmentTimeResult({
    this.requestId,
    required this.estimatedFulfillmentHours,
    required this.confidenceLowHours,
    required this.confidenceHighHours,
    required this.fulfillmentCategory,
    required this.urgencyNote,
  });

  factory FulfillmentTimeResult.fromJson(Map<String, dynamic> j) =>
      FulfillmentTimeResult(
        requestId: j['request_id'] as String?,
        estimatedFulfillmentHours:
            (j['estimated_fulfillment_hours'] as num).toDouble(),
        confidenceLowHours: (j['confidence_low_hours'] as num).toDouble(),
        confidenceHighHours: (j['confidence_high_hours'] as num).toDouble(),
        fulfillmentCategory: j['fulfillment_category'] as String,
        urgencyNote: j['urgency_note'] as String,
      );
}

// ---------------------------------------------------------------------------
// SERVICE
// ---------------------------------------------------------------------------

class MlApiException implements Exception {
  final int statusCode;
  final String message;
  MlApiException(this.statusCode, this.message);

  @override
  String toString() => 'MlApiException($statusCode): $message';
}

class MlService {
  final String baseUrl;
  final http.Client _client;

  MlService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _kMlBaseUrl,
        _client = client ?? http.Client();

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw MlApiException(
        response.statusCode,
        data['detail']?.toString() ?? 'Unknown error',
      );
    }
    return data;
  }

  // -------------------------------------------------------------------------
  // Model 1: Demand Forecasting
  // -------------------------------------------------------------------------

  /// Predict blood unit demand for the next 7 days.
  ///
  /// [bloodGroup]        - e.g. "O+", "AB-"
  /// [hospitalId]        - e.g. "HOS001"
  /// [last7DaysUnits]    - units requested each of last 7 days
  /// [dayOfWeekToday]    - 0=Mon … 6=Sun
  /// [month]             - 1–12
  /// [weekOfYear]        - 1–53
  Future<DemandForecastResult> predictDemand({
    required String bloodGroup,
    required String hospitalId,
    List<double> last7DaysUnits = const [10, 12, 8, 15, 11, 9, 13],
    int dayOfWeekToday = 0,
    int month = 5,
    int weekOfYear = 18,
    double avgUrgencyScore = 1.5,
  }) async {
    final data = await _post('/predict/demand', {
      'blood_group': bloodGroup,
      'hospital_id': hospitalId,
      'last_7_days_units': last7DaysUnits,
      'day_of_week_today': dayOfWeekToday,
      'month': month,
      'week_of_year': weekOfYear,
      'avg_urgency_score': avgUrgencyScore,
    });
    return DemandForecastResult.fromJson(data);
  }

  // -------------------------------------------------------------------------
  // Model 2: Donor Show-Rate Scoring
  // -------------------------------------------------------------------------

  /// Score a donor's likelihood to respond/show up when contacted.
  ///
  /// Returns a probability (0–1) and reliability tier.
  Future<DonorScoreResult> scoreDonor({
    String? donorId,
    required int totalDonations,
    required double daysSinceLastDonation,
    required int monthsSinceFirstDonation,
    required double avgResponseTimeHours,
    required int age,
    double bmi = 24.0,
    String city = 'Amman',
    required String bloodGroup,
    String gender = 'Male',
  }) async {
    final data = await _post('/predict/donor-score', {
      if (donorId != null) 'donor_id': donorId,
      'total_donations': totalDonations,
      'days_since_last_donation': daysSinceLastDonation,
      'months_since_first_donation': monthsSinceFirstDonation,
      'avg_response_time_hours': avgResponseTimeHours,
      'age': age,
      'bmi': bmi,
      'city': city,
      'blood_group': bloodGroup,
      'gender': gender,
    });
    return DonorScoreResult.fromJson(data);
  }

  // -------------------------------------------------------------------------
  // Model 3: Fulfillment Time Estimation
  // -------------------------------------------------------------------------

  /// Estimate how long a blood request will take to fulfill.
  ///
  /// [urgency]    - "Low" | "Medium" | "High" | "Critical"
  /// [stockLevel] - "Low" | "Medium" | "High"
  Future<FulfillmentTimeResult> estimateFulfillmentTime({
    String? requestId,
    required String urgency,
    required String bloodGroup,
    required int unitsNeeded,
    String stockLevel = 'Medium',
    int hourOfDay = 12,
    int dayOfWeek = 0,
    int month = 5,
    bool isWeekend = false,
    bool isHoliday = false,
  }) async {
    final now = DateTime.now();
    final data = await _post('/predict/fulfillment-time', {
      if (requestId != null) 'request_id': requestId,
      'urgency': urgency,
      'blood_group': bloodGroup,
      'units_needed': unitsNeeded,
      'stock_level': stockLevel,
      'hour_of_day': hourOfDay,
      'day_of_week': dayOfWeek,
      'month': month,
      'is_weekend': isWeekend ? 1 : 0,
      'is_holiday': isHoliday ? 1 : 0,
    });
    return FulfillmentTimeResult.fromJson(data);
  }

  // -------------------------------------------------------------------------
  // Health Check
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>> healthCheck() async {
    final uri = Uri.parse('$baseUrl/health');
    final response = await _client.get(uri);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void dispose() => _client.close();
}
