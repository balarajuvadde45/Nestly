import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/vendor.dart';

class CartProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final List<CartItem> _items = [];
  String? _vendorId;
  Vendor? _vendor;
  String? _couponCode;
  double _couponDiscount = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  String? get vendorId => _vendorId;
  Vendor? get vendor => _vendor;
  String? get couponCode => _couponCode;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  double get itemTotal =>
      _items.fold(0.0, (sum, i) => sum + i.lineTotal);

  double get deliveryFee {
    if (isEmpty) return 0;
    if (_vendor?.freeDelivery == true) return 0;
    if (itemTotal >= AppConstants.freeDeliveryMin) return 0;
    return AppConstants.deliveryFee;
  }

  double get platformFee => isEmpty ? 0 : AppConstants.platformFee;

  double get tax =>
      (itemTotal + deliveryFee + platformFee - _couponDiscount) *
      AppConstants.gstPercent /
      100;

  double get couponDiscount => _couponDiscount;

  double get grandTotal {
    final total =
        itemTotal + deliveryFee + platformFee + tax - _couponDiscount;
    return total < 0 ? 0 : total;
  }

  int quantityOf(String productId, {String? size}) {
    final match = _items.where(
      (i) =>
          i.product.id == productId &&
          (size == null || i.selectedSize == size),
    );
    return match.fold(0, (s, i) => s + i.quantity);
  }

  bool canAddFromVendor(String vendorId) {
    return _vendorId == null || _vendorId == vendorId || _items.isEmpty;
  }

  void setVendorContext(Vendor? vendor) {
    if (vendor == null) return;
    _vendor = vendor;
    _vendorId = vendor.id;
  }

  void clearAndAdd(
    Product product, {
    int quantity = 1,
    String? size,
    String? instructions,
    Vendor? vendor,
  }) {
    _items.clear();
    _vendorId = product.vendorId;
    if (vendor != null) _vendor = vendor;
    _couponCode = null;
    _couponDiscount = 0;
    _items.add(CartItem(
      id: _uuid.v4(),
      product: product,
      quantity: quantity,
      selectedSize: size,
      specialInstructions: instructions,
    ));
    notifyListeners();
  }

  bool addItem(
    Product product, {
    int quantity = 1,
    String? size,
    String? instructions,
    bool forceReplace = false,
    Vendor? vendor,
  }) {
    if (!canAddFromVendor(product.vendorId)) {
      if (!forceReplace) return false;
      clearAndAdd(product,
          quantity: quantity,
          size: size,
          instructions: instructions,
          vendor: vendor);
      return true;
    }

    _vendorId ??= product.vendorId;
    if (vendor != null) _vendor = vendor;

    final existingIndex = _items.indexWhere(
      (i) =>
          i.product.id == product.id &&
          i.selectedSize == size &&
          i.specialInstructions == instructions,
    );

    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      _items[existingIndex] =
          existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      _items.add(CartItem(
        id: _uuid.v4(),
        product: product,
        quantity: quantity,
        selectedSize: size,
        specialInstructions: instructions,
      ));
    }
    notifyListeners();
    return true;
  }

  void increment(String cartItemId) {
    final i = _items.indexWhere((e) => e.id == cartItemId);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(quantity: _items[i].quantity + 1);
    notifyListeners();
  }

  void decrement(String cartItemId) {
    final i = _items.indexWhere((e) => e.id == cartItemId);
    if (i < 0) return;
    if (_items[i].quantity <= 1) {
      _items.removeAt(i);
      if (_items.isEmpty) {
        _vendorId = null;
        _vendor = null;
        _couponCode = null;
        _couponDiscount = 0;
      }
    } else {
      _items[i] = _items[i].copyWith(quantity: _items[i].quantity - 1);
    }
    notifyListeners();
  }

  void setQuantity(String cartItemId, int qty) {
    final i = _items.indexWhere((e) => e.id == cartItemId);
    if (i < 0) return;
    if (qty <= 0) {
      _items.removeAt(i);
      if (_items.isEmpty) {
        _vendorId = null;
        _vendor = null;
        _couponCode = null;
        _couponDiscount = 0;
      }
    } else {
      _items[i] = _items[i].copyWith(quantity: qty);
    }
    notifyListeners();
  }

  void removeItem(String cartItemId) {
    _items.removeWhere((e) => e.id == cartItemId);
    if (_items.isEmpty) {
      _vendorId = null;
      _vendor = null;
      _couponCode = null;
      _couponDiscount = 0;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _vendorId = null;
    _vendor = null;
    _couponCode = null;
    _couponDiscount = 0;
    notifyListeners();
  }

  String? applyCoupon(String code) {
    final c = code.trim().toUpperCase();
    if (isEmpty) return 'Cart is empty';

    switch (c) {
      case 'NESTLY20':
      case 'HOMEFOODS20':
        _couponCode = 'NESTLY20';
        _couponDiscount = (itemTotal * 0.2).clamp(0, 100);
        notifyListeners();
        return null;
      case 'FLAT50':
        if (itemTotal < 199) return 'Minimum order ₹199 required';
        _couponCode = c;
        _couponDiscount = 50;
        notifyListeners();
        return null;
      case 'FIRST100':
        _couponCode = c;
        _couponDiscount = 100.clamp(0, itemTotal).toDouble();
        notifyListeners();
        return null;
      default:
        return 'Invalid coupon code';
    }
  }

  void removeCoupon() {
    _couponCode = null;
    _couponDiscount = 0;
    notifyListeners();
  }
}
