// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_stream_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionStreamHash() => r'af7deb42177e58e171fea6214416a6c77f6d9c2a';

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

/// A family [StreamProvider] that exposes a real-time [domain.Transaction]
/// stream for a given [transactionId].
///
/// The UI can watch this provider directly to reactively rebuild whenever
/// the Firestore transaction document changes (e.g., status transitions
/// from `pending` → `processing` → `success`).
///
/// Usage in a widget:
/// ```dart
/// final asyncTransaction = ref.watch(transactionStreamProvider(transactionId));
/// asyncTransaction.when(
///   data: (transaction) => Text(transaction.status.name),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
///
/// This provider is auto-disposed when no longer watched, which automatically
/// cancels the underlying Firestore snapshot listener.
///
/// Copied from [transactionStream].
@ProviderFor(transactionStream)
const transactionStreamProvider = TransactionStreamFamily();

/// A family [StreamProvider] that exposes a real-time [domain.Transaction]
/// stream for a given [transactionId].
///
/// The UI can watch this provider directly to reactively rebuild whenever
/// the Firestore transaction document changes (e.g., status transitions
/// from `pending` → `processing` → `success`).
///
/// Usage in a widget:
/// ```dart
/// final asyncTransaction = ref.watch(transactionStreamProvider(transactionId));
/// asyncTransaction.when(
///   data: (transaction) => Text(transaction.status.name),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
///
/// This provider is auto-disposed when no longer watched, which automatically
/// cancels the underlying Firestore snapshot listener.
///
/// Copied from [transactionStream].
class TransactionStreamFamily extends Family<AsyncValue<domain.Transaction>> {
  /// A family [StreamProvider] that exposes a real-time [domain.Transaction]
  /// stream for a given [transactionId].
  ///
  /// The UI can watch this provider directly to reactively rebuild whenever
  /// the Firestore transaction document changes (e.g., status transitions
  /// from `pending` → `processing` → `success`).
  ///
  /// Usage in a widget:
  /// ```dart
  /// final asyncTransaction = ref.watch(transactionStreamProvider(transactionId));
  /// asyncTransaction.when(
  ///   data: (transaction) => Text(transaction.status.name),
  ///   loading: () => CircularProgressIndicator(),
  ///   error: (e, st) => Text('Error: $e'),
  /// );
  /// ```
  ///
  /// This provider is auto-disposed when no longer watched, which automatically
  /// cancels the underlying Firestore snapshot listener.
  ///
  /// Copied from [transactionStream].
  const TransactionStreamFamily();

  /// A family [StreamProvider] that exposes a real-time [domain.Transaction]
  /// stream for a given [transactionId].
  ///
  /// The UI can watch this provider directly to reactively rebuild whenever
  /// the Firestore transaction document changes (e.g., status transitions
  /// from `pending` → `processing` → `success`).
  ///
  /// Usage in a widget:
  /// ```dart
  /// final asyncTransaction = ref.watch(transactionStreamProvider(transactionId));
  /// asyncTransaction.when(
  ///   data: (transaction) => Text(transaction.status.name),
  ///   loading: () => CircularProgressIndicator(),
  ///   error: (e, st) => Text('Error: $e'),
  /// );
  /// ```
  ///
  /// This provider is auto-disposed when no longer watched, which automatically
  /// cancels the underlying Firestore snapshot listener.
  ///
  /// Copied from [transactionStream].
  TransactionStreamProvider call(String transactionId) {
    return TransactionStreamProvider(transactionId);
  }

  @override
  TransactionStreamProvider getProviderOverride(
    covariant TransactionStreamProvider provider,
  ) {
    return call(provider.transactionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'transactionStreamProvider';
}

/// A family [StreamProvider] that exposes a real-time [domain.Transaction]
/// stream for a given [transactionId].
///
/// The UI can watch this provider directly to reactively rebuild whenever
/// the Firestore transaction document changes (e.g., status transitions
/// from `pending` → `processing` → `success`).
///
/// Usage in a widget:
/// ```dart
/// final asyncTransaction = ref.watch(transactionStreamProvider(transactionId));
/// asyncTransaction.when(
///   data: (transaction) => Text(transaction.status.name),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
///
/// This provider is auto-disposed when no longer watched, which automatically
/// cancels the underlying Firestore snapshot listener.
///
/// Copied from [transactionStream].
class TransactionStreamProvider
    extends AutoDisposeStreamProvider<domain.Transaction> {
  /// A family [StreamProvider] that exposes a real-time [domain.Transaction]
  /// stream for a given [transactionId].
  ///
  /// The UI can watch this provider directly to reactively rebuild whenever
  /// the Firestore transaction document changes (e.g., status transitions
  /// from `pending` → `processing` → `success`).
  ///
  /// Usage in a widget:
  /// ```dart
  /// final asyncTransaction = ref.watch(transactionStreamProvider(transactionId));
  /// asyncTransaction.when(
  ///   data: (transaction) => Text(transaction.status.name),
  ///   loading: () => CircularProgressIndicator(),
  ///   error: (e, st) => Text('Error: $e'),
  /// );
  /// ```
  ///
  /// This provider is auto-disposed when no longer watched, which automatically
  /// cancels the underlying Firestore snapshot listener.
  ///
  /// Copied from [transactionStream].
  TransactionStreamProvider(String transactionId)
    : this._internal(
        (ref) => transactionStream(ref as TransactionStreamRef, transactionId),
        from: transactionStreamProvider,
        name: r'transactionStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$transactionStreamHash,
        dependencies: TransactionStreamFamily._dependencies,
        allTransitiveDependencies:
            TransactionStreamFamily._allTransitiveDependencies,
        transactionId: transactionId,
      );

  TransactionStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.transactionId,
  }) : super.internal();

  final String transactionId;

  @override
  Override overrideWith(
    Stream<domain.Transaction> Function(TransactionStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TransactionStreamProvider._internal(
        (ref) => create(ref as TransactionStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        transactionId: transactionId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<domain.Transaction> createElement() {
    return _TransactionStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionStreamProvider &&
        other.transactionId == transactionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, transactionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TransactionStreamRef on AutoDisposeStreamProviderRef<domain.Transaction> {
  /// The parameter `transactionId` of this provider.
  String get transactionId;
}

class _TransactionStreamProviderElement
    extends AutoDisposeStreamProviderElement<domain.Transaction>
    with TransactionStreamRef {
  _TransactionStreamProviderElement(super.provider);

  @override
  String get transactionId =>
      (origin as TransactionStreamProvider).transactionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
