import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../providers/seller_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/veg_badge.dart';

class SellerProductsScreen extends StatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  State<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final seller = context.watch<SellerProvider>();
    final pad = Responsive.contentPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            onPressed: () => context.push('/seller/products/new'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: seller.products.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No products yet'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.push('/seller/products/new'),
                    child: const Text('Add first product'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(pad),
              itemCount: seller.products.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = seller.products[i];
                return Card(
                  child: ListTile(
                    leading: AppNetworkImage(
                      url: p.imageUrl,
                      width: 52,
                      height: 52,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Row(
                      children: [
                        VegBadge(isVeg: p.isVeg, size: 12),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${Formatters.currency(p.price)} • ${p.isAvailable ? "Available" : "Hidden"}',
                      style: TextStyle(
                        color: p.isAvailable
                            ? AppColors.textSecondary
                            : AppColors.error,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'toggle') {
                          await seller.updateProduct(p.id, {
                            'isAvailable': !p.isAvailable,
                          });
                        } else if (v == 'edit') {
                          context.push('/seller/products/${p.id}/edit');
                        } else if (v == 'delete') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete product?'),
                              content: Text('Remove ${p.name}?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok == true) await seller.deleteProduct(p.id);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(p.isAvailable
                              ? 'Mark unavailable'
                              : 'Mark available'),
                        ),
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/seller/products/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SellerProductFormScreen extends StatefulWidget {
  final String? productId;

  const SellerProductFormScreen({super.key, this.productId});

  @override
  State<SellerProductFormScreen> createState() =>
      _SellerProductFormScreenState();
}

class _SellerProductFormScreenState extends State<SellerProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _mrp = TextEditingController();
  final _image = TextEditingController(
    text:
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
  );
  bool _isVeg = true;
  bool _saving = false;

  bool get isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final p = context
            .read<SellerProvider>()
            .products
            .where((x) => x.id == widget.productId)
            .firstOrNull;
        if (p != null) {
          _name.text = p.name;
          _desc.text = p.description;
          _price.text = p.price.toStringAsFixed(0);
          _mrp.text = p.mrp?.toStringAsFixed(0) ?? '';
          _image.text = p.imageUrl;
          _isVeg = p.isVeg;
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _mrp.dispose();
    _image.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.contentPadding(context);
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit product' : 'New product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(pad),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  v == null || v.trim().length < 2 ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) =>
                  v == null || v.trim().length < 5 ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price (₹)'),
                    validator: (v) =>
                        double.tryParse(v ?? '') == null ? 'Invalid' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _mrp,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'MRP (optional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _image,
              decoration: const InputDecoration(labelText: 'Image URL'),
              validator: (v) =>
                  v == null || !v.startsWith('http') ? 'Valid URL required' : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vegetarian'),
              value: _isVeg,
              onChanged: (v) => setState(() => _isVeg = v),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEdit ? 'Save changes' : 'Create product'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final seller = context.read<SellerProvider>();
    final body = {
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'price': double.parse(_price.text.trim()),
      if (_mrp.text.trim().isNotEmpty)
        'mrp': double.tryParse(_mrp.text.trim()),
      'imageUrl': _image.text.trim(),
      'isVeg': _isVeg,
      'type': 'FOOD',
    };
    final ok = isEdit
        ? await seller.updateProduct(widget.productId!, body)
        : await seller.createProduct(body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Product updated' : 'Product created')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(seller.error ?? 'Failed')),
      );
    }
  }
}
