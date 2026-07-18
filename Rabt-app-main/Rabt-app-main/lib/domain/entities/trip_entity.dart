enum TripStatus {
  searching,
  accepted,
  inProgress,
  completed,
  cancelled;

  static TripStatus fromString(String status) {
    switch (status) {
      case 'searching':
        return TripStatus.searching;
      case 'accepted':
        return TripStatus.accepted;
      case 'in_progress':
        return TripStatus.inProgress;
      case 'completed':
        return TripStatus.completed;
      case 'cancelled':
        return TripStatus.cancelled;
      default:
        return TripStatus.searching;
    }
  }

  String get value {
    switch (this) {
      case TripStatus.searching:
        return 'searching';
      case TripStatus.accepted:
        return 'accepted';
      case TripStatus.inProgress:
        return 'in_progress';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.cancelled:
        return 'cancelled';
    }
  }
}

class TripEntity {
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
  final TripStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  TripEntity({
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

  TripEntity copyWith({
    String? id,
    String? customerId,
    String? driverId,
    String? sectorId,
    String? pickupAddress,
    String? dropoffAddress,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    double? price,
    TripStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TripEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      sectorId: sectorId ?? this.sectorId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
