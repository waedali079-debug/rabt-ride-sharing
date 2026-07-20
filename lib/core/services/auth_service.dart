import 'package:rabt/core/services/api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  
  // User data cache
  Map<String, dynamic>? _userData;

  // Get current user data
  Map<String, dynamic>? get currentUser => _userData;

  // Check if user is authenticated
  bool get isAuthenticated => _apiClient.isAuthenticated;

  // Get auth token
  String? get token => _apiClient.authToken;

  // Initialize - load saved token
  Future<void> init() async {
    await _apiClient.loadToken();
    if (_apiClient.isAuthenticated) {
      await _fetchUserProfile();
    }
  }

  // Send OTP
  Future<void> sendOtp(String phoneNumber) async {
    try {
      await _apiClient.post('/v1/auth/send-otp', data: {'phone': phoneNumber});
    } catch (e) {
      throw Exception(_apiClient.handleError(e));
    }
  }

  // Verify OTP and login
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await _apiClient.post('/v1/auth/verify-otp', data: {
        'phone': phoneNumber,
        'otp': otp,
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final userData = response.data['user'];
        
        // Save token
        await _apiClient.saveToken(token);
        
        // Cache user data
        _userData = userData;
        
        return true;
      }
      return false;
    } catch (e) {
      throw Exception(_apiClient.handleError(e));
    }
  }

  // Fetch user profile
  Future<void> _fetchUserProfile() async {
    try {
      final response = await _apiClient.get('/v1/user/profile');
      if (response.statusCode == 200) {
        _userData = response.data;
      }
    } catch (e) {
      // If token is invalid, logout
      if (e.toString().contains('403') || e.toString().contains('401')) {
        await signOut();
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _apiClient.clearToken();
    _userData = null;
  }

  // Update user profile
  Future<bool> updateProfile({String? fullName}) async {
    try {
      final response = await _apiClient.put('/v1/user/profile', data: {
        if (fullName != null) 'full_name': fullName,
      });

      if (response.statusCode == 200) {
        _userData = response.data;
        return true;
      }
      return false;
    } catch (e) {
      throw Exception(_apiClient.handleError(e));
    }
  }
}
