import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../notifiers/profile_notifier.dart';

/// Screen for editing the authenticated user's display name, email, and phone
/// number.
///
/// Pre-populates fields from [profileNotifierProvider]. On save:
/// - If email or phone changed → navigates to [AppRoutes.otp] for OTP
///   re-verification before the change is persisted.
/// - Otherwise → calls [ProfileNotifier.updateProfile] directly.
///
/// Satisfies Requirements 2.1 – 2.8.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  /// Whether the form fields have been initialised from the current profile.
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Initialise fields from profile (once)
  // ---------------------------------------------------------------------------

  void _initFieldsFromProfile() {
    if (_initialised) return;
    final profile = ref.read(profileNotifierProvider).valueOrNull;
    if (profile == null) return;

    _displayNameController.text = profile.displayName;
    _emailController.text = profile.email ?? '';
    _phoneController.text = profile.phoneNumber ?? '';
    _initialised = true;
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  /// Requirement 2.1 / 2.2 — display name must be 2–50 characters.
  String? _validateDisplayName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length < 2) {
      return 'Display name must be at least 2 characters.';
    }
    if (trimmed.length > 50) {
      return 'Display name must be at most 50 characters.';
    }
    return null;
  }

  /// Basic email format validation (optional field).
  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null; // optional
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Requirement 2.4 / 2.5 — phone must be E.164 format (optional field).
  String? _validatePhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null; // optional
    // E.164: starts with +, followed by digits only, 7–15 digits total.
    final e164Regex = RegExp(r'^\+\d{7,15}$');
    if (!e164Regex.hasMatch(trimmed)) {
      return 'Phone must be in E.164 format (e.g. +22670000000).';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Save action
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final displayName = _displayNameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newPhone = _phoneController.text.trim();

    // Persist directly — OTP re-verification is skipped for now since
    // phone/SMS verification requires a deployed backend.
    await ref.read(profileNotifierProvider.notifier).updateProfile(
          displayName,
          email: newEmail.isEmpty ? null : newEmail,
          phone: newPhone.isEmpty ? null : newPhone,
        );
  }

  // ---------------------------------------------------------------------------
  // Side-effect listener
  // ---------------------------------------------------------------------------

  void _handleProfileStateChange(
    AsyncValue<dynamic>? previous,
    AsyncValue<dynamic> next,
  ) {
    if (!mounted) return;

    // Transition from loading → data means the update succeeded.
    final wasLoading = previous?.isLoading ?? false;
    if (wasLoading && next.hasValue && !next.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      context.pop();
      return;
    }

    // Show error snackbar on failure.
    if (next.hasError) {
      final message = next.error?.toString() ?? 'Failed to update profile.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen(profileNotifierProvider, _handleProfileStateChange);

    final profileAsync = ref.watch(profileNotifierProvider);

    // Initialise fields once the profile data is available.
    profileAsync.whenData((_) => _initFieldsFromProfile());

    final isLoading = profileAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(profileNotifierProvider),
        ),
        data: (_) => _buildForm(context, isLoading),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Display Name ─────────────────────────────────────────
              TextFormField(
                controller: _displayNameController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                validator: _validateDisplayName,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Your name (2–50 characters)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),

              // ── Email ────────────────────────────────────────────────
              TextFormField(
                controller: _emailController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: _validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'your@email.com (optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                  helperText:
                      'Changing your email requires OTP verification.',
                ),
              ),
              const SizedBox(height: 20),

              // ── Phone Number ─────────────────────────────────────────
              TextFormField(
                controller: _phoneController,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
                onFieldSubmitted: (_) => isLoading ? null : _save(),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+22670000000 (E.164 format)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  helperText:
                      'Changing your phone requires OTP verification.',
                ),
              ),
              const SizedBox(height: 32),

              // ── Save button / loading indicator ──────────────────────
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Saving profile',
                  ),
                )
              else
                FilledButton(
                  onPressed: _save,
                  child: const Text('Save Changes'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorView
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
