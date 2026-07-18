import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import 'app_network_image.dart';
import 'price_text.dart';
import 'quantity_stepper.dart';
import 'veg_badge.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool compact;
  final bool showVendor;

  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
    this.showVendor = false,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(product.id);

    return InkWell(
      onTap: () => context.push('/product/${product.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: compact ? _compactBody(context, cart, qty) : _fullBody(context, cart, qty),
      ),
    );
  }

  Widget _fullBody(BuildContext context, CartProvider cart, int qty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppNetworkImage(
                url: product.imageUrl,
                placeholderIcon: Icons.fastfood_rounded,
              ),
              if (product.hasDiscount)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${product.discountPercent.round()}% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VegBadge(isVeg: product.isVeg, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                PriceText(price: product.price, mrp: product.mrp, fontSize: 13),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: QuantityStepper(
                    quantity: qty,
                    compact: true,
                    outlined: true,
                    onIncrement: () => _add(context, cart),
                    onDecrement: () {
                      if (qty > 0) {
                        final item = cart.items
                            .where((i) => i.product.id == product.id)
                            .firstOrNull;
                        if (item != null) cart.decrement(item.id);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactBody(BuildContext context, CartProvider cart, int qty) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          AppNetworkImage(
            url: product.imageUrl,
            width: 72,
            height: 72,
            borderRadius: BorderRadius.circular(10),
            placeholderIcon: Icons.fastfood_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VegBadge(isVeg: product.isVeg, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    PriceText(
                        price: product.price, mrp: product.mrp, fontSize: 13),
                    const Spacer(),
                    QuantityStepper(
                      quantity: qty,
                      compact: true,
                      outlined: true,
                      onIncrement: () => _add(context, cart),
                      onDecrement: () {
                        final item = cart.items
                            .where((i) => i.product.id == product.id)
                            .firstOrNull;
                        if (item != null) cart.decrement(item.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _add(BuildContext context, CartProvider cart) {
    if (product.sizes.isNotEmpty) {
      context.push('/product/${product.id}');
      return;
    }
    final catalog = context.read<CatalogProvider>();
    final vendor = catalog.vendorById(product.vendorId);
    final ok = cart.addItem(product, vendor: vendor);
    if (!ok) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace cart?'),
          content: Text(
            'Your cart has items from ${cart.vendor?.name ?? 'another seller'}. '
            'Clear cart and add from this seller?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('No')),
            ElevatedButton(
              onPressed: () {
                cart.addItem(product, forceReplace: true, vendor: vendor);
                Navigator.pop(ctx);
              },
              child: const Text('Yes, replace'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          duration: const Duration(seconds: 1),
          action: SnackBarAction(
            label: 'VIEW',
            onPressed: () => context.push('/cart'),
          ),
        ),
      );
    }
  }
}
