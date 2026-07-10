import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/seller_provider.dart';

class SellerOnboardScreen extends StatefulWidget {
  const SellerOnboardScreen({super.key});

  @override
  State<SellerOnboardScreen> createState() => _SellerOnboardScreenState();
}

class _SellerOnboardScreenState extends State<SellerOnboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _desc = TextEditingController();
  final _area = TextEditingController(text: 'Madhapur');
  String _type = 'HOME_COOK';

  static const _types = {
    'HOME_COOK': 'Home Kitchen',
    'CLOUD_KITCHEN': 'Cloud Kitchen',
    'HOME_BUSINESS': 'Home Business',
    'BOUTIQUE': 'Home Boutique',
  };

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _desc.dispose();
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seller = context.watch<SellerProvider>();
    final pad = Responsive.contentPadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create storefront')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(pad),
          children: [
            const Text(
              'Set up your Nestly store',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              'Customers will see this as your public kitchen / business page.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Store name'),
              validator: (v) =>
                  v == null || v.trim().length < 2 ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagline,
              decoration: const InputDecoration(labelText: 'Tagline'),
              validator: (v) =>
                  v == null || v.trim().length < 2 ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) =>
                  v == null || v.trim().length < 10 ? 'Min 10 chars' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _area,
              decoration: const InputDecoration(labelText: 'Area'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Business type'),
              items: _types.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: seller.loading
                  ? null
                  : () async {
                      if (!(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      final ok = await seller.onboard(
                        name: _name.text.trim(),
                        tagline: _tagline.text.trim(),
                        description: _desc.text.trim(),
                        type: _type,
                        area: _area.text.trim(),
                      );
                      if (!context.mounted) return;
                      if (ok) {
                        context.go('/seller');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(seller.error ?? 'Failed')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.secondary,
              ),
              child: seller.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create storefront'),
            ),
          ],
        ),
      ),
    );
  }
}

class SellerStoreSettingsScreen extends StatefulWidget {
  const SellerStoreSettingsScreen({super.key});

  @override
  State<SellerStoreSettingsScreen> createState() =>
      _SellerStoreSettingsScreenState();
}

class _SellerStoreSettingsScreenState extends State<SellerStoreSettingsScreen> {
  final _offer = TextEditingController();
  final _tagline = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final v = context.read<SellerProvider>().vendor;
      if (v != null) {
        _offer.text = v.offerText ?? '';
        _tagline.text = v.tagline;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _offer.dispose();
    _tagline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seller = context.watch<SellerProvider>();
    final pad = Responsive.contentPadding(context);
    final v = seller.vendor;

    return Scaffold(
      appBar: AppBar(title: const Text('Store settings')),
      body: v == null
          ? const Center(child: Text('No storefront'))
          : ListView(
              padding: EdgeInsets.all(pad),
              children: [
                TextFormField(
                  controller: _tagline,
                  decoration: const InputDecoration(labelText: 'Tagline'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _offer,
                  decoration: const InputDecoration(
                    labelText: 'Offer text',
                    hintText: 'e.g. 20% OFF up to ₹100',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Store open'),
                  value: v.isOpen,
                  onChanged: (val) => seller.updateStore({'isOpen': val}),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Free delivery'),
                  value: v.freeDelivery,
                  onChanged: (val) =>
                      seller.updateStore({'freeDelivery': val}),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final ok = await seller.updateStore({
                      'tagline': _tagline.text.trim(),
                      'offerText': _offer.text.trim().isEmpty
                          ? null
                          : _offer.text.trim(),
                    });
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(ok ? 'Saved' : seller.error ?? 'Failed')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
    );
  }
}
