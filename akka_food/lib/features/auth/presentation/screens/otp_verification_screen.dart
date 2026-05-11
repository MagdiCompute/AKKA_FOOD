import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/auth_state.dart';

/// OTP verification screen.
///
/// Accepts a 6-digit one-time password and verifies it against the pending
/// [OtpRequest] stored in [AuthState.pendingOtpRequest].
///
/// A 60-second countdown timer controls the "Resend code" button — it is
/// disabled while the timer is running and re-enabled when it expires.
///
/// [phoneNumber] is the E.164 phone number the OTP was sent to. It is used
/// when the user requests a resend so the notifier can re-trigger the SMS.
///
/// Satisfies Requirement 3 (Account Verification).
class OtpVerificationScreen extends ConsumerStatefulWidget {
  /// The E.164 phone number the OTP was sent to.
  ///
  /// Passed via the router's `state.extra` field or directly from the
  /// calling screen.
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  static const _resendCooldownSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  Timer? _resendTimer;
  int _secondsRemaining = _resendCooldownSeconds;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _secondsRemaining = _resendCooldownSeconds;
      _canResend = false;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 0;
          _canResend = true;
          timer.cancel();
        }
      });
    });
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

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authNotifierProvider.notifier)
        .verifyOtp(_otpController.text.trim());
  }

  Future<void> _resend() async {
    await ref
        .read(authNotifierProvider.notifier)
        .signInWithPhone(widget.phoneNumber);
    _startResendTimer();
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  String? _validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the 6-digit code.';
    }
    if (value.trim().length != 6 ||
        !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Code must be exactly 6 digits.';
    }
    return null;
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
        title: const Text('Verify Your Account'),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : null,
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
                  // ── Instruction text ───────────────────────────────────
                  Text(
                    'Enter the 6-digit code sent to ${widget.phoneNumber}.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // ── OTP input ──────────────────────────────────────────
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _verify(),
                    validator: _validateOtp,
                    style: Theme.of(context).textTheme.headlineSmall,
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      hintText: '000000',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Verify button ──────────────────────────────────────
                  isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Verifying code',
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _verify,
                          child: const Text('Verify'),
                        ),
                  const SizedBox(height: 16),

                  // ── Resend button / countdown ──────────────────────────
                  Center(
                    child: _canResend
                        ? TextButton(
                            onPressed: isLoading ? null : _resend,
                            child: const Text('Resend code'),
                          )
                        : Text(
                            'Resend in ${_secondsRemaining}s',
                            style: Theme.of(context).textTheme.bodyMedium,
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
