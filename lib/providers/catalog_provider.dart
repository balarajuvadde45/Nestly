import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';
import '../models/banner_item.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/vendor.dart';
import '../services/api_client.dart';
import '../services/api_mappers.dart';

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

  List<ShopCategory> get categories =>
      _categories.isNotEmpty ? _categories : MockData.categories;
  List<BannerItem> get banners =>
      _banners.isNotEmpty ? _banners : MockData.banners;
  List<Vendor> get allVendors =>
      _vendors.isNotEmpty ? _vendors : MockData.vendors;
  List<Product> get allProducts =>
      _products.isNotEmpty ? _products : MockData.products;
  List<Vendor> get popularVendors =>
      _popular.isNotEmpty ? _popular : MockData.popularVendors;
  List<Vendor> get topRated =>
      _topRated.isNotEmpty ? _topRated : MockData.topRated;
  List<Product> get bestsellers =>
      _bestsellers.isNotEmpty ? _bestsellers : MockData.bestsellers;

  Future<void> loadHome() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final online = await _api.healthCheck();
      if (!online) {
        _loadedFromApi = false;
        _loading = false;
        notifyListeners();
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

      _loadedFromApi = true;
    } catch (e) {
      _error = e.toString();
      _loadedFromApi = false;
    } finally {
      _loading = false;
      notifyListeners();
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
    var list = List<Vendor>.from(allVendors);

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
    var list = List<Product>.from(allProducts);

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
      return allVendors.firstWhere((v) => v.id == id);
    } catch (_) {
      return MockData.vendorById(id);
    }
  }

  Product? productById(String id) {
    try {
      return allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return MockData.productById(id);
    }
  }

  ShopCategory? categoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return MockData.categoryById(id);
    }
  }

  List<Product> productsForVendor(String id) =>
      allProducts.where((p) => p.vendorId == id).toList();

  List<Vendor> vendorsForCategory(String id) =>
      allVendors.where((v) => v.categories.contains(id)).toList();
}
