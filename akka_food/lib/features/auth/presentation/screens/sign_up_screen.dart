import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/auth_state.dart';
import '../widgets/auth_validators.dart';

/// Sign-up screen — clean, minimal design matching the login screen.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAuthStateChange(AuthState? previous, AuthState next) {
    if (!mounted) return;
    if (next.status == AuthStatus.authenticated) {
      context.go(AppRoutes.home);
      return;
    }
    if (next.status == AuthStatus.error && next.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _displayNameController.text.trim(),
        );
  }

  Future<void> _signUpWithGoogle() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, _handleAuthStateChange);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/logo.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => Icon(Icons.restaurant, size: 20, color: AppColors.primaryBlue),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'AKKA Food',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ──────────────────────────────────────────────
                FadeInWidget(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Créer un compte',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Entrez vos informations pour créer votre compte.',
                        style: TextStyle(fontSize: 13, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Google sign-up ─────────────────────────────────────
                FadeInWidget(
                  delay: const Duration(milliseconds: 100),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _signUpWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 22),
                      label: const Text('Google'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: AppColors.textLight.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Divider ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.textLight.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Ou', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: AppColors.textLight.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Name field ─────────────────────────────────────────
                FadeInWidget(
                  delay: const Duration(milliseconds: 200),
                  child: _LabeledField(
                    label: 'Nom complet',
                    child: TextFormField(
                      controller: _displayNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: validateDisplayName,
                      style: const TextStyle(fontSize: 14),
                      decoration: _fieldDecoration('Nom complet'),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Email field ────────────────────────────────────────
                FadeInWidget(
                  delay: const Duration(milliseconds: 250),
                  child: _LabeledField(
                    label: 'Adresse e-mail',
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: validateEmail,
                      style: const TextStyle(fontSize: 14),
                      decoration: _fieldDecoration('Adresse e-mail'),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Password field ─────────────────────────────────────
                FadeInWidget(
                  delay: const Duration(milliseconds: 300),
                  child: _LabeledField(
                    label: 'Mot de passe',
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signUp(),
                      validator: validatePassword,
                      style: const TextStyle(fontSize: 14),
                      decoration: _fieldDecoration('Mot de passe').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textLight,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Doit contenir au moins 6 caractères.',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
                const SizedBox(height: 28),

                // ── Sign Up button ─────────────────────────────────────
                FadeInWidget(
                  delay: const Duration(milliseconds: 350),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : FilledButton(
                            onPressed: _signUp,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'S\'inscrire',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Sign In link ───────────────────────────────────────
                FadeInWidget(
                  delay: const Duration(milliseconds: 400),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Déjà un compte ? ',
                        style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                      ),
                      GestureDetector(
                        onTap: () => context.pushReplacement(AppRoutes.login),
                        child: Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Labeled field helper
// ---------------------------------------------------------------------------

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
