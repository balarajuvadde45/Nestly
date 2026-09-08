import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';

/// Production Login + Sign up (verified phone and email).
class LoginScreen extends StatefulWidget {
  final bool sellerMode;
  final String? nextPath;

  const LoginScreen({super.key, this.sellerMode = false, this.nextPath});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final TabController _modeTabs; // Login | Sign up
  late final TabController _methodTabs; // Phone | Email

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmController = TextEditingController();

  bool _otpSent = false;
  bool _obscure = true;
  bool _obscureSignup = true;
  bool _obscureConfirm = true;
  int _resendSeconds = 0;
  String? _otpHint;
  final _signupOtp = TextEditingController();
  bool _signupOtpSent = false;

  @override
  void initState() {
    super.initState();
    _modeTabs = TabController(length: 2, vsync: this);
    _methodTabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.sellerMode ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _signupOtp.dispose();
    _modeTabs.dispose();
    _methodTabs.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _signupEmailController.dispose();
    _signupPhoneController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendSeconds = 30);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      return _resendSeconds > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primarySoft, AppColors.background, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Responsive.formShell(
            maxWidth: 460,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.sellerMode
                      ? 'Seller account'
                      : 'Welcome to ${AppConstants.appName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.sellerMode
                      ? 'Sign in to manage your business'
                      : 'Login or create an account to order & sell',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _modeTabs,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 2.5,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        tabs: const [
                          Tab(text: 'Login'),
                          Tab(text: 'Sign up'),
                        ],
                        onTap: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 18),
                      AnimatedBuilder(
                        animation: _modeTabs,
                        builder: (context, _) {
                          return _modeTabs.index == 0
                              ? _loginBody(auth)
                              : _signupBody(auth);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Browse without login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginBody(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _methodTabs,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.primaryDark,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Phone OTP'),
              Tab(text: 'Email'),
            ],
            onTap: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _methodTabs,
          builder: (context, _) {
            return _methodTabs.index == 0
                ? _phoneLogin(auth)
                : _emailLogin(auth);
          },
        ),
      ],
    );
  }

  Widget _phoneLogin(AuthProvider auth) {
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
            prefixText: '+91  ',
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
            decoration: InputDecoration(
              labelText: 'Enter 6-digit OTP',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              helperText: _otpHint,
              helperMaxLines: 2,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: (_resendSeconds > 0 || auth.isLoading)
                  ? null
                  : () => _sendOtp(auth),
              child: Text(
                _resendSeconds > 0
                    ? 'Resend in ${_resendSeconds}s'
                    : 'Resend OTP',
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: auth.isLoading
              ? null
              : () async {
                  if (!_otpSent) {
                    await _sendOtp(auth);
                    return;
                  }
                  if (_otpController.text.length != 6) {
                    _toast('Enter the 6-digit OTP');
                    return;
                  }
                  final ok = await auth.verifyPhoneOtp(
                    _phoneController.text,
                    _otpController.text,
                  );
                  if (!mounted) return;
                  if (ok) {
                    _goAfterLogin(context, auth);
                  } else {
                    _toast(auth.error ?? 'Invalid OTP');
                  }
                },
          child: auth.isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_otpSent ? 'Verify & continue' : 'Send OTP'),
        ),
      ],
    );
  }

  Future<void> _sendOtp(AuthProvider auth) async {
    if (_phoneController.text.length < 10) {
      _toast('Enter a valid 10-digit mobile number');
      return;
    }
    final res = await auth.sendPhoneOtp(_phoneController.text);
    if (!mounted) return;
    if (res != null) {
      setState(() {
        _otpSent = true;
        _otpHint = 'OTP sent to your mobile number.';
      });
      _startResendTimer();
      _toast('OTP sent to +91 ${_phoneController.text}');
    } else {
      _toast(auth.error ?? 'Could not send OTP');
    }
  }

  Widget _emailLogin(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: auth.isLoading
              ? null
              : () async {
                  final email = _emailController.text.trim();
                  final pass = _passwordController.text;
                  if (email.isEmpty || pass.length < 4) {
                    _toast('Enter email and password');
                    return;
                  }
                  final ok = await auth.loginWithEmail(email, pass);
                  if (!mounted) return;
                  if (ok) {
                    _goAfterLogin(context, auth);
                  } else {
                    _toast(auth.error ?? 'Login failed');
                  }
                },
          child: auth.isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Login'),
        ),
      ],
    );
  }

  Widget _signupBody(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _signupEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _signupPhoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: const InputDecoration(
            labelText: 'Mobile number',
            prefixText: '+91  ',
            prefixIcon: Icon(Icons.phone_android_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _signupPasswordController,
          obscureText: _obscureSignup,
          decoration: InputDecoration(
            labelText: 'Password (min 12)',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignup
                    ? Icons.visibility_outlined
                    : Icons.visibility_off,
              ),
              onPressed: () => setState(() => _obscureSignup = !_obscureSignup),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _signupConfirmController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _signupOtp,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(
            labelText: 'Phone verification code',
          ),
        ),
        TextButton(
          onPressed: auth.isLoading || _resendSeconds > 0
              ? null
              : () async {
                  final result = await auth.sendPhoneOtp(
                    _signupPhoneController.text,
                  );
                  if (!mounted) return;
                  if (result == null) {
                    _toast(auth.error ?? 'Unable to send code');
                    return;
                  }
                  setState(() => _signupOtpSent = true);
                  _startResendTimer();
                  _toast('Verification code sent');
                },
          child: Text(
            _resendSeconds > 0
                ? 'Resend in ${_resendSeconds}s'
                : _signupOtpSent
                ? 'Resend code'
                : 'Verify phone',
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: auth.isLoading
              ? null
              : () async {
                  final name = _nameController.text.trim();
                  final email = _signupEmailController.text.trim();
                  final phone = _signupPhoneController.text.trim();
                  final pass = _signupPasswordController.text;
                  final confirm = _signupConfirmController.text;
                  if (name.length < 2) {
                    _toast('Enter your full name');
                    return;
                  }
                  if (!email.contains('@')) {
                    _toast('Enter a valid email');
                    return;
                  }
                  if (phone.length < 10) {
                    _toast('Enter a valid 10-digit mobile number');
                    return;
                  }
                  if (pass.length < 12) {
                    _toast('Password must be at least 12 characters');
                    return;
                  }
                  if (pass != confirm) {
                    _toast('Passwords do not match');
                    return;
                  }
                  final ok = await auth.register(
                    name: name,
                    email: email,
                    phone: phone,
                    password: pass,
                    otp: _signupOtp.text,
                  );
                  if (!mounted) return;
                  if (ok) {
                    _goAfterLogin(context, auth);
                  } else {
                    _toast(auth.error ?? 'Sign up failed');
                  }
                },
          child: auth.isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create account'),
        ),
      ],
    );
  }

  void _goAfterLogin(BuildContext context, AuthProvider auth) {
    final next = widget.nextPath;
    if (next != null && next.startsWith('/')) {
      if (next.startsWith('/sell') || next.startsWith('/seller')) {
        if (auth.hasBusiness || auth.isSeller) {
          auth.enterSellerMode();
        }
      }
      context.go(next);
      return;
    }
    if (auth.user?.role == 'ADMIN') {
      context.go('/admin/applications');
      return;
    }
    if (widget.sellerMode && (auth.hasBusiness || auth.isSeller)) {
      auth.enterSellerMode();
      context.go('/seller');
      return;
    }
    if (widget.sellerMode) {
      context.go('/sell');
      return;
    }
    auth.enterBuyerMode();
    context.go('/home');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
