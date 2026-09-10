import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Dedicated Seller UI shell — separate from buyer MainShell.
class SellerShell extends StatelessWidget {
  final Widget child;
  final String location;

  const SellerShell({super.key, required this.child, required this.location});

  int get _index {
    if (location.contains('/seller/products')) return 1;
    if (location.contains('/seller/orders')) return 2;
    if (location.contains('/seller/store')) return 3;
    return 0;
  }

  void _go(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go('/seller');
        break;
      case 1:
        context.go('/seller/products');
        break;
      case 2:
        context.go('/seller/orders');
        break;
      case 3:
        context.go('/seller/store');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          Material(
            color: const Color(0xFF4E342E),
            elevation: 2,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nestly Seller',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Business dashboard · separate from buyer shop',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        auth.enterBuyerMode();
                        context.go('/home');
                      },
                      icon: const Icon(Icons.shopping_bag_outlined,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'Buyer app',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => _go(context, i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.secondaryLight,
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon:
                Icon(Icons.dashboard_rounded, color: AppColors.secondary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon:
                Icon(Icons.inventory_2_rounded, color: AppColors.secondary),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon:
                Icon(Icons.receipt_long_rounded, color: AppColors.secondary),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon:
                Icon(Icons.settings_rounded, color: AppColors.secondary),
            label: 'Store',
          ),
        ],
      ),
    );
  }
}
