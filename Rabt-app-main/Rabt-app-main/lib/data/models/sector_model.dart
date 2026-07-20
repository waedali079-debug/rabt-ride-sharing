import 'dart:convert';
import '../../domain/entities/sector_entity.dart';
import '../../core/constants/icons.dart';

class SectorModel {
  final int id;
  final String sectorId;
  final String name;
  final String description;
  final bool isActive;
  final double searchRadiusM;

  SectorModel({
    required this.id,
    required this.sectorId,
    required this.name,
    required this.description,
    required this.isActive,
    required this.searchRadiusM,
  });

  factory SectorModel.fromJson(Map<String, dynamic> json) {
    // Support both Backend API format (name_ar/sector_code) and legacy format (name/sector_id)
    final name = json['name_ar'] as String? ?? json['name'] as String? ?? '';
    final sectorId = json['sector_code'] as String? ?? json['sector_id'] as String? ?? '';
    final isActive = json['is_operational'] as bool? ?? json['is_active'] as bool? ?? true;
    
    return SectorModel(
      id: json['id'] as int? ?? 0,
      sectorId: sectorId,
      name: name,
      description: json['name_en'] as String? ?? json['description'] as String? ?? '',
      isActive: isActive,
      searchRadiusM: (json['search_radius_m'] as num?)?.toDouble() ?? 10000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sector_code': sectorId,
      'name_ar': name,
      'name_en': description,
      'is_operational': isActive,
      'search_radius_m': searchRadiusM,
    };
  }

  String get iconPath {
    const iconMap = {
      'S-01': RabtIcons.passenger,
      'S-02': RabtIcons.gas,
      'S-03': RabtIcons.water,
      'S-04': RabtIcons.cargo,
      'S-05': RabtIcons.trucks,
      'S-06': RabtIcons.wrecker,
      'S-07': RabtIcons.heavy,
      'S-08': RabtIcons.large,
      'S-09': RabtIcons.special,
    };
    return iconMap[sectorId] ?? RabtIcons.passenger;
  }

  SectorEntity toEntity() {
    return SectorEntity(
      id: id,
      sectorId: sectorId,
      name: name,
      description: description,
      iconPath: iconPath,
      isActive: isActive,
      searchRadiusM: searchRadiusM,
    );
  }
}
