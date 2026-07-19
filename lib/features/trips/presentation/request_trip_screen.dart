import 'dart:ui';
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

    const dropoff = LatLng(31.9539, 35.9106);

    final routeData = await _tripService.fetchRouteWithFare(
      fromLat: _currentPosition!.latitude,
      fromLng: _currentPosition!.longitude,
      toLat: dropoff.latitude,
      toLng: dropoff.longitude,
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
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80.0)),
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
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
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
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.rabt.app',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 6.0,
                            color: widget.sector.color,
                            borderColor: Colors.white,
                            borderStrokeWidth: 2.0,
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
                          width: 50.0,
                          height: 50.0,
                          child: Icon(
                            Icons.radio_button_checked,
                            color: widget.sector.color,
                            size: 40.0,
                          ),
                        ),
                        if (_routePoints.isNotEmpty)
                          Marker(
                            point: _routePoints.last,
                            width: 50.0,
                            height: 50.0,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40.0,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            widget.sector.nameAr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E).withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isFetchingRoute)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        if (_routeInfo != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoCard(
                                'المسافة',
                                '${_routeInfo!['distanceKm']} كم',
                              ),
                              _buildInfoCard(
                                'الوقت المقدر',
                                '${_routeInfo!['durationMinutes']} دقيقة',
                              ),
                            ],
                          ),
                          if (_routeInfo!['fare'] != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoCard(
                                  'التكلفة المقدرة',
                                  '${_routeInfo!['fare']['amount']} ${_routeInfo!['fare']['currency']}',
                                  isHighlighted: true,
                                ),
                                _buildInfoCard(
                                  'الخدمة',
                                  widget.sector.nameAr,
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.sector.color,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: _isRequesting ? null : _requestRide,
                            child: _isRequesting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'تأكيد وطلب الخدمة',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard(String title, String value, {bool isHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? widget.sector.color : Colors.white,
          ),
        ),
      ],
    );
  }
}
