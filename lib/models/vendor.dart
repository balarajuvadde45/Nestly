enum VendorType { homeCook, cloudKitchen, homeBusiness, boutique }

class Vendor {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String imageUrl;
  final String coverUrl;
  final VendorType type;
  final double rating;
  final int reviewCount;
  final int deliveryTimeMins;
  final double distanceKm;
  final String area;
  final String city;
  final List<String> categories;
  final List<String> tags;
  final bool isOpen;
  final bool isPureVeg;
  final bool freeDelivery;
  final double? minOrder;
  final String? offerText;
  final int orderCount;
  final double lat;
  final double lng;
  final String? ownerId;

  const Vendor({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.imageUrl,
    required this.coverUrl,
    required this.type,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTimeMins,
    required this.distanceKm,
    required this.area,
    this.city = 'Hyderabad',
    this.categories = const [],
    this.tags = const [],
    this.isOpen = true,
    this.isPureVeg = false,
    this.freeDelivery = false,
    this.minOrder,
    this.offerText,
    this.orderCount = 0,
    this.lat = 17.4486,
    this.lng = 78.3908,
    this.ownerId,
  });

  String get typeLabel {
    switch (type) {
      case VendorType.homeCook:
        return 'Home Kitchen';
      case VendorType.cloudKitchen:
        return 'Cloud Kitchen';
      case VendorType.homeBusiness:
        return 'Home Business';
      case VendorType.boutique:
        return 'Home Boutique';
    }
  }

  Vendor copyWith({
    bool? isOpen,
    String? offerText,
    String? name,
    String? tagline,
    String? description,
  }) {
    return Vendor(
      id: id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      imageUrl: imageUrl,
      coverUrl: coverUrl,
      type: type,
      rating: rating,
      reviewCount: reviewCount,
      deliveryTimeMins: deliveryTimeMins,
      distanceKm: distanceKm,
      area: area,
      city: city,
      categories: categories,
      tags: tags,
      isOpen: isOpen ?? this.isOpen,
      isPureVeg: isPureVeg,
      freeDelivery: freeDelivery,
      minOrder: minOrder,
      offerText: offerText ?? this.offerText,
      orderCount: orderCount,
      lat: lat,
      lng: lng,
      ownerId: ownerId,
    );
  }
}
