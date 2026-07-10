import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/vendor_card.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final TabController _tabs;
  final _focus = FocusNode();

  static const _suggestions = [
    'Biryani',
    'Pickle',
    'Thali',
    'Kurti',
    'Laddoo',
    'Tiffin',
    'Healthy bowl',
    'Cake',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<CatalogProvider>();
      if (widget.initialQuery != null) {
        catalog.setSearchQuery(widget.initialQuery!);
      }
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabs.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final pad = Responsive.contentPadding(context);
    final query = catalog.searchQuery;
    final vendors = catalog.filteredVendors;
    final products = catalog.filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search food, sellers, pickles…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _controller.clear();
                        catalog.setSearchQuery('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.2),
              ),
            ),
            onChanged: catalog.setSearchQuery,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Veg only'),
                      selected: catalog.vegOnly,
                      onSelected: catalog.setVegOnly,
                      selectedColor: AppColors.accentLight,
                      checkmarkColor: AppColors.veg,
                    ),
                    const SizedBox(width: 8),
                    ...['relevance', 'rating', 'delivery', 'distance'].map((s) {
                      final labels = {
                        'relevance': 'Popular',
                        'rating': 'Rating',
                        'delivery': 'Fast delivery',
                        'distance': 'Nearest',
                      };
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(labels[s]!),
                          selected: catalog.sortBy == s,
                          onSelected: (_) => catalog.setSortBy(s),
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color: catalog.sortBy == s
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'Sellers (${vendors.length})'),
                  Tab(text: 'Items (${products.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: query.isEmpty
          ? _suggestionsView(context, catalog, pad)
          : TabBarView(
              controller: _tabs,
              children: [
                _vendorsList(vendors, pad),
                _productsList(products, pad),
              ],
            ),
    );
  }

  Widget _suggestionsView(
      BuildContext context, CatalogProvider catalog, double pad) {
    return ListView(
      padding: EdgeInsets.all(pad),
      children: [
        const Text(
          'Popular searches',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((s) {
            return ActionChip(
              avatar: const Icon(Icons.trending_up_rounded, size: 16),
              label: Text(s),
              onPressed: () {
                _controller.text = s;
                catalog.setSearchQuery(s);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        const Text(
          'Browse categories',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...catalog.categories.map((cat) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: cat.color,
              child: Icon(cat.icon, color: AppColors.textPrimary, size: 20),
            ),
            title: Text(cat.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${cat.vendorCount} sellers • ${cat.description}',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/category/${cat.id}'),
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _vendorsList(List vendors, double pad) {
    if (vendors.isEmpty) {
      return const EmptyState(
        icon: Icons.store_outlined,
        title: 'No sellers found',
        subtitle: 'Try a different keyword or browse categories',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(pad, 12, pad, 100),
      itemCount: vendors.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) => VendorCard(vendor: vendors[i]),
    );
  }

  Widget _productsList(List products, double pad) {
    if (products.isEmpty) {
      return const EmptyState(
        icon: Icons.fastfood_outlined,
        title: 'No items found',
        subtitle: 'Try searching for biryani, pickle, kurti…',
      );
    }
    final cols = Responsive.gridColumns(context, mobile: 2, tablet: 3, desktop: 4);
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(pad, 12, pad, 100),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, i) => ProductCard(product: products[i]),
    );
  }
}
