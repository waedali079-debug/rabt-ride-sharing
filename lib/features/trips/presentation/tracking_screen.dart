import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rabt/core/services/tracking_service.dart';
import 'package:rabt/core/services/auth_service.dart';
import 'package:rabt/features/sectors/domain/sector_model.dart';

class TrackingScreen extends StatefulWidget {
  final String tripId;
  final Sector sector;

  const TrackingScreen({Key? key, required this.tripId, required this.sector})
      : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  late TrackingService _trackingService;
  LatLng? _driverLocation;
  String _currentStatus = 'accepted';

  @override
  void initState() {
    super.initState();

    final authService = AuthService();
    final token = authService.token ?? '';

    _trackingService = TrackingService(
      tripId: widget.tripId,
      onLocationUpdate: (lat, lng) {
        setState(() {
          _driverLocation = LatLng(lat, lng);
        });
        _mapController.move(LatLng(lat, lng), 15.0);
      },
      onStatusUpdate: (status) {
        setState(() {
          _currentStatus = status;
        });
        if (status == 'completed' || status == 'cancelled') {
          if (mounted) Navigator.pop(context);
        }
      },
    );

    _trackingService.connect(token);
  }

  @override
  void dispose() {
    _trackingService.disconnect();
    super.dispose();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'السائق في الطريق إليك';
      case 'arrived':
        return 'السائق وصل إلى موقعك';
      case 'in_progress':
        return 'أنت الآن في الرحلة';
      case 'completed':
        return 'اكتملت الرحلة';
      case 'cancelled':
        return 'تم إلغاء الرحلة';
      default:
        return 'جاري المعالجة...';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.directions_car;
      case 'arrived':
        return Icons.location_on;
      case 'in_progress':
        return Icons.linear_scale;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.hourglass_top;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الرحلة'),
        backgroundColor: widget.sector.color,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _driverLocation ??
                  const LatLng(24.7136, 46.6753),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rabt.app',
              ),
              if (_driverLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _driverLocation!,
                      width: 50.0,
                      height: 50.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.sector.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.sector.color.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 28.0,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      spreadRadius: 2),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.sector.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(_currentStatus),
                          color: widget.sector.color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(_currentStatus),
                          style: TextStyle(
                            color: widget.sector.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionCircle(
                        icon: Icons.phone,
                        label: 'اتصال',
                        color: widget.sector.color,
                        onTap: () {},
                      ),
                      _ActionCircle(
                        icon: Icons.chat_bubble_outline,
                        label: 'رسالة',
                        color: widget.sector.color,
                        onTap: () {},
                      ),
                      _ActionCircle(
                        icon: Icons.sos,
                        label: 'طوارئ',
                        color: Colors.red,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_currentStatus == 'accepted' ||
                      _currentStatus == 'arrived')
                    TextButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('إلغاء الرحلة'),
                            content: const Text('هل أنت متأكد من إلغاء الرحلة؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('لا'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('نعم',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          _trackingService.cancelTrip();
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text('إلغاء الرحلة',
                          style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCircle({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
