import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/api_config.dart';

/// WebSocket client for real-time updates (trip status, location, etc.).
class WebSocketDataSource {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _currentTripId;
  String? _token;
  bool _isConnected = false;

  // Callbacks for the UI layer
  void Function(Map<String, dynamic> data)? onTripUpdate;
  void Function(Map<String, dynamic> data)? onLocationUpdate;
  void Function()? onConnected;
  void Function(String error)? onError;
  void Function()? onDisconnected;

  bool get isConnected => _isConnected;
  String? get currentTripId => _currentTripId;

  /// Connect to the Rabt WebSocket server.
  void connect({String? token}) {
    if (_isConnected) return;

    _token = token;
    try {
      final uri = Uri.parse(ApiConfig.wsUrl);
      _channel = WebSocketChannel.connect(uri, headers: _buildHeaders());

      _isConnected = true;
      onConnected?.call();

      _subscription = _channel!.stream.listen(
        (dynamic data) {
          _handleMessage(data);
        },
        onError: (dynamic error) {
          _isConnected = false;
          onError?.call(error.toString());
          _reconnect();
        },
        onDone: () {
          _isConnected = false;
          onDisconnected?.call();
          _reconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      onError?.call('Failed to connect: $e');
    }
  }

  /// Disconnect from the WebSocket server.
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _channel = null;
    _subscription = null;
  }

  /// Subscribe to trip updates.
  void subscribeToTrip(String tripId) {
    _currentTripId = tripId;
    _send({'event': 'subscribe_trip', 'trip_id': tripId});
  }

  /// Send a ping to keep the connection alive.
  void ping() {
    _send({'event': 'ping'});
  }

  /// Send raw location update via WebSocket.
  void sendLocationUpdate(double lat, double lng) {
    _send({
      'event': 'location_update',
      'lat': lat,
      'lng': lng,
    });
  }

  /// Build HTTP headers for WebSocket upgrade.
  Map<String, dynamic> _buildHeaders() {
    final headers = <String, dynamic>{};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Send a JSON message.
  void _send(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  /// Handle incoming messages.
  void _handleMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = data['event'] as String?;

      switch (event) {
        case 'trip_update':
        case 'trip_accepted':
        case 'trip_cancelled':
        case 'trip_completed':
          onTripUpdate?.call(data);
          break;
        case 'location_update':
        case 'driver_location':
          onLocationUpdate?.call(data);
          break;
        case 'pong':
          // heartbeat response — ignore
          break;
        default:
          // Unknown event — forward as trip update
          onTripUpdate?.call(data);
      }
    } catch (e) {
      // Ignore malformed messages
    }
  }

  /// Auto-reconnect after 3 seconds.
  void _reconnect() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isConnected) {
        connect(token: _token);
      }
    });
  }

  void dispose() {
    disconnect();
    onTripUpdate = null;
    onLocationUpdate = null;
    onConnected = null;
    onError = null;
    onDisconnected = null;
  }
}
