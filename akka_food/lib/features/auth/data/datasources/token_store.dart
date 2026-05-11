import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auth_token.dart';

/// Persists [AuthToken] fields in the platform's hardware-backed secure store.
///
/// - **Android**: `EncryptedSharedPreferences` backed by Android Keystore (AES-256).
/// - **iOS**: Keychain with `first_unlock` accessibility so tokens survive
///   device restarts without requiring the user to unlock first.
///
/// Never uses plain `SharedPreferences` or any unencrypted storage.
///
/// Inject a custom [FlutterSecureStorage] instance in tests to avoid touching
/// real platform storage.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage}) : _storage = storage ?? _defaultStorage;

  final FlutterSecureStorage _storage;

  // ---------------------------------------------------------------------------
  // Storage keys
  // ---------------------------------------------------------------------------

  static const _accessTokenKey = 'akka_access_token';
  static const _refreshTokenKey = 'akka_refresh_token';
  static const _expiresAtKey = 'akka_token_expires_at';

  // ---------------------------------------------------------------------------
  // Platform-specific options
  // ---------------------------------------------------------------------------

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  static const _defaultStorage = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Persists all three token fields as separate encrypted entries.
  Future<void> save(AuthToken token) async {
    await Future.wait([
      _storage.write(
        key: _accessTokenKey,
        value: token.accessToken,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      ),
      _storage.write(
        key: _refreshTokenKey,
        value: token.refreshToken,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      ),
      _storage.write(
        key: _expiresAtKey,
        value: token.expiresAt.toIso8601String(),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      ),
    ]);
  }

  /// Reads all three token fields and reconstructs an [AuthToken].
  ///
  /// Returns `null` if any field is missing (e.g. first launch or after [clear]).
  Future<AuthToken?> load() async {
    final results = await Future.wait([
      _storage.read(
        key: _accessTokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      ),
      _storage.read(
        key: _refreshTokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      ),
      _storage.read(
        key: _expiresAtKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      ),
    ]);

    final accessToken = results[0];
    final refreshToken = results[1];
    final expiresAtRaw = results[2];

    if (accessToken == null || refreshToken == null || expiresAtRaw == null) {
      return null;
    }

    return AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.parse(expiresAtRaw),
    );
  }

  /// Deletes all three token entries from secure storage.
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(
        key: _accessTokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      ),
      _storage.delete(
        key: _refreshTokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      ),
      _storage.delete(
        key: _expiresAtKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      ),
    ]);
  }

  /// Returns `true` when a token is stored and has not yet expired.
  ///
  /// Delegates expiry logic to [AuthToken.isExpired] to keep the check
  /// consistent with the domain entity.
  Future<bool> isValid() async {
    final token = await load();
    if (token == null) return false;
    return !token.isExpired;
  }
}
