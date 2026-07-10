import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/category.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/vendor_card.dart';

class CategoryScreen extends StatelessWidget {
  final String categoryId;

  const CategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final category = catalog.categoryById(categoryId);
    final pad = Responsive.contentPadding(context);

    if (category == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Category')),
        body: const EmptyState(
          icon: Icons.category_outlined,
          title: 'Category not found',
        ),
      );
    }

    final vendors = catalog.vendorsForCategory(categoryId);
    final products = catalog.allProducts
        .where((p) => p.categoryId == categoryId)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(url: category.imageUrl),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Responsive.constrained(
              child: Padding(
                padding: EdgeInsets.all(pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: category.color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(category.icon, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                              Text(
                                '${vendors.length} sellers • ${products.length} items',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (vendors.isNotEmpty) ...[
                      const SectionHeader(title: 'Sellers in this category'),
                      ...vendors.map((v) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: VendorCard(vendor: v),
                          )),
                    ],
                    if (products.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const SectionHeader(title: 'Popular items'),
                      LayoutBuilder(
                        builder: (context, constraints) {
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
                    ],
                    if (vendors.isEmpty && products.isEmpty)
                      const EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'Nothing here yet',
                        subtitle: 'Check back soon for new sellers',
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoriesListScreen extends StatelessWidget {
  const CategoriesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final pad = Responsive.contentPadding(context);
    final cols =
        Responsive.gridColumns(context, mobile: 2, tablet: 3, desktop: 4);

    return Scaffold(
      appBar: AppBar(title: const Text('All Categories')),
      body: Responsive.constrained(
        child: GridView.builder(
          padding: EdgeInsets.all(pad),
          itemCount: catalog.categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, i) {
            final ShopCategory c = catalog.categories[i];
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/category/${c.id}'),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: c.color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(c.icon, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        c.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${c.vendorCount} sellers',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
