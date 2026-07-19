import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:rabt/core/services/api_client.dart';
import 'package:rabt/core/services/auth_service.dart';

class TripService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  /// جلب المسار الدقيق (Polyline) من خادم GraphHopper
  Future<List<LatLng>> fetchRoute({
    required LatLng pickup,
    required LatLng dropoff,
    required String sectorCode,
  }) async {
    try {
      final response = await _apiClient.post(
        '/v1/routing/trip-route',
        data: {
          'pickup': {'lat': pickup.latitude, 'lng': pickup.longitude},
          'dropoff': {'lat': dropoff.latitude, 'lng': dropoff.longitude},
          'sectorCode': sectorCode,
        },
      );

      if (response.statusCode == 200 && response.data['points'] != null) {
        final List<dynamic> points = response.data['points'];
        return points.map<LatLng>((p) => LatLng(p['lat'], p['lng'])).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// جلب المسار مع تقدير التكلفة
  Future<Map<String, dynamic>?> fetchRouteWithFare({
    required LatLng pickup,
    required LatLng dropoff,
    required String sectorCode,
  }) async {
    try {
      final response = await _apiClient.post(
        '/v1/routing/trip-route',
        data: {
          'pickup': {'lat': pickup.latitude, 'lng': pickup.longitude},
          'dropoff': {'lat': dropoff.latitude, 'lng': dropoff.longitude},
          'sectorCode': sectorCode,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// طلب رحلة جديدة
  Future<Map<String, dynamic>> requestTrip({
    required String sectorId,
    required double pickupLat,
    required double pickupLng,
  }) async {
    try {
      final response = await _apiClient.post(
        '/v1/trips/request',
        data: {
          'sectorId': sectorId,
          'pickupLat': pickupLat,
          'pickupLng': pickupLng,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'trip_id': response.data['trip_id']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'لا يوجد سائقين متاحين'};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في طلب الرحلة'};
    }
  }

  /// جلب رحلاتي
  Future<List<Map<String, dynamic>>> getMyTrips() async {
    try {
      final response = await _apiClient.get('/v1/trips');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// إلغاء رحلة
  Future<Map<String, dynamic>> cancelTrip(String tripId) async {
    try {
      final response = await _apiClient.post(
        '/v1/trips/$tripId/cancel',
        data: {},
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'حدث خطأ في إلغاء الرحلة'};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في إلغاء الرحلة'};
    }
  }
}
