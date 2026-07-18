import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity> login(String phone, String password);
  Future<UserEntity> register(String fullName, String phone, String password);
  Future<UserEntity> verifyOtp(String phone, String otp);
  Future<UserEntity> getProfile();
  Future<UserEntity> updateProfile(UserEntity user);
  Future<void> logout();
}
