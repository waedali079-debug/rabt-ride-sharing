import 'dart:convert';
import '../../domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String role;
  final int? sectorId;
  final String? profileImage;
  final double? rating;
  final int? tripCount;
  final bool isActive;
  final String createdAt;
  final String? token;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.role,
    this.sectorId,
    this.profileImage,
    this.rating,
    this.tripCount,
    required this.isActive,
    required this.createdAt,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      sectorId: json['sector_id'] as int?,
      profileImage: json['profile_image'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      tripCount: json['trip_count'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'sector_id': sectorId,
      'profile_image': profileImage,
      'rating': rating,
      'trip_count': tripCount,
      'is_active': isActive,
      'created_at': createdAt,
      'token': token,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      fullName: fullName,
      phone: phone,
      email: email,
      role: UserRole.fromString(role),
      sectorId: sectorId,
      profileImage: profileImage,
      rating: rating,
      tripCount: tripCount,
      isActive: isActive,
      createdAt: DateTime.parse(createdAt),
    );
  }

  static UserModel fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      fullName: entity.fullName,
      phone: entity.phone,
      email: entity.email,
      role: entity.role.name.toUpperCase(),
      sectorId: entity.sectorId,
      profileImage: entity.profileImage,
      rating: entity.rating,
      tripCount: entity.tripCount,
      isActive: entity.isActive,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }
}
