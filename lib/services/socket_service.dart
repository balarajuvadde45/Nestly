import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/config/app_config.dart';

typedef JsonHandler = void Function(Map<String, dynamic> data);

/// Socket.IO client for live order tracking.
class SocketService {
  io.Socket? _socket;
  String? _token;

  bool get isConnected => _socket?.connected ?? false;

  void setToken(String? token) {
    _token = token;
  }

  void connect() {
    if (_socket?.connected == true) return;
    _socket?.dispose();
    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth(_token != null ? {'token': _token} : {})
          .build(),
    );
    _socket!.onConnect((_) {});
    _socket!.onDisconnect((_) {});
    _socket!.onConnectError((e) {
      // Backend may be offline — app falls back to polling/mock
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void subscribeOrder(String orderId) {
    connect();
    _socket?.emit('tracking:subscribe', orderId);
  }

  void unsubscribeOrder(String orderId) {
    _socket?.emit('tracking:unsubscribe', orderId);
  }

  void onOrderUpdated(JsonHandler handler) {
    _socket?.on('order:updated', (data) {
      if (data is Map) {
        handler(Map<String, dynamic>.from(data));
      }
    });
  }

  void onTrackingLocation(JsonHandler handler) {
    _socket?.on('tracking:location', (data) {
      if (data is Map) {
        handler(Map<String, dynamic>.from(data));
      }
    });
  }

  void onNewOrder(JsonHandler handler) {
    _socket?.on('order:new', (data) {
      if (data is Map) {
        handler(Map<String, dynamic>.from(data));
      }
    });
  }

  void offAll() {
    _socket?.clearListeners();
  }
}
