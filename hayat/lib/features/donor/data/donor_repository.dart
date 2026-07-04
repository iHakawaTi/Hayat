import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'donor_model.dart';

final donorRepositoryProvider = Provider<DonorRepository>((ref) {
  return DonorRepository(Supabase.instance.client);
});

final donorProfileProvider = FutureProvider.family<Donor?, String>((ref, userId) {
  return ref.read(donorRepositoryProvider).getDonorProfile(userId);
});

class DonorRepository {
  final SupabaseClient _supabase;

  DonorRepository(this._supabase);

  Future<Donor?> getDonorProfile(String userId) async {
    try {
      final response = await _supabase
          .from('donors')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Donor.fromJson(response);
    } catch (e) {
      // Handle error or rethrow
      return null;
    }
  }

  Future<void> createDonorProfile(Donor donor) async {
    await _supabase.from('donors').upsert(donor.toJson());
  }

  Future<void> updateDonorField(String userId, String field, dynamic value) async {
    await _supabase.from('donors').update({field: value}).eq('id', userId);
  }
}
