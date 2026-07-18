import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/rabt_button.dart';
import '../../../../shared/widgets/trip_card.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../../shared/providers/trip_provider.dart';
import '../../../../shared/providers/sector_provider.dart';
import 'sectors_hub_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    // Load data on first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().fetchTrips();
      context.read<SectorProvider>().fetchSectors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTab == 0 ? 'الرئيسية' :
          _currentTab == 1 ? 'الخدمات' :
          _currentTab == 2 ? 'الإشعارات' : 'حسابي',
          style: theme.textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildServicesTab();
      case 2:
        return _buildNotificationsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Padding(
      padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // زر طلب رحلة سريع
          SizedBox(
            width: double.infinity,
            height: 120,
            child: Card(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/sectors-hub'),
                borderRadius: BorderRadius.circular(RabtDesignConstants.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: RabtDesignConstants.spaceLg),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلب خدمة نقل',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اختر الخدمة التي تناسبك',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: RabtDesignConstants.spaceLg),

          // رحلاتي الأخيرة
          Text(
            'رحلاتي الأخيرة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: RabtDesignConstants.spaceMd),

          Expanded(
            child: Consumer<TripProvider>(
              builder: (context, provider, _) {
                if (provider.trips.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد رحلات بعد',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.trips.length,
                  itemBuilder: (context, index) {
                    final trip = provider.trips[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: RabtDesignConstants.spaceMd),
                      child: TripCard(
                        tripId: trip.id,
                        sectorId: trip.sectorId,
                        pickupAddress: trip.pickupAddress,
                        dropoffAddress: trip.dropoffAddress,
                        price: trip.price,
                        status: TripStatus.values.firstWhere(
                          (s) => s.name == trip.status.name,
                          orElse: () => TripStatus.completed,
                        ),
                        createdAt: trip.createdAt,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return const SectorsHubScreen();
  }

  Widget _buildNotificationsTab() {
    return Center(
      child: Text(
        'لا توجد إشعارات',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildProfileTab() {
    return const ProfileScreen();
  }
}
