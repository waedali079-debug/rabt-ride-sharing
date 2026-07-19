import 'package:supabase_flutter/supabase_flutter.dart';

class TripService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> requestTrip({
    required String sectorId,
    required double pickupLat,
    required double pickupLng,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'يجب تسجيل الدخول أولاً'};
      }

      final response = await _client.from('rabt_trips').insert({
        'customer_id': user.id,
        'sector_id': sectorId,
        'pickup_location': 'POINT($pickupLng $pickupLat)',
        'status': 'requested',
      }).select().single();

      return {'success': true, 'trip_id': response['id']};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في طلب الرحلة: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getMyTrips() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('rabt_trips')
          .select()
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> cancelTrip(String tripId) async {
    try {
      await _client
          .from('rabt_trips')
          .update({'status': 'cancelled'})
          .eq('id', tripId);

      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في إلغاء الرحلة'};
    }
  }
}
