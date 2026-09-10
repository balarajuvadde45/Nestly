import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/seller_provider.dart';
import '../../services/api_mappers.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuthProvider>().refreshSellerToken();
      if (!mounted) return;
      await context.read<SellerProvider>().loadProducts();
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
        title: const Text('Products'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Shop'),
          ),
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
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      [
                        Formatters.currency(p.price),
                        p.typeLabel,
                        if (p.unitLabel != null) p.unitLabel!,
                        if (p.minCartQuantity > 1) 'MOQ ${p.minCartQuantity}',
                        p.isAvailable ? 'Available' : 'Hidden',
                      ].join(' / '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) await seller.deleteProduct(p.id);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            p.isAvailable
                                ? 'Mark unavailable'
                                : 'Mark available',
                          ),
                        ),
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
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
  final _brand = TextEditingController();
  final _sku = TextEditingController();
  final _unitLabel = TextEditingController();
  final _minQty = TextEditingController(text: '1');
  final _casePack = TextEditingController();
  final _maxQty = TextEditingController();
  final _stock = TextEditingController();
  final _hsn = TextEditingController();
  final _gst = TextEditingController();
  final _batch = TextEditingController();
  final _manufactureDate = TextEditingController();
  final _expiryDate = TextEditingController();
  final _shelfLife = TextEditingController();
  final _manufacturer = TextEditingController();
  final _packer = TextEditingController();
  final _origin = TextEditingController(text: 'India');
  final _fssai = TextEditingController();
  final _sizes = TextEditingController();
  final _colors = TextEditingController();
  final _material = TextEditingController();
  final _returnWindow = TextEditingController(text: '7');
  final _dispatchDays = TextEditingController();
  final _wholesaleTiers = TextEditingController();
  final _image = TextEditingController(
    text: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
  );

  bool _isVeg = true;
  bool _isReturnable = false;
  bool _madeToOrder = false;
  bool _saving = false;
  String _type = 'FOOD';

  static const _productTypes = {
    'FOOD': 'Food / cloud kitchen',
    'PICKLE': 'Pickle',
    'SWEET': 'Sweet',
    'SNACK': 'Snack',
    'GROCERY': 'Grocery',
    'FMCG': 'FMCG',
    'PERSONAL_CARE': 'Personal care',
    'HOME_CARE': 'Home care',
    'BEVERAGE': 'Beverage',
    'READY_TO_COOK': 'Ready to cook',
    'CLOTHES': 'Dress / kurti',
    'SAREE': 'Saree',
    'ACCESSORY': 'Accessory',
    'OTHER': 'Other',
  };

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
        if (p == null) return;
        _fillFromProduct(p);
        setState(() {});
      });
    }
  }

  void _fillFromProduct(Product p) {
    _name.text = p.name;
    _desc.text = p.description;
    _price.text = p.price.toStringAsFixed(0);
    _mrp.text = p.mrp?.toStringAsFixed(0) ?? '';
    _image.text = p.imageUrl;
    _isVeg = p.isVeg;
    _type = productTypeToApi(p.type);
    _brand.text = p.brandName ?? '';
    _sku.text = p.sku ?? '';
    _unitLabel.text = p.unitLabel ?? '';
    _minQty.text = '${p.minOrderQuantity}';
    _casePack.text = p.casePackQuantity?.toString() ?? '';
    _maxQty.text = p.maxOrderQuantity?.toString() ?? '';
    _stock.text = p.stockQuantity?.toString() ?? '';
    _hsn.text = p.hsnCode ?? '';
    _gst.text = p.gstRate?.toStringAsFixed(0) ?? '';
    _batch.text = p.batchNumber ?? '';
    _manufactureDate.text =
        p.manufactureDate?.toIso8601String().split('T').first ?? '';
    _expiryDate.text = p.expiryDate?.toIso8601String().split('T').first ?? '';
    _shelfLife.text = p.shelfLifeDays?.toString() ?? '';
    _manufacturer.text = p.manufacturerName ?? '';
    _packer.text = p.packerName ?? '';
    _origin.text = p.originCountry ?? 'India';
    _fssai.text = p.fssaiLicense ?? '';
    _sizes.text = p.sizes.join(', ');
    _colors.text = p.colors.join(', ');
    _material.text = p.material ?? '';
    _isReturnable = p.isReturnable;
    _returnWindow.text = p.returnWindowDays?.toString() ?? '7';
    _madeToOrder = p.madeToOrder;
    _dispatchDays.text = p.dispatchTimeDays?.toString() ?? '';
    _wholesaleTiers.text = p.wholesaleTiers
        .map(
          (tier) => '${tier.minQuantity}:${tier.unitPrice.toStringAsFixed(0)}',
        )
        .join('\n');
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _mrp.dispose();
    _brand.dispose();
    _sku.dispose();
    _unitLabel.dispose();
    _minQty.dispose();
    _casePack.dispose();
    _maxQty.dispose();
    _stock.dispose();
    _hsn.dispose();
    _gst.dispose();
    _batch.dispose();
    _manufactureDate.dispose();
    _expiryDate.dispose();
    _shelfLife.dispose();
    _manufacturer.dispose();
    _packer.dispose();
    _origin.dispose();
    _fssai.dispose();
    _sizes.dispose();
    _colors.dispose();
    _material.dispose();
    _returnWindow.dispose();
    _dispatchDays.dispose();
    _wholesaleTiers.dispose();
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
            _section('Basics'),
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
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Product type'),
              items: _productTypes.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price incl. GST (Rs)',
                    ),
                    validator: (v) {
                      final parsed = double.tryParse(v ?? '');
                      return parsed == null || parsed <= 0 ? 'Invalid' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _mrp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'MRP (optional)',
                    ),
                    validator: _optionalPositiveDoubleValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _image,
              decoration: const InputDecoration(labelText: 'Image URL'),
              validator: (v) => v == null || !v.startsWith('http')
                  ? 'Valid URL required'
                  : null,
            ),
            const SizedBox(height: 18),
            _section('Inventory'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _unitLabel,
                    decoration: const InputDecoration(
                      labelText: 'Unit / pack label',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock quantity',
                    ),
                    validator: _optionalIntValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minQty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'MOQ'),
                    validator: (v) {
                      final value = int.tryParse(v ?? '');
                      return value == null || value < 1 ? 'Invalid' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _casePack,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Case pack qty',
                    ),
                    validator: _optionalPositiveIntValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxQty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max qty'),
                    validator: _optionalPositiveIntValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _section('Business fields'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brand,
                    decoration: const InputDecoration(labelText: 'Brand'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sku,
                    decoration: const InputDecoration(labelText: 'SKU'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hsn,
                    decoration: const InputDecoration(labelText: 'HSN code'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _gst,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'GST rate %'),
                    validator: _optionalDoubleValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _section('Food and packaged goods'),
            TextFormField(
              controller: _fssai,
              decoration: const InputDecoration(labelText: 'FSSAI license'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _batch,
                    decoration: const InputDecoration(
                      labelText: 'Batch number',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _shelfLife,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Shelf life days',
                    ),
                    validator: _optionalPositiveIntValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _manufactureDate,
                    decoration: const InputDecoration(
                      labelText: 'Mfg date YYYY-MM-DD',
                    ),
                    validator: _optionalDateValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _expiryDate,
                    decoration: const InputDecoration(
                      labelText: 'Expiry YYYY-MM-DD',
                    ),
                    validator: _optionalDateValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _manufacturer,
              decoration: const InputDecoration(labelText: 'Manufacturer'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _packer,
              decoration: const InputDecoration(labelText: 'Packer'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _origin,
              decoration: const InputDecoration(labelText: 'Country of origin'),
            ),
            const SizedBox(height: 18),
            _section('Fashion'),
            TextFormField(
              controller: _sizes,
              decoration: const InputDecoration(labelText: 'Sizes'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _colors,
              decoration: const InputDecoration(labelText: 'Colors'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _material,
              decoration: const InputDecoration(labelText: 'Material'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Returnable'),
              value: _isReturnable,
              onChanged: (v) => setState(() => _isReturnable = v),
            ),
            if (_isReturnable) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _returnWindow,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Return window days',
                ),
                validator: _optionalPositiveIntValidator,
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Made to order'),
              value: _madeToOrder,
              onChanged: (v) => setState(() => _madeToOrder = v),
            ),
            if (_madeToOrder) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _dispatchDays,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Dispatch days'),
                validator: _optionalIntValidator,
              ),
            ],
            const SizedBox(height: 18),
            _section('Wholesale slabs'),
            TextFormField(
              controller: _wholesaleTiers,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Slabs, one per line',
                hintText: '12:78',
              ),
              validator: _wholesaleTierValidator,
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEdit ? 'Save changes' : 'Create product'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }

  String? _optionalIntValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    return parsed == null || parsed < 0 ? 'Invalid' : null;
  }

  String? _optionalDoubleValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    return parsed == null || parsed < 0 ? 'Invalid' : null;
  }

  String? _optionalPositiveIntValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    return parsed == null || parsed < 1 ? 'Invalid' : null;
  }

  String? _optionalPositiveDoubleValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    return parsed == null || parsed <= 0 ? 'Invalid' : null;
  }

  String? _optionalDateValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return DateTime.tryParse(text) == null ? 'Invalid date' : null;
  }

  String? _wholesaleTierValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split(':');
      if (parts.length != 2 ||
          (int.tryParse(parts[0].trim()) ?? 0) < 1 ||
          (double.tryParse(parts[1].trim()) ?? 0) <= 0) {
        return 'Use qty:price';
      }
    }
    return null;
  }

  List<String> _csv(TextEditingController controller) {
    return controller.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  int? _intOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : int.tryParse(text);
  }

  double? _doubleOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : double.tryParse(text);
  }

  void _putText(
    Map<String, dynamic> body,
    String key,
    TextEditingController controller,
  ) {
    final text = controller.text.trim();
    if (text.isNotEmpty) body[key] = text;
  }

  List<Map<String, dynamic>> _parseWholesaleTiers() {
    final tiers = <Map<String, dynamic>>[];
    for (final line in _wholesaleTiers.text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split(':');
      if (parts.length != 2) continue;
      final minQuantity = int.tryParse(parts[0].trim());
      final unitPrice = double.tryParse(parts[1].trim());
      if (minQuantity == null ||
          minQuantity < 1 ||
          unitPrice == null ||
          unitPrice <= 0) {
        continue;
      }
      tiers.add({
        'minQuantity': minQuantity,
        'unitPrice': unitPrice,
        'label': '$minQuantity+',
      });
    }
    return tiers;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final seller = context.read<SellerProvider>();
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'price': double.parse(_price.text.trim()),
      'imageUrl': _image.text.trim(),
      'isVeg': _isVeg,
      'type': _type,
      'minOrderQuantity': int.parse(_minQty.text.trim()),
      'tags': _csv(_brand).followedBy(_csv(_sku)).toList(),
      'sizes': _csv(_sizes),
      'colors': _csv(_colors),
      'isReturnable': _isReturnable,
      'madeToOrder': _madeToOrder,
      'wholesaleTiers': _parseWholesaleTiers(),
    };

    final mrp = _doubleOrNull(_mrp);
    final casePack = _intOrNull(_casePack);
    final maxQty = _intOrNull(_maxQty);
    final stock = _intOrNull(_stock);
    final gst = _doubleOrNull(_gst);
    final shelfLife = _intOrNull(_shelfLife);
    final returnWindow = _intOrNull(_returnWindow);
    final dispatchDays = _intOrNull(_dispatchDays);

    if (mrp != null) body['mrp'] = mrp;
    if (casePack != null) body['casePackQuantity'] = casePack;
    if (maxQty != null) body['maxOrderQuantity'] = maxQty;
    if (stock != null) body['stockQuantity'] = stock;
    if (gst != null) body['gstRate'] = gst;
    if (shelfLife != null) body['shelfLifeDays'] = shelfLife;
    if (_isReturnable && returnWindow != null) {
      body['returnWindowDays'] = returnWindow;
    }
    if (_madeToOrder && dispatchDays != null) {
      body['dispatchTimeDays'] = dispatchDays;
    }
    if (_manufactureDate.text.trim().isNotEmpty) {
      body['manufactureDate'] = _manufactureDate.text.trim();
    }
    if (_expiryDate.text.trim().isNotEmpty) {
      body['expiryDate'] = _expiryDate.text.trim();
    }
    _putText(body, 'brandName', _brand);
    _putText(body, 'sku', _sku);
    _putText(body, 'unitLabel', _unitLabel);
    _putText(body, 'hsnCode', _hsn);
    _putText(body, 'batchNumber', _batch);
    _putText(body, 'manufacturerName', _manufacturer);
    _putText(body, 'packerName', _packer);
    _putText(body, 'originCountry', _origin);
    _putText(body, 'fssaiLicense', _fssai);
    _putText(body, 'material', _material);

    await context.read<AuthProvider>().refreshSellerToken();
    if (!mounted) return;

    final ok = isEdit
        ? await seller.updateProduct(widget.productId!, body)
        : await seller.createProduct(body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      context.read<CatalogProvider>().loadHome();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Product updated' : 'Product created')),
      );
      context.pop();
    } else {
      final err = seller.error ?? 'Failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err.contains('Forbidden')
                ? 'Session outdated. Open Seller Dashboard, then try again.'
                : err,
          ),
        ),
      );
    }
  }
}
