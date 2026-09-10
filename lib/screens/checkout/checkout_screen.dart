import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/empty_state.dart';
import '../profile/addresses_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Address? _selectedAddress;
  bool _placing = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final pad = Responsive.contentPadding(context);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Nothing to checkout',
          actionLabel: 'Go home',
          onAction: () => context.go('/home'),
        ),
      );
    }

    final addresses = auth.user?.addresses ?? [];
    _selectedAddress ??=
        auth.user?.defaultAddress ??
        (addresses.isNotEmpty ? addresses.first : null);

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Login required',
          subtitle: 'Sign in to place an order with your saved address.',
          actionLabel: 'Login',
          onAction: () => context.push('/login'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: Responsive.constrained(
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, 12, pad, 120),
          children: [
            // Address
            const Text(
              'Delivery address',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (ctx) => const AddressFormSheet(),
                );
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add new address'),
            ),
            if (addresses.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Add a delivery address to place your order.'),
                ),
              )
            else
              ...addresses.map((a) {
                final selected = _selectedAddress?.id == a.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selectedAddress = a),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textHint,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        a.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (a.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'DEFAULT',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${a.fullAddress}, ${a.area}, ${a.city} - ${a.pincode}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
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
                  ),
                );
              }),
            const SizedBox(height: 20),
            const Text(
              'Payment method',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.payments_outlined, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash on Delivery',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pay in cash when your order arrives.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle_rounded, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _row('Items (${cart.itemCount})', cart.itemTotal),
                    _row('Delivery', cart.deliveryFee),
                    _row('Platform fee', cart.platformFee),
                    if (cart.couponDiscount > 0)
                      _row(
                        'Discount',
                        -cart.couponDiscount,
                        color: AppColors.success,
                      ),
                    const Divider(height: 18),
                    _row('Estimated total', cart.grandTotal, bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'By placing this order you agree to Nestly ',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
                GestureDetector(
                  onTap: () => context.push('/legal/terms'),
                  child: const Text(
                    'Terms',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text(
                  ' and ',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
                GestureDetector(
                  onTap: () => context.push('/legal/privacy'),
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text(
                  '.',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          color: Colors.white,
          child: ElevatedButton(
            onPressed: _placing ? null : () => _placeOrder(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: _placing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Review order'),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double amount, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                fontSize: bold ? 15 : 13,
              ),
            ),
          ),
          Text(
            Formatters.currency(amount, decimals: amount % 1 != 0),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              fontSize: bold ? 16 : 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final orders = context.read<OrderProvider>();

    if (!auth.isLoggedIn) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to place an order')),
        );
        context.push('/login');
      }
      return;
    }

    final address = _selectedAddress ?? auth.user?.defaultAddress;
    if (address == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add a delivery address in your profile first'),
          ),
        );
      }
      return;
    }

    final vendor = cart.vendor;
    if (vendor == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller info missing. Re-add items.')),
        );
      }
      return;
    }

    setState(() => _placing = true);
    try {
      final response = await context.read<ApiClient>().post(
        '/api/orders/quote',
        body: {
          'vendorId': vendor.id,
          'addressId': address.id,
          'paymentMethod': 'COD',
          'items': cart.items
              .map(
                (i) => {
                  'productId': i.product.id,
                  'quantity': i.quantity,
                  if (i.selectedSize != null) 'selectedSize': i.selectedSize,
                  if (i.specialInstructions != null)
                    'specialInstructions': i.specialInstructions,
                },
              )
              .toList(),
        },
      );
      final quote = Map<String, dynamic>.from(response['quote'] as Map);
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in (quote['items'] as List))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['productName'] as String),
                    subtitle: Text('Quantity: ${item['quantity']}'),
                    trailing: Text(
                      Formatters.currency(
                        (item['unitPrice'] as num).toDouble() *
                            (item['quantity'] as num),
                      ),
                    ),
                  ),
                _row('Items', (quote['itemTotal'] as num).toDouble()),
                _row('Delivery', (quote['deliveryFee'] as num).toDouble()),
                _row('Platform fee', (quote['platformFee'] as num).toDouble()),
                _row('GST included', (quote['tax'] as num).toDouble()),
                _row(
                  'Cash on delivery',
                  (quote['grandTotal'] as num).toDouble(),
                  bold: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Place order'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final order = await orders.placeOrder(
        quoteHash: quote['quoteHash'] as String,
        vendor: vendor,
        items: cart.items,
        address: address,
        itemTotal: cart.itemTotal,
        deliveryFee: cart.deliveryFee,
        platformFee: cart.platformFee,
        tax: cart.tax,
        discount: cart.couponDiscount,
        grandTotal: cart.grandTotal,
        paymentMethod: 'COD',
        couponCode: cart.couponCode,
      );

      cart.clear();
      if (!context.mounted) return;
      context.go('/order-success/${order.id}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Order failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }
}
