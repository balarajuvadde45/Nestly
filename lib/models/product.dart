enum ProductType { food, pickle, clothes, snack, sweet, grocery, other }

class Product {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final double price;
  final double? mrp;
  final String imageUrl;
  final ProductType type;
  final bool isVeg;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final String? categoryId;
  final int? prepTimeMins;
  final List<String> sizes; // for clothes
  final Map<String, dynamic>? extras;

  const Product({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.price,
    this.mrp,
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

  Product copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    double? price,
    double? mrp,
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
