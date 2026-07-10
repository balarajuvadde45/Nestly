class BannerItem {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? actionRoute;
  final String? categoryId;
  final String? vendorId;

  const BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.actionRoute,
    this.categoryId,
    this.vendorId,
  });
}
