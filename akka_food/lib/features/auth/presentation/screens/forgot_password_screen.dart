import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/auth_state.dart';
import '../widgets/auth_validators.dart';

/// Forgot-password screen.
///
/// Supports password reset via email (sends a reset link) or via phone
/// (sends an OTP and navigates to [OtpVerificationScreen]).
///
/// Satisfies Requirement 9 (Forgot Password and Password Reset).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _usePhone = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Side-effect listener
  // ---------------------------------------------------------------------------

  void _handleAuthStateChange(AuthState? previous, AuthState next) {
    if (!mounted) return;

    // Email reset: notifier emits unauthenticated on success.
    if (!_usePhone &&
        previous?.status == AuthStatus.loading &&
        next.status == AuthStatus.unauthenticated) {
      setState(() => _emailSent = true);
      return;
    }

    // Phone OTP flow: navigate to OTP screen when a pending request is set.
    if (_usePhone &&
        next.status == AuthStatus.loading &&
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

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authNotifierProvider.notifier);

    if (_usePhone) {
      await notifier.signInWithPhone(_phoneController.text.trim());
    } else {
      await notifier.resetPassword(_emailController.text.trim());
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
        title: const Text('Mot de passe oublié'),
        leading: BackButton(
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
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
                  Text(
                    'Réinitialisez votre mot de passe',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _usePhone
                        ? 'Entrez votre numéro de téléphone pour recevoir un code de vérification.'
                        : 'Entrez votre adresse e-mail pour recevoir un lien de réinitialisation.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ── Mode toggle ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('E-mail'),
                        selected: !_usePhone,
                        onSelected: (_) {
                          setState(() {
                            _usePhone = false;
                            _emailSent = false;
                            _formKey.currentState?.reset();
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Téléphone'),
                        selected: _usePhone,
                        onSelected: (_) {
                          setState(() {
                            _usePhone = true;
                            _emailSent = false;
                            _formKey.currentState?.reset();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Success message (email mode only) ──────────────────
                  if (_emailSent) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Lien de réinitialisation envoyé ! Vérifiez votre boîte e-mail.',
                              style: TextStyle(color: Colors.green.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Email or Phone field ───────────────────────────────
                  if (!_usePhone)
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      onFieldSubmitted: (_) => _sendResetCode(),
                      validator: validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        hintText: 'vous@exemple.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    )
                  else
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _sendResetCode(),
                      validator: validatePhoneNumber,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        hintText: '+22670000000',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Send Reset Code button ─────────────────────────────
                  isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Sending reset code',
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _emailSent ? null : _sendResetCode,
                          child: Text(
                            _usePhone ? 'Envoyer le code' : 'Envoyer le lien',
                          ),
                        ),
                  const SizedBox(height: 16),

                  // ── Back to Sign In ────────────────────────────────────
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Retour à la connexion'),
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
