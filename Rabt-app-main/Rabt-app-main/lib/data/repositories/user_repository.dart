import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/constants/api_config.dart';
import '../datasources/local_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final http.Client _client;
  final LocalDataSource _localDataSource;

  UserRepositoryImpl(this._client, this._localDataSource);

  @override
  Future<UserEntity> login(String phone, String password) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final userModel = UserModel.fromJson(json['data'] as Map<String, dynamic>);
      if (userModel.token != null) {
        await _localDataSource.saveToken(userModel.token!);
        await _localDataSource.saveUserData(json['data'] as Map<String, dynamic>);
      }
      return userModel.toEntity();
    }
    throw Exception('Login failed: ${response.statusCode}');
  }

  @override
  Future<UserEntity> register(String fullName, String phone, String password) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'phone': phone,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      final userModel = UserModel.fromJson(json['data'] as Map<String, dynamic>);
      if (userModel.token != null) {
        await _localDataSource.saveToken(userModel.token!);
        await _localDataSource.saveUserData(json['data'] as Map<String, dynamic>);
      }
      return userModel.toEntity();
    }
    throw Exception('Register failed: ${response.statusCode}');
  }

  @override
  Future<UserEntity> verifyOtp(String phone, String otp) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserModel.fromJson(json['data'] as Map<String, dynamic>).toEntity();
    }
    throw Exception('OTP verification failed');
  }

  @override
  Future<UserEntity> getProfile() async {
    final token = await _localDataSource.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserModel.fromJson(json['data'] as Map<String, dynamic>).toEntity();
    }
    throw Exception('Failed to get profile');
  }

  @override
  Future<UserEntity> updateProfile(UserEntity user) async {
    // TODO: implement when endpoint is ready
    throw UnimplementedError('Update profile not yet implemented');
  }

  @override
  Future<void> logout() async {
    await _localDataSource.clearAll();
  }
}
