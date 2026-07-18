import '../entities/sector_entity.dart';

abstract class SectorRepository {
  Future<List<SectorEntity>> getSectors();
  Future<SectorEntity> getSectorById(String sectorId);
}
