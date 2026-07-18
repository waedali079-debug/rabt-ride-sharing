import 'dart:convert';
import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_remote_datasource.dart';
import '../models/trip_model.dart';

class TripRepositoryImpl implements TripRepository {
  final TripRemoteDataSource _remoteDataSource;

  TripRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<TripEntity>> getTrips() async {
    final response = await _remoteDataSource.getTrips();
    final List<dynamic> jsonList = jsonDecode(response)['data'] as List<dynamic>;
    return jsonList
        .map((json) => TripModel.fromJson(json as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<TripEntity> getTripById(String id) async {
    final response = await _remoteDataSource.getTripById(id);
    final json = jsonDecode(response)['data'] as Map<String, dynamic>;
    return TripModel.fromJson(json).toEntity();
  }

  @override
  Future<TripEntity> createTrip(TripEntity trip) async {
    final tripData = TripModel.fromEntity(trip).toJson();
    final response = await _remoteDataSource.createTrip(tripData);
    final json = jsonDecode(response)['data'] as Map<String, dynamic>;
    return TripModel.fromJson(json).toEntity();
  }

  @override
  Future<TripEntity> acceptTrip(String tripId) async {
    final response = await _remoteDataSource.acceptTrip(tripId);
    final json = jsonDecode(response)['data'] as Map<String, dynamic>;
    return TripModel.fromJson(json).toEntity();
  }

  @override
  Future<TripEntity> completeTrip(String tripId) async {
    final response = await _remoteDataSource.completeTrip(tripId);
    final json = jsonDecode(response)['data'] as Map<String, dynamic>;
    return TripModel.fromJson(json).toEntity();
  }

  @override
  Future<void> cancelTrip(String tripId) async {
    throw UnimplementedError('Cancel trip not yet implemented');
  }
}
