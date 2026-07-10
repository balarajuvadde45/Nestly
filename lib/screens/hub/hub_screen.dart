import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/category_tree.dart';
import '../../models/vendor.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/marketplace_header.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/vendor_card.dart';

/// Hub landing: Food / Pickles / Clothes with subcategories (e.g. Boutiques).
class HubScreen extends StatelessWidget {
  final String hubId;

  const HubScreen({super.key, required this.hubId});

  @override
  Widget build(BuildContext context) {
    final hub = CategoryTree.byId(hubId);
    final catalog = context.watch<CatalogProvider>();
    final pad = Responsive.contentPadding(context);
    final wide = Responsive.isWide(context);

    if (hub == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Category')),
        body: const EmptyState(
          icon: Icons.category_outlined,
          title: 'Hub not found',
        ),
      );
    }

    // Collect products/vendors for all child catalog categories
    final catIds = hub.children
        .map((c) => c.catalogCategoryId)
        .whereType<String>()
        .toSet()
        .toList();

    final vendors = catalog.allVendors
        .where((v) => v.categories.any(catIds.contains))
        .toList();
    final products = catalog.allProducts
        .where((p) => p.categoryId != null && catIds.contains(p.categoryId))
        .toList();

    // Clothes: highlight boutiques
    final boutiques = hub.id == 'hub_clothes'
        ? catalog.allVendors
            .where((v) =>
                v.categories.contains('cat_clothes') ||
                v.type == VendorType.boutique)
            .toList()
        : <Vendor>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          if (wide)
            SliverToBoxAdapter(
              child: MarketplaceHeader(activeHubId: hub.id),
            )
          else
            SliverAppBar(
              pinned: true,
              title: Text(hub.name),
              backgroundColor: Colors.white,
            ),
          SliverToBoxAdapter(
            child: Responsive.constrained(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero
                  Padding(
                    padding: EdgeInsets.all(pad),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: wide ? 200 : 160,
                            width: double.infinity,
                            child: AppNetworkImage(url: hub.imageUrl),
                          ),
                          Container(
                            height: wide ? 200 : 160,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                colors: [
                                  Colors.black.withValues(alpha: 0.75),
                                  Colors.black.withValues(alpha: 0.2),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hub.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: wide ? 28 : 22,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  hub.description,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Subcategories
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: const SectionHeader(
                      title: 'Browse inside',
                      subtitle: 'Choose a specialty — made for home businesses',
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final cols = Responsive.gridColumns(context,
                            mobile: 2, tablet: 3, desktop: 3);
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: hub.children.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.5,
                          ),
                          itemBuilder: (context, i) {
                            final sub = hub.children[i];
                            final isBoutique = sub.id == 'sub_boutiques';
                            return Material(
                              color: isBoutique
                                  ? AppColors.secondaryLight
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  if (sub.catalogCategoryId != null) {
                                    context.push(
                                        '/category/${sub.catalogCategoryId}');
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isBoutique
                                          ? AppColors.secondary
                                              .withValues(alpha: 0.4)
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(sub.icon,
                                          color: isBoutique
                                              ? AppColors.secondary
                                              : AppColors.primary),
                                      const Spacer(),
                                      Text(
                                        sub.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        sub.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Women sellers CTA for clothes
                  if (hub.id == 'hub_clothes') ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Are you a home boutique owner?',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Thousands of women sell kurtis, sarees, kids wear and custom stitching from home. List sizes, photos & offers — customers nearby can order like Meesho + local trust.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () =>
                                  context.push('/become-seller'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                              ),
                              child: const Text('Start your boutique store'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (hub.id == 'hub_clothes' && boutiques.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
                      child: const SectionHeader(
                        title: 'Home boutiques',
                        subtitle: 'Women-led fashion from nearby homes',
                      ),
                    ),
                    SizedBox(
                      height: 230,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: pad),
                        itemCount: boutiques.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) => VendorCard(
                          vendor: boutiques[i],
                          horizontal: true,
                        ),
                      ),
                    ),
                  ],

                  if (vendors.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
                      child: SectionHeader(
                        title: 'Sellers in ${hub.name}',
                        subtitle: '${vendors.length} home businesses',
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      child: Column(
                        children: vendors
                            .take(6)
                            .map((v) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: VendorCard(vendor: v),
                                ))
                            .toList(),
                      ),
                    ),
                  ],

                  if (products.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
                      child: const SectionHeader(title: 'Popular products'),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 0, pad, 100),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final cols = Responsive.gridColumns(context,
                              mobile: 2, tablet: 3, desktop: 4);
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: products.length.clamp(0, 12),
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
                  ] else
                    const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
