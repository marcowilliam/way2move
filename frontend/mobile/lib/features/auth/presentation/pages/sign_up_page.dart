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

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailLooksValid = false;

  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: WayMotion.settled,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: WayMotion.easeStandard,
    ));
    _slideController.forward();
    _emailController.addListener(_reevaluateEmail);
  }

  @override
  void dispose() {
    _emailController.removeListener(_reevaluateEmail);
    _slideController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
    final textSecondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg + AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                const Center(child: Way2MoveLogoMark(size: 56)),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Text(
                    'Start from the ground up.',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Center(
                  child: Text(
                    'Two minutes to set up. Voice-first from day one.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl - AppSpacing.sm),
                _buildForm(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildErrorBanner(),
                ],
                const SizedBox(height: AppSpacing.lg + AppSpacing.sm),
                _buildSignUpButton(),
                const SizedBox(height: AppSpacing.lg),
                _buildSignInLink(textSecondary),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _LabeledField(
            label: 'NAME',
            child: TextFormField(
              key: AppKeys.nameField,
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Marco'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
                hintText: '8+ characters',
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
                if (v.length < 8)
                  return 'Password must be at least 8 characters';
                return null;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _LabeledField(
            label: 'CONFIRM PASSWORD',
            child: TextFormField(
              key: AppKeys.confirmPasswordField,
              controller: _confirmController,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(hintText: 'Repeat password'),
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
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

  Widget _buildSignUpButton() {
    return FilledButton(
      key: AppKeys.submitButton,
      onPressed: _isLoading ? null : _handleSignUp,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textOnPrimary,
              ),
            )
          : const Text('Create account'),
    );
  }

  Widget _buildSignInLink(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTypography.manrope(
            size: 14,
            weight: FontWeight.w500,
            color: color,
          ),
        ),
        TextButton(
          key: AppKeys.signInLink,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => context.pop(),
          child: const Text('Sign in'),
        ),
      ],
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(authNotifierProvider.notifier).signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) =>
          setState(() => _errorMessage = _mapFailureToMessage(failure)),
      (_) => context.go(Routes.home),
    );
  }

  String _mapFailureToMessage(AppFailure failure) {
    if (failure is AuthFailure) {
      return switch (failure.code) {
        'email-already-in-use' => 'An account with this email already exists.',
        'invalid-email' => 'Please enter a valid email address.',
        'weak-password' => 'Password is too weak. Use at least 8 characters.',
        'network-request-failed' => 'No internet connection.',
        _ => 'Sign up failed. Please try again.',
      };
    }
    return 'Something went wrong. Please try again.';
  }
}

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
