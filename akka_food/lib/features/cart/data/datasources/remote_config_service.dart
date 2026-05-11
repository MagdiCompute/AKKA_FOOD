import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_config_service.g.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Remote Config parameter key for the delivery fee in XOF.
const String kDeliveryFeeKey = 'delivery_fee_xof';

/// Default delivery fee in XOF, used when Remote Config is unavailable.
const double kDefaultDeliveryFeeXof = 500.0;

// ---------------------------------------------------------------------------
// RemoteConfigService
// ---------------------------------------------------------------------------

/// Wraps [FirebaseRemoteConfig] to provide typed access to remote parameters.
///
/// Responsibilities:
/// - Sets default values for all remote parameters.
/// - Provides a typed getter for the delivery fee.
/// - Handles fetch and activation (called on app start via task 6.2).
///
/// This class is intentionally thin — it delegates all caching and fetch
/// logic to the Firebase Remote Config SDK.
class RemoteConfigService {
  RemoteConfigService(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  /// Initializes Remote Config with default values and recommended settings.
  ///
  /// Call this once during app startup before reading any parameter values.
  Future<void> initialize() async {
    // Set defaults so the app works even if fetch fails or is pending.
    await _remoteConfig.setDefaults(<String, dynamic>{
      kDeliveryFeeKey: kDefaultDeliveryFeeXof.toInt(),
    });

    // Use a minimum fetch interval of 1 hour for production.
    // During development, this can be lowered via Firebase console.
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
  }

  /// Fetches the latest values from Firebase Remote Config and activates them.
  ///
  /// Returns `true` if new values were fetched and activated, `false` otherwise.
  /// Errors are caught and logged silently — the app falls back to defaults.
  Future<bool> fetchAndActivate() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('RemoteConfigService: fetchAndActivate failed: $e');
      return false;
    }
  }

  /// Returns the current delivery fee in XOF from Remote Config.
  ///
  /// Falls back to [kDefaultDeliveryFeeXof] if the parameter is not set or
  /// Remote Config has not been fetched yet.
  double get deliveryFeeXof {
    final value = _remoteConfig.getDouble(kDeliveryFeeKey);
    // Guard against misconfigured zero or negative values.
    return value > 0 ? value : kDefaultDeliveryFeeXof;
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Provides the singleton [RemoteConfigService] instance.
///
/// The service is initialized lazily on first access. Subsequent reads
/// return the same instance.
@riverpod
Future<RemoteConfigService> remoteConfigService(Ref ref) async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  final service = RemoteConfigService(remoteConfig);
  await service.initialize();
  return service;
}

/// Provides the current delivery fee in XOF from Firebase Remote Config.
///
/// Returns [kDefaultDeliveryFeeXof] (500) if Remote Config is not yet
/// initialized or if the fetch failed.
///
/// Usage in the Cart entity or notifier:
/// ```dart
/// final fee = ref.watch(deliveryFeeProvider);
/// ```
@riverpod
double deliveryFee(Ref ref) {
  final asyncService = ref.watch(remoteConfigServiceProvider);
  return asyncService.when(
    data: (service) => service.deliveryFeeXof,
    loading: () => kDefaultDeliveryFeeXof,
    error: (_, __) => kDefaultDeliveryFeeXof,
  );
}
