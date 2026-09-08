import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/seller_provider.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _usePassword = false;
  bool _busy = false;
  bool _confirmed = false;
  String? _message;
  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (!auth.isLoggedIn) ...[
                const Text(
                  'Sign in to verify ownership and delete your Nestly account.',
                ),
                TextButton(
                  onPressed: () => context.go('/login?next=/account/delete'),
                  child: const Text('Sign in'),
                ),
              ] else ...[
                const Text(
                  'Deleting your account removes your profile and favourites, signs you out, and closes your seller store. Complete or cancel active orders first.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Order and invoice records required for accounting, disputes or legal obligations are retained under the privacy policy.',
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Confirm with password'),
                  value: _usePassword,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _usePassword = v),
                ),
                if (_usePassword)
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  )
                else ...[
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            final result = await auth.sendPhoneOtp(
                              auth.user!.phone,
                            );
                            if (!mounted) return;
                            setState(() {
                              _busy = false;
                              _message = result == null
                                  ? auth.error
                                  : 'Verification code sent';
                            });
                          },
                    child: const Text('Send verification code'),
                  ),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Verification code',
                    ),
                  ),
                ],
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _confirmed,
                  title: const Text(
                    'I understand that deleting my account is permanent.',
                  ),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _confirmed = v ?? false),
                ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_message!),
                  ),
                FilledButton.icon(
                  icon: const Icon(Icons.person_remove_outlined),
                  label: Text(_busy ? 'Please wait' : 'Delete account'),
                  onPressed: !_confirmed || _busy
                      ? null
                      : () async {
                          setState(() {
                            _busy = true;
                            _message = null;
                          });
                          final ok = await auth.deleteAccount(
                            password: _usePassword ? _password.text : null,
                            otp: _usePassword ? null : _code.text,
                          );
                          if (!context.mounted) return;
                          if (ok) {
                            context.read<CartProvider>().clear();
                            context.read<OrderProvider>().clear();
                            context.read<SellerProvider>().clear();
                            context.go('/home');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Account deleted')),
                            );
                          } else {
                            setState(() {
                              _busy = false;
                              _message = auth.error;
                            });
                          }
                        },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
