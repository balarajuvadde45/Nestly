enum VendorType {
  homeCook,
  cloudKitchen,
  homeBusiness,
  boutique,
  foodOutlet,
  picklesAndPackagedFood,
  sweetsSnacks,
  fmcgDistributor,
  handmadeProducts,
}

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
  final String? businessAddress;
  final String? pincode;
  final String premisesType;
  final String? supportPhone;
  final String? supportEmail;
  final String? gstin;
  final String? pan;
  final String? fssaiLicense;
  final DateTime? fssaiExpiry;
  final String kycStatus;
  final String? bankAccountLast4;
  final bool bankVerified;
  final List<String> fulfillmentModes;
  final double serviceRadiusKm;
  final bool gstInvoiceAvailable;
  final bool acceptsWholesale;
  final List<String> categories;
  final List<String> tags;
  final bool isApproved;
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
    this.businessAddress,
    this.pincode,
    this.premisesType = 'BUSINESS_PLACE',
    this.supportPhone,
    this.supportEmail,
    this.gstin,
    this.pan,
    this.fssaiLicense,
    this.fssaiExpiry,
    this.kycStatus = 'PENDING',
    this.bankAccountLast4,
    this.bankVerified = false,
    this.fulfillmentModes = const ['LOCAL_DELIVERY'],
    this.serviceRadiusKm = 5,
    this.gstInvoiceAvailable = false,
    this.acceptsWholesale = false,
    this.categories = const [],
    this.tags = const [],
    this.isApproved = false,
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

  bool get isVerified => kycStatus.toUpperCase() == 'VERIFIED';

  String get typeLabel {
    switch (type) {
      case VendorType.homeCook:
        return 'Home kitchen';
      case VendorType.cloudKitchen:
        return 'Cloud kitchen';
      case VendorType.homeBusiness:
        return 'Local business';
      case VendorType.boutique:
        return 'Boutique';
      case VendorType.foodOutlet:
        return 'Food outlet';
      case VendorType.picklesAndPackagedFood:
        return 'Pickles & packaged food';
      case VendorType.sweetsSnacks:
        return 'Sweets & snacks';
      case VendorType.fmcgDistributor:
        return 'FMCG wholesaler';
      case VendorType.handmadeProducts:
        return 'Handmade products';
    }
  }

  Vendor copyWith({
    bool? isOpen,
    String? offerText,
    String? name,
    String? tagline,
    String? description,
    bool? freeDelivery,
    bool? gstInvoiceAvailable,
    bool? acceptsWholesale,
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
      businessAddress: businessAddress,
      pincode: pincode,
      premisesType: premisesType,
      supportPhone: supportPhone,
      supportEmail: supportEmail,
      gstin: gstin,
      pan: pan,
      fssaiLicense: fssaiLicense,
      fssaiExpiry: fssaiExpiry,
      kycStatus: kycStatus,
      bankAccountLast4: bankAccountLast4,
      bankVerified: bankVerified,
      fulfillmentModes: fulfillmentModes,
      serviceRadiusKm: serviceRadiusKm,
      gstInvoiceAvailable: gstInvoiceAvailable ?? this.gstInvoiceAvailable,
      acceptsWholesale: acceptsWholesale ?? this.acceptsWholesale,
      categories: categories,
      tags: tags,
      isOpen: isOpen ?? this.isOpen,
      isPureVeg: isPureVeg,
      freeDelivery: freeDelivery ?? this.freeDelivery,
      minOrder: minOrder,
      offerText: offerText ?? this.offerText,
      orderCount: orderCount,
      lat: lat,
      lng: lng,
      ownerId: ownerId,
    );
  }
}
