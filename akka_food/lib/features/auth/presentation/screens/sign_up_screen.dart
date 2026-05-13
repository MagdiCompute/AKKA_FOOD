import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/auth_state.dart';
import '../widgets/auth_validators.dart';

/// Registration mode — email/password or phone number.
enum _RegistrationMode { email, phone }

/// Sign-up screen.
///
/// Supports registration via email/password or phone number (E.164 format).
/// A [SegmentedButton] lets the user toggle between the two modes.
///
/// Satisfies Requirement 1 (User Registration with Email and Password) and
/// Requirement 2 (User Registration with Phone Number).
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  _RegistrationMode _mode = _RegistrationMode.email;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

    // Phone OTP flow: navigate to OTP screen when a pending request is set.
    if (next.status == AuthStatus.loading &&
        next.pendingOtpRequest != null &&
        (previous == null || previous.pendingOtpRequest == null)) {
      context.push(
        AppRoutes.otp,
        extra: _phoneController.text.trim(),
      );
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

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authNotifierProvider.notifier);

    if (_mode == _RegistrationMode.email) {
      await notifier.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim(),
      );
    } else {
      await notifier.signInWithPhone(_phoneController.text.trim());
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, _handleAuthStateChange);

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Mode toggle ────────────────────────────────────────
                SegmentedButton<_RegistrationMode>(
                  segments: const [
                    ButtonSegment(
                      value: _RegistrationMode.email,
                      label: Text('E-mail'),
                      icon: Icon(Icons.email_outlined),
                    ),
                    ButtonSegment(
                      value: _RegistrationMode.phone,
                      label: Text('Téléphone'),
                      icon: Icon(Icons.phone_outlined),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _mode = selected.first;
                      _formKey.currentState?.reset();
                    });
                  },
                ),
                const SizedBox(height: 24),

                // ── Display name ───────────────────────────────────────
                TextFormField(
                  controller: _displayNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: validateDisplayName,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    hintText: 'Votre nom',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Email or Phone field ───────────────────────────────
                if (_mode == _RegistrationMode.email) ...[
                  TextFormField(
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
                  const SizedBox(height: 16),

                  // ── Password ─────────────────────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
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
                  const SizedBox(height: 16),

                  // ── Confirm password ──────────────────────────────────
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signUp(),
                    validator: (value) => validateConfirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        tooltip: _obscureConfirmPassword
                            ? 'Afficher'
                            : 'Masquer',
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                ] else ...[
                  // ── Phone number ──────────────────────────────────────
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signUp(),
                    validator: validatePhoneNumber,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      hintText: '+22370000000',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // ── Sign Up button ─────────────────────────────────────
                isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: 'Création du compte',
                        ),
                      )
                    : FilledButton(
                        onPressed: _signUp,
                        child: const Text('S\'inscrire'),
                      ),
                const SizedBox(height: 16),

                // ── Sign In link ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Déjà un compte ?'),
                    TextButton(
                      onPressed: () => context.pushReplacement(AppRoutes.login),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
