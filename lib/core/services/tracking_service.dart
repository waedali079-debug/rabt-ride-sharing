import 'package:socket_io_client/socket_io_client.dart' as IO;

class TrackingService {
  late IO.Socket _socket;
  final String tripId;
  final Function(double lat, double lng) onLocationUpdate;
  final Function(String status) onStatusUpdate;

  TrackingService({
    required this.tripId,
    required this.onLocationUpdate,
    required this.onStatusUpdate,
  });

  void connect(String token) {
    _socket = IO.io(
      'http://10.0.2.2:8080',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket.onConnect((_) {
      _socket.emit('join_trip', tripId);
    });

    _socket.on('location_update', (data) {
      if (data['tripId'] == tripId) {
        final lat = (data['lat'] as num).toDouble();
        final lng = (data['lng'] as num).toDouble();
        onLocationUpdate(lat, lng);
      }
    });

    _socket.on('status_update', (data) {
      if (data['tripId'] == tripId) {
        onStatusUpdate(data['status'] as String);
      }
    });

    _socket.connect();
  }

  void cancelTrip() {
    _socket.emit('cancel_trip', tripId);
  }

  void disconnect() {
    _socket.disconnect();
    _socket.dispose();
  }
}
