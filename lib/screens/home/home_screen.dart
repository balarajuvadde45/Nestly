import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/marketplace_header.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/vendor_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bannerController = PageController(viewportFraction: 0.92);
  int _bannerIndex = 0;

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final auth = context.watch<AuthProvider>();
    final pad = Responsive.contentPadding(context);
    final wide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: wide,
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 64,
            titleSpacing: pad,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        auth.user?.defaultAddress?.area ??
                            AppConstants.defaultArea,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  ],
                ),
                Text(
                  auth.user?.defaultAddress?.short ??
                      '${AppConstants.defaultArea}, ${AppConstants.defaultCity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => context.push('/cart'),
                icon: const Icon(Icons.shopping_bag_outlined),
                tooltip: 'Cart',
              ),
              if (wide) ...[
                TextButton.icon(
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          SliverToBoxAdapter(
            child: Responsive.constrained(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mobile hub chips: Food · Pickles · Clothes · Wisdom
                  if (!wide) ...[
                    const SizedBox(height: 8),
                    const MarketplaceHeader(),
                    const SizedBox(height: 4),
                  ],

                  // Search bar
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 12, pad, 8),
                    child: InkWell(
                      onTap: () => context.go('/search'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search_rounded,
                                color: AppColors.textHint),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Search food, pickles, boutiques, wisdom tips…',
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(Icons.mic_none_rounded,
                                color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Shop by world: Food / Pickles / Clothes / Wisdom
                  const SizedBox(height: 8),
                  const HubShowcase(),
                  const SizedBox(height: 20),

                  // Banners
                  SizedBox(
                    height: wide ? 220 : 160,
                    child: PageView.builder(
                      controller: _bannerController,
                      itemCount: catalog.banners.length,
                      onPageChanged: (i) => setState(() => _bannerIndex = i),
                      itemBuilder: (context, i) {
                        final b = catalog.banners[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 8),
                          child: InkWell(
                            onTap: () {
                              if (b.categoryId != null) {
                                context.push('/category/${b.categoryId}');
                              } else {
                                context.go('/search');
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  AppNetworkImage(
                                    url: b.imageUrl,
                                    placeholderIcon: Icons.local_offer_rounded,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.7),
                                          Colors.black.withValues(alpha: 0.15),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          b.title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: wide ? 26 : 20,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          b.subtitle,
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize: wide ? 15 : 13,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'Order Now →',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Center(
                    child: AnimatedSmoothIndicator(
                      activeIndex: _bannerIndex,
                      count: catalog.banners.length,
                      effect: const WormEffect(
                        dotHeight: 7,
                        dotWidth: 7,
                        activeDotColor: AppColors.primary,
                        dotColor: AppColors.border,
                      ),
                    ),
                  ),

                  // Categories
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
                    child: SectionHeader(
                      title: 'What are you craving?',
                      subtitle: 'Home kitchens, pickles, fashion & more',
                      actionLabel: 'See all',
                      onAction: () => context.push('/categories'),
                    ),
                  ),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      itemCount: catalog.categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final cat = catalog.categories[i];
                        return CategoryTile(
                          category: cat,
                          onTap: () => context.push('/category/${cat.id}'),
                        );
                      },
                    ),
                  ),

                  // Popular near you
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 28, pad, 0),
                    child: SectionHeader(
                      title: 'Popular near you',
                      subtitle: 'Most ordered home businesses',
                      actionLabel: 'See all',
                      onAction: () => context.go('/search'),
                    ),
                  ),
                  SizedBox(
                    height: 230,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      itemCount: catalog.popularVendors.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => VendorCard(
                        vendor: catalog.popularVendors[i],
                        horizontal: true,
                      ),
                    ),
                  ),

                  // Top rated
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 28, pad, 0),
                    child: SectionHeader(
                      title: 'Top rated kitchens',
                      subtitle: 'Loved by thousands of customers',
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = Responsive.gridColumns(context,
                            mobile: 1, tablet: 2, desktop: 3);
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: catalog.topRated.length.clamp(0, cols * 2),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: cols == 1 ? 1.55 : 0.95,
                          ),
                          itemBuilder: (context, i) =>
                              VendorCard(vendor: catalog.topRated[i]),
                        );
                      },
                    ),
                  ),

                  // Bestsellers
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 28, pad, 0),
                    child: const SectionHeader(
                      title: 'Bestsellers',
                      subtitle: 'Crowd favourites this week',
                    ),
                  ),
                  SizedBox(
                    height: 280,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      itemCount: catalog.bestsellers.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => SizedBox(
                        width: 170,
                        child: ProductCard(product: catalog.bestsellers[i]),
                      ),
                    ),
                  ),

                  // Become a seller CTA
                  Padding(
                    padding: EdgeInsets.fromLTRB(pad, 28, pad, 100),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sell from your home',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Join ${AppConstants.appName} as a home cook, cloud kitchen or home business. Reach thousands of customers.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  onPressed: () => context.push('/become-seller'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                  ),
                                  child: const Text('Start selling'),
                                ),
                              ],
                            ),
                          ),
                          if (wide) ...[
                            const SizedBox(width: 24),
                            const Icon(Icons.storefront_rounded,
                                size: 72, color: AppColors.secondary),
                          ],
                        ],
                      ),
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
}
