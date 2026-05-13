import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A bank of pre-made avatar options for users to choose from.
///
/// Each avatar is a combination of a background color and an emoji/icon.
/// The selected avatar is stored as a URL-like string: "avatar://index"
/// which the profile system can recognize and render.

/// Available avatar options.
const List<AvatarOption> kAvatarOptions = [
  AvatarOption(emoji: '👨‍🍳', bgColor: Color(0xFF2B6CB0), label: 'Chef'),
  AvatarOption(emoji: '👩‍🍳', bgColor: Color(0xFFE53E3E), label: 'Cheffe'),
  AvatarOption(emoji: '🦁', bgColor: Color(0xFFF5A623), label: 'Lion'),
  AvatarOption(emoji: '🐘', bgColor: Color(0xFF718096), label: 'Éléphant'),
  AvatarOption(emoji: '🌍', bgColor: Color(0xFF38A169), label: 'Afrique'),
  AvatarOption(emoji: '🍕', bgColor: Color(0xFFDD6B20), label: 'Pizza'),
  AvatarOption(emoji: '🍔', bgColor: Color(0xFF975A16), label: 'Burger'),
  AvatarOption(emoji: '🥗', bgColor: Color(0xFF2F855A), label: 'Salade'),
  AvatarOption(emoji: '☕', bgColor: Color(0xFF553C9A), label: 'Café'),
  AvatarOption(emoji: '🎵', bgColor: Color(0xFFB83280), label: 'Musique'),
  AvatarOption(emoji: '⚽', bgColor: Color(0xFF276749), label: 'Football'),
  AvatarOption(emoji: '🌟', bgColor: Color(0xFFB7791F), label: 'Étoile'),
  AvatarOption(emoji: '🚀', bgColor: Color(0xFF2C5282), label: 'Fusée'),
  AvatarOption(emoji: '🎨', bgColor: Color(0xFF9B2C2C), label: 'Art'),
  AvatarOption(emoji: '📚', bgColor: Color(0xFF285E61), label: 'Livres'),
  AvatarOption(emoji: '💎', bgColor: Color(0xFF4C51BF), label: 'Diamant'),
];

/// Represents a single avatar option.
class AvatarOption {
  const AvatarOption({
    required this.emoji,
    required this.bgColor,
    required this.label,
  });

  final String emoji;
  final Color bgColor;
  final String label;

  /// Generates the avatar URL string for storage.
  String get avatarUrl => 'avatar://${kAvatarOptions.indexOf(this)}';
}

/// Returns the [AvatarOption] for a given avatar URL, or null if not found.
AvatarOption? avatarOptionFromUrl(String? url) {
  if (url == null || !url.startsWith('avatar://')) return null;
  final indexStr = url.replaceFirst('avatar://', '');
  final index = int.tryParse(indexStr);
  if (index == null || index < 0 || index >= kAvatarOptions.length) return null;
  return kAvatarOptions[index];
}

/// A bottom sheet that displays the avatar bank for selection.
class AvatarBankSheet extends StatelessWidget {
  const AvatarBankSheet({super.key, this.selectedUrl});

  final String? selectedUrl;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Choisir un avatar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          // Avatar grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: kAvatarOptions.length,
              itemBuilder: (context, index) {
                final option = kAvatarOptions[index];
                final isSelected = selectedUrl == option.avatarUrl;

                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(option.avatarUrl),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: option.bgColor,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: AppColors.primaryBlue,
                              width: 3,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        option.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Remove avatar option
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop('remove'),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Supprimer l\'avatar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Widget that renders an avatar from the bank (or fallback to initials).
class AvatarBankDisplay extends StatelessWidget {
  const AvatarBankDisplay({
    super.key,
    required this.avatarUrl,
    this.radius = 52,
    this.displayName = '',
  });

  final String? avatarUrl;
  final double radius;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final option = avatarOptionFromUrl(avatarUrl);

    if (option != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: option.bgColor,
        child: Text(
          option.emoji,
          style: TextStyle(fontSize: radius * 0.7),
        ),
      );
    }

    // Network image avatar
    if (avatarUrl != null && avatarUrl!.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        onBackgroundImageError: (_, __) {},
      );
    }

    // Fallback: initials
    final initials = _getInitials(displayName);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryBlue,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.white,
          fontSize: radius * 0.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
