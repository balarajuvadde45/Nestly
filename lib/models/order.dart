import 'cart_item.dart';

enum OrderStatus {
  placed,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

class Address {
  final String id;
  final String label;
  final String fullAddress;
  final String area;
  final String city;
  final String pincode;
  final String? landmark;
  final bool isDefault;
  final double? lat;
  final double? lng;

  const Address({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.area,
    required this.city,
    required this.pincode,
    this.landmark,
    this.isDefault = false,
    this.lat,
    this.lng,
  });

  String get short => '$area, $city';

  bool get isPlaceholder =>
      fullAddress.toLowerCase().contains('please update') ||
      fullAddress.trim().isEmpty;

  Address copyWith({
    String? id,
    String? label,
    String? fullAddress,
    String? area,
    String? city,
    String? pincode,
    String? landmark,
    bool? isDefault,
    double? lat,
    double? lng,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      area: area ?? this.area,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

class OrderEvent {
  final String message;
  final DateTime time;
  const OrderEvent({required this.message, required this.time});
}

class Order {
  final String id;
  final String vendorId;
  final String vendorName;
  final List<OrderEvent> events;
  final List<CartItem> items;
  final OrderStatus status;
  final DateTime placedAt;
  final Address address;
  final double itemTotal;
  final double deliveryFee;
  final double platformFee;
  final double tax;
  final double discount;
  final double grandTotal;
  final String paymentMethod;
  final String? deliveryPartner;
  final DateTime? estimatedDelivery;
  final String? couponCode;
  final double? riderLat;
  final double? riderLng;
  final double? vendorLat;
  final double? vendorLng;

  const Order({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    this.events = const [],
    required this.items,
    required this.status,
    required this.placedAt,
    required this.address,
    required this.itemTotal,
    required this.deliveryFee,
    required this.platformFee,
    required this.tax,
    this.discount = 0,
    required this.grandTotal,
    required this.paymentMethod,
    this.deliveryPartner,
    this.estimatedDelivery,
    this.couponCode,
    this.riderLat,
    this.riderLng,
    this.vendorLat,
    this.vendorLng,
  });

  String get statusLabel {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive =>
      status != OrderStatus.delivered && status != OrderStatus.cancelled;

  bool get canTrack =>
      status == OrderStatus.outForDelivery ||
      status == OrderStatus.preparing ||
      status == OrderStatus.confirmed ||
      status == OrderStatus.placed;

  Order copyWith({
    OrderStatus? status,
    double? riderLat,
    double? riderLng,
    String? deliveryPartner,
  }) {
    return Order(
      id: id,
      vendorId: vendorId,
      vendorName: vendorName,
      events: events,
      items: items,
      status: status ?? this.status,
      placedAt: placedAt,
      address: address,
      itemTotal: itemTotal,
      deliveryFee: deliveryFee,
      platformFee: platformFee,
      tax: tax,
      discount: discount,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      deliveryPartner: deliveryPartner ?? this.deliveryPartner,
      estimatedDelivery: estimatedDelivery,
      couponCode: couponCode,
      riderLat: riderLat ?? this.riderLat,
      riderLng: riderLng ?? this.riderLng,
      vendorLat: vendorLat,
      vendorLng: vendorLng,
    );
  }
}
