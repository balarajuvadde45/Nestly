import 'package:flutter/foundation.dart';
import '../models/banner_item.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/vendor.dart';
import '../services/api_client.dart';
import '../services/api_mappers.dart';

/// Live catalog from Nestly API only (no client-side mock data).
class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._api);

  final ApiClient _api;

  String _searchQuery = '';
  String? _selectedCategoryId;
  bool _vegOnly = false;
  String _sortBy = 'relevance';
  bool _loading = false;
  bool _loadedFromApi = false;
  String? _error;

  List<ShopCategory> _categories = [];
  List<BannerItem> _banners = [];
  List<Vendor> _vendors = [];
  List<Product> _products = [];
  List<Vendor> _popular = [];
  List<Vendor> _topRated = [];
  List<Product> _bestsellers = [];

  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get vegOnly => _vegOnly;
  String get sortBy => _sortBy;
  bool get loading => _loading;
  bool get loadedFromApi => _loadedFromApi;
  String? get error => _error;
  bool get isEmptyCatalog =>
      _vendors.isEmpty && _products.isEmpty && _loadedFromApi;

  List<ShopCategory> get categories => List.unmodifiable(_categories);
  List<BannerItem> get banners => List.unmodifiable(_banners);
  List<Vendor> get allVendors => List.unmodifiable(_vendors);
  List<Product> get allProducts => List.unmodifiable(_products);
  List<Vendor> get popularVendors => List.unmodifiable(_popular);
  List<Vendor> get topRated => List.unmodifiable(_topRated);
  List<Product> get bestsellers => List.unmodifiable(_bestsellers);

  Future<void> loadHome() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final online = await _api.healthCheck();
      if (!online) {
        _loadedFromApi = false;
        _error =
            'Cannot reach Nestly API. Start the backend and check API_BASE_URL.';
        _clearCatalog();
        return;
      }

      final res = await _api.get('/api/catalog/home');
      _categories = (res['categories'] as List? ?? [])
          .map((e) => categoryFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _banners = (res['banners'] as List? ?? [])
          .map((e) => bannerFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _popular = (res['popularVendors'] as List? ?? [])
          .map((e) => vendorFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _topRated = (res['topRated'] as List? ?? [])
          .map((e) => vendorFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _bestsellers = (res['bestsellers'] as List? ?? [])
          .map((e) => productFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _vendors = (res['vendors'] as List? ?? [])
          .map((e) => vendorFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final productsRes = await _api.get('/api/catalog/products');
      _products = (productsRes['products'] as List? ?? [])
          .map((e) => productFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      // If bestsellers empty, derive from products
      if (_bestsellers.isEmpty && _products.isNotEmpty) {
        final sorted = List<Product>.from(_products)
          ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        _bestsellers = sorted.take(8).toList();
      }
      if (_popular.isEmpty) {
        final sorted = List<Vendor>.from(_vendors)
          ..sort((a, b) => b.orderCount.compareTo(a.orderCount));
        _popular = sorted.take(6).toList();
      }
      if (_topRated.isEmpty) {
        final sorted = List<Vendor>.from(_vendors)
          ..sort((a, b) => b.rating.compareTo(a.rating));
        _topRated = sorted.take(6).toList();
      }

      _loadedFromApi = true;
    } catch (e) {
      _error = e.toString();
      _loadedFromApi = false;
      _clearCatalog();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _clearCatalog() {
    _categories = [];
    _banners = [];
    _vendors = [];
    _products = [];
    _popular = [];
    _topRated = [];
    _bestsellers = [];
  }

  /// Refresh a single vendor's products from API (seller storefront).
  Future<List<Product>> fetchProductsForVendor(String vendorId) async {
    try {
      final res = await _api.get('/api/catalog/vendors/$vendorId/products');
      final list = (res['products'] as List? ?? [])
          .map((e) => productFromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      // Merge into catalog cache
      _products.removeWhere((p) => p.vendorId == vendorId);
      _products.addAll(list);
      notifyListeners();
      return list;
    } catch (_) {
      return productsForVendor(vendorId);
    }
  }

  Future<Vendor?> fetchVendor(String id) async {
    try {
      final res = await _api.get('/api/catalog/vendors/$id');
      final v =
          vendorFromJson(Map<String, dynamic>.from(res['vendor'] as Map));
      final i = _vendors.indexWhere((x) => x.id == id);
      if (i >= 0) {
        _vendors[i] = v;
      } else {
        _vendors.add(v);
      }
      notifyListeners();
      return v;
    } catch (_) {
      return vendorById(id);
    }
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCategory(String? id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  void setVegOnly(bool value) {
    _vegOnly = value;
    notifyListeners();
  }

  void setSortBy(String value) {
    _sortBy = value;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _vegOnly = false;
    _sortBy = 'relevance';
    notifyListeners();
  }

  List<Vendor> get filteredVendors {
    var list = List<Vendor>.from(_vendors);

    if (_selectedCategoryId != null) {
      list =
          list.where((v) => v.categories.contains(_selectedCategoryId)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((v) =>
              v.name.toLowerCase().contains(q) ||
              v.tagline.toLowerCase().contains(q) ||
              v.tags.any((t) => t.toLowerCase().contains(q)) ||
              v.area.toLowerCase().contains(q))
          .toList();
    }

    if (_vegOnly) {
      list = list.where((v) => v.isPureVeg).toList();
    }

    switch (_sortBy) {
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'delivery':
        list.sort((a, b) => a.deliveryTimeMins.compareTo(b.deliveryTimeMins));
        break;
      case 'distance':
        list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      default:
        list.sort((a, b) => b.orderCount.compareTo(a.orderCount));
    }

    return list;
  }

  List<Product> get filteredProducts {
    var list = List<Product>.from(_products);

    if (_selectedCategoryId != null) {
      list = list.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }

    if (_vegOnly) {
      list = list.where((p) => p.isVeg).toList();
    }

    return list;
  }

  Vendor? vendorById(String id) {
    try {
      return _vendors.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  Product? productById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  ShopCategory? categoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Product> productsForVendor(String id) =>
      _products.where((p) => p.vendorId == id).toList();

  List<Vendor> vendorsForCategory(String id) =>
      _vendors.where((v) => v.categories.contains(id)).toList();
}
