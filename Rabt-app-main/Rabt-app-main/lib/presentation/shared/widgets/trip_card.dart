import 'package:flutter/material.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/constants/icons.dart';
import '../../../core/utils/formatters.dart';

enum TripStatus {
  searching,
  accepted,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case TripStatus.searching:
        return 'جاري البحث';
      case TripStatus.accepted:
        return 'تم القبول';
      case TripStatus.inProgress:
        return 'قيد التنفيذ';
      case TripStatus.completed:
        return 'مكتملة';
      case TripStatus.cancelled:
        return 'ملغية';
    }
  }
}

class TripCard extends StatelessWidget {
  final String tripId;
  final String sectorId;
  final String pickupAddress;
  final String dropoffAddress;
  final double? price;
  final TripStatus status;
  final DateTime createdAt;
  final VoidCallback? onTap;

  const TripCard({
    super.key,
    required this.tripId,
    required this.sectorId,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.price,
    required this.status,
    required this.createdAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectorColor = Color(RabtDesignConstants.sectorColors[sectorId] ?? RabtDesignConstants.primaryLight);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RabtDesignConstants.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: sectorColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#$tripId',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RabtDesignConstants.spaceMd),

              // Pickup
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: sectorColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pickupAddress,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RabtDesignConstants.spaceSm),

              // Dropoff
              Row(
                children: [
                  Icon(Icons.flag, size: 16, color: sectorColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dropoffAddress,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RabtDesignConstants.spaceMd),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.formatDate(createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  if (price != null)
                    Text(
                      Formatters.formatCurrency(price!),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case TripStatus.searching:
        return const Color(RabtDesignConstants.warningLight);
      case TripStatus.accepted:
        return const Color(RabtDesignConstants.primaryLight);
      case TripStatus.inProgress:
        return const Color(RabtDesignConstants.accessibleLight);
      case TripStatus.completed:
        return const Color(RabtDesignConstants.successLight);
      case TripStatus.cancelled:
        return const Color(RabtDesignConstants.dangerLight);
    }
  }
}
