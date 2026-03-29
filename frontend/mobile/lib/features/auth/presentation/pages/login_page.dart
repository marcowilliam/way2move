import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                _buildHeader(theme),
                const SizedBox(height: 40),
                _buildForm(theme),
                const SizedBox(height: 16),
                if (_errorMessage != null) _buildErrorBanner(),
                const SizedBox(height: 24),
                _buildSignInButton(),
                const SizedBox(height: 16),
                _buildDivider(theme),
                const SizedBox(height: 16),
                _buildSocialButtons(),
                const SizedBox(height: 32),
                _buildCreateAccountLink(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Way2Move',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your movement operating system',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            key: AppKeys.emailField,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: AppKeys.passwordField,
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.accentRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                  color: AppColors.accentRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton(
      key: AppKeys.submitButton,
      onPressed: _isLoading ? null : _handleSignIn,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Text('Sign In'),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: theme.textTheme.bodySmall,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: AppKeys.googleSignInButton,
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            icon: const Icon(Icons.g_mobiledata, size: 24),
            label: const Text('Google'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            key: AppKeys.appleSignInButton,
            onPressed: _isLoading ? null : _handleAppleSignIn,
            icon: const Icon(Icons.apple, size: 20),
            label: const Text('Apple'),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ",
            style: theme.textTheme.bodyMedium),
        TextButton(
          key: AppKeys.createAccountButton,
          onPressed: () => context.push(Routes.signup),
          child: const Text('Create account'),
        ),
      ],
    );
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(authNotifierProvider.notifier)
        .signIn(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => setState(
          () => _errorMessage = _mapFailureToMessage(failure)),
      (_) => context.go(Routes.home),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result =
        await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    result.fold(
      (f) {
        if (f is! AuthFailure || f.code != 'sign-in-cancelled') {
          setState(() => _errorMessage = _mapFailureToMessage(f));
        }
      },
      (_) => context.go(Routes.home),
    );
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result =
        await ref.read(authNotifierProvider.notifier).signInWithApple();
    if (!mounted) return;
    setState(() => _isLoading = false);
    result.fold(
      (f) {
        if (f is! AuthFailure || f.code != 'sign-in-cancelled') {
          setState(() => _errorMessage = _mapFailureToMessage(f));
        }
      },
      (_) => context.go(Routes.home),
    );
  }

  String _mapFailureToMessage(AppFailure failure) {
    if (failure is AuthFailure) {
      return switch (failure.code) {
        'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password.',
        'user-not-found' => 'No account found with this email.',
        'invalid-email' => 'Please enter a valid email address.',
        'too-many-requests' =>
          'Too many attempts. Please try again later.',
        'network-request-failed' => 'No internet connection.',
        _ => 'Sign in failed. Please try again.',
      };
    }
    return 'Something went wrong. Please try again.';
  }
}
