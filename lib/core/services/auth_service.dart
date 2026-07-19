import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> sendOtp(String phoneNumber) async {
    await _client.auth.signInWithOtp(phone: phoneNumber);
  }

  Future<Session?> verifyOtp(String phoneNumber, String token) async {
    final response = await _client.auth.verifyOTP(
      phone: phoneNumber,
      token: token,
      type: OtpType.sms,
    );
    return response.session;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authState => _client.auth.onAuthStateChange;
}
