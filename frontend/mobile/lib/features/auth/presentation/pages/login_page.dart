import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/way2move_logo_mark.dart';
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
  bool _emailLooksValid = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: WayMotion.easeStandard);
    _fadeController.forward();
    _emailController.addListener(_reevaluateEmail);
  }

  @override
  void dispose() {
    _emailController.removeListener(_reevaluateEmail);
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _reevaluateEmail() {
    final looks = _emailController.text.contains('@') &&
        _emailController.text.contains('.');
    if (looks != _emailLooksValid) {
      setState(() => _emailLooksValid = looks);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg + AppSpacing.xs, // 28
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                const Center(child: Way2MoveLogoMark(size: 56)),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Text(
                    'Welcome back.',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Center(
                  child: Text(
                    'Pick up where you left off.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl - AppSpacing.sm),
                _buildForm(textSecondary),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildErrorBanner(),
                ],
                const SizedBox(height: AppSpacing.lg + AppSpacing.sm),
                _buildSignInButton(),
                const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
                _buildOrDivider(textSecondary),
                const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
                _buildSocialButtons(),
                const SizedBox(height: AppSpacing.xl),
                _buildCreateAccountLink(textSecondary),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Color labelColor) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _LabeledField(
            label: 'EMAIL',
            child: TextFormField(
              key: AppKeys.emailField,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'you@email.com',
                suffixIcon: _emailLooksValid
                    ? const Icon(Icons.check_circle_outline,
                        color: AppColors.accent, size: 20)
                    : null,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _LabeledField(
            label: 'PASSWORD',
            child: TextFormField(
              key: AppKeys.passwordField,
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                return null;
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot password?',
                style: AppTypography.manrope(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return AnimatedContainer(
      duration: WayMotion.standard,
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.manrope(
                size: 13,
                weight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton() {
    return FilledButton(
      key: AppKeys.submitButton,
      onPressed: _isLoading ? null : _handleSignIn,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textOnPrimary,
              ),
            )
          : const Text('Sign in'),
    );
  }

  Widget _buildOrDivider(Color color) {
    return Row(
      children: [
        Expanded(child: Divider(color: color.withValues(alpha: 0.25))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'OR',
            style: AppTypography.manrope(
              size: 11,
              weight: FontWeight.w700,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: color.withValues(alpha: 0.25))),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        OutlinedButton.icon(
          key: AppKeys.googleSignInButton,
          onPressed: _isLoading ? null : _handleGoogleSignIn,
          icon: const Icon(Icons.g_mobiledata, size: 22),
          label: const Text('Continue with Google'),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        OutlinedButton.icon(
          key: AppKeys.appleSignInButton,
          onPressed: _isLoading ? null : _handleAppleSignIn,
          icon: const Icon(Icons.apple, size: 20),
          label: const Text('Continue with Apple'),
        ),
      ],
    );
  }

  Widget _buildCreateAccountLink(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'New here? ',
          style: AppTypography.manrope(
            size: 14,
            weight: FontWeight.w500,
            color: color,
          ),
        ),
        TextButton(
          key: AppKeys.createAccountButton,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
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
      (failure) =>
          setState(() => _errorMessage = _mapFailureToMessage(failure)),
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
        'wrong-password' ||
        'invalid-credential' =>
          'Incorrect email or password.',
        'user-not-found' => 'No account found with this email.',
        'invalid-email' => 'Please enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' => 'No internet connection.',
        _ => 'Sign in failed. Please try again.',
      };
    }
    return 'Something went wrong. Please try again.';
  }
}

/// Uppercase tracked label + underlined input — the signature auth-form look.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.manrope(
            size: 11,
            weight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
        child,
      ],
    );
  }
}
