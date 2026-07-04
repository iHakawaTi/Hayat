import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BloodRequest {
  final String id;
  final String bloodGroup;
  final int unitsNeeded;
  final String urgency; // 'critical', 'urgent', 'standard'
  final String status;
  final String? hospitalName;
  final DateTime createdAt;

  BloodRequest({
    required this.id,
    required this.bloodGroup,
    required this.unitsNeeded,
    required this.urgency,
    required this.status,
    this.hospitalName,
    required this.createdAt,
  });

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'] as String,
      bloodGroup: json['blood_group'] as String,
      unitsNeeded: json['units_needed'] as int,
      urgency: json['urgency'] as String,
      status: json['status'] as String,
      hospitalName: json['hospitals']?['name'] as String?, // Flattened join
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepository(Supabase.instance.client);
});

class RequestRepository {
  final SupabaseClient _supabase;

  RequestRepository(this._supabase);

  Future<List<BloodRequest>> getUrgentRequests() async {
    final response = await _supabase
        .from('blood_requests')
        .select('*, hospitals(name)')
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return (response as List).map((json) => BloodRequest.fromJson(json)).toList();
  }
}
