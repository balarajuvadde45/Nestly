import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/rating_chip.dart';

class VendorScreen extends StatefulWidget {
  final String vendorId;

  const VendorScreen({super.key, required this.vendorId});

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  bool _vegOnly = false;
  String _query = '';
  bool _loadingProducts = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final catalog = context.read<CatalogProvider>();
      await catalog.fetchVendor(widget.vendorId);
      await catalog.fetchProductsForVendor(widget.vendorId);
      if (mounted) setState(() => _loadingProducts = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final auth = context.watch<AuthProvider>();
    final vendor = catalog.vendorById(widget.vendorId);
    final pad = Responsive.contentPadding(context);

    if (vendor == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _loadingProducts
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(
                icon: Icons.store_outlined,
                title: 'Seller not found',
              ),
      );
    }

    var products = catalog.productsForVendor(vendor.id);
    if (_vegOnly) products = products.where((p) => p.isVeg).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();
    }

    final isFav = auth.isVendorFavorite(vendor.id);
    final wide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: wide ? 260 : 200,
            pinned: true,
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.primary : Colors.white,
                ),
                onPressed: () => auth.toggleFavoriteVendor(vendor.id),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share link copied (demo)')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    url: vendor.coverUrl,
                    placeholderIcon: Icons.storefront_rounded,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: pad,
                    right: pad,
                    bottom: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AppNetworkImage(
                            url: vendor.imageUrl,
                            width: 72,
                            height: 72,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                vendor.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                              Text(
                                vendor.tagline,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Responsive.constrained(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(pad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RatingChip(
                              rating: vendor.rating,
                              count: vendor.reviewCount,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                vendor.typeLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          vendor.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _infoChip(Icons.schedule_rounded,
                                Formatters.deliveryTime(vendor.deliveryTimeMins)),
                            _infoChip(Icons.location_on_outlined,
                                '${Formatters.distance(vendor.distanceKm)} • ${vendor.area}'),
                            if (vendor.freeDelivery)
                              _infoChip(Icons.delivery_dining_rounded,
                                  'Free delivery',
                                  color: AppColors.freeDelivery),
                            if (vendor.isPureVeg)
                              _infoChip(Icons.eco_rounded, 'Pure Veg',
                                  color: AppColors.veg),
                          ],
                        ),
                        if (vendor.offerText != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EAF6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_offer_rounded,
                                    color: Color(0xFF1A237E), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    vendor.offerText!,
                                    style: const TextStyle(
                                      color: Color(0xFF1A237E),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (vendor.tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            children: vendor.tags
                                .map((t) => Chip(
                                      label: Text(t,
                                          style: const TextStyle(fontSize: 11)),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 16, pad, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search in menu…',
                              prefixIcon: Icon(Icons.search_rounded),
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilterChip(
                          label: const Text('Veg'),
                          selected: _vegOnly,
                          onSelected: (v) => setState(() => _vegOnly = v),
                          selectedColor: AppColors.accentLight,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 8, pad, 100),
                    child: _loadingProducts
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : products.isEmpty
                        ? const EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'No products yet',
                            subtitle:
                                'This seller has not added items. Check back soon.',
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final useGrid = constraints.maxWidth > 500;
                              if (!useGrid) {
                                return Column(
                                  children: products
                                      .map((p) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: ProductCard(
                                              product: p,
                                              compact: true,
                                            ),
                                          ))
                                      .toList(),
                                );
                              }
                              final cols = Responsive.gridColumns(context,
                                  mobile: 2, tablet: 3, desktop: 4);
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: products.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.62,
                                ),
                                itemBuilder: (context, i) =>
                                    ProductCard(product: products[i]),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
