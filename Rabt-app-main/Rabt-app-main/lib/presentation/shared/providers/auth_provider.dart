import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user_model.dart';
import '../../../data/datasources/api_service.dart';
import '../../../core/constants/api_config.dart';

/// AuthProvider handles login, registration, profile, and token persistence.
class AuthProvider with ChangeNotifier {
  final ApiService _api;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._api);

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null && _api.token != null;
  String? get error => _error;

  /// Attempt login with phone + password. Saves token on success.
  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(ApiConfig.login, body: {
        'phone': phone,
        'password': password,
      });

      final token = response['token'] as String;
      _api.setToken(token);

      // Save token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      // Fetch full profile
      await _fetchProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'فشل الاتصال بالخادم';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register a new account. Returns success.
  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    required String role,
    int? sectorId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'name': name,
        'phone': phone,
        'password': password,
        'role': role,
      };
      if (sectorId != null) {
        body['sector_id'] = sectorId;
      }

      final response = await _api.post(ApiConfig.register, body: body);

      // Auto-login after registration
      final token = response['token'] as String;
      _api.setToken(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      await _fetchProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'فشل الاتصال بالخادم';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch current user profile from /api/v1/profile
  Future<void> _fetchProfile() async {
    try {
      final data = await _api.get(ApiConfig.profile);
      _currentUser = UserModel(
        id: data['id'] as String,
        fullName: data['name'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        email: null,
        role: data['role'] as String? ?? 'customer',
        sectorId: data['sector_id'] as int?,
        profileImage: null,
        rating: (data['rating'] as num?)?.toDouble(),
        tripCount: data['total_trips'] as int? ?? 0,
        isActive: data['is_active'] as bool? ?? true,
        createdAt: data['created_at'] as String? ?? '',
        token: _api.token,
      );
    } catch (e) {
      // Profile fetch failed but login succeeded — use minimal data
      debugPrint('Profile fetch failed (non-fatal): $e');
    }
  }

  /// Restore session from stored token (app startup).
  Future<bool> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    if (savedToken == null) return false;

    _api.setToken(savedToken);
    try {
      await _fetchProfile();
      notifyListeners();
      return true;
    } catch (_) {
      // Token expired or invalid
      await prefs.remove('auth_token');
      _api.setToken(null);
      return false;
    }
  }

  /// Update profile (name, phone).
  Future<bool> updateProfile({String? name, String? phone}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;

      await _api.put(ApiConfig.profile, body: body);
      await _fetchProfile();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'فشل تحديث الملف الشخصي';
      notifyListeners();
      return false;
    }
  }

  /// Logout — clear token and user data.
  Future<void> logout() async {
    _api.setToken(null);
    _currentUser = null;
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
