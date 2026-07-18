import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class CreateTripUseCase {
  final TripRepository repository;

  CreateTripUseCase(this.repository);

  Future<TripEntity> call(TripEntity trip) async {
    return await repository.createTrip(trip);
  }
}
