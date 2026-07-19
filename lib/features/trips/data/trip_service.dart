import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class TripService {
  final Dio _dio = Dio();

  // GraphHopper direct URL (Codespace - development)
  static const String _graphhopperUrl =
      'https://rabt-graphhopper-9697wg54gpvxhpxv4-8989.app.github.dev';

  // Sector code to vehicle profile mapping
  static const Map<String, String> _profileMap = {
    'S-01': 'car',       // ركاب
    'S-02': 'small_truck', // غاز
    'S-03': 'small_truck', // مياه
    'S-04': 'small_truck', // شحن صغير
    'S-05': 'truck',      // شاحنات
    'S-06': 'truck',      // ونشات
    'S-07': 'truck',      // آليات
    'S-08': 'truck',      // شحن كبير
    'S-09': 'car',        // خدمات خاصة
  };

  // DB fare rates per sector
  static const Map<String, Map<String, double>> _rates = {
    'S-01': {'base': 5, 'perKm': 1.5},
    'S-02': {'base': 7, 'perKm': 2.0},
    'S-03': {'base': 6.5, 'perKm': 1.8},
    'S-04': {'base': 8, 'perKm': 2.2},
    'S-05': {'base': 25, 'perKm': 5.0},
    'S-06': {'base': 30, 'perKm': 6.0},
    'S-07': {'base': 50, 'perKm': 12.0},
    'S-08': {'base': 40, 'perKm': 8.0},
    'S-09': {'base': 15, 'perKm': 3.5},
  };

  /// Fetch route polyline points directly from GraphHopper
  Future<List<LatLng>> fetchRoute({
    required LatLng pickup,
    required LatLng dropoff,
    required String sectorCode,
  }) async {
    try {
      final profile = _profileMap[sectorCode] ?? 'car';
      final response = await _dio.get(
        '$_graphhopperUrl/route',
        queryParameters: {
          'point': [
            '${pickup.latitude},${pickup.longitude}',
            '${dropoff.latitude},${dropoff.longitude}',
          ],
          'profile': profile,
          'points_encoded': false,
          'calc_points': true,
        },
      );

      if (response.statusCode == 200) {
        final paths = response.data['paths'];
        if (paths != null && paths.isNotEmpty) {
          final coords = paths[0]['points']['coordinates'] as List;
          return coords
              .map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch route with distance, duration, fare estimation
  Future<Map<String, dynamic>?> fetchRouteWithFare({
    required LatLng pickup,
    required LatLng dropoff,
    required String sectorCode,
  }) async {
    try {
      final profile = _profileMap[sectorCode] ?? 'car';
      final response = await _dio.get(
        '$_graphhopperUrl/route',
        queryParameters: {
          'point': [
            '${pickup.latitude},${pickup.longitude}',
            '${dropoff.latitude},${dropoff.longitude}',
          ],
          'profile': profile,
          'points_encoded': false,
          'calc_points': true,
        },
      );

      if (response.statusCode == 200) {
        final paths = response.data['paths'];
        if (paths != null && paths.isNotEmpty) {
          final path = paths[0];
          final distanceMeters = path['distance'].toDouble();
          final durationMs = path['time'].toDouble();
          final distanceKm = distanceMeters / 1000.0;
          final durationMinutes = (durationMs / 60000).round();

          // Calculate fare from DB rates
          final rate = _rates[sectorCode] ?? _rates['S-01']!;
          final fare = rate['base']! + (distanceKm * rate['perKm']!);

          // Extract points
          final coords = path['points']['coordinates'] as List;
          final points =
              coords.map((c) => {'lat': c[1], 'lng': c[0]}).toList();

          return {
            'distanceKm': double.parse(distanceKm.toStringAsFixed(2)),
            'durationMinutes': durationMinutes,
            'points': points,
            'fare': {
              'amount': double.parse(fare.toStringAsFixed(3)),
              'currency': 'JOD',
            },
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Request a trip (via Render API)
  Future<Map<String, dynamic>> requestTrip({
    required String sectorId,
    required double pickupLat,
    required double pickupLng,
  }) async {
    // TODO: implement via ApiClient when backend trip endpoints are ready
    return {'success': false, 'message': 'خدمة طلب الرحلات قيد التطوير'};
  }
}
