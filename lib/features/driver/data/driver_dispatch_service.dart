import 'dart:async';
import 'package:rabt/core/services/api_client.dart';

class DriverDispatchService {
  final ApiClient _apiClient = ApiClient();
  Timer? _pollingTimer;
  bool _isPolling = false;

  final StreamController<Map<String, dynamic>> _tripController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get tripStream => _tripController.stream;

  bool get isPolling => _isPolling;

  void startListening() {
    _pollingTimer?.cancel();
    _isPolling = true;
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkForTrips();
    });
  }

  Future<void> _checkForTrips() async {
    try {
      final response = await _apiClient.get('/v1/trips/dispatch');

      if (response.statusCode == 200 && response.data['has_trip'] == true) {
        final tripData = response.data['trip'];
        _tripController.add(tripData);
        _pollingTimer?.cancel();
        _isPolling = false;
      }
    } catch (_) {
      // Ignore transient network errors during polling
    }
  }

  void stopListening() {
    _pollingTimer?.cancel();
    _isPolling = false;
  }

  void dispose() {
    stopListening();
    _tripController.close();
  }
}
