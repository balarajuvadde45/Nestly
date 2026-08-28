import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/vendor.dart';
import '../services/api_mappers.dart';

const _kCartKey = 'nestly_cart_v1';

class CartProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final List<CartItem> _items = [];
  String? _vendorId;
  Vendor? _vendor;
  String? _couponCode;
  double _couponDiscount = 0;
  bool _restored = false;

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
    _changed();
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
    _changed();
    return true;
  }

  void increment(String cartItemId) {
    final i = _items.indexWhere((e) => e.id == cartItemId);
    if (i < 0) return;
    _items[i] = _items[i].copyWith(quantity: _items[i].quantity + 1);
    _changed();
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
    _changed();
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
    _changed();
  }

  void removeItem(String cartItemId) {
    _items.removeWhere((e) => e.id == cartItemId);
    if (_items.isEmpty) {
      _vendorId = null;
      _vendor = null;
      _couponCode = null;
      _couponDiscount = 0;
    }
    _changed();
  }

  void clear() {
    _items.clear();
    _vendorId = null;
    _vendor = null;
    _couponCode = null;
    _couponDiscount = 0;
    _changed();
  }

  String? applyCoupon(String code) {
    final c = code.trim().toUpperCase();
    if (isEmpty) return 'Cart is empty';

    switch (c) {
      case 'NESTLY20':
      case 'HOMEFOODS20':
        _couponCode = 'NESTLY20';
        _couponDiscount = (itemTotal * 0.2).clamp(0, 100);
        _changed();
        return null;
      case 'FLAT50':
        if (itemTotal < 199) return 'Minimum order ₹199 required';
        _couponCode = c;
        _couponDiscount = 50;
        _changed();
        return null;
      case 'FIRST100':
        _couponCode = c;
        _couponDiscount = 100.clamp(0, itemTotal).toDouble();
        _changed();
        return null;
      default:
        return 'Invalid coupon code';
    }
  }

  void removeCoupon() {
    _couponCode = null;
    _couponDiscount = 0;
    _changed();
  }

  void _changed() {
    notifyListeners();
    _persist();
  }

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCartKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final items = (map['items'] as List? ?? [])
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return CartItem(
              id: m['id'] as String? ?? const Uuid().v4(),
              product: productFromJson(
                Map<String, dynamic>.from(m['product'] as Map),
              ),
              quantity: (m['quantity'] as num?)?.toInt() ?? 1,
              selectedSize: m['selectedSize'] as String?,
              specialInstructions: m['specialInstructions'] as String?,
            );
          })
          .toList();
      if (items.isEmpty) return;
      _items
        ..clear()
        ..addAll(items);
      _vendorId = map['vendorId'] as String?;
      if (map['vendor'] is Map) {
        _vendor = vendorFromJson(Map<String, dynamic>.from(map['vendor'] as Map));
      }
      _couponCode = map['couponCode'] as String?;
      _couponDiscount = (map['couponDiscount'] as num?)?.toDouble() ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_items.isEmpty) {
        await prefs.remove(_kCartKey);
        return;
      }
      final payload = {
        'vendorId': _vendorId,
        if (_vendor != null) 'vendor': vendorToJson(_vendor!),
        'couponCode': _couponCode,
        'couponDiscount': _couponDiscount,
        'items': _items
            .map((i) => {
                  'id': i.id,
                  'quantity': i.quantity,
                  'selectedSize': i.selectedSize,
                  'specialInstructions': i.specialInstructions,
                  'product': productToJson(i.product),
                })
            .toList(),
      };
      await prefs.setString(_kCartKey, jsonEncode(payload));
    } catch (_) {}
  }
}
