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
import '../../widgets/empty_state.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _payment = 'UPI';
  Address? _selectedAddress;
  bool _placing = false;

  static const _payments = [
    ('UPI', Icons.qr_code_rounded),
    ('Card', Icons.credit_card_rounded),
    ('Cash on Delivery', Icons.payments_outlined),
    ('Wallet', Icons.account_balance_wallet_outlined),
  ];

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
    _selectedAddress ??= auth.user?.defaultAddress ??
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
            if (addresses.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No address found. Using demo address on place order.'),
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
                                            fontWeight: FontWeight.w700),
                                      ),
                                      if (a.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius:
                                                BorderRadius.circular(4),
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
            ..._payments.map((p) {
              final selected = _payment == p.$1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _payment = p.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(p.$2,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              p.$1,
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _row('Items (${cart.itemCount})', cart.itemTotal),
                    _row('Delivery', cart.deliveryFee),
                    _row('Taxes & fees', cart.platformFee + cart.tax),
                    if (cart.couponDiscount > 0)
                      _row('Discount', -cart.couponDiscount,
                          color: AppColors.success),
                    const Divider(height: 18),
                    _row('To pay', cart.grandTotal, bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'By placing order you agree to Nestly terms of service (demo).',
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
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
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Place order • ${Formatters.currency(cart.grandTotal)}',
                  ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double amount,
      {bool bold = false, Color? color}) {
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
              content: Text('Add a delivery address in your profile first')),
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
      final order = await orders.placeOrder(
        vendor: vendor,
        items: cart.items,
        address: address,
        itemTotal: cart.itemTotal,
        deliveryFee: cart.deliveryFee,
        platformFee: cart.platformFee,
        tax: cart.tax,
        discount: cart.couponDiscount,
        grandTotal: cart.grandTotal,
        paymentMethod: _payment,
        couponCode: cart.couponCode,
      );

      cart.clear();
      if (!context.mounted) return;
      context.go('/order-success/${order.id}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }
}
