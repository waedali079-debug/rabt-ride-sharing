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
    return SectorModel(
      id: json['id'] as int,
      sectorId: json['sector_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      searchRadiusM: (json['search_radius_m'] as num?)?.toDouble() ?? 10000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sector_id': sectorId,
      'name': name,
      'description': description,
      'is_active': isActive,
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
