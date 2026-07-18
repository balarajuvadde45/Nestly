import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../services/api_client.dart';

class BecomeSellerScreen extends StatefulWidget {
  const BecomeSellerScreen({super.key});

  @override
  State<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends State<BecomeSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _business = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController(text: AppConstants.defaultCity);
  final _area = TextEditingController();
  final _message = TextEditingController();
  String _type = 'Home Kitchen';
  bool _submitted = false;
  bool _submitting = false;
  String? _error;
  String? _applicationId;

  static const _types = [
    'Home Kitchen',
    'Cloud Kitchen',
    'Pickles & Spices',
    'Home Bakery',
    'Home Boutique',
    'Kurtis & Ethnic Wear',
    'Handloom & Sarees',
    'Kids Ethnic Wear',
    'Custom Stitching',
    'Tiffin Service',
    'Other Home Business',
  ];

  @override
  void dispose() {
    _name.dispose();
    _business.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    _area.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final res = await api.post('/api/seller-applications', body: {
        'applicantName': _name.text.trim(),
        'businessName': _business.text.trim(),
        'phone': _phone.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        'city': _city.text.trim(),
        if (_area.text.trim().isNotEmpty) 'area': _area.text.trim(),
        'businessType': _type,
        if (_message.text.trim().isNotEmpty) 'message': _message.text.trim(),
      });
      final app = res['application'] as Map<String, dynamic>?;
      setState(() {
        _submitted = true;
        _applicationId = app?['id'] as String?;
        _submitting = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (e) {
      setState(() {
        _error =
            'Could not submit. Check that Nestly API is running and try again.\n$e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.contentPadding(context);

    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Become a seller')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration_rounded,
                    size: 72, color: AppColors.secondary),
                const SizedBox(height: 16),
                const Text(
                  'Application saved!',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  _applicationId != null
                      ? 'Your application was stored in Nestly (ref: ${_applicationId!.substring(0, 8)}…).\nOur admin team will review it and contact you.'
                      : 'Your application was stored. Our admin team will review it.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Back to home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Become a seller')),
      body: Responsive.constrained(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(pad),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Built for women-led home businesses',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Submit your application. Nestly admin will review it in the database and contact you to go live.',
                      style: TextStyle(
                          color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _benefit(Icons.people_outline_rounded, 'Reach local customers'),
              _benefit(Icons.payments_outlined, 'Simple payouts & orders'),
              _benefit(Icons.storefront_outlined, 'Your branded storefront'),
              _benefit(Icons.support_agent_rounded, 'Onboarding support'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Your name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _business,
                decoration: const InputDecoration(
                  labelText: 'Business / kitchen name *',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => v == null || v.trim().length < 10
                    ? 'Valid phone required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(
                  labelText: 'City *',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _area,
                decoration: const InputDecoration(
                  labelText: 'Area / locality (optional)',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Business type *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _message,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Tell us about your business (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, height: 1.35),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.secondary,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit application'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 22),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
