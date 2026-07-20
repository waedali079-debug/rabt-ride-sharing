import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/sector_entity.dart';
import '../../domain/repositories/sector_repository.dart';
import '../../core/constants/api_config.dart';
import '../models/sector_model.dart';

class SectorRepositoryImpl implements SectorRepository {
  final http.Client _client;

  SectorRepositoryImpl(this._client);

  @override
  Future<List<SectorEntity>> getSectors() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sectors}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> sectors = jsonDecode(response.body) as List<dynamic>;
        return sectors
            .map((s) => SectorModel.fromJson(s as Map<String, dynamic>).toEntity())
            .toList();
      }
    } catch (e) {
      print('API Error: $e');
    }
    // Fallback to static sectors if API not available
    return _getStaticSectors();
  }

  @override
  Future<SectorEntity> getSectorById(String sectorId) async {
    final sectors = await getSectors();
    return sectors.firstWhere((s) => s.sectorId == sectorId);
  }

  List<SectorEntity> _getStaticSectors() {
    return [
      SectorEntity(id: 1, sectorId: 'S-01', name: 'ركاب', description: 'سفر آمن ومريح', iconPath: '', isActive: true, searchRadiusM: 8000),
      SectorEntity(id: 2, sectorId: 'S-02', name: 'غاز', description: 'توصيل الغاز بسرعة', iconPath: '', isActive: true, searchRadiusM: 10000),
      SectorEntity(id: 3, sectorId: 'S-03', name: 'مياه', description: 'توصيل المياه النقية', iconPath: '', isActive: true, searchRadiusM: 10000),
      SectorEntity(id: 4, sectorId: 'S-04', name: 'شحن صغير', description: 'طرود صغيرة بدقة', iconPath: '', isActive: true, searchRadiusM: 12000),
      SectorEntity(id: 5, sectorId: 'S-05', name: 'شاحنات', description: 'نقل البضائع الثقيلة', iconPath: '', isActive: true, searchRadiusM: 15000),
      SectorEntity(id: 6, sectorId: 'S-06', name: 'ونشات', description: 'الإنقاذ والمساعدة', iconPath: '', isActive: true, searchRadiusM: 15000),
      SectorEntity(id: 7, sectorId: 'S-07', name: 'آليات ثقيلة', description: 'معدات البناء', iconPath: '', isActive: true, searchRadiusM: 15000),
      SectorEntity(id: 8, sectorId: 'S-08', name: 'شحن كبير', description: 'لوجستيات متكاملة', iconPath: '', isActive: true, searchRadiusM: 20000),
      SectorEntity(id: 9, sectorId: 'S-09', name: 'خدمات خاصة', description: 'حلول مخصصة', iconPath: '', isActive: true, searchRadiusM: 10000),
    ];
  }
}
