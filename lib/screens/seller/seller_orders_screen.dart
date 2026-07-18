import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/order.dart';
import '../../providers/seller_provider.dart';
import '../../services/api_mappers.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final seller = context.watch<SellerProvider>();
    final pad = Responsive.contentPadding(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/seller'),
        ),
        title: const Text('Seller orders'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Shop'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: seller.loadOrders,
        child: seller.orders.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No orders yet')),
                ],
              )
            : ListView.separated(
                padding: EdgeInsets.all(pad),
                itemCount: seller.orders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final o = seller.orders[i];
                  return Card(
                    child: ListTile(
                      title: Text(
                        Formatters.orderId(o.id),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${o.statusLabel}\n${o.items.map((e) => e.product.name).join(", ")}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        Formatters.currency(o.grandTotal),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      onTap: () => context.push('/seller/orders/${o.id}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class SellerOrderDetailScreen extends StatelessWidget {
  final String orderId;

  const SellerOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final seller = context.watch<SellerProvider>();
    final order = seller.orders.where((o) => o.id == orderId).firstOrNull;
    final pad = Responsive.contentPadding(context);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Order not found. Refresh orders list.')),
      );
    }

    final nextActions = <(String, String)>[];
    switch (order.status) {
      case OrderStatus.placed:
        nextActions.add(('CONFIRMED', 'Confirm order'));
        nextActions.add(('CANCELLED', 'Cancel'));
        break;
      case OrderStatus.confirmed:
        nextActions.add(('PREPARING', 'Start preparing'));
        break;
      case OrderStatus.preparing:
        nextActions.add(('OUT_FOR_DELIVERY', 'Out for delivery'));
        break;
      case OrderStatus.outForDelivery:
        nextActions.add(('DELIVERED', 'Mark delivered'));
        break;
      default:
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text(Formatters.orderId(order.id))),
      body: ListView(
        padding: EdgeInsets.all(pad),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.statusLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(Formatters.dateTime(order.placedAt)),
                  const SizedBox(height: 8),
                  Text(
                    '${order.address.fullAddress}, ${order.address.area}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...order.items.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(
                                    '${i.product.name} × ${i.quantity}')),
                            Text(Formatters.currency(i.lineTotal)),
                          ],
                        ),
                      )),
                  const Divider(),
                  Row(
                    children: [
                      const Expanded(
                          child: Text('Total',
                              style: TextStyle(fontWeight: FontWeight.w700))),
                      Text(Formatters.currency(order.grandTotal),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (nextActions.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Update status',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 10),
            ...nextActions.map((a) {
              final isCancel = a.$1 == 'CANCELLED';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: isCancel
                    ? OutlinedButton(
                        onPressed: () => _update(context, a.$1),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(a.$2),
                      )
                    : ElevatedButton(
                        onPressed: () => _update(context, a.$1),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(a.$2),
                      ),
              );
            }),
          ],
          if (order.status == OrderStatus.outForDelivery) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/track/${order.id}'),
              icon: const Icon(Icons.map_outlined),
              label: const Text('View live map'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _update(BuildContext context, String status) async {
    final seller = context.read<SellerProvider>();
    final ok = await seller.updateOrderStatus(orderId, status);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Updated to ${orderStatusFromApi(status).name}'
            : (seller.error ?? 'Failed')),
      ),
    );
  }
}
