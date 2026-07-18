import 'package:flutter/material.dart';
import '../../../../shared/widgets/trip_card.dart';
import '../../../../core/constants/design_constants.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('سجل الرحلات', style: theme.textTheme.headlineMedium),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
        child: ListView(
          children: [
            TripCard(
              tripId: 'TRIP-001',
              sectorId: 'S-01',
              pickupAddress: 'حي السلام، عمان',
              dropoffAddress: 'حي النخيل، عمان',
              price: 45.00,
              status: TripStatus.completed,
              createdAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
            const SizedBox(height: RabtDesignConstants.spaceMd),
            TripCard(
              tripId: 'TRIP-002',
              sectorId: 'S-02',
              pickupAddress: 'شارع الملك عبدالله',
              dropoffAddress: 'وسط البلد',
              price: 32.50,
              status: TripStatus.completed,
              createdAt: DateTime.now().subtract(const Duration(days: 3)),
            ),
          ],
        ),
      ),
    );
  }
}
