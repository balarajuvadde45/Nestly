import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seller_provider.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn || !auth.isSeller) {
        context.go('/login?seller=1');
        return;
      }
      context.read<SellerProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final seller = context.watch<SellerProvider>();
    final pad = Responsive.contentPadding(context);
    final wide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seller Dashboard'),
            if (seller.vendor != null)
              Text(
                seller.vendor!.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => seller.loadDashboard(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Store settings',
            onPressed: () => context.push('/seller/store'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: seller.loading && seller.vendor == null
          ? const Center(child: CircularProgressIndicator())
          : seller.error != null && seller.vendor == null
              ? _onboardPrompt(context, seller)
              : RefreshIndicator(
                  onRefresh: seller.loadDashboard,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(pad, 12, pad, 100),
                    children: [
                      if (seller.vendor != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                seller.vendor!.isOpen
                                    ? 'Store is OPEN'
                                    : 'Store is CLOSED',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: seller.vendor!.isOpen
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                            Switch(
                              value: seller.vendor!.isOpen,
                              activeThumbColor: AppColors.success,
                              onChanged: (v) =>
                                  seller.updateStore({'isOpen': v}),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      LayoutBuilder(
                        builder: (context, c) {
                          final cols = c.maxWidth > 700 ? 4 : 2;
                          return GridView.count(
                            crossAxisCount: cols,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: wide ? 1.6 : 1.4,
                            children: [
                              _statCard(
                                'Revenue',
                                Formatters.currency(seller.stats.revenue),
                                Icons.currency_rupee_rounded,
                                AppColors.primary,
                              ),
                              _statCard(
                                'Orders',
                                '${seller.stats.totalOrders}',
                                Icons.receipt_long_rounded,
                                AppColors.secondary,
                              ),
                              _statCard(
                                'Active',
                                '${seller.stats.activeOrders}',
                                Icons.local_shipping_rounded,
                                AppColors.info,
                              ),
                              _statCard(
                                'Products',
                                '${seller.stats.productCount}',
                                Icons.inventory_2_outlined,
                                AppColors.accent,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  context.push('/seller/products'),
                              icon: const Icon(Icons.inventory_2_outlined),
                              label: const Text('Manage products'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/seller/orders'),
                              icon: const Icon(Icons.receipt_long_outlined),
                              label: const Text('Orders'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Recent orders',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      if (seller.orders.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No orders yet. Share your storefront with customers!',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ...seller.orders.take(8).map((o) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                Formatters.orderId(o.id),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${o.statusLabel} • ${o.items.length} items • ${Formatters.relativeTime(o.placedAt)}',
                              ),
                              trailing: Text(
                                Formatters.currency(o.grandTotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              onTap: () =>
                                  context.push('/seller/orders/${o.id}'),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
      floatingActionButton: seller.vendor != null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/seller/products/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            )
          : null,
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _onboardPrompt(BuildContext context, SellerProvider seller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined,
                size: 64, color: AppColors.secondary),
            const SizedBox(height: 16),
            Text(
              seller.error ?? 'No storefront yet',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your home kitchen / business storefront to start selling.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/seller/onboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
              child: const Text('Create storefront'),
            ),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to customer app'),
            ),
          ],
        ),
      ),
    );
  }
}
