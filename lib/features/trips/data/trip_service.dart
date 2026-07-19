import 'package:dio/dio.dart';
import 'package:rabt/core/services/api_client.dart';

class TripService {
  final ApiClient _api = ApiClient();

  /// Calculate route between two points via Render API (middleware)
  /// Returns the best route with distance, duration, polyline, and fare estimate
  Future<Map<String, dynamic>?> fetchRouteWithFare({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required String sectorCode,
  }) async {
    try {
      final response = await _api.post(
        '/v1/routing/trip-route',
        data: {
          'pickup': {'lat': fromLat, 'lng': fromLng},
          'dropoff': {'lat': toLat, 'lng': toLng},
          'sector_code': sectorCode,
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

  /// Request a trip via Render API
  Future<Map<String, dynamic>> requestTrip({
    required String sectorId,
    required double pickupLat,
    required double pickupLng,
  }) async {
    try {
      final response = await _api.post(
        '/v1/trips/request',
        data: {
          'sectorId': sectorId,
          'pickupLat': pickupLat,
          'pickupLng': pickupLng,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return {'success': false, 'message': 'خطأ غير معروف'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالخادم'};
    }
  }
}
