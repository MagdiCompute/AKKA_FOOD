// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_visibility_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$leaderboardVisibilityNotifierHash() =>
    r'39296dbf2fb4f1078d598794447c022b946b40b5';

/// Manages the `leaderboardVisible` toggle state for the current user.
///
/// Reads and writes directly to `/userScores/{uid}.leaderboardVisible` in
/// Firestore. This is separate from the notification preferences because
/// leaderboard visibility lives in a different collection.
///
/// Returns `null` when no user is signed in.
/// Defaults to `true` (opted in) when the document does not exist.
///
/// Satisfies Requirement 4 AC1.
///
/// Copied from [LeaderboardVisibilityNotifier].
@ProviderFor(LeaderboardVisibilityNotifier)
final leaderboardVisibilityNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      LeaderboardVisibilityNotifier,
      bool?
    >.internal(
      LeaderboardVisibilityNotifier.new,
      name: r'leaderboardVisibilityNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leaderboardVisibilityNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LeaderboardVisibilityNotifier = AutoDisposeAsyncNotifier<bool?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
