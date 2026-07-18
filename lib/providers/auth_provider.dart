import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/api_mappers.dart';
import '../services/socket_service.dart';

/// Auth against Nestly API only (no guest/mock users for UAT).
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api, this._socket);

  final ApiClient _api;
  final SocketService _socket;

  AppUser? _user;
  String? _token;
  String? _vendorId;
  bool _isLoading = false;
  bool _backendOnline = false;
  String? _error;

  AppUser? get user => _user;
  String? get token => _token;
  String? get vendorId => _vendorId;
  bool get isLoggedIn =>
      _user != null &&
      _token != null &&
      _token!.isNotEmpty &&
      !_token!.startsWith('mock') &&
      !_token!.startsWith('guest');
  bool get isSeller => _user?.isSeller == true;
  bool get isLoading => _isLoading;
  bool get backendOnline => _backendOnline;
  String? get error => _error;

  Future<void> init() async {
    _backendOnline = await _api.healthCheck();
    notifyListeners();
  }

  Future<bool> loginWithPhone(String phone, {String otp = '123456'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final online = await _api.healthCheck();
      _backendOnline = online;
      if (!online) {
        _error = 'Server offline. Start Nestly API and try again.';
        return false;
      }
      final res = await _api.post('/api/auth/phone-otp', body: {
        'phone': phone,
        'otp': otp,
      });
      _applyAuth(res);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final online = await _api.healthCheck();
      _backendOnline = online;
      if (!online) {
        _error = 'Server offline. Start Nestly API and try again.';
        return false;
      }
      final res = await _api.post('/api/auth/login', body: {
        'email': email.trim(),
        'password': password,
      });
      _applyAuth(res);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    bool asSeller = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final online = await _api.healthCheck();
      _backendOnline = online;
      if (!online) {
        _error = 'Server offline. Start Nestly API and try again.';
        return false;
      }
      final res = await _api.post('/api/auth/register', body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        if (asSeller) 'role': 'SELLER',
      });
      _applyAuth(res);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyAuth(Map<String, dynamic> res) {
    _token = res['token'] as String?;
    final userJson = res['user'] as Map<String, dynamic>?;
    if (userJson != null) {
      _user = userFromJson(userJson);
    }
    _api.setToken(_token);
    _socket.setToken(_token);
    _socket.connect();
    if (_user?.isSeller == true) {
      _refreshMe();
    }
  }

  Future<void> _refreshMe() async {
    try {
      final res = await _api.get('/api/auth/me');
      if (res['user'] is Map) {
        _user = userFromJson(Map<String, dynamic>.from(res['user'] as Map));
      }
      _vendorId = res['vendorId'] as String?;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshProfile() => _refreshMe();

  void logout() {
    _user = null;
    _token = null;
    _vendorId = null;
    _api.setToken(null);
    _socket.disconnect();
    notifyListeners();
  }

  void updateProfile({String? name, String? email, String? phone}) {
    if (_user == null) return;
    _user = _user!.copyWith(name: name, email: email, phone: phone);
    notifyListeners();
  }

  void toggleFavoriteVendor(String vendorId) {
    if (_user == null) return;
    final list = List<String>.from(_user!.favoriteVendorIds);
    if (list.contains(vendorId)) {
      list.remove(vendorId);
    } else {
      list.add(vendorId);
    }
    _user = _user!.copyWith(favoriteVendorIds: list);
    notifyListeners();
  }

  void toggleFavoriteProduct(String productId) {
    if (_user == null) return;
    final list = List<String>.from(_user!.favoriteProductIds);
    if (list.contains(productId)) {
      list.remove(productId);
    } else {
      list.add(productId);
    }
    _user = _user!.copyWith(favoriteProductIds: list);
    notifyListeners();
  }

  bool isVendorFavorite(String id) =>
      _user?.favoriteVendorIds.contains(id) ?? false;

  bool isProductFavorite(String id) =>
      _user?.favoriteProductIds.contains(id) ?? false;

  void addAddress(Address address) {
    if (_user == null) return;
    final list = List<Address>.from(_user!.addresses)..add(address);
    _user = _user!.copyWith(addresses: list);
    notifyListeners();
  }

  void setVendorId(String? id) {
    _vendorId = id;
    notifyListeners();
  }
}
