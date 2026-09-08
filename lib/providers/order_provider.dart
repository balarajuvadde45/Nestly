import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/vendor.dart';
import '../services/api_client.dart';
import '../services/api_mappers.dart';
import '../services/socket_service.dart';

/// Orders from Nestly API only.
class OrderProvider extends ChangeNotifier {
  OrderProvider(this._api, this._socket);

  final ApiClient _api;
  final SocketService _socket;
  final List<Order> _orders = [];
  bool _loading = false;
  String? _error;

  List<Order> get orders => List.unmodifiable(_orders);
  List<Order> get activeOrders => _orders.where((o) => o.isActive).toList();
  List<Order> get pastOrders => _orders.where((o) => !o.isActive).toList();
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadOrders() async {
    if (_api.token == null) {
      _orders.clear();
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/orders');
      final list = (res['orders'] as List? ?? [])
          .map((e) => orderFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _orders
        ..clear()
        ..addAll(list);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Order> placeOrder({
    required String quoteHash,
    required Vendor vendor,
    required List<CartItem> items,
    required Address address,
    required double itemTotal,
    required double deliveryFee,
    required double platformFee,
    required double tax,
    required double discount,
    required double grandTotal,
    required String paymentMethod,
    String? couponCode,
  }) async {
    if (_api.token == null) {
      throw Exception('Please log in to place an order.');
    }

    final body = <String, dynamic>{
      'vendorId': vendor.id,
      'addressId': address.id,
      'paymentMethod': 'COD',
      'quoteHash': quoteHash,
      'items': items
          .map(
            (i) => {
              'productId': i.product.id,
              'quantity': i.quantity,
              if (i.selectedSize != null) 'selectedSize': i.selectedSize,
              if (i.specialInstructions != null)
                'specialInstructions': i.specialInstructions,
            },
          )
          .toList(),
    };
    final prefs = await SharedPreferences.getInstance();
    final signature = jsonEncode(body);
    final saved = prefs.getString('nestly_checkout_pending');
    Map<String, dynamic>? pending;
    try {
      if (saved != null) pending = jsonDecode(saved) as Map<String, dynamic>;
    } catch (_) {}
    final key = pending?['signature'] == signature
        ? pending!['key'] as String
        : const Uuid().v4();
    await prefs.setString(
      'nestly_checkout_pending',
      jsonEncode({'signature': signature, 'key': key}),
    );
    final res = await _api.post(
      '/api/orders',
      body: {...body, 'idempotencyKey': key},
    );
    await prefs.remove('nestly_checkout_pending');

    final order = orderFromJson(Map<String, dynamic>.from(res['order'] as Map));
    _orders.insert(0, order);
    _listenToOrder(order.id);
    notifyListeners();
    return order;
  }

  void _listenToOrder(String orderId) {
    _socket.subscribeOrder(orderId);
    _socket.onOrderUpdated((data) {
      if (data['id'] != orderId) return;
      final updated = orderFromJson(data);
      final i = _orders.indexWhere((o) => o.id == orderId);
      if (i >= 0) {
        _orders[i] = updated;
        notifyListeners();
      }
    });
    _socket.onTrackingLocation((data) {
      if (data['orderId'] != orderId) return;
      final i = _orders.indexWhere((o) => o.id == orderId);
      if (i < 0) return;
      _orders[i] = _orders[i].copyWith(
        riderLat: (data['lat'] as num?)?.toDouble(),
        riderLng: (data['lng'] as num?)?.toDouble(),
        deliveryPartner: data['deliveryPartner'] as String?,
      );
      notifyListeners();
    });
  }

  Order? getById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshOrder(String id) async {
    if (_api.token == null) return;
    try {
      final res = await _api.get('/api/orders/$id');
      final order = orderFromJson(
        Map<String, dynamic>.from(res['order'] as Map),
      );
      final i = _orders.indexWhere((o) => o.id == id);
      if (i >= 0) {
        _orders[i] = order;
      } else {
        _orders.insert(0, order);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cancelOrder(String orderId) async {
    if (_api.token == null) return;
    try {
      final res = await _api.post('/api/orders/$orderId/cancel');
      final order = orderFromJson(
        Map<String, dynamic>.from(res['order'] as Map),
      );
      final i = _orders.indexWhere((o) => o.id == orderId);
      if (i >= 0) _orders[i] = order;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void applyRemoteOrder(Order order) {
    final i = _orders.indexWhere((o) => o.id == order.id);
    if (i >= 0) {
      _orders[i] = order;
    } else {
      _orders.insert(0, order);
    }
    notifyListeners();
  }

  void clear() {
    _orders.clear();
    notifyListeners();
  }
}
