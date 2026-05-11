import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/auth_notifier.dart';
import '../notifiers/auth_state.dart';
import '../widgets/auth_validators.dart';

/// Change-password screen (authenticated users only).
///
/// Requires the user to supply their current password before setting a new
/// one. On success a SnackBar confirms the change; on error a SnackBar shows
/// the error message.
///
/// Satisfies Requirement 10 (Change Password — Authenticated).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Side-effect listener
  // ---------------------------------------------------------------------------

  void _handleAuthStateChange(AuthState? previous, AuthState next) {
    if (!mounted) return;

    // Success: state returns to authenticated after a loading state.
    if (previous?.status == AuthStatus.loading &&
        next.status == AuthStatus.authenticated) {
      _formKey.currentState?.reset();
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully.'),
        ),
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

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).changePassword(
          _currentPasswordController.text,
          _newPasswordController.text,
        );
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
        title: const Text('Change Password'),
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
                  // ── Current password ───────────────────────────────────
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Current password is required.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        tooltip: _obscureCurrent
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () {
                          setState(() => _obscureCurrent = !_obscureCurrent);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── New password ───────────────────────────────────────
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    textInputAction: TextInputAction.next,
                    validator: validatePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        tooltip:
                            _obscureNew ? 'Show password' : 'Hide password',
                        onPressed: () {
                          setState(() => _obscureNew = !_obscureNew);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Confirm new password ───────────────────────────────
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _changePassword(),
                    validator: (value) => validateConfirmPassword(
                      value,
                      _newPasswordController.text,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        tooltip: _obscureConfirm
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Change Password button ─────────────────────────────
                  isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: 'Changing password',
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _changePassword,
                          child: const Text('Change Password'),
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
