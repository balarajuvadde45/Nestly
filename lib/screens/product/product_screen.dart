import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/price_text.dart';
import '../../widgets/rating_chip.dart';
import '../../widgets/veg_badge.dart';

class ProductScreen extends StatefulWidget {
  final String productId;

  const ProductScreen({super.key, required this.productId});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  String? _selectedSize;
  int _qty = 1;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final product = catalog.productById(widget.productId);
    final pad = Responsive.contentPadding(context);
    final wide = Responsive.isWide(context);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.fastfood_outlined,
          title: 'Product not found',
        ),
      );
    }

    final vendor = catalog.vendorById(product.vendorId);
    final isFav = auth.isProductFavorite(product.id);
    _selectedSize ??= product.sizes.isNotEmpty ? product.sizes.first : null;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!wide)
          AspectRatio(
            aspectRatio: 1.2,
            child: AppNetworkImage(
              url: product.imageUrl,
              placeholderIcon: Icons.fastfood_rounded,
            ),
          ),
        Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  VegBadge(isVeg: product.isVeg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        auth.toggleFavoriteProduct(product.id),
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.primary : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RatingChip(
                rating: product.rating,
                count: product.reviewCount,
              ),
              const SizedBox(height: 12),
              PriceText(
                price: product.price,
                mrp: product.mrp,
                fontSize: 20,
              ),
              if (product.prepTimeMins != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Prep time ~ ${Formatters.deliveryTime(product.prepTimeMins!)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                product.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (product.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: product.tags
                      .map((t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
              if (product.sizes.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Select size',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: product.sizes.map((s) {
                    final selected = _selectedSize == s;
                    return ChoiceChip(
                      label: Text(s),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedSize = s),
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Quantity',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _qtyBtn(Icons.remove_rounded, () {
                    if (_qty > 1) setState(() => _qty--);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '$_qty',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                  _qtyBtn(Icons.add_rounded, () {
                    setState(() => _qty++);
                  }),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Special instructions (optional)',
                  hintText: 'e.g. less spicy, no onion…',
                ),
              ),
              if (vendor != null) ...[
                const SizedBox(height: 24),
                InkWell(
                  onTap: () => context.push('/vendor/${vendor.id}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        AppNetworkImage(
                          url: vendor.imageUrl,
                          width: 48,
                          height: 48,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vendor.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(
                                '${vendor.typeLabel} • ${vendor.area}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: wide ? Colors.white : Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: !wide,
      body: wide
          ? Responsive.constrained(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.all(pad),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: AppNetworkImage(url: product.imageUrl),
                        ),
                      ),
                    ),
                  ),
                  Expanded(flex: 5, child: SingleChildScrollView(child: content)),
                ],
              ),
            )
          : SingleChildScrollView(child: content),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      Formatters.currency(product.price * _qty),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: product.isAvailable
                      ? () => _addToCart(context, cart, product)
                      : null,
                  child: const Text('Add to cart'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, CartProvider cart, product) {
    final ok = cart.addItem(
      product,
      quantity: _qty,
      size: _selectedSize,
      instructions: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    if (!ok) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace cart?'),
          content: Text(
            'Your cart has items from ${cart.vendor?.name ?? 'another seller'}. '
            'Clear cart and add this item?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('No')),
            ElevatedButton(
              onPressed: () {
                cart.addItem(
                  product,
                  quantity: _qty,
                  size: _selectedSize,
                  instructions: _notesController.text.trim().isEmpty
                      ? null
                      : _notesController.text.trim(),
                  forceReplace: true,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added'),
                    action: SnackBarAction(
                      label: 'CART',
                      onPressed: () => context.push('/cart'),
                    ),
                  ),
                );
              },
              child: const Text('Yes, replace'),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () => context.push('/cart'),
        ),
      ),
    );
  }
}
