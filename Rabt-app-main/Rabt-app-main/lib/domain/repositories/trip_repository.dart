import '../entities/trip_entity.dart';

abstract class TripRepository {
  Future<List<TripEntity>> getTrips();
  Future<TripEntity> getTripById(String id);
  Future<TripEntity> createTrip(TripEntity trip);
  Future<TripEntity> acceptTrip(String tripId);
  Future<TripEntity> completeTrip(String tripId);
  Future<void> cancelTrip(String tripId);
}
