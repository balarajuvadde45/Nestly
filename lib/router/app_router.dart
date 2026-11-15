import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/category/category_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/hub/hub_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/product/product_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/addresses_screen.dart';
import '../screens/profile/delete_account_screen.dart';
import '../screens/legal/legal_screens.dart';
import '../screens/search/search_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/tracking/live_tracking_screen.dart';
import '../screens/vendor/vendor_screen.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) {
          return MainShell(location: state.uri.toString(), child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => NoTransitionPage(
              child: SearchScreen(initialQuery: state.uri.queryParameters['q']),
            ),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OrdersScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/hub/:id',
        builder: (context, state) =>
            HubScreen(hubId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesListScreen(),
      ),
      GoRoute(
        path: '/category/:id',
        builder: (context, state) =>
            CategoryScreen(categoryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/vendor/:id',
        builder: (context, state) =>
            VendorScreen(vendorId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/order-success/:id',
        builder: (context, state) =>
            OrderSuccessScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/track/:id',
        builder: (context, state) =>
            LiveTrackingScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          nextPath: state.uri.queryParameters['next'],
        ),
      ),
      GoRoute(
        path: '/favourites',
        builder: (context, state) => const FavouritesScreen(),
      ),
      GoRoute(
        path: '/account/delete',
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      // Selling happens in the separate Tamarin Partner app; the customer
      // CTAs open its store listing (see core/utils/store_links.dart).
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    ),
  );
}
