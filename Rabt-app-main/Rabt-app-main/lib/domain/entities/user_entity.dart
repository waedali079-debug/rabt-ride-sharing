enum UserRole {
  customer,
  driver,
  sectorAdmin,
  systemAdmin;

  static UserRole fromString(String role) {
    switch (role) {
      case 'CUSTOMER':
        return UserRole.customer;
      case 'DRIVER':
        return UserRole.driver;
      case 'SECTOR_ADMIN':
        return UserRole.sectorAdmin;
      case 'SYSTEM_ADMIN':
        return UserRole.systemAdmin;
      default:
        return UserRole.customer;
    }
  }
}

class UserEntity {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final UserRole role;
  final int? sectorId;
  final String? profileImage;
  final double? rating;
  final int? tripCount;
  final bool isActive;
  final DateTime createdAt;

  UserEntity({
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
  });

  UserEntity copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    UserRole? role,
    int? sectorId,
    String? profileImage,
    double? rating,
    int? tripCount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      sectorId: sectorId ?? this.sectorId,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      tripCount: tripCount ?? this.tripCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
