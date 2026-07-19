import 'package:flutter/material.dart';

class Sector {
  final String code;
  final String nameAr;
  final String nameEn;
  final String colorHex;
  final String iconName;

  Sector({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.colorHex,
    required this.iconName,
  });

  factory Sector.fromMap(Map<String, dynamic> map) {
    return Sector(
      code: map['sector_code'] as String,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      colorHex: map['color_code'] as String,
      iconName: map['icon_name'] as String,
    );
  }

  Color get color => Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  
  IconData get icon => _mapIcon(iconName);
  
  static IconData _mapIcon(String name) {
    switch (name) {
      case 'passenger': return Icons.directions_car;
      case 'gas': return Icons.local_gas_station;
      case 'water': return Icons.water_drop;
      case 'cargo': return Icons.inventory_2;
      case 'trucks': return Icons.local_shipping;
      case 'wrecker': return Icons.car_repair;
      case 'heavy': return Icons.agriculture;
      case 'large': return Icons.all_inbox;
      case 'special': return Icons.miscellaneous_services;
      default: return Icons.category;
    }
  }
}
