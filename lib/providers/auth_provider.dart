import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/api_mappers.dart';
import '../services/socket_service.dart';

/// App surface: buyer shop vs seller dashboard (same login, different UI + logs).
enum NestlyMode { buyer, seller }

const _kTokenKey = 'nestly_auth_token';

/// Auth against Nestly API — email, phone OTP, Google.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api, this._socket);

  final ApiClient _api;
  final SocketService _socket;
  final _secureStorage = const FlutterSecureStorage();

  AppUser? _user;
  String? _token;
  String? _vendorId;
  bool _isLoading = false;
  bool _backendOnline = false;
  bool _restoring = true;
  String? _error;
  NestlyMode _mode = NestlyMode.buyer;

  AppUser? get user => _user;
  String? get token => _token;
  String? get vendorId => _vendorId;
  NestlyMode get mode => _mode;
  bool get isBuyerMode => _mode == NestlyMode.buyer;
  bool get isSellerMode => _mode == NestlyMode.seller;
  bool get isLoggedIn => _user != null && _token != null && _token!.isNotEmpty;
  bool get isSeller => _user?.isSeller == true || _vendorId != null;
  bool get hasBusiness => _vendorId != null;
  bool get isLoading => _isLoading;
  bool get restoring => _restoring;
  bool get backendOnline => _backendOnline;
  String? get error => _error;

  void enterBuyerMode() {
    _mode = NestlyMode.buyer;
    notifyListeners();
    _logBuyer('ENTER_BUYER_MODE', 'Switched to buyer shop');
  }

  void enterSellerMode() {
    _mode = NestlyMode.seller;
    notifyListeners();
    _logSeller('ENTER_SELLER_MODE', 'Switched to seller dashboard');
  }

  Future<void> _logBuyer(String action, [String? message]) async {
    if (!isLoggedIn) return;
    try {
      await _api.post(
        '/api/buyer/log',
        body: {'action': action, 'message': ?message},
      );
    } catch (_) {}
  }

  Future<void> _logSeller(String action, [String? message]) async {
    if (!isLoggedIn) return;
    try {
      await _api.post(
        '/api/seller/log',
        body: {'action': action, 'message': ?message},
      );
    } catch (_) {}
  }

  Future<bool> openBusiness({
    required String businessName,
    required String area,
    String city = 'Hyderabad',
    String businessType = 'HOME_BUSINESS',
    String? tagline,
    String? description,
    String? businessAddress,
    String? pincode,
    String premisesType = 'BUSINESS_PLACE',
    String? gstin,
    String? pan,
    String? fssaiLicense,
    bool gstInvoiceAvailable = false,
    bool acceptsWholesale = false,
  }) async {
    if (!isLoggedIn) {
      _error = 'Login with your buyer account first.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post(
        '/api/buyer/open-business',
        body: {
          'businessName': businessName,
          'area': area,
          'city': city,
          'businessType': businessType,
          'premisesType': premisesType,
          'gstInvoiceAvailable': gstInvoiceAvailable,
          'acceptsWholesale': acceptsWholesale,
          if (tagline != null && tagline.isNotEmpty) 'tagline': tagline,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (businessAddress != null && businessAddress.isNotEmpty)
            'businessAddress': businessAddress,
          if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
          if (gstin != null && gstin.isNotEmpty) 'gstin': gstin,
          if (pan != null && pan.isNotEmpty) 'pan': pan,
          if (fssaiLicense != null && fssaiLicense.isNotEmpty)
            'fssaiLicense': fssaiLicense,
        },
      );
      final newToken = res['token'] as String?;
      if (newToken != null && newToken.isNotEmpty) {
        _token = newToken;
        _api.setToken(newToken);
        _socket.setToken(newToken);
        await _persistToken(newToken);
      }
      if (res['user'] is Map) {
        _user = userFromJson(Map<String, dynamic>.from(res['user'] as Map));
      } else {
        _user = _user?.copyWith(role: 'SELLER');
      }
      final business = res['business'] as Map<String, dynamic>?;
      _vendorId = business?['id'] as String?;
      _mode = NestlyMode.seller;
      await _refreshMe();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      await _refreshMe();
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshSellerToken() async {
    if (!isLoggedIn) return false;
    try {
      final res = await _api.post('/api/buyer/refresh-seller-session');
      final t = res['token'] as String?;
      if (t != null && t.isNotEmpty) {
        _token = t;
        _api.setToken(t);
        _socket.setToken(t);
        await _persistToken(t);
      }
      if (res['user'] is Map) {
        _user = userFromJson(Map<String, dynamic>.from(res['user'] as Map));
      }
      if (res['business'] is Map) {
        _vendorId = (res['business'] as Map)['id'] as String?;
      }
      _mode = NestlyMode.seller;
      notifyListeners();
      return true;
    } catch (_) {
      await _refreshMe();
      return isSeller || _vendorId != null;
    }
  }

  Future<void> init() async {
    _backendOnline = await _api.healthCheck();
    await _restoreSession();
    _restoring = false;
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTokenKey);
      if (kIsWeb) return;
      final saved = await _secureStorage.read(key: _kTokenKey);
      if (saved == null || saved.isEmpty) return;
      _token = saved;
      _api.setToken(saved);
      _socket.setToken(saved);
      await _refreshMe();
      if (_user != null) {
        _socket.connect();
      }
    } catch (_) {}
  }

  Future<void> _persistToken(String? token) async {
    try {
      if (kIsWeb) return;
      if (token == null || token.isEmpty) {
        await _secureStorage.delete(key: _kTokenKey);
      } else {
        await _secureStorage.write(key: _kTokenKey, value: token);
      }
    } catch (_) {}
  }

  Future<void> _clearPersistedToken() => _persistToken(null);

  /// Send OTP to phone. Returns the delivery acknowledgement.
  Future<Map<String, dynamic>?> sendPhoneOtp(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final online = await _api.healthCheck();
      _backendOnline = online;
      if (!online) {
        _error = 'Unable to connect. Please try again shortly.';
        return null;
      }
      final res = await _api.post('/api/auth/send-otp', body: {'phone': phone});
      return res;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyPhoneOtp(String phone, String otp, {String? name}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final online = await _api.healthCheck();
      _backendOnline = online;
      if (!online) {
        _error = 'Unable to connect. Please try again shortly.';
        return false;
      }
      final res = await _api.post(
        '/api/auth/verify-otp',
        body: {
          'phone': phone,
          'otp': otp,
          if (name != null && name.isNotEmpty) 'name': name,
        },
      );
      await _applyAuth(res);
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
        _error = 'Unable to connect. Please try again shortly.';
        return false;
      }
      final res = await _api.post(
        '/api/auth/login',
        body: {'email': email.trim(), 'password': password},
      );
      await _applyAuth(res);
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
    required String otp,
    bool asSeller = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final online = await _api.healthCheck();
      _backendOnline = online;
      if (!online) {
        _error = 'Unable to connect. Please try again shortly.';
        return false;
      }
      final res = await _api.post(
        '/api/auth/register',
        body: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'otp': otp,
        },
      );
      await _applyAuth(res);
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

  Future<void> _applyAuth(Map<String, dynamic> res) async {
    _token = res['token'] as String?;
    final userJson = res['user'] as Map<String, dynamic>?;
    if (userJson != null) {
      _user = userFromJson(userJson);
    }
    _api.setToken(_token);
    _socket.setToken(_token);
    await _persistToken(_token);
    _socket.connect();
    await _refreshMe();
  }

  Future<void> _refreshMe() async {
    final requestedToken = _token;
    try {
      final res = await _api.get('/api/auth/me');
      if (requestedToken != _token) return;
      if (res['user'] is Map) {
        _user = userFromJson(Map<String, dynamic>.from(res['user'] as Map));
      }
      _vendorId = res['vendorId'] as String?;
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401 && requestedToken == _token) await logout();
    } catch (_) {}
  }

  Future<void> refreshProfile() => _refreshMe();

  Future<void> logout() async {
    _user = null;
    _token = null;
    _vendorId = null;
    _mode = NestlyMode.buyer;
    _api.setToken(null);
    _socket.disconnect();
    _socket.setToken(null);
    await _clearPersistedToken();
    notifyListeners();
  }

  Future<bool> updateProfile({required String name}) async {
    try {
      await _api.patch('/api/auth/me', body: {'name': name});
      await _refreshMe();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to update profile. Please try again.';
      return false;
    }
  }

  Future<bool> deleteAccount({String? password, String? otp}) async {
    try {
      await _api.post(
        '/api/auth/me/delete',
        body: {
          'confirmation': 'DELETE',
          if (password != null && password.isNotEmpty) 'password': password,
          if (otp != null && otp.isNotEmpty) 'otp': otp,
        },
      );
      await logout();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to delete account. Please try again.';
      return false;
    }
  }

  Future<void> _setFavorite(String kind, String id, bool saved) async {
    if (!isLoggedIn) return;
    try {
      await _api.post(
        '/api/favorites',
        body: {'kind': kind, 'id': id, 'saved': saved},
      );
      await _refreshMe();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (_) {
      _error = 'Unable to save favourite. Please try again.';
      notifyListeners();
    }
  }

  Future<void> toggleFavoriteVendor(String id) =>
      _setFavorite('vendor', id, !isVendorFavorite(id));
  Future<void> toggleFavoriteProduct(String id) =>
      _setFavorite('product', id, !isProductFavorite(id));

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

  Future<bool> saveAddress({
    String? id,
    required String label,
    required String fullAddress,
    required String area,
    required String city,
    required String pincode,
    String? landmark,
    bool isDefault = false,
  }) async {
    if (!isLoggedIn) {
      _error = 'Login required';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final body = {
        'label': label,
        'fullAddress': fullAddress,
        'area': area,
        'city': city,
        'pincode': pincode,
        if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
        'isDefault': isDefault,
      };
      if (id == null) {
        await _api.post('/api/addresses', body: body);
      } else {
        await _api.patch('/api/addresses/$id', body: body);
      }
      await _refreshMe();
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

  Future<bool> deleteAddress(String id) async {
    if (!isLoggedIn) return false;
    try {
      await _api.delete('/api/addresses/$id');
      await _refreshMe();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setVendorId(String? id) {
    _vendorId = id;
    notifyListeners();
  }
}
