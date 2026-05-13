import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../data/datasources/hive_profile_cache.dart';
import '../../domain/entities/user_profile.dart';
import '../notifiers/coin_history_notifier.dart';
import '../notifiers/profile_notifier.dart';
import '../widgets/avatar_picker_widget.dart';

/// The main profile hub screen.
///
/// Displays the authenticated user's avatar, display name, email, and phone
/// number, then provides navigation tiles to all profile sub-sections.
///
/// Satisfies Requirements 1.1, 1.3, 8.1, 9.7, 9.8.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(profileNotifierProvider),
        ),
        data: (profile) => _ProfileBody(profile: profile),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProfileBody
// ---------------------------------------------------------------------------

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinBalanceAsync = ref.watch(coinBalanceProvider);

    return ListView(
      children: [
        // ── Connectivity banner (stale cache) ──────────────────────────
        // The SWR pattern in ProfileNotifier emits cached data first, then
        // fresh data. When the notifier is in a hasError state but still
        // carries a previous value, we know we're showing stale data.
        if (ref.watch(profileNotifierProvider).hasError)
          _ConnectivityBanner(),

        // ── Avatar + user info ─────────────────────────────────────────
        _AvatarSection(profile: profile, avatarPicker: const AvatarPickerWidget()),

        const SizedBox(height: 8),

        // ── Navigation tiles ──────────────────────────────────────────
        _SectionHeader(title: 'Compte'),
        _NavTile(
          icon: Icons.person_outline,
          title: 'Modifier le profil',
          onTap: () => context.push(AppRoutes.editProfile),
        ),
        _NavTile(
          icon: Icons.location_on_outlined,
          title: 'Mes adresses',
          onTap: () => context.push(AppRoutes.addresses),
        ),
        _NavTile(
          icon: Icons.receipt_long_outlined,
          title: 'Historique des commandes',
          onTap: () => context.push(AppRoutes.orderHistory),
        ),
        _NavTile(
          icon: Icons.monetization_on_outlined,
          title: 'Mes coins',
          trailing: coinBalanceAsync.when(
            data: (balance) => _CoinBadge(balance: balance),
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          onTap: () => context.push(AppRoutes.coinHistory),
        ),
        _NavTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: () => context.push(AppRoutes.notificationPrefs),
        ),

        const Divider(height: 32),

        // ── Account lifecycle ─────────────────────────────────────────
        _SectionHeader(title: 'Gestion du compte'),
        _NavTile(
          icon: Icons.pause_circle_outline,
          title: 'Désactiver le compte',
          iconColor: Colors.orange,
          titleColor: Colors.orange,
          onTap: () => _showDeactivateDialog(context, ref),
        ),
        _NavTile(
          icon: Icons.delete_outline,
          title: 'Supprimer le compte',
          iconColor: Colors.red,
          titleColor: Colors.red,
          onTap: () => _showDeleteDialog(context, ref),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Account lifecycle dialogs
  // ---------------------------------------------------------------------------

  /// Shows a password confirmation dialog and returns the entered password,
  /// or `null` if the user cancelled.
  Future<String?> _showPasswordDialog(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color confirmColor,
    required String confirmLabel,
  }) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    bool obscure = true;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscure,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(ctx).pop(passwordController.text);
                }
              },
              style: TextButton.styleFrom(foregroundColor: confirmColor),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ),
    );
  }

  /// Task 7.1 — Account deactivation flow.
  ///
  /// 1. Shows a password confirmation dialog (Requirement 8.1).
  /// 2. Calls the `deactivateAccount` Cloud Function with the password.
  /// 3. On success: signs the user out and navigates to the login screen.
  /// 4. On failure: shows an error snackbar (Requirement 8.5).
  Future<void> _showDeactivateDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final password = await _showPasswordDialog(
      context,
      title: 'Deactivate Account',
      subtitle:
          'Your account will be temporarily deactivated. You can reactivate it '
          'at any time by signing in again.\n\nEnter your current password to confirm.',
      confirmColor: Colors.orange,
      confirmLabel: 'Deactivate',
    );

    if (password == null || !context.mounted) return;

    // Show a loading indicator while the Cloud Function call is in flight.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFunctions.instance
          .httpsCallable('deactivateAccount')
          .call({'password': password});

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loader
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(AppRoutes.login);
      }
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Deactivation failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deactivation failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Task 7.2 — Account deletion flow.
  ///
  /// 1. Shows an irreversible confirmation dialog (Requirement 9.8).
  /// 2. If confirmed, shows a password confirmation dialog (Requirement 9.1).
  /// 3. Calls the `deleteAccount` Cloud Function with the password.
  /// 4. On success: clears Hive cache, signs the user out, navigates to login
  ///    (Requirement 9.7).
  /// 5. On failure: shows an error snackbar without clearing local data.
  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Step 1 — Irreversible confirmation dialog (Requirement 9.8).
    final irreversibleConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and cannot be undone.\n\n'
          'All your personal data, delivery addresses, coin balance, and '
          'transaction history will be permanently deleted. '
          'Your order records will be anonymised for legal compliance.\n\n'
          'Are you absolutely sure you want to delete your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, delete my account'),
          ),
        ],
      ),
    );

    if (irreversibleConfirmed != true || !context.mounted) return;

    // Step 2 — Password confirmation dialog.
    final password = await _showPasswordDialog(
      context,
      title: 'Confirm Deletion',
      subtitle: 'Enter your current password to permanently delete your account.',
      confirmColor: Colors.red,
      confirmLabel: 'Delete',
    );

    if (password == null || !context.mounted) return;

    // Show a loading indicator while the Cloud Function call is in flight.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFunctions.instance
          .httpsCallable('deleteAccount')
          .call({'password': password});

      // Clear local Hive cache before signing out (Requirement 9.7).
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid != null) {
        final cache = await HiveProfileCache.open();
        await cache.clearAll(uid);
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loader
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(AppRoutes.login);
      }
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Account deletion failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deletion failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// _AvatarSection
// ---------------------------------------------------------------------------

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.profile,
    required this.avatarPicker,
  });

  final UserProfile? profile;
  final Widget avatarPicker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Avatar picker (handles pick → compress → upload flow)
          avatarPicker,

          const SizedBox(height: 16),

          // Display name
          Text(
            profile?.displayName ?? '—',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          // Email
          if (profile?.email != null && profile!.email!.isNotEmpty)
            Text(
              profile!.email!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

          const SizedBox(height: 2),

          // Phone number
          if (profile?.phoneNumber != null &&
              profile!.phoneNumber!.isNotEmpty)
            Text(
              profile!.phoneNumber!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ConnectivityBanner
// ---------------------------------------------------------------------------

class _ConnectivityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Vous êtes hors ligne. Données en cache affichées.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SectionHeader
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NavTile
// ---------------------------------------------------------------------------

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
        iconColor ?? theme.colorScheme.onSurfaceVariant;
    final effectiveTitleColor = titleColor ?? theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: effectiveIconColor),
      title: Text(
        title,
        style: TextStyle(color: effectiveTitleColor),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// _CoinBadge
// ---------------------------------------------------------------------------

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$balance',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorView
// ---------------------------------------------------------------------------

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              'Échec du chargement du profil',
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
              label: const Text('Réessayer'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}
