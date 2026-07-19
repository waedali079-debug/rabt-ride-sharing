import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:rabt/core/services/api_client.dart';

class TripService {
  final ApiClient _api = ApiClient();

  /// Fetch route + fare from server (GraphHopper via backend)
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

  /// Request a trip — server calculates fare, returns trip data
  Future<Map<String, dynamic>> requestTrip({
    required String sectorId,
    required double pickupLat,
    required double pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    double? distanceKm,
  }) async {
    try {
      final body = <String, dynamic>{
        'sectorId': sectorId,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
      };
      if (dropoffLat != null) body['dropoffLat'] = dropoffLat;
      if (dropoffLng != null) body['dropoffLng'] = dropoffLng;
      if (distanceKm != null) body['distance_km'] = distanceKm;

      final response = await _api.post('/v1/trips/request', data: body);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'trip_id': response.data['trip_id'],
          'driver_id': response.data['driver_id'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'خطأ غير معروف',
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالخادم'};
    }
  }

  /// Get points list from route response as LatLng
  List<LatLng> parseRoutePoints(Map<String, dynamic> routeData) {
    if (routeData['points'] == null) return [];
    final List<dynamic> points = routeData['points'];
    return points
        .map<LatLng>((p) => LatLng(p['lat'] as double, p['lng'] as double))
        .toList();
  }
}
