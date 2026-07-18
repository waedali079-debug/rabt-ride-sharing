import '../entities/sector_entity.dart';
import '../repositories/sector_repository.dart';

class GetSectorsUseCase {
  final SectorRepository repository;

  GetSectorsUseCase(this.repository);

  Future<List<SectorEntity>> call() async {
    return await repository.getSectors();
  }
}
