import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/mock_data.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/vendor.dart';
import '../services/api_client.dart';
import '../services/api_mappers.dart';
import '../services/socket_service.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._api, this._socket) {
    _seedDemoOrders();
  }

  final ApiClient _api;
  final SocketService _socket;
  final _uuid = const Uuid();
  final List<Order> _orders = [];
  bool _loading = false;

  List<Order> get orders => List.unmodifiable(_orders);
  List<Order> get activeOrders => _orders.where((o) => o.isActive).toList();
  List<Order> get pastOrders => _orders.where((o) => !o.isActive).toList();
  bool get loading => _loading;

  void _seedDemoOrders() {
    final v1 = MockData.vendorById('v1')!;
    final v3 = MockData.vendorById('v3')!;
    final p1 = MockData.productById('p1')!;
    final p9 = MockData.productById('p9')!;
    final addr = MockData.demoUser.addresses.first;

    _orders.addAll([
      Order(
        id: 'ord_demo_1',
        vendorId: v1.id,
        vendorName: v1.name,
        items: [CartItem(id: 'ci1', product: p1, quantity: 2)],
        status: OrderStatus.outForDelivery,
        placedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        address: addr,
        itemTotal: p1.price * 2,
        deliveryFee: 0,
        platformFee: 5,
        tax: 15.3,
        grandTotal: p1.price * 2 + 5 + 15.3,
        paymentMethod: 'UPI',
        deliveryPartner: 'Ravi K.',
        estimatedDelivery: DateTime.now().add(const Duration(minutes: 15)),
        riderLat: 17.445,
        riderLng: 78.385,
        vendorLat: v1.lat,
        vendorLng: v1.lng,
      ),
      Order(
        id: 'ord_demo_2',
        vendorId: v3.id,
        vendorName: v3.name,
        items: [CartItem(id: 'ci2', product: p9, quantity: 1)],
        status: OrderStatus.delivered,
        placedAt: DateTime.now().subtract(const Duration(days: 3)),
        address: addr,
        itemTotal: p9.price,
        deliveryFee: 0,
        platformFee: 5,
        tax: 12.7,
        discount: 20,
        grandTotal: p9.price + 5 + 12.7 - 20,
        paymentMethod: 'Cash on Delivery',
        vendorLat: v3.lat,
        vendorLng: v3.lng,
      ),
    ]);
  }

  Future<void> loadOrders() async {
    if (_api.token == null) return;
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.get('/api/orders');
      final list = (res['orders'] as List? ?? [])
          .map((e) => orderFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (list.isNotEmpty) {
        _orders
          ..clear()
          ..addAll(list);
      }
    } catch (_) {
      // keep local/demo orders
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Order> placeOrder({
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
    // Prefer backend when authenticated against real API
    if (_api.token != null && _api.token != 'mock-token' && _api.token != 'guest-token') {
      try {
        final paymentMap = {
          'UPI': 'UPI',
          'Card': 'CARD',
          'Cash on Delivery': 'COD',
          'Wallet': 'WALLET',
        };
        final res = await _api.post('/api/orders', body: {
          'vendorId': vendor.id,
          'addressId': address.id,
          'paymentMethod': paymentMap[paymentMethod] ?? 'COD',
          if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
          'items': items
              .map((i) => {
                    'productId': i.product.id,
                    'quantity': i.quantity,
                    if (i.selectedSize != null) 'selectedSize': i.selectedSize,
                    if (i.specialInstructions != null)
                      'specialInstructions': i.specialInstructions,
                  })
              .toList(),
        });
        final order =
            orderFromJson(Map<String, dynamic>.from(res['order'] as Map));
        _orders.insert(0, order);
        _listenToOrder(order.id);
        notifyListeners();
        return order;
      } catch (_) {
        // fall through to local place
      }
    }

    final order = Order(
      id: 'ord_${_uuid.v4().substring(0, 8)}',
      vendorId: vendor.id,
      vendorName: vendor.name,
      items: List.from(items),
      status: OrderStatus.placed,
      placedAt: DateTime.now(),
      address: address,
      itemTotal: itemTotal,
      deliveryFee: deliveryFee,
      platformFee: platformFee,
      tax: tax,
      discount: discount,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      estimatedDelivery:
          DateTime.now().add(Duration(minutes: vendor.deliveryTimeMins + 10)),
      couponCode: couponCode,
      vendorLat: vendor.lat,
      vendorLng: vendor.lng,
    );
    _orders.insert(0, order);
    notifyListeners();
    _simulateProgress(order.id, vendor);
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

  void _simulateProgress(String orderId, Vendor vendor) {
    Future.delayed(const Duration(seconds: 8), () {
      _updateStatus(orderId, OrderStatus.confirmed);
    });
    Future.delayed(const Duration(seconds: 20), () {
      _updateStatus(orderId, OrderStatus.preparing);
    });
    Future.delayed(const Duration(seconds: 35), () {
      _updateStatus(
        orderId,
        OrderStatus.outForDelivery,
        riderLat: vendor.lat,
        riderLng: vendor.lng,
        partner: 'Ravi K.',
      );
      _simulateRider(orderId, vendor);
    });
  }

  void _simulateRider(String orderId, Vendor vendor) {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    final dropLat = _orders[i].address.lat ?? 17.44;
    final dropLng = _orders[i].address.lng ?? 78.39;
    const steps = 8;
    for (var s = 1; s <= steps; s++) {
      Future.delayed(Duration(seconds: 8 * s), () {
        final t = s / steps;
        final lat = vendor.lat + (dropLat - vendor.lat) * t;
        final lng = vendor.lng + (dropLng - vendor.lng) * t;
        final idx = _orders.indexWhere((o) => o.id == orderId);
        if (idx < 0) return;
        if (_orders[idx].status != OrderStatus.outForDelivery) return;
        _orders[idx] = _orders[idx].copyWith(riderLat: lat, riderLng: lng);
        notifyListeners();
        if (s == steps) {
          _updateStatus(orderId, OrderStatus.delivered,
              riderLat: dropLat, riderLng: dropLng);
        }
      });
    }
  }

  void _updateStatus(
    String orderId,
    OrderStatus status, {
    double? riderLat,
    double? riderLng,
    String? partner,
  }) {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    final o = _orders[i];
    if (o.status == OrderStatus.cancelled || o.status == OrderStatus.delivered) {
      return;
    }
    _orders[i] = o.copyWith(
      status: status,
      riderLat: riderLat,
      riderLng: riderLng,
      deliveryPartner: partner ??
          (status.index >= OrderStatus.outForDelivery.index
              ? (o.deliveryPartner ?? 'Ravi K.')
              : o.deliveryPartner),
    );
    notifyListeners();
  }

  Order? getById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshOrder(String id) async {
    if (_api.token == null ||
        _api.token == 'mock-token' ||
        _api.token == 'guest-token') {
      return;
    }
    try {
      final res = await _api.get('/api/orders/$id');
      final order =
          orderFromJson(Map<String, dynamic>.from(res['order'] as Map));
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
    if (_api.token != null &&
        _api.token != 'mock-token' &&
        _api.token != 'guest-token') {
      try {
        final res = await _api.post('/api/orders/$orderId/cancel');
        final order =
            orderFromJson(Map<String, dynamic>.from(res['order'] as Map));
        final i = _orders.indexWhere((o) => o.id == orderId);
        if (i >= 0) _orders[i] = order;
        notifyListeners();
        return;
      } catch (_) {}
    }
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    final o = _orders[i];
    if (o.status == OrderStatus.delivered ||
        o.status == OrderStatus.cancelled ||
        o.status == OrderStatus.outForDelivery) {
      return;
    }
    _updateStatus(orderId, OrderStatus.cancelled);
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
}
