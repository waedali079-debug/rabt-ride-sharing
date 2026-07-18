import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';

class TripRemoteDataSource {
  final http.Client _client;
  String? _token;

  TripRemoteDataSource(this._client);

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<String> _get(String endpoint) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return response.body;
    }
    throw Exception('GET $endpoint failed: ${response.statusCode}');
  }

  Future<String> _post(String endpoint, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    }
    throw Exception('POST $endpoint failed: ${response.statusCode}');
  }

  Future<String> getTrips() => _get(ApiConfig.trips);

  Future<String> getTripById(String id) => _get(ApiConfig.tripById(id));

  Future<String> createTrip(Map<String, dynamic> tripData) =>
      _post(ApiConfig.trips, tripData);

  Future<String> acceptTrip(String tripId) =>
      _post(ApiConfig.tripAccept(tripId), {});

  Future<String> completeTrip(String tripId) =>
      _post(ApiConfig.tripComplete(tripId), {});
}
