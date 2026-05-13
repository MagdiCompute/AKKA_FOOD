import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repositories/profile_repository.dart' show kDefaultAvatarUrl;
import '../notifiers/profile_notifier.dart';

/// A reusable widget that handles the full avatar pick → compress → upload
/// flow with a progress indicator overlay.
///
/// Shows the current avatar from [profileNotifierProvider] as a circular
/// image with a camera icon overlay. Tapping the overlay opens a bottom
/// sheet with options to take a photo, choose from gallery, or remove the
/// current avatar.
///
/// Satisfies Requirements 3.1, 3.2, 3.3, 3.4, 3.5.
class AvatarPickerWidget extends ConsumerWidget {
  const AvatarPickerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final isLoading = profileAsync.isLoading;

    final avatarUrl = profileAsync.valueOrNull?.avatarUrl;
    final hasRealAvatar = avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl != kDefaultAvatarUrl;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () => _showPickerBottomSheet(context, ref, hasRealAvatar),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // ── Avatar circle ──────────────────────────────────────────
          _AvatarCircle(avatarUrl: avatarUrl, isLoading: isLoading),

          // ── Camera icon overlay ────────────────────────────────────
          if (!isLoading)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.camera_alt,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom sheet
  // ---------------------------------------------------------------------------

  Future<void> _showPickerBottomSheet(
    BuildContext context,
    WidgetRef ref,
    bool hasRealAvatar,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Photo de profil',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(context, ref, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(context, ref, ImageSource.gallery);
              },
            ),
            if (hasRealAvatar)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  'Supprimer la photo',
                  style: TextStyle(
                    color: Theme.of(ctx).colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _removeAvatar(context, ref);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Image picking
  // ---------------------------------------------------------------------------

  Future<void> _pickImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 90, // Pre-pick quality hint; real compression is in repo
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (picked == null) return; // User cancelled

    if (kIsWeb) {
      // On web, dart:io File is not available. Show a message.
      if (context.mounted) {
        _showErrorSnackbar(
          context,
          'L\'envoi de photo n\'est pas disponible sur le web. Utilisez l\'application mobile.',
        );
      }
      return;
    }

    final file = File(picked.path);

    try {
      await ref
          .read(profileNotifierProvider.notifier)
          .uploadAvatar(file);
    } catch (_) {
      // Error is already reflected in profileNotifierProvider state.
      // Show a snackbar if the context is still mounted.
      if (context.mounted) {
        _showErrorSnackbar(context, 'Échec de l\'envoi. Veuillez réessayer.');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Remove avatar
  // ---------------------------------------------------------------------------

  Future<void> _removeAvatar(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(profileNotifierProvider.notifier).removeAvatar();
    } catch (_) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Échec de la suppression. Veuillez réessayer.');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AvatarCircle
// ---------------------------------------------------------------------------

/// Renders the circular avatar image with an optional loading overlay.
class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.avatarUrl,
    required this.isLoading,
  });

  final String? avatarUrl;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar = avatarUrl != null &&
        avatarUrl!.isNotEmpty &&
        avatarUrl != kDefaultAvatarUrl;

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
          onBackgroundImageError: hasAvatar
              ? (_, __) {} // Silently ignore load errors; fallback to icon
              : null,
          child: hasAvatar
              ? null
              : Icon(
                  Icons.person,
                  size: 52,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),

        // Upload progress overlay
        if (isLoading)
          Container(
            width: 104, // diameter = radius * 2
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.45),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
      ],
    );
  }
}
