import 'dart:convert';
import '../../domain/entities/trip_entity.dart';

class TripModel {
  final String id;
  final String customerId;
  final String? driverId;
  final String sectorId;
  final String pickupAddress;
  final String dropoffAddress;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final double? price;
  final String status;
  final String createdAt;
  final String? completedAt;

  TripModel({
    required this.id,
    required this.customerId,
    this.driverId,
    required this.sectorId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    this.price,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      driverId: json['driver_id'] as String?,
      sectorId: json['sector_id'] as String,
      pickupAddress: json['pickup_address'] as String,
      dropoffAddress: json['dropoff_address'] as String,
      pickupLat: (json['pickup_lat'] as num).toDouble(),
      pickupLng: (json['pickup_lng'] as num).toDouble(),
      dropoffLat: (json['dropoff_lat'] as num).toDouble(),
      dropoffLng: (json['dropoff_lng'] as num).toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      completedAt: json['completed_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'driver_id': driverId,
      'sector_id': sectorId,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'price': price,
      'status': status,
      'created_at': createdAt,
      'completed_at': completedAt,
    };
  }

  TripEntity toEntity() {
    return TripEntity(
      id: id,
      customerId: customerId,
      driverId: driverId,
      sectorId: sectorId,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      price: price,
      status: TripStatus.fromString(status),
      createdAt: DateTime.parse(createdAt),
      completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
    );
  }

  static TripModel fromEntity(TripEntity entity) {
    return TripModel(
      id: entity.id,
      customerId: entity.customerId,
      driverId: entity.driverId,
      sectorId: entity.sectorId,
      pickupAddress: entity.pickupAddress,
      dropoffAddress: entity.dropoffAddress,
      pickupLat: entity.pickupLat,
      pickupLng: entity.pickupLng,
      dropoffLat: entity.dropoffLat,
      dropoffLng: entity.dropoffLng,
      price: entity.price,
      status: entity.status.value,
      createdAt: entity.createdAt.toIso8601String(),
      completedAt: entity.completedAt?.toIso8601String(),
    );
  }
}
