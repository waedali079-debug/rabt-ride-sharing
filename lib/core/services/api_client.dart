import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  String? _authToken;
  static const String _tokenKey = 'auth_token';
  static const String _baseUrlKey = 'api_base_url';

  // Default base URL (emulator)
  static const String _defaultBaseUrl = 'http://10.0.2.2:8080/api';

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor for logging and error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token to every request
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        if (kDebugMode) {
          print('API Request: ${options.method} ${options.path}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('API Response: ${response.statusCode}');
        }
        handler.next(response);
      },
      onError: (e, handler) {
        if (kDebugMode) {
          print('API Error: ${e.response?.statusCode} - ${e.response?.data}');
        }
        handler.next(e);
      },
    ));
  }

  // Initialize with custom base URL
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  // Set auth token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  // Get auth token
  String? get authToken => _authToken;

  // Save token to persistent storage
  Future<void> saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Load token from persistent storage
  Future<bool> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    return _authToken != null;
  }

  // Clear token
  Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Generic GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  // Generic POST request
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  // Generic PUT request
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  // Generic DELETE request
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  // Check if user is authenticated
  bool get isAuthenticated => _authToken != null;

  // Handle API errors
  String handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response?.data;
        if (data is Map && data.containsKey('error')) {
          return data['error'];
        }
        return 'Server error: ${error.response?.statusCode}';
      } else if (error.type == DioExceptionType.connectionTimeout) {
        return 'Connection timeout. Please check your internet.';
      } else if (error.type == DioExceptionType.receiveTimeout) {
        return 'Receive timeout. Server is slow.';
      } else {
        return 'Network error. Please check your connection.';
      }
    }
    return 'An unexpected error occurred.';
  }
}
