import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rabt/features/sectors/domain/sector_model.dart';
import 'package:rabt/features/trips/data/trip_service.dart';
import 'package:rabt/features/trips/presentation/tracking_screen.dart';

class RequestTripScreen extends StatefulWidget {
  final Sector sector;

  const RequestTripScreen({Key? key, required this.sector}) : super(key: key);

  @override
  State<RequestTripScreen> createState() => _RequestTripScreenState();
}

class _RequestTripScreenState extends State<RequestTripScreen> {
  final MapController _mapController = MapController();
  final TripService _tripService = TripService();

  Position? _currentPosition;
  List<LatLng> _routePoints = [];
  Map<String, dynamic>? _routeInfo;
  bool _isLoading = true;
  bool _isFetchingRoute = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('خدمة الموقع غير مفعلة');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      _showError('تم رفض إذن الوصول للموقع');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
      _isLoading = false;
    });

    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    if (_currentPosition == null) return;

    setState(() => _isFetchingRoute = true);

    final pickup = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    // نقطة وسط عمّان كوجهة مؤقتة
    const dropoff = LatLng(31.9539, 35.9106);

    final routeData = await _tripService.fetchRouteWithFare(
      pickup: pickup,
      dropoff: dropoff,
      sectorCode: widget.sector.code,
    );

    if (routeData != null && routeData['points'] != null) {
      final List<dynamic> points = routeData['points'];
      setState(() {
        _routePoints = points.map<LatLng>((p) => LatLng(p['lat'], p['lng'])).toList();
        _routeInfo = routeData;
        _isFetchingRoute = false;
      });

      if (_routePoints.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(_routePoints);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)),
        );
      }
    } else {
      setState(() => _isFetchingRoute = false);
    }
  }

  Future<void> _requestRide() async {
    if (_currentPosition == null) return;

    setState(() => _isRequesting = true);

    final result = await _tripService.requestTrip(
      sectorId: widget.sector.code,
      pickupLat: _currentPosition!.latitude,
      pickupLng: _currentPosition!.longitude,
    );

    setState(() => _isRequesting = false);

    if (result['success'] && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TrackingScreen(
            tripId: result['trip_id'],
            sector: widget.sector,
          ),
        ),
      );
    } else {
      _showError(result['message']);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('طلب: ${widget.sector.nameAr}'),
        backgroundColor: widget.sector.color,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.rabt.app',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5.0,
                            color: widget.sector.color,
                            borderColor: Colors.white,
                            borderStrokeWidth: 1.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          width: 40.0,
                          height: 40.0,
                          child: Icon(
                            Icons.location_on,
                            color: widget.sector.color,
                            size: 40.0,
                          ),
                        ),
                        if (_routePoints.isNotEmpty)
                          Marker(
                            point: _routePoints.last,
                            width: 40.0,
                            height: 40.0,
                            child: const Icon(Icons.flag, color: Colors.red, size: 40.0),
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isFetchingRoute)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: LinearProgressIndicator(),
                          ),
                        if (_routeInfo != null) ...[
                          Text(
                            '${_routeInfo!['distanceKm']} كم',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'الوقت المقدر: ${_routeInfo!['durationMinutes']} دقيقة',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (_routeInfo!['fare'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'التكلفة المقدرة: ${_routeInfo!['fare']['amount']} ${_routeInfo!['fare']['currency']}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: widget.sector.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.sector.color,
                          ),
                          onPressed: _isRequesting ? null : _requestRide,
                          child: _isRequesting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('تأكيد وطلب الخدمة'),
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
