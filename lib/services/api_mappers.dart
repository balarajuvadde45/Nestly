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
    case 'local_grocery_store':
      return Icons.local_grocery_store_rounded;
    case 'inventory_2':
      return Icons.inventory_2_rounded;
    case 'local_mall':
      return Icons.local_mall_rounded;
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
    case 'FOOD_OUTLET':
      return VendorType.foodOutlet;
    case 'PICKLES_AND_PACKAGED_FOOD':
      return VendorType.picklesAndPackagedFood;
    case 'SWEETS_SNACKS':
      return VendorType.sweetsSnacks;
    case 'FMCG_DISTRIBUTOR':
      return VendorType.fmcgDistributor;
    case 'HANDMADE_PRODUCTS':
      return VendorType.handmadeProducts;
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
    case 'FMCG':
      return ProductType.fmcg;
    case 'PERSONAL_CARE':
      return ProductType.personalCare;
    case 'HOME_CARE':
      return ProductType.homeCare;
    case 'BEVERAGE':
      return ProductType.beverage;
    case 'READY_TO_COOK':
      return ProductType.readyToCook;
    case 'SAREE':
      return ProductType.saree;
    case 'ACCESSORY':
      return ProductType.accessory;
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

String vendorTypeToApi(VendorType t) {
  switch (t) {
    case VendorType.cloudKitchen:
      return 'CLOUD_KITCHEN';
    case VendorType.homeBusiness:
      return 'HOME_BUSINESS';
    case VendorType.boutique:
      return 'BOUTIQUE';
    case VendorType.foodOutlet:
      return 'FOOD_OUTLET';
    case VendorType.picklesAndPackagedFood:
      return 'PICKLES_AND_PACKAGED_FOOD';
    case VendorType.sweetsSnacks:
      return 'SWEETS_SNACKS';
    case VendorType.fmcgDistributor:
      return 'FMCG_DISTRIBUTOR';
    case VendorType.handmadeProducts:
      return 'HANDMADE_PRODUCTS';
    case VendorType.homeCook:
      return 'HOME_COOK';
  }
}

String productTypeToApi(ProductType t) {
  switch (t) {
    case ProductType.pickle:
      return 'PICKLE';
    case ProductType.clothes:
      return 'CLOTHES';
    case ProductType.snack:
      return 'SNACK';
    case ProductType.sweet:
      return 'SWEET';
    case ProductType.grocery:
      return 'GROCERY';
    case ProductType.fmcg:
      return 'FMCG';
    case ProductType.personalCare:
      return 'PERSONAL_CARE';
    case ProductType.homeCare:
      return 'HOME_CARE';
    case ProductType.beverage:
      return 'BEVERAGE';
    case ProductType.readyToCook:
      return 'READY_TO_COOK';
    case ProductType.saree:
      return 'SAREE';
    case ProductType.accessory:
      return 'ACCESSORY';
    case ProductType.other:
      return 'OTHER';
    case ProductType.food:
      return 'FOOD';
  }
}

DateTime? _dateFromJson(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

List<WholesaleTier> _wholesaleTiersFromJson(dynamic value) {
  if (value is! List) return const [];
  final tiers = <WholesaleTier>[];
  for (final entry in value) {
    if (entry is! Map) continue;
    final map = Map<String, dynamic>.from(entry);
    final minQuantity = (map['minQuantity'] as num?)?.toInt();
    final unitPrice = (map['unitPrice'] as num?)?.toDouble();
    if (minQuantity == null || unitPrice == null) continue;
    tiers.add(
      WholesaleTier(
        minQuantity: minQuantity,
        unitPrice: unitPrice,
        label: map['label'] as String?,
      ),
    );
  }
  tiers.sort((a, b) => a.minQuantity.compareTo(b.minQuantity));
  return tiers;
}

Map<String, dynamic> vendorToJson(Vendor v) {
  return {
    'id': v.id,
    'name': v.name,
    'tagline': v.tagline,
    'description': v.description,
    'imageUrl': v.imageUrl,
    'coverUrl': v.coverUrl,
    'type': vendorTypeToApi(v.type),
    'rating': v.rating,
    'reviewCount': v.reviewCount,
    'deliveryTimeMins': v.deliveryTimeMins,
    'distanceKm': v.distanceKm,
    'area': v.area,
    'city': v.city,
    'businessAddress': v.businessAddress,
    'pincode': v.pincode,
    'premisesType': v.premisesType,
    'supportPhone': v.supportPhone,
    'supportEmail': v.supportEmail,
    'gstin': v.gstin,
    'pan': v.pan,
    'fssaiLicense': v.fssaiLicense,
    'fssaiExpiry': v.fssaiExpiry?.toIso8601String(),
    'kycStatus': v.kycStatus,
    'bankAccountLast4': v.bankAccountLast4,
    'bankVerified': v.bankVerified,
    'fulfillmentModes': v.fulfillmentModes,
    'serviceRadiusKm': v.serviceRadiusKm,
    'gstInvoiceAvailable': v.gstInvoiceAvailable,
    'acceptsWholesale': v.acceptsWholesale,
    'categories': v.categories,
    'tags': v.tags,
    'isApproved': v.isApproved,
    'isOpen': v.isOpen,
    'isPureVeg': v.isPureVeg,
    'freeDelivery': v.freeDelivery,
    'minOrder': v.minOrder,
    'offerText': v.offerText,
    'orderCount': v.orderCount,
    'lat': v.lat,
    'lng': v.lng,
    'ownerId': v.ownerId,
  };
}

Map<String, dynamic> productToJson(Product p) {
  return {
    'id': p.id,
    'vendorId': p.vendorId,
    'name': p.name,
    'description': p.description,
    'price': p.price,
    'mrp': p.mrp,
    'brandName': p.brandName,
    'sku': p.sku,
    'unitLabel': p.unitLabel,
    'minOrderQuantity': p.minOrderQuantity,
    'casePackQuantity': p.casePackQuantity,
    'maxOrderQuantity': p.maxOrderQuantity,
    'stockQuantity': p.stockQuantity,
    'hsnCode': p.hsnCode,
    'gstRate': p.gstRate,
    'batchNumber': p.batchNumber,
    'manufactureDate': p.manufactureDate?.toIso8601String(),
    'expiryDate': p.expiryDate?.toIso8601String(),
    'shelfLifeDays': p.shelfLifeDays,
    'manufacturerName': p.manufacturerName,
    'packerName': p.packerName,
    'originCountry': p.originCountry,
    'fssaiLicense': p.fssaiLicense,
    'isReturnable': p.isReturnable,
    'returnWindowDays': p.returnWindowDays,
    'madeToOrder': p.madeToOrder,
    'dispatchTimeDays': p.dispatchTimeDays,
    'wholesaleTiers': p.wholesaleTiers.map((e) => e.toJson()).toList(),
    'colors': p.colors,
    'material': p.material,
    'imageUrl': p.imageUrl,
    'type': productTypeToApi(p.type),
    'isVeg': p.isVeg,
    'isAvailable': p.isAvailable,
    'rating': p.rating,
    'reviewCount': p.reviewCount,
    'tags': p.tags,
    'categoryId': p.categoryId,
    'prepTimeMins': p.prepTimeMins,
    'sizes': p.sizes,
  };
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
    businessAddress: j['businessAddress'] as String?,
    pincode: j['pincode'] as String?,
    premisesType: j['premisesType'] as String? ?? 'BUSINESS_PLACE',
    supportPhone: j['supportPhone'] as String?,
    supportEmail: j['supportEmail'] as String?,
    gstin: j['gstin'] as String?,
    pan: j['pan'] as String?,
    fssaiLicense: j['fssaiLicense'] as String?,
    fssaiExpiry: _dateFromJson(j['fssaiExpiry']),
    kycStatus: j['kycStatus'] as String? ?? 'PENDING',
    bankAccountLast4: j['bankAccountLast4'] as String?,
    bankVerified: j['bankVerified'] as bool? ?? false,
    fulfillmentModes:
        (j['fulfillmentModes'] as List?)?.map((e) => e.toString()).toList() ??
        const ['LOCAL_DELIVERY'],
    serviceRadiusKm: (j['serviceRadiusKm'] as num?)?.toDouble() ?? 5,
    gstInvoiceAvailable: j['gstInvoiceAvailable'] as bool? ?? false,
    acceptsWholesale: j['acceptsWholesale'] as bool? ?? false,
    categories:
        (j['categories'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    isApproved: j['isApproved'] as bool? ?? false,
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
    brandName: j['brandName'] as String?,
    sku: j['sku'] as String?,
    unitLabel: j['unitLabel'] as String?,
    minOrderQuantity: (j['minOrderQuantity'] as num?)?.toInt() ?? 1,
    casePackQuantity: (j['casePackQuantity'] as num?)?.toInt(),
    maxOrderQuantity: (j['maxOrderQuantity'] as num?)?.toInt(),
    stockQuantity: (j['stockQuantity'] as num?)?.toInt(),
    hsnCode: j['hsnCode'] as String?,
    gstRate: (j['gstRate'] as num?)?.toDouble(),
    batchNumber: j['batchNumber'] as String?,
    manufactureDate: _dateFromJson(j['manufactureDate']),
    expiryDate: _dateFromJson(j['expiryDate']),
    shelfLifeDays: (j['shelfLifeDays'] as num?)?.toInt(),
    manufacturerName: j['manufacturerName'] as String?,
    packerName: j['packerName'] as String?,
    originCountry: j['originCountry'] as String?,
    fssaiLicense: j['fssaiLicense'] as String?,
    isReturnable: j['isReturnable'] as bool? ?? false,
    returnWindowDays: (j['returnWindowDays'] as num?)?.toInt(),
    madeToOrder: j['madeToOrder'] as bool? ?? false,
    dispatchTimeDays: (j['dispatchTimeDays'] as num?)?.toInt(),
    wholesaleTiers: _wholesaleTiersFromJson(j['wholesaleTiers']),
    colors:
        (j['colors'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    material: j['material'] as String?,
    imageUrl: j['imageUrl'] as String? ?? '',
    type: productTypeFromApi(j['type'] as String?),
    isVeg: j['isVeg'] as bool? ?? true,
    isAvailable: j['isAvailable'] as bool? ?? true,
    rating: (j['rating'] as num?)?.toDouble() ?? 0,
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
  final addresses =
      (j['addresses'] as List?)
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
    favoriteVendorIds: (j['favoriteVendorIds'] as List? ?? [])
        .map((e) => e.toString())
        .toList(),
    favoriteProductIds: (j['favoriteProductIds'] as List? ?? [])
        .map((e) => e.toString())
        .toList(),
  );
}

CartItem orderItemFromJson(Map<String, dynamic> j) {
  final product = Product(
    id: j['productId'] as String? ?? '',
    vendorId: '',
    name: j['productName'] as String? ?? '',
    description: '',
    price: (j['unitPrice'] as num?)?.toDouble() ?? 0,
    unitLabel: j['unitLabel'] as String?,
    hsnCode: j['hsnCode'] as String?,
    gstRate: (j['gstRate'] as num?)?.toDouble(),
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
  final items =
      (j['items'] as List?)
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
    events: (j['events'] as List? ?? [])
        .whereType<Map>()
        .map(
          (e) => OrderEvent(
            message: e['message'] as String? ?? '',
            time: DateTime.parse(e['createdAt'] as String),
          ),
        )
        .toList(),
    items: items,
    status: orderStatusFromApi(j['status'] as String?),
    placedAt:
        DateTime.tryParse(j['placedAt'] as String? ?? '') ?? DateTime.now(),
    address: address,
    itemTotal: (j['itemTotal'] as num?)?.toDouble() ?? 0,
    deliveryFee: (j['deliveryFee'] as num?)?.toDouble() ?? 0,
    platformFee: (j['platformFee'] as num?)?.toDouble() ?? 0,
    tax: (j['tax'] as num?)?.toDouble() ?? 0,
    discount: (j['discount'] as num?)?.toDouble() ?? 0,
    grandTotal: (j['grandTotal'] as num?)?.toDouble() ?? 0,
    paymentMethod: j['paymentMethod'] as String? ?? 'COD',
    deliveryPartner: j['deliveryPartner'] as String?,
    estimatedDelivery: DateTime.tryParse(
      j['estimatedDelivery'] as String? ?? '',
    ),
    couponCode: j['couponCode'] as String?,
    riderLat: (j['riderLat'] as num?)?.toDouble(),
    riderLng: (j['riderLng'] as num?)?.toDouble(),
    vendorLat: (j['vendorLat'] as num?)?.toDouble(),
    vendorLng: (j['vendorLng'] as num?)?.toDouble(),
  );
}
