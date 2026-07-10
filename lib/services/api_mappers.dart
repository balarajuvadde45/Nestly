import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/banner_item.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/vendor.dart';

IconData iconFromKey(String? key) {
  switch (key) {
    case 'restaurant_menu':
      return Icons.restaurant_menu_rounded;
    case 'storefront':
      return Icons.storefront_rounded;
    case 'spa':
      return Icons.spa_rounded;
    case 'cake':
      return Icons.cake_rounded;
    case 'checkroom':
      return Icons.checkroom_rounded;
    case 'bakery_dining':
      return Icons.bakery_dining_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'lunch_dining':
      return Icons.lunch_dining_rounded;
    default:
      return Icons.category_rounded;
  }
}

Color colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return AppColors.categoryColors[0];
  final cleaned = hex.replaceAll('#', '');
  try {
    return Color(int.parse('FF$cleaned', radix: 16));
  } catch (_) {
    return AppColors.categoryColors[0];
  }
}

VendorType vendorTypeFromApi(String? t) {
  switch (t) {
    case 'CLOUD_KITCHEN':
      return VendorType.cloudKitchen;
    case 'HOME_BUSINESS':
      return VendorType.homeBusiness;
    case 'BOUTIQUE':
      return VendorType.boutique;
    default:
      return VendorType.homeCook;
  }
}

ProductType productTypeFromApi(String? t) {
  switch (t) {
    case 'PICKLE':
      return ProductType.pickle;
    case 'CLOTHES':
      return ProductType.clothes;
    case 'SNACK':
      return ProductType.snack;
    case 'SWEET':
      return ProductType.sweet;
    case 'GROCERY':
      return ProductType.grocery;
    case 'OTHER':
      return ProductType.other;
    default:
      return ProductType.food;
  }
}

OrderStatus orderStatusFromApi(String? s) {
  switch (s) {
    case 'CONFIRMED':
      return OrderStatus.confirmed;
    case 'PREPARING':
      return OrderStatus.preparing;
    case 'OUT_FOR_DELIVERY':
      return OrderStatus.outForDelivery;
    case 'DELIVERED':
      return OrderStatus.delivered;
    case 'CANCELLED':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.placed;
  }
}

String orderStatusToApi(OrderStatus s) {
  switch (s) {
    case OrderStatus.placed:
      return 'PLACED';
    case OrderStatus.confirmed:
      return 'CONFIRMED';
    case OrderStatus.preparing:
      return 'PREPARING';
    case OrderStatus.outForDelivery:
      return 'OUT_FOR_DELIVERY';
    case OrderStatus.delivered:
      return 'DELIVERED';
    case OrderStatus.cancelled:
      return 'CANCELLED';
  }
}

ShopCategory categoryFromJson(Map<String, dynamic> j) {
  return ShopCategory(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    description: j['description'] as String? ?? '',
    icon: iconFromKey(j['iconKey'] as String?),
    color: colorFromHex(j['colorHex'] as String?),
    imageUrl: j['imageUrl'] as String? ?? '',
    vendorCount: (j['vendorCount'] as num?)?.toInt() ?? 0,
  );
}

BannerItem bannerFromJson(Map<String, dynamic> j) {
  return BannerItem(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    subtitle: j['subtitle'] as String? ?? '',
    imageUrl: j['imageUrl'] as String? ?? '',
    categoryId: j['categoryId'] as String?,
    vendorId: j['vendorId'] as String?,
  );
}

Vendor vendorFromJson(Map<String, dynamic> j) {
  return Vendor(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    tagline: j['tagline'] as String? ?? '',
    description: j['description'] as String? ?? '',
    imageUrl: j['imageUrl'] as String? ?? '',
    coverUrl: j['coverUrl'] as String? ?? '',
    type: vendorTypeFromApi(j['type'] as String?),
    rating: (j['rating'] as num?)?.toDouble() ?? 0,
    reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
    deliveryTimeMins: (j['deliveryTimeMins'] as num?)?.toInt() ?? 40,
    distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
    area: j['area'] as String? ?? '',
    city: j['city'] as String? ?? 'Hyderabad',
    categories: (j['categories'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    isOpen: j['isOpen'] as bool? ?? true,
    isPureVeg: j['isPureVeg'] as bool? ?? false,
    freeDelivery: j['freeDelivery'] as bool? ?? false,
    minOrder: (j['minOrder'] as num?)?.toDouble(),
    offerText: j['offerText'] as String?,
    orderCount: (j['orderCount'] as num?)?.toInt() ?? 0,
    lat: (j['lat'] as num?)?.toDouble() ?? 17.4486,
    lng: (j['lng'] as num?)?.toDouble() ?? 78.3908,
    ownerId: j['ownerId'] as String?,
  );
}

Product productFromJson(Map<String, dynamic> j) {
  return Product(
    id: j['id'] as String,
    vendorId: j['vendorId'] as String,
    name: j['name'] as String? ?? '',
    description: j['description'] as String? ?? '',
    price: (j['price'] as num?)?.toDouble() ?? 0,
    mrp: (j['mrp'] as num?)?.toDouble(),
    imageUrl: j['imageUrl'] as String? ?? '',
    type: productTypeFromApi(j['type'] as String?),
    isVeg: j['isVeg'] as bool? ?? true,
    isAvailable: j['isAvailable'] as bool? ?? true,
    rating: (j['rating'] as num?)?.toDouble() ?? 4,
    reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
    tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    categoryId: j['categoryId'] as String?,
    prepTimeMins: (j['prepTimeMins'] as num?)?.toInt(),
    sizes: (j['sizes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
  );
}

Address addressFromJson(Map<String, dynamic> j) {
  return Address(
    id: j['id'] as String,
    label: j['label'] as String? ?? '',
    fullAddress: j['fullAddress'] as String? ?? '',
    area: j['area'] as String? ?? '',
    city: j['city'] as String? ?? '',
    pincode: j['pincode'] as String? ?? '',
    landmark: j['landmark'] as String?,
    isDefault: j['isDefault'] as bool? ?? false,
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
  );
}

AppUser userFromJson(Map<String, dynamic> j) {
  final addresses = (j['addresses'] as List?)
          ?.map((e) => addressFromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ??
      const [];
  return AppUser(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    email: j['email'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    avatarUrl: j['avatarUrl'] as String?,
    role: j['role'] as String? ?? 'CUSTOMER',
    addresses: addresses,
  );
}

CartItem orderItemFromJson(Map<String, dynamic> j) {
  final product = Product(
    id: j['productId'] as String? ?? '',
    vendorId: '',
    name: j['productName'] as String? ?? '',
    description: '',
    price: (j['unitPrice'] as num?)?.toDouble() ?? 0,
    imageUrl: j['productImage'] as String? ?? '',
    isVeg: j['isVeg'] as bool? ?? true,
  );
  return CartItem(
    id: j['id'] as String? ?? '',
    product: product,
    quantity: (j['quantity'] as num?)?.toInt() ?? 1,
    selectedSize: j['selectedSize'] as String?,
    specialInstructions: j['specialInstructions'] as String?,
  );
}

Order orderFromJson(Map<String, dynamic> j) {
  final items = (j['items'] as List?)
          ?.map((e) => orderItemFromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ??
      <CartItem>[];
  final addressJson = j['address'];
  final address = addressJson is Map
      ? addressFromJson(Map<String, dynamic>.from(addressJson))
      : const Address(
          id: '',
          label: '',
          fullAddress: '',
          area: '',
          city: '',
          pincode: '',
        );

  return Order(
    id: j['id'] as String,
    vendorId: j['vendorId'] as String? ?? '',
    vendorName: j['vendorName'] as String? ?? '',
    items: items,
    status: orderStatusFromApi(j['status'] as String?),
    placedAt: DateTime.tryParse(j['placedAt'] as String? ?? '') ??
        DateTime.now(),
    address: address,
    itemTotal: (j['itemTotal'] as num?)?.toDouble() ?? 0,
    deliveryFee: (j['deliveryFee'] as num?)?.toDouble() ?? 0,
    platformFee: (j['platformFee'] as num?)?.toDouble() ?? 0,
    tax: (j['tax'] as num?)?.toDouble() ?? 0,
    discount: (j['discount'] as num?)?.toDouble() ?? 0,
    grandTotal: (j['grandTotal'] as num?)?.toDouble() ?? 0,
    paymentMethod: j['paymentMethod'] as String? ?? 'COD',
    deliveryPartner: j['deliveryPartner'] as String?,
    estimatedDelivery:
        DateTime.tryParse(j['estimatedDelivery'] as String? ?? ''),
    couponCode: j['couponCode'] as String?,
    riderLat: (j['riderLat'] as num?)?.toDouble(),
    riderLng: (j['riderLng'] as num?)?.toDouble(),
    vendorLat: (j['vendorLat'] as num?)?.toDouble(),
    vendorLng: (j['vendorLng'] as num?)?.toDouble(),
  );
}
