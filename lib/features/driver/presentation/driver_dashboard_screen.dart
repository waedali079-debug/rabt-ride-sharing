import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rabt/core/services/api_client.dart';
import 'package:rabt/features/driver/data/driver_dispatch_service.dart';
import 'package:rabt/features/driver/presentation/dispatch_screen.dart';
import 'package:rabt/features/sectors/presentation/landing_hub_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final DriverDispatchService _dispatchService = DriverDispatchService();
  bool _isOnline = false;
  StreamSubscription<Map<String, dynamic>>? _tripSubscription;

  void _toggleStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });

    if (_isOnline) {
      _dispatchService.startListening();
      _tripSubscription = _dispatchService.tripStream.listen((tripData) {
        if (!mounted) return;
        _showDispatchDialog(tripData);
      });
    } else {
      _dispatchService.stopListening();
      _tripSubscription?.cancel();
    }
  }

  void _showDispatchDialog(Map<String, dynamic> tripData) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'dispatch',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => DispatchScreen(
        tripData: tripData,
        onAccept: () => _acceptTrip(tripData['id']),
        onReject: () {
          // Resume polling for next trip
          if (_isOnline) {
            _dispatchService.startListening();
          }
        },
      ),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }

  Future<void> _acceptTrip(String tripId) async {
    try {
      final response = await ApiClient().post('/v1/trips/$tripId/accept');
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول الرحلة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        // TODO: Navigate to trip tracking screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل قبول الرحلة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Resume polling after failure
      if (_isOnline) {
        _dispatchService.startListening();
      }
    }
  }

  @override
  void dispose() {
    _dispatchService.dispose();
    _tripSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم السائق'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiClient().clearToken();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LandingHubScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isOnline ? Icons.navigation : Icons.pause_circle_outline,
              size: 80,
              color: _isOnline ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              _isOnline ? 'متصل - في انتظار الطلبات' : 'غير متصل',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _isOnline
                  ? 'سيتم إشعارك عند وصول طلب جديد'
                  : 'اضغط على الزر لبدء استقبال الطلبات',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _toggleStatus,
                icon: Icon(_isOnline ? Icons.stop : Icons.play_arrow),
                label: Text(
                  _isOnline ? 'إيقاف العمل' : 'بدء العمل',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isOnline ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
