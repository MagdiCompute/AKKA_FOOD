import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/user_profile/presentation/notifiers/profile_notifier.dart';
import '../theme/app_theme.dart';
import 'avatar_bank.dart';

/// A circular profile avatar button that appears in the AppBar.
///
/// Shows the user's avatar from the avatar bank, or their initials.
/// Tapping it calls [onTap] (typically navigates to the profile screen).
class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);
    final profile = profileAsync.valueOrNull;

    final avatarUrl = profile?.avatarUrl;
    final displayName = profile?.displayName ?? '';

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AvatarBankDisplay(
            avatarUrl: avatarUrl,
            radius: 16,
            displayName: displayName,
          ),
        ),
      ),
    );
  }
}
