// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firestoreLeaderboardDataSourceHash() =>
    r'f1b6e8d85c2abac2539615396dd9bc82dac0a2fc';

/// Provides the [FirestoreLeaderboardDataSource] wired to the default
/// [FirebaseFirestore] instance.
///
/// Override in tests via `ProviderScope(overrides: [...])`.
///
/// Copied from [firestoreLeaderboardDataSource].
@ProviderFor(firestoreLeaderboardDataSource)
final firestoreLeaderboardDataSourceProvider =
    AutoDisposeProvider<FirestoreLeaderboardDataSource>.internal(
      firestoreLeaderboardDataSource,
      name: r'firestoreLeaderboardDataSourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$firestoreLeaderboardDataSourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirestoreLeaderboardDataSourceRef =
    AutoDisposeProviderRef<FirestoreLeaderboardDataSource>;
String _$leaderboardRepositoryHash() =>
    r'3d9bbd12d688de9ab00904693ccc89c5f0fa46d0';

/// Provides the concrete [LeaderboardRepository] bound to
/// [ILeaderboardRepository].
///
/// Wires up all data-layer dependencies:
/// - [FirestoreLeaderboardDataSource] — real-time leaderboard streams and
///   user rank computation from Firestore.
/// - [FirebaseAuth] — current user identification.
///
/// Override in tests via `ProviderScope(overrides: [...])`.
///
/// Copied from [leaderboardRepository].
@ProviderFor(leaderboardRepository)
final leaderboardRepositoryProvider =
    AutoDisposeProvider<ILeaderboardRepository>.internal(
      leaderboardRepository,
      name: r'leaderboardRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leaderboardRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LeaderboardRepositoryRef =
    AutoDisposeProviderRef<ILeaderboardRepository>;
String _$leaderboardStreamHash() => r'13e3e8ec5a1e7751a398301e7772cec9deea76f0';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// A family [StreamProvider] that exposes a real-time stream of
/// [LeaderboardEntry] items for the given [period].
///
/// Uses [ILeaderboardRepository.watchLeaderboard] to subscribe to Firestore
/// `snapshots()` on the leaderboard document. The stream emits a new list
/// whenever the document changes (e.g., after a new order is completed and
/// the Cloud Function rebuilds the leaderboard).
///
/// When the user switches period tabs, Riverpod automatically disposes the
/// previous period's provider (cancelling the Firestore listener) and creates
/// a new one for the selected period.
///
/// Satisfies:
/// - Requirement 1 AC4: Return rankings for the selected period on tab switch.
/// - Requirement 1 AC5: Rankings update within 60 seconds of a new completed
///   order (real-time listener handles this).
///
/// Copied from [leaderboardStream].
@ProviderFor(leaderboardStream)
const leaderboardStreamProvider = LeaderboardStreamFamily();

/// A family [StreamProvider] that exposes a real-time stream of
/// [LeaderboardEntry] items for the given [period].
///
/// Uses [ILeaderboardRepository.watchLeaderboard] to subscribe to Firestore
/// `snapshots()` on the leaderboard document. The stream emits a new list
/// whenever the document changes (e.g., after a new order is completed and
/// the Cloud Function rebuilds the leaderboard).
///
/// When the user switches period tabs, Riverpod automatically disposes the
/// previous period's provider (cancelling the Firestore listener) and creates
/// a new one for the selected period.
///
/// Satisfies:
/// - Requirement 1 AC4: Return rankings for the selected period on tab switch.
/// - Requirement 1 AC5: Rankings update within 60 seconds of a new completed
///   order (real-time listener handles this).
///
/// Copied from [leaderboardStream].
class LeaderboardStreamFamily
    extends Family<AsyncValue<List<LeaderboardEntry>>> {
  /// A family [StreamProvider] that exposes a real-time stream of
  /// [LeaderboardEntry] items for the given [period].
  ///
  /// Uses [ILeaderboardRepository.watchLeaderboard] to subscribe to Firestore
  /// `snapshots()` on the leaderboard document. The stream emits a new list
  /// whenever the document changes (e.g., after a new order is completed and
  /// the Cloud Function rebuilds the leaderboard).
  ///
  /// When the user switches period tabs, Riverpod automatically disposes the
  /// previous period's provider (cancelling the Firestore listener) and creates
  /// a new one for the selected period.
  ///
  /// Satisfies:
  /// - Requirement 1 AC4: Return rankings for the selected period on tab switch.
  /// - Requirement 1 AC5: Rankings update within 60 seconds of a new completed
  ///   order (real-time listener handles this).
  ///
  /// Copied from [leaderboardStream].
  const LeaderboardStreamFamily();

  /// A family [StreamProvider] that exposes a real-time stream of
  /// [LeaderboardEntry] items for the given [period].
  ///
  /// Uses [ILeaderboardRepository.watchLeaderboard] to subscribe to Firestore
  /// `snapshots()` on the leaderboard document. The stream emits a new list
  /// whenever the document changes (e.g., after a new order is completed and
  /// the Cloud Function rebuilds the leaderboard).
  ///
  /// When the user switches period tabs, Riverpod automatically disposes the
  /// previous period's provider (cancelling the Firestore listener) and creates
  /// a new one for the selected period.
  ///
  /// Satisfies:
  /// - Requirement 1 AC4: Return rankings for the selected period on tab switch.
  /// - Requirement 1 AC5: Rankings update within 60 seconds of a new completed
  ///   order (real-time listener handles this).
  ///
  /// Copied from [leaderboardStream].
  LeaderboardStreamProvider call(LeaderboardPeriod period) {
    return LeaderboardStreamProvider(period);
  }

  @override
  LeaderboardStreamProvider getProviderOverride(
    covariant LeaderboardStreamProvider provider,
  ) {
    return call(provider.period);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'leaderboardStreamProvider';
}

/// A family [StreamProvider] that exposes a real-time stream of
/// [LeaderboardEntry] items for the given [period].
///
/// Uses [ILeaderboardRepository.watchLeaderboard] to subscribe to Firestore
/// `snapshots()` on the leaderboard document. The stream emits a new list
/// whenever the document changes (e.g., after a new order is completed and
/// the Cloud Function rebuilds the leaderboard).
///
/// When the user switches period tabs, Riverpod automatically disposes the
/// previous period's provider (cancelling the Firestore listener) and creates
/// a new one for the selected period.
///
/// Satisfies:
/// - Requirement 1 AC4: Return rankings for the selected period on tab switch.
/// - Requirement 1 AC5: Rankings update within 60 seconds of a new completed
///   order (real-time listener handles this).
///
/// Copied from [leaderboardStream].
class LeaderboardStreamProvider
    extends AutoDisposeStreamProvider<List<LeaderboardEntry>> {
  /// A family [StreamProvider] that exposes a real-time stream of
  /// [LeaderboardEntry] items for the given [period].
  ///
  /// Uses [ILeaderboardRepository.watchLeaderboard] to subscribe to Firestore
  /// `snapshots()` on the leaderboard document. The stream emits a new list
  /// whenever the document changes (e.g., after a new order is completed and
  /// the Cloud Function rebuilds the leaderboard).
  ///
  /// When the user switches period tabs, Riverpod automatically disposes the
  /// previous period's provider (cancelling the Firestore listener) and creates
  /// a new one for the selected period.
  ///
  /// Satisfies:
  /// - Requirement 1 AC4: Return rankings for the selected period on tab switch.
  /// - Requirement 1 AC5: Rankings update within 60 seconds of a new completed
  ///   order (real-time listener handles this).
  ///
  /// Copied from [leaderboardStream].
  LeaderboardStreamProvider(LeaderboardPeriod period)
    : this._internal(
        (ref) => leaderboardStream(ref as LeaderboardStreamRef, period),
        from: leaderboardStreamProvider,
        name: r'leaderboardStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$leaderboardStreamHash,
        dependencies: LeaderboardStreamFamily._dependencies,
        allTransitiveDependencies:
            LeaderboardStreamFamily._allTransitiveDependencies,
        period: period,
      );

  LeaderboardStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.period,
  }) : super.internal();

  final LeaderboardPeriod period;

  @override
  Override overrideWith(
    Stream<List<LeaderboardEntry>> Function(LeaderboardStreamRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LeaderboardStreamProvider._internal(
        (ref) => create(ref as LeaderboardStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        period: period,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<LeaderboardEntry>> createElement() {
    return _LeaderboardStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LeaderboardStreamProvider && other.period == period;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, period.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LeaderboardStreamRef
    on AutoDisposeStreamProviderRef<List<LeaderboardEntry>> {
  /// The parameter `period` of this provider.
  LeaderboardPeriod get period;
}

class _LeaderboardStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<LeaderboardEntry>>
    with LeaderboardStreamRef {
  _LeaderboardStreamProviderElement(super.provider);

  @override
  LeaderboardPeriod get period => (origin as LeaderboardStreamProvider).period;
}

String _$leaderboardNotifierHash() =>
    r'd549f1119801a0217bfb50844293d74442196aa4';

/// Manages the leaderboard state for the Leaderboard feature.
///
/// Responsibilities:
/// - Fetching the top 100 leaderboard entries for a given [LeaderboardPeriod].
/// - Tracking the currently selected period via [_period].
/// - Providing the current user's [LeaderboardEntry] (whether in top 100 or
///   computed rank outside top 100).
/// - Handling loading/error states via [AsyncValue].
///
/// Satisfies:
/// - Requirement 1 AC1: Return top 100 entries ranked by score descending.
/// - Requirement 1 AC3: Support three period tabs (All-Time, Monthly, Weekly).
/// - Requirement 1 AC4: Return rankings for the selected period on tab switch.
/// - Requirement 2 AC2: Display user's rank when outside top 100.
///
/// Copied from [LeaderboardNotifier].
@ProviderFor(LeaderboardNotifier)
final leaderboardNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      LeaderboardNotifier,
      List<LeaderboardEntry>
    >.internal(
      LeaderboardNotifier.new,
      name: r'leaderboardNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leaderboardNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LeaderboardNotifier =
    AutoDisposeAsyncNotifier<List<LeaderboardEntry>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
