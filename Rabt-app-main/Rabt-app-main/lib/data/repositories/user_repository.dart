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
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['data'] != null) {
          final userModel = UserModel.fromJson(json['data'] as Map<String, dynamic>);
          if (userModel.token != null) {
            await _localDataSource.saveToken(userModel.token!);
            await _localDataSource.saveUserData(json['data'] as Map<String, dynamic>);
          }
          return userModel.toEntity();
        }
        // OTP sent case
        throw Exception(json['message'] ?? 'OTP sent');
      }
      throw Exception('Login failed: ${response.statusCode}');
    } catch (e) {
      if (e.toString().contains('OTP sent')) rethrow;
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<UserEntity> register(String fullName, String phone, String password) async {
    try {
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
        if (json['data'] != null) {
          final userModel = UserModel.fromJson(json['data'] as Map<String, dynamic>);
          if (userModel.token != null) {
            await _localDataSource.saveToken(userModel.token!);
            await _localDataSource.saveUserData(json['data'] as Map<String, dynamic>);
          }
          return userModel.toEntity();
        }
        throw Exception('Registration successful');
      }
      throw Exception('Register failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Register failed: $e');
    }
  }

  @override
  Future<UserEntity> verifyOtp(String phone, String otp) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/users/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'token': otp}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['data'] != null) {
          final userModel = UserModel.fromJson(json['data'] as Map<String, dynamic>);
          if (userModel.token != null) {
            await _localDataSource.saveToken(userModel.token!);
            await _localDataSource.saveUserData(json['data'] as Map<String, dynamic>);
          }
          return userModel.toEntity();
        }
      }
      throw Exception('OTP verification failed');
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  @override
  Future<UserEntity> getProfile() async {
    final token = await _localDataSource.getToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/users/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['data'] != null) {
          return UserModel.fromJson(json['data'] as Map<String, dynamic>).toEntity();
        }
      }
      throw Exception('Failed to get profile');
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
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
