import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pad = Responsive.contentPadding(context);
    final addresses = auth.user?.addresses ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Addresses')),
      floatingActionButton: auth.isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add address'),
            )
          : null,
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
                  subtitle: 'Add a delivery address to place orders',
                  actionLabel: 'Add address',
                  onAction: () => _openForm(context),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(pad, 12, pad, 100),
                  itemCount: addresses.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
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
                            Flexible(
                              child: Text(
                                a.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (a.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'DEFAULT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${a.fullAddress}\n${a.area}, ${a.city} - ${a.pincode}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await _openForm(context, existing: a);
                            } else if (v == 'delete') {
                              final ok = await auth.deleteAddress(a.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'Address removed'
                                        : (auth.error ?? 'Could not delete'),
                                  ),
                                ),
                              );
                            }
                          },
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _openForm(BuildContext context, {Address? existing}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddressFormSheet(existing: existing),
    );
  }
}

class AddressFormSheet extends StatefulWidget {
  final Address? existing;

  const AddressFormSheet({super.key, this.existing});

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  late final TextEditingController _label;
  late final TextEditingController _full;
  late final TextEditingController _area;
  late final TextEditingController _city;
  late final TextEditingController _pincode;
  late final TextEditingController _landmark;
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? 'Home');
    _full = TextEditingController(text: e?.isPlaceholder == true ? '' : e?.fullAddress);
    _area = TextEditingController(text: e?.area ?? '');
    _city = TextEditingController(text: e?.city.isNotEmpty == true ? e!.city : 'Hyderabad');
    _pincode = TextEditingController(text: e?.pincode ?? '');
    _landmark = TextEditingController(text: e?.landmark ?? '');
    _isDefault = e?.isDefault ?? true;
  }

  @override
  void dispose() {
    _label.dispose();
    _full.dispose();
    _area.dispose();
    _city.dispose();
    _pincode.dispose();
    _landmark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existing == null ? 'Add address' : 'Edit address',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _label,
              decoration: const InputDecoration(
                labelText: 'Label (Home, Office…)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _full,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Full address',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _area,
              decoration: const InputDecoration(labelText: 'Area / locality'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pincode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(labelText: 'Pincode'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _landmark,
              decoration: const InputDecoration(
                labelText: 'Landmark (optional)',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set as default'),
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
            ),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save address'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_full.text.trim().length < 3 ||
        _area.text.trim().length < 2 ||
        _city.text.trim().length < 2 ||
        _pincode.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill address, area, city and 6-digit pincode')),
      );
      return;
    }
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.saveAddress(
      id: widget.existing?.id,
      label: _label.text.trim().isEmpty ? 'Home' : _label.text.trim(),
      fullAddress: _full.text.trim(),
      area: _area.text.trim(),
      city: _city.text.trim(),
      pincode: _pincode.text.trim(),
      landmark: _landmark.text.trim(),
      isDefault: _isDefault,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not save address')),
      );
    }
  }
}
