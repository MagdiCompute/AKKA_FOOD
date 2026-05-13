import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/auth_state.dart';
import '../widgets/auth_validators.dart';

/// Sign-in screen.
///
/// Supports email/password sign-in, Google sign-in, and Facebook sign-in.
/// Navigates to [AppRoutes.home] on successful authentication.
///
/// Satisfies Requirement 4 (Sign-In with Email and Password) and
/// Requirement 6 (Social Login).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Side-effect listener
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authNotifierProvider.notifier)
        .signIn(_emailController.text.trim(), _passwordController.text);
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  Future<void> _signInWithFacebook() async {
    await ref.read(authNotifierProvider.notifier).signInWithFacebook();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Listen for side effects (navigation, SnackBars).
    ref.listen<AuthState>(authNotifierProvider, _handleAuthStateChange);

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Title ──────────────────────────────────────────────
                  FadeInWidget(
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AKKA Food',
                          style: Theme.of(context).textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Savourez le meilleur du Mali',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Email field ────────────────────────────────────────
                  FadeInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail',
                        hintText: 'vous@exemple.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Password field ─────────────────────────────────────
                  FadeInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      validator: validatePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscurePassword
                              ? 'Afficher'
                              : 'Masquer',
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Forgot password link ───────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Sign In button ─────────────────────────────────────
                  FadeInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Connexion en cours',
                            ),
                          )
                        : FilledButton(
                            onPressed: _signIn,
                            child: const Text('Se connecter'),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // ── Divider ────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'ou',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Google sign-in ─────────────────────────────────────
                  FadeInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata),
                      label: const Text('Continuer avec Google'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Facebook sign-in ───────────────────────────────────
                  FadeInWidget(
                    delay: const Duration(milliseconds: 450),
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _signInWithFacebook,
                      icon: const Icon(Icons.facebook),
                      label: const Text('Continuer avec Facebook'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Sign Up link ───────────────────────────────────────
                  FadeInWidget(
                    delay: const Duration(milliseconds: 500),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Pas encore de compte ?'),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.signup),
                          child: const Text('Créer un compte'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
