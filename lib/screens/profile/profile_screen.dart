import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/vendor_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pad = Responsive.contentPadding(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: Responsive.constrained(
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, 12, pad, 100),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: user == null
                    ? Column(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 48, color: AppColors.primary),
                          const SizedBox(height: 12),
                          const Text(
                            'Welcome to Nestly',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Login to track orders, save favourites & more',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.push('/login'),
                            child: const Text('Login / Sign up'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                context.push('/login?seller=1'),
                            child: const Text('Seller login'),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18),
                                ),
                                Text(user.phone,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                                Text(user.email,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.push('/login'),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _tile(
              Icons.receipt_long_outlined,
              'My Orders',
              'Track active & past orders',
              () => context.go('/orders'),
            ),
            _tile(
              Icons.favorite_outline_rounded,
              'Favourites',
              'Saved kitchens & items',
              () => context.push('/favourites'),
            ),
            _tile(
              Icons.location_on_outlined,
              'Addresses',
              user?.addresses.isNotEmpty == true
                  ? '${user!.addresses.length} saved'
                  : 'Manage delivery addresses',
              () => context.push('/addresses'),
            ),
            if (user?.role == 'ADMIN')
              _tile(
                Icons.admin_panel_settings_outlined,
                'Seller applications',
                'Review Sell from Home submissions',
                () => context.push('/admin/applications'),
              ),
            _tile(
              Icons.diversity_3_rounded,
              'Wisdom Circle',
              'Elders\' tips, remedies & community Q&A',
              () => context.go('/wisdom'),
            ),
            _tile(
              Icons.dashboard_customize_outlined,
              'Seller dashboard',
              auth.isSeller
                  ? 'Manage menu, orders & store'
                  : 'Login as seller: amma@nestly.app',
              () {
                if (auth.isSeller) {
                  context.push('/seller');
                } else {
                  context.push('/login?seller=1');
                }
              },
            ),
            _tile(
              Icons.storefront_outlined,
              'Become a seller',
              'Register your home kitchen / business',
              () => context.push('/become-seller'),
            ),
            _tile(
              Icons.local_offer_outlined,
              'Offers & coupons',
              'NESTLY20, FLAT50, FIRST100',
              () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Available coupons'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• NESTLY20 — 20% off up to ₹100'),
                        SizedBox(height: 8),
                        Text('• FLAT50 — ₹50 off above ₹199'),
                        SizedBox(height: 8),
                        Text('• FIRST100 — ₹100 off on first order'),
                      ],
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Got it')),
                    ],
                  ),
                );
              },
            ),
            _tile(
              Icons.help_outline_rounded,
              'Help & support',
              'FAQs and contact',
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Support: help@nestly.app (demo)')),
                );
              },
            ),
            _tile(
              Icons.info_outline_rounded,
              'About ${AppConstants.appName}',
              AppConstants.appTagline,
              () {
                showAboutDialog(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: '1.0.0',
                  applicationLegalese:
                      'Marketplace for home cooks, cloud kitchens & home businesses.',
                );
              },
            ),
            if (user != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  auth.logout();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out')),
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<CatalogProvider>();
    final pad = Responsive.contentPadding(context);
    final favIds = auth.user?.favoriteVendorIds ?? [];
    final vendors = favIds
        .map(catalog.vendorById)
        .whereType<dynamic>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: !auth.isLoggedIn
          ? EmptyState(
              icon: Icons.lock_outline,
              title: 'Login required',
              subtitle: 'Sign in to save favourites',
              actionLabel: 'Login',
              onAction: () => context.push('/login'),
            )
          : vendors.isEmpty
              ? EmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'No favourites yet',
                  subtitle: 'Tap the heart on a seller to save it',
                  actionLabel: 'Browse',
                  onAction: () => context.go('/home'),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(pad),
                  itemCount: vendors.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      VendorCard(vendor: vendors[i]),
                ),
    );
  }
}

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pad = Responsive.contentPadding(context);
    final addresses = auth.user?.addresses ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Addresses')),
      body: !auth.isLoggedIn
          ? EmptyState(
              icon: Icons.lock_outline,
              title: 'Login required',
              subtitle: 'Sign in to manage delivery addresses',
              actionLabel: 'Login',
              onAction: () => context.push('/login'),
            )
          : addresses.isEmpty
          ? EmptyState(
              icon: Icons.location_off_outlined,
              title: 'No addresses yet',
              subtitle: 'Addresses appear after you register or login',
              actionLabel: 'Home',
              onAction: () => context.go('/home'),
            )
          : ListView.separated(
              padding: EdgeInsets.all(pad),
              itemCount: addresses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = addresses[i];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      a.label.toLowerCase() == 'office'
                          ? Icons.work_outline_rounded
                          : Icons.home_outlined,
                      color: AppColors.primary,
                    ),
                    title: Row(
                      children: [
                        Text(a.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        if (a.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('DEFAULT',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${a.fullAddress}\n${a.area}, ${a.city} - ${a.pincode}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
