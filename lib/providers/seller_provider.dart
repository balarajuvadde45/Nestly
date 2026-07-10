import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/vendor.dart';
import '../services/api_client.dart';
import '../services/api_mappers.dart';
import '../services/socket_service.dart';

// re-export for clarity — ApiException lives in api_client

class SellerStats {
  final int productCount;
  final int totalOrders;
  final int activeOrders;
  final double revenue;
  final double rating;

  const SellerStats({
    this.productCount = 0,
    this.totalOrders = 0,
    this.activeOrders = 0,
    this.revenue = 0,
    this.rating = 0,
  });
}

class SellerProvider extends ChangeNotifier {
  SellerProvider(this._api, this._socket);

  final ApiClient _api;
  final SocketService _socket;

  Vendor? _vendor;
  List<Product> _products = [];
  List<Order> _orders = [];
  SellerStats _stats = const SellerStats();
  bool _loading = false;
  String? _error;

  Vendor? get vendor => _vendor;
  List<Product> get products => List.unmodifiable(_products);
  List<Order> get orders => List.unmodifiable(_orders);
  SellerStats get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasStorefront => _vendor != null;

  Future<void> loadDashboard() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/api/seller/dashboard');
      _vendor = vendorFromJson(
          Map<String, dynamic>.from(res['vendor'] as Map));
      final s = res['stats'] as Map<String, dynamic>? ?? {};
      _stats = SellerStats(
        productCount: (s['productCount'] as num?)?.toInt() ?? 0,
        totalOrders: (s['totalOrders'] as num?)?.toInt() ?? 0,
        activeOrders: (s['activeOrders'] as num?)?.toInt() ?? 0,
        revenue: (s['revenue'] as num?)?.toDouble() ?? 0,
        rating: (s['rating'] as num?)?.toDouble() ?? 0,
      );
      _orders = (res['recentOrders'] as List? ?? [])
          .map((e) => orderFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      _socket.connect();
      _socket.onNewOrder((data) {
        final order = orderFromJson(data);
        _orders.insert(0, order);
        _stats = SellerStats(
          productCount: _stats.productCount,
          totalOrders: _stats.totalOrders + 1,
          activeOrders: _stats.activeOrders + 1,
          revenue: _stats.revenue,
          rating: _stats.rating,
        );
        notifyListeners();
      });
    } on ApiException catch (e) {
      _error = e.message;
      _vendor = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    try {
      final res = await _api.get('/api/seller/products');
      _products = (res['products'] as List? ?? [])
          .map((e) => productFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadOrders() async {
    try {
      final res = await _api.get('/api/seller/orders');
      _orders = (res['orders'] as List? ?? [])
          .map((e) => orderFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> onboard({
    required String name,
    required String tagline,
    required String description,
    required String type,
    required String area,
    String city = 'Hyderabad',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post('/api/seller/onboard', body: {
        'name': name,
        'tagline': tagline,
        'description': description,
        'type': type,
        'area': area,
        'city': city,
      });
      _vendor =
          vendorFromJson(Map<String, dynamic>.from(res['vendor'] as Map));
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createProduct(Map<String, dynamic> body) async {
    try {
      final res = await _api.post('/api/seller/products', body: body);
      final p =
          productFromJson(Map<String, dynamic>.from(res['product'] as Map));
      _products.insert(0, p);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> body) async {
    try {
      final res = await _api.patch('/api/seller/products/$id', body: body);
      final p =
          productFromJson(Map<String, dynamic>.from(res['product'] as Map));
      final i = _products.indexWhere((x) => x.id == id);
      if (i >= 0) _products[i] = p;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _api.delete('/api/seller/products/$id');
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final res = await _api.patch('/api/seller/orders/$orderId/status', body: {
        'status': status,
      });
      final order =
          orderFromJson(Map<String, dynamic>.from(res['order'] as Map));
      final i = _orders.indexWhere((o) => o.id == orderId);
      if (i >= 0) {
        _orders[i] = order;
      } else {
        _orders.insert(0, order);
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStore(Map<String, dynamic> body) async {
    try {
      final res = await _api.patch('/api/seller/store', body: body);
      _vendor =
          vendorFromJson(Map<String, dynamic>.from(res['vendor'] as Map));
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
