import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';

/// Motivation + gateway from Buyer app → Seller surface.
class SellerEntryScreen extends StatelessWidget {
  const SellerEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pad = Responsive.contentPadding(context);
    final wide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Sell on Nestly'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Back to shopping',
          onPressed: () {
            auth.enterBuyerMode();
            context.go('/home');
          },
        ),
      ),
      body: Responsive.constrained(
        child: ListView(
          padding: EdgeInsets.all(pad),
          children: [
            Container(
              padding: EdgeInsets.all(wide ? 32 : 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80), Color(0xFFFFAB40)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        size: 36, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Start your home business today',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      height: 1.2,
                      color: Color(0xFF4E342E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Anyone can sell from home or their own shop — food, pickles, fashion, crafts, and more. Nestly gives you a free storefront, orders, and customers nearby. Built for home businesses worldwide.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Why sell on Nestly?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 12),
            _reason(
              Icons.home_work_outlined,
              'Work from home',
              'No shop rent. List products from your kitchen or boutique table.',
            ),
            _reason(
              Icons.groups_outlined,
              'Reach real customers',
              'Buyers on Nestly discover local homemade food, fashion & more.',
            ),
            _reason(
              Icons.dashboard_customize_outlined,
              'Your own seller dashboard',
              'Separate seller UI — products, orders, and store tools. Buyer shopping stays clean.',
            ),
            _reason(
              Icons.link_rounded,
              'Linked to your buyer account',
              'You open a business using the same Nestly login. One person, two spaces: Shop & Sell.',
            ),
            const SizedBox(height: 20),
            if (auth.hasBusiness) ...[
              ElevatedButton.icon(
                onPressed: () {
                  auth.enterSellerMode();
                  context.go('/seller');
                },
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text('Open Seller Dashboard'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.secondary,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  auth.enterBuyerMode();
                  context.go('/home');
                },
                child: const Text('Continue shopping as buyer'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  if (!auth.isLoggedIn) {
                    context.push('/login?next=/sell/setup');
                    return;
                  }
                  context.push('/sell/setup');
                },
                icon: const Icon(Icons.rocket_launch_rounded),
                label: Text(
                  auth.isLoggedIn
                      ? 'Create my business account'
                      : 'Login & start selling',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.secondary,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              if (!auth.isLoggedIn)
                const Text(
                  'You need a Nestly buyer account first. Then add a business to the same login.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
            ],
            const SizedBox(height: 28),
            TextButton(
              onPressed: () {
                auth.enterBuyerMode();
                context.go('/home');
              },
              child: const Text('← Back to Nestly shop'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _reason(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.secondaryLight,
            child: Icon(icon, color: AppColors.secondary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(body, style: const TextStyle(height: 1.35)),
        ),
      ),
    );
  }
}

/// Create business on top of logged-in buyer account.
class SellerBusinessSetupScreen extends StatefulWidget {
  const SellerBusinessSetupScreen({super.key});

  @override
  State<SellerBusinessSetupScreen> createState() =>
      _SellerBusinessSetupScreenState();
}

class _SellerBusinessSetupScreenState extends State<SellerBusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _desc = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController(text: 'Hyderabad');
  String _type = 'HOME_COOK';

  static const _types = {
    'HOME_COOK': 'Home Kitchen / Food',
    'CLOUD_KITCHEN': 'Cloud Kitchen',
    'HOME_BUSINESS': 'Pickles / Bakery / General',
    'BOUTIQUE': 'Boutique / Clothes',
  };

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _desc.dispose();
    _area.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pad = Responsive.contentPadding(context);

    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login?next=/sell/setup');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create business account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/sell'),
        ),
      ),
      body: Responsive.constrained(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(pad),
            children: [
              Card(
                color: AppColors.primaryLight,
                child: ListTile(
                  leading: const Icon(Icons.person, color: AppColors.primary),
                  title: Text(auth.user?.name ?? 'Buyer'),
                  subtitle: Text(
                    '${auth.user?.email ?? ''} · Buyer account',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your business is linked to this buyer login. Shopping and selling stay separate in the app.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Business name *',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().length < 2 ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagline,
                decoration: const InputDecoration(
                  labelText: 'Tagline (optional)',
                  hintText: 'e.g. Homemade with love',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'About your business (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Business type *'),
                items: _types.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _area,
                decoration: const InputDecoration(
                  labelText: 'Area / locality *',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().length < 2 ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'City *'),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 12),
                Text(auth.error!,
                    style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final ok = await auth.openBusiness(
                          businessName: _name.text.trim(),
                          area: _area.text.trim(),
                          city: _city.text.trim(),
                          businessType: _type,
                          tagline: _tagline.text.trim().isEmpty
                              ? null
                              : _tagline.text.trim(),
                          description: _desc.text.trim().isEmpty
                              ? null
                              : _desc.text.trim(),
                        );
                        if (!context.mounted) return;
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Business created! Welcome to Seller Dashboard.'),
                            ),
                          );
                          context.go('/seller');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.secondary,
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create business & open dashboard'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
