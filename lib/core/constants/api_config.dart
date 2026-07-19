class ApiConfig {
  static const String baseUrl = 'https://rabt-api-server.onrender.com/api';

  // Auth
  static const String sendOtp = '/v1/auth/send-otp';
  static const String verifyOtp = '/v1/auth/verify-otp';
  static const String userProfile = '/v1/user/profile';

  // Sectors
  static const String sectors = '/v1/sectors';

  // Trips
  static const String tripRoute = '/v1/routing/trip-route';
  static const String trips = '/v1/trips';
  static const String requestTrip = '/v1/trips/request';

  // Payments
  static const String payments = '/v1/payments';

  // Health
  static const String health = '/health';
}
