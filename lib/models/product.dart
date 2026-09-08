enum ProductType {
  food,
  pickle,
  clothes,
  snack,
  sweet,
  grocery,
  fmcg,
  personalCare,
  homeCare,
  beverage,
  readyToCook,
  saree,
  accessory,
  other,
}

class WholesaleTier {
  final int minQuantity;
  final double unitPrice;
  final String? label;

  const WholesaleTier({
    required this.minQuantity,
    required this.unitPrice,
    this.label,
  });

  String get displayLabel =>
      label == null || label!.isEmpty ? '$minQuantity+' : label!;

  Map<String, dynamic> toJson() => {
    'minQuantity': minQuantity,
    'unitPrice': unitPrice,
    if (label != null && label!.isNotEmpty) 'label': label,
  };
}

class Product {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final double price;
  final double? mrp;
  final String? brandName;
  final String? sku;
  final String? unitLabel;
  final int minOrderQuantity;
  final int? casePackQuantity;
  final int? maxOrderQuantity;
  final int? stockQuantity;
  final String? hsnCode;
  final double? gstRate;
  final String? batchNumber;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final int? shelfLifeDays;
  final String? manufacturerName;
  final String? packerName;
  final String? originCountry;
  final String? fssaiLicense;
  final bool isReturnable;
  final int? returnWindowDays;
  final bool madeToOrder;
  final int? dispatchTimeDays;
  final List<WholesaleTier> wholesaleTiers;
  final List<String> colors;
  final String? material;
  final String imageUrl;
  final ProductType type;
  final bool isVeg;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final String? categoryId;
  final int? prepTimeMins;
  final List<String> sizes;
  final Map<String, dynamic>? extras;

  const Product({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.price,
    this.mrp,
    this.brandName,
    this.sku,
    this.unitLabel,
    this.minOrderQuantity = 1,
    this.casePackQuantity,
    this.maxOrderQuantity,
    this.stockQuantity,
    this.hsnCode,
    this.gstRate,
    this.batchNumber,
    this.manufactureDate,
    this.expiryDate,
    this.shelfLifeDays,
    this.manufacturerName,
    this.packerName,
    this.originCountry,
    this.fssaiLicense,
    this.isReturnable = false,
    this.returnWindowDays,
    this.madeToOrder = false,
    this.dispatchTimeDays,
    this.wholesaleTiers = const [],
    this.colors = const [],
    this.material,
    required this.imageUrl,
    this.type = ProductType.food,
    this.isVeg = true,
    this.isAvailable = true,
    this.rating = 4.0,
    this.reviewCount = 0,
    this.tags = const [],
    this.categoryId,
    this.prepTimeMins,
    this.sizes = const [],
    this.extras,
  });

  bool get hasDiscount => mrp != null && mrp! > price;

  double get discountPercent {
    if (!hasDiscount) return 0;
    return ((mrp! - price) / mrp! * 100);
  }

  bool get isPackagedFood =>
      type == ProductType.pickle ||
      type == ProductType.snack ||
      type == ProductType.sweet ||
      type == ProductType.readyToCook ||
      type == ProductType.grocery ||
      type == ProductType.beverage;

  bool get isFashion =>
      type == ProductType.clothes ||
      type == ProductType.saree ||
      type == ProductType.accessory;

  bool get hasWholesalePricing =>
      wholesaleTiers.isNotEmpty ||
      minOrderQuantity > 1 ||
      (casePackQuantity ?? 1) > 1;

  int get minCartQuantity {
    final minimum = minOrderQuantity < 1 ? 1 : minOrderQuantity;
    return ((minimum + quantityStep - 1) ~/ quantityStep) * quantityStep;
  }

  bool get canOrder =>
      isAvailable &&
      (stockQuantity == null || stockQuantity! >= minCartQuantity) &&
      (maxOrderQuantity == null || maxOrderQuantity! >= minCartQuantity) &&
      (expiryDate == null || expiryDate!.isAfter(DateTime.now()));

  int get quantityStep {
    final step = casePackQuantity ?? 1;
    return step < 1 ? 1 : step;
  }

  int normalizeQuantity(int requested) {
    final step = quantityStep;
    var minimum = minCartQuantity;
    if (step > 1) {
      final remainder = minimum % step;
      if (remainder != 0) minimum += step - remainder;
    }

    var qty = requested < minimum ? minimum : requested;
    if (step > 1) {
      final remainder = qty % step;
      if (remainder != 0) qty += step - remainder;
    }
    final limit = stockQuantity == null
        ? maxOrderQuantity
        : maxOrderQuantity == null
        ? stockQuantity
        : (stockQuantity! < maxOrderQuantity!
              ? stockQuantity
              : maxOrderQuantity);
    if (limit != null && qty > limit) {
      var capped = limit;
      if (step > 1) {
        capped = (capped ~/ step) * step;
      }
      return capped < minimum ? minimum : capped;
    }
    return qty;
  }

  double unitPriceForQuantity(int quantity) {
    var unitPrice = price;
    var threshold = 0;
    for (final tier in wholesaleTiers) {
      if (quantity >= tier.minQuantity && tier.minQuantity >= threshold) {
        threshold = tier.minQuantity;
        unitPrice = tier.unitPrice;
      }
    }
    return unitPrice;
  }

  String get typeLabel {
    switch (type) {
      case ProductType.food:
        return 'Food';
      case ProductType.pickle:
        return 'Pickle';
      case ProductType.clothes:
        return 'Clothes';
      case ProductType.snack:
        return 'Snack';
      case ProductType.sweet:
        return 'Sweet';
      case ProductType.grocery:
        return 'Grocery';
      case ProductType.fmcg:
        return 'FMCG';
      case ProductType.personalCare:
        return 'Personal care';
      case ProductType.homeCare:
        return 'Home care';
      case ProductType.beverage:
        return 'Beverage';
      case ProductType.readyToCook:
        return 'Ready to cook';
      case ProductType.saree:
        return 'Saree';
      case ProductType.accessory:
        return 'Accessory';
      case ProductType.other:
        return 'Other';
    }
  }

  Product copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    double? price,
    double? mrp,
    String? brandName,
    String? sku,
    String? unitLabel,
    int? minOrderQuantity,
    int? casePackQuantity,
    int? maxOrderQuantity,
    int? stockQuantity,
    String? hsnCode,
    double? gstRate,
    String? batchNumber,
    DateTime? manufactureDate,
    DateTime? expiryDate,
    int? shelfLifeDays,
    String? manufacturerName,
    String? packerName,
    String? originCountry,
    String? fssaiLicense,
    bool? isReturnable,
    int? returnWindowDays,
    bool? madeToOrder,
    int? dispatchTimeDays,
    List<WholesaleTier>? wholesaleTiers,
    List<String>? colors,
    String? material,
    String? imageUrl,
    ProductType? type,
    bool? isVeg,
    bool? isAvailable,
    double? rating,
    int? reviewCount,
    List<String>? tags,
    String? categoryId,
    int? prepTimeMins,
    List<String>? sizes,
    Map<String, dynamic>? extras,
  }) {
    return Product(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      brandName: brandName ?? this.brandName,
      sku: sku ?? this.sku,
      unitLabel: unitLabel ?? this.unitLabel,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      casePackQuantity: casePackQuantity ?? this.casePackQuantity,
      maxOrderQuantity: maxOrderQuantity ?? this.maxOrderQuantity,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      hsnCode: hsnCode ?? this.hsnCode,
      gstRate: gstRate ?? this.gstRate,
      batchNumber: batchNumber ?? this.batchNumber,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      expiryDate: expiryDate ?? this.expiryDate,
      shelfLifeDays: shelfLifeDays ?? this.shelfLifeDays,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      packerName: packerName ?? this.packerName,
      originCountry: originCountry ?? this.originCountry,
      fssaiLicense: fssaiLicense ?? this.fssaiLicense,
      isReturnable: isReturnable ?? this.isReturnable,
      returnWindowDays: returnWindowDays ?? this.returnWindowDays,
      madeToOrder: madeToOrder ?? this.madeToOrder,
      dispatchTimeDays: dispatchTimeDays ?? this.dispatchTimeDays,
      wholesaleTiers: wholesaleTiers ?? this.wholesaleTiers,
      colors: colors ?? this.colors,
      material: material ?? this.material,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      isVeg: isVeg ?? this.isVeg,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      tags: tags ?? this.tags,
      categoryId: categoryId ?? this.categoryId,
      prepTimeMins: prepTimeMins ?? this.prepTimeMins,
      sizes: sizes ?? this.sizes,
      extras: extras ?? this.extras,
    );
  }
}
