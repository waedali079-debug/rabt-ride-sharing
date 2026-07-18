import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class GetTripsUseCase {
  final TripRepository repository;

  GetTripsUseCase(this.repository);

  Future<List<TripEntity>> call() async {
    return await repository.getTrips();
  }
}
