import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final bool sellerMode;

  const LoginScreen({super.key, this.sellerMode = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _otpSent = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.sellerMode ? 1 : 0,
    );
    if (widget.sellerMode) {
      _emailController.text = 'amma@nestly.app';
      _passwordController.text = 'password123';
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.home_work_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.sellerMode
                        ? 'Seller login'
                        : 'Welcome to ${AppConstants.appName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.sellerMode
                        ? 'Login with your seller account to manage orders & menu'
                        : 'Login to order homemade food, pickles, clothes & more',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  TabBar(
                    controller: _tabs,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'Phone'),
                      Tab(text: 'Email'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 280,
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _phoneTab(auth),
                        _emailTab(auth),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.sellerMode
                        ? 'UAT seller: amma@nestly.app / password123'
                        : 'UAT customer: priya@nestly.app / password123\nPhone OTP demo: 123456',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Browse without login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneTab(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: const InputDecoration(
            labelText: 'Mobile number',
            prefixText: '+91 ',
            prefixIcon: Icon(Icons.phone_android_rounded),
          ),
        ),
        if (_otpSent) ...[
          const SizedBox(height: 14),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: 'OTP',
              hintText: '123456',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
        ],
        const Spacer(),
        ElevatedButton(
          onPressed: auth.isLoading
              ? null
              : () async {
                  if (!_otpSent) {
                    if (_phoneController.text.length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Enter a valid 10-digit number')),
                      );
                      return;
                    }
                    setState(() => _otpSent = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('OTP sent! Use 123456 (demo)')),
                    );
                    return;
                  }
                  final ok = await auth.loginWithPhone(
                    _phoneController.text,
                    otp: _otpController.text,
                  );
                  if (!mounted) return;
                  if (ok) {
                    context.go(widget.sellerMode ? '/seller' : '/home');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              auth.error ?? 'Invalid OTP. Use 123456')),
                    );
                  }
                },
          child: auth.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(_otpSent ? 'Verify & login' : 'Send OTP'),
        ),
      ],
    );
  }

  Widget _emailTab(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: auth.isLoading
              ? null
              : () async {
                  final ok = await auth.loginWithEmail(
                    _emailController.text.trim(),
                    _passwordController.text,
                  );
                  if (!mounted) return;
                  if (ok) {
                    if (auth.user?.role == 'ADMIN') {
                      context.go('/admin/applications');
                    } else if (widget.sellerMode ||
                        (auth.user?.isSeller ?? false)) {
                      context.go('/seller');
                    } else {
                      context.go('/home');
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(auth.error ??
                              'Enter email & password (min 4 chars)')),
                    );
                  }
                },
          child: auth.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Login'),
        ),
        if (widget.sellerMode) ...[
          const SizedBox(height: 12),
          const Text(
            'Demo seller: amma@nestly.app / password123',
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
