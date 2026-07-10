import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/empty_state.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final pad = Responsive.contentPadding(context);
    final active = orders.activeOrders;
    final past = orders.pastOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.orders.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Your homemade food orders will show up here',
              actionLabel: 'Start ordering',
              onAction: () => context.go('/home'),
            )
          : Responsive.constrained(
              child: ListView(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 100),
                children: [
                  if (active.isNotEmpty) ...[
                    const Text(
                      'Active orders',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    ...active.map((o) => _OrderCard(order: o, highlight: true)),
                    const SizedBox(height: 20),
                  ],
                  if (past.isNotEmpty) ...[
                    const Text(
                      'Past orders',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    ...past.map((o) => _OrderCard(order: o)),
                  ],
                ],
              ),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool highlight;

  const _OrderCard({required this.order, this.highlight = false});

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.outForDelivery:
        return AppColors.info;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstImage = order.items.isNotEmpty
        ? order.items.first.product.imageUrl
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/order/${order.id}'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: highlight
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (firstImage.isNotEmpty)
                      AppNetworkImage(
                        url: firstImage,
                        width: 52,
                        height: 52,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.vendorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          Text(
                            Formatters.orderId(order.id),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  order.items
                      .map((i) => '${i.product.name} × ${i.quantity}')
                      .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      Formatters.currency(order.grandTotal),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.relativeTime(order.placedAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textHint),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.textHint),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>().getById(orderId);
    final pad = Responsive.contentPadding(context);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Order not found',
        ),
      );
    }

    final steps = [
      OrderStatus.placed,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];
    final currentIdx = order.status == OrderStatus.cancelled
        ? -1
        : steps.indexOf(order.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(Formatters.orderId(order.id)),
        actions: [
          if (order.isActive &&
              order.status.index < OrderStatus.outForDelivery.index)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cancel order?'),
                    content: const Text(
                        'Are you sure you want to cancel this order?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('No')),
                      ElevatedButton(
                        onPressed: () {
                          context.read<OrderProvider>().cancelOrder(order.id);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Yes, cancel'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: Responsive.constrained(
        child: ListView(
          padding: EdgeInsets.all(pad),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.vendorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.dateTime(order.placedAt),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    if (order.estimatedDelivery != null && order.isActive) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 16, color: AppColors.info),
                          const SizedBox(width: 6),
                          Text(
                            'ETA ${Formatters.dateTime(order.estimatedDelivery!)}',
                            style: const TextStyle(
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                    if (order.canTrack) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/track/${order.id}'),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Track live on map'),
                        ),
                      ),
                    ],
                    if (order.deliveryPartner != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Delivery partner: ${order.deliveryPartner}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (order.status != OrderStatus.cancelled)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order status',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(steps.length, (i) {
                        final done = currentIdx >= i;
                        final active = currentIdx == i;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: done
                                        ? AppColors.success
                                        : AppColors.border,
                                    shape: BoxShape.circle,
                                  ),
                                  child: done
                                      ? const Icon(Icons.check,
                                          size: 14, color: Colors.white)
                                      : null,
                                ),
                                if (i < steps.length - 1)
                                  Container(
                                    width: 2,
                                    height: 28,
                                    color: currentIdx > i
                                        ? AppColors.success
                                        : AppColors.border,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _label(steps[i]),
                                style: TextStyle(
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: done
                                      ? AppColors.textPrimary
                                      : AppColors.textHint,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_rounded, color: AppColors.error),
                      const SizedBox(width: 10),
                      const Text(
                        'This order was cancelled',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Items',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    ...order.items.map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              AppNetworkImage(
                                url: i.product.imageUrl,
                                width: 44,
                                height: 44,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${i.product.name} × ${i.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(Formatters.currency(i.lineTotal)),
                            ],
                          ),
                        )),
                    const Divider(),
                    _bill('Item total', order.itemTotal),
                    _bill('Delivery', order.deliveryFee),
                    _bill('Taxes & fees', order.platformFee + order.tax),
                    if (order.discount > 0)
                      _bill('Discount', -order.discount,
                          color: AppColors.success),
                    _bill('Total paid', order.grandTotal, bold: true),
                    const SizedBox(height: 8),
                    Text(
                      'Paid via ${order.paymentMethod}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivered to',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.address.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${order.address.fullAddress}, ${order.address.area}, ${order.address.city} - ${order.address.pincode}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _label(OrderStatus s) {
    switch (s) {
      case OrderStatus.placed:
        return 'Order placed';
      case OrderStatus.confirmed:
        return 'Confirmed by seller';
      case OrderStatus.preparing:
        return 'Preparing your order';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Widget _bill(String label, double amount,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                    fontSize: bold ? 14 : 13)),
          ),
          Text(
            Formatters.currency(amount, decimals: amount % 1 != 0),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    size: 56, color: AppColors.success),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order placed!',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Your order ${Formatters.orderId(orderId)} is confirmed.\nThe home kitchen is preparing it.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => context.go('/order/$orderId'),
                child: const Text('Track order'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
