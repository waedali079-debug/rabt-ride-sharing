import 'package:flutter/foundation.dart';
import '../../../data/models/trip_model.dart';
import '../../../data/datasources/api_service.dart';
import '../../../core/constants/api_config.dart';
import '../../../domain/entities/trip_entity.dart';

/// TripProvider handles trip lifecycle: list, create, accept, complete, cancel, rate.
class TripProvider with ChangeNotifier {
  final ApiService _api;
  List<TripEntity> _trips = [];
  TripEntity? _currentTrip;
  bool _isLoading = false;
  String? _error;

  TripProvider(this._api);

  List<TripEntity> get trips => _trips;
  TripEntity? get currentTrip => _currentTrip;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch trips from API.
  Future<void> fetchTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getList(ApiConfig.trips);
      _trips = data.map((json) {
        return TripModel.fromJson(json as Map<String, dynamic>).toEntity();
      }).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'فشل جلب الرحلات';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch a single trip by ID.
  Future<TripEntity?> fetchTripById(String id) async {
    try {
      final data = await _api.get(ApiConfig.tripById(id));
      final trip = TripModel.fromJson(data).toEntity();
      _currentTrip = trip;
      notifyListeners();
      return trip;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'فشل جلب الرحلة';
      notifyListeners();
      return null;
    }
  }

  /// Create a new trip (customer only).
  Future<Map<String, dynamic>?> createTrip({
    required int sectorId,
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(ApiConfig.trips, body: {
        'sector_id': sectorId,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
      });

      _isLoading = false;
      notifyListeners();
      return response;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'فشل إنشاء الرحلة';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Accept a trip (driver only).
  Future<bool> acceptTrip(String tripId) async {
    try {
      await _api.post(ApiConfig.tripAccept(tripId));
      await fetchTripById(tripId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'فشل قبول الرحلة';
      notifyListeners();
      return false;
    }
  }

  /// Complete a trip (driver only).
  Future<bool> completeTrip(String tripId) async {
    try {
      await _api.post(ApiConfig.tripComplete(tripId));
      await fetchTripById(tripId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'فشل إكمال الرحلة';
      notifyListeners();
      return false;
    }
  }

  /// Cancel a trip (customer or driver).
  Future<bool> cancelTrip(String tripId) async {
    try {
      await _api.post(ApiConfig.tripCancel(tripId));
      _currentTrip = null;
      await fetchTrips();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'فشل إلغاء الرحلة';
      notifyListeners();
      return false;
    }
  }

  /// Rate a completed trip (customer only).
  Future<bool> rateTrip(String tripId, {required int rating, String? review}) async {
    try {
      await _api.post(ApiConfig.tripRate(tripId), body: {
        'rating': rating,
        if (review != null) 'review': review,
      });
      await fetchTripById(tripId);
      await fetchTrips();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'فشل إرسال التقييم';
      notifyListeners();
      return false;
    }
  }

  void setCurrentTrip(TripEntity? trip) {
    _currentTrip = trip;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
