// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authRepositoryHash() => r'8cf736177f3eda3149196face33d807f7f451fac';

/// Provides the concrete [AuthRepository] bound to [IAuthRepository].
///
/// Override in tests by using `ProviderScope(overrides: [...])`.
///
/// Copied from [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = AutoDisposeProvider<IAuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = AutoDisposeProviderRef<IAuthRepository>;
String _$authNotifierHash() => r'f21b555e93a261a12775e5a1d59ee608876fa426';

/// Manages the global authentication state for the app.
///
/// Uses a synchronous [Notifier] (not [AsyncNotifier]) because [AuthState]
/// is a plain value object — loading/error states are encoded inside it.
///
/// On first build, [_restoreSession] is triggered asynchronously so the UI
/// can render immediately with [AuthStatus.initial] while the session check
/// runs in the background.
///
/// Copied from [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider =
    AutoDisposeNotifierProvider<AuthNotifier, AuthState>.internal(
      AuthNotifier.new,
      name: r'authNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthNotifier = AutoDisposeNotifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
