import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/store_links.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/cart_fab.dart';
import '../../widgets/marketplace_header.dart';

// Buyer-only shell — seller is a separate surface via /sell

class MainShell extends StatelessWidget {
  final Widget child;
  final String location;

  const MainShell({super.key, required this.child, required this.location});

  int get _index {
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/orders');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);
    final cart = context.watch<CartProvider>();
    final showCartBar =
        cart.isNotEmpty &&
        !location.startsWith('/cart') &&
        !location.startsWith('/checkout');

    final showTopHeader =
        wide &&
        (location.startsWith('/home') ||
            location.startsWith('/search') ||
            location.startsWith('/orders') ||
            location.startsWith('/profile'));

    if (wide) {
      return Scaffold(
        body: Column(
          children: [
            if (showTopHeader) const MarketplaceHeader(),
            Expanded(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (i) => _onTap(context, i),
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: Colors.white,
                    indicatorColor: AppColors.primaryLight,
                    selectedIconTheme: const IconThemeData(
                      color: AppColors.primary,
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.search_rounded),
                        selectedIcon: Icon(Icons.search_rounded),
                        label: Text('Search'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.receipt_long_outlined),
                        selectedIcon: Icon(Icons.receipt_long_rounded),
                        label: Text('Orders'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline_rounded),
                        selectedIcon: Icon(Icons.person_rounded),
                        label: Text('Profile'),
                      ),
                    ],
                    trailing: IconButton(
                      onPressed: () => showSellDialog(context),
                      tooltip: 'Sell on Tamarin',
                      icon: const Icon(Icons.storefront_rounded),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Stack(
                      children: [
                        child,
                        if (showCartBar)
                          const Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: CartBottomBar(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          child,
          if (showCartBar)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CartBottomBar(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSellDialog(context),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.storefront_rounded),
        label: const Text('Sell'),
        tooltip: 'Become a seller / Seller dashboard',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => _onTap(context, i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryLight,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
            ),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
