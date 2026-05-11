import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/auth/data/datasources/token_store.dart';
import 'package:akka_food/features/auth/domain/entities/auth_token.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStore tokenStore;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    tokenStore = TokenStore();
  });

  group('TokenStore', () {
    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    AuthToken _makeToken({Duration offset = const Duration(hours: 1)}) {
      return AuthToken(
        accessToken: 'test_access_token',
        refreshToken: 'test_refresh_token',
        expiresAt: DateTime.now().add(offset),
      );
    }

    // -------------------------------------------------------------------------
    // save + load round-trip
    // -------------------------------------------------------------------------

    test('save then load returns a token with matching fields', () async {
      final token = _makeToken();

      await tokenStore.save(token);
      final loaded = await tokenStore.load();

      expect(loaded, isNotNull);
      expect(loaded!.accessToken, equals(token.accessToken));
      expect(loaded.refreshToken, equals(token.refreshToken));
      // DateTime round-trips through ISO-8601 string; compare milliseconds
      expect(
        loaded.expiresAt.millisecondsSinceEpoch,
        equals(token.expiresAt.millisecondsSinceEpoch),
      );
    });

    // -------------------------------------------------------------------------
    // load returns null when storage is empty
    // -------------------------------------------------------------------------

    test('load returns null when storage is empty', () async {
      final result = await tokenStore.load();
      expect(result, isNull);
    });

    // -------------------------------------------------------------------------
    // load returns null when only some keys are present
    // -------------------------------------------------------------------------

    test('load returns null when only accessToken key is present', () async {
      // Seed storage with only the access-token key; omit refresh and expiresAt.
      FlutterSecureStorage.setMockInitialValues({
        'akka_access_token': 'partial_access_token',
      });
      tokenStore = TokenStore();

      final result = await tokenStore.load();
      expect(result, isNull);
    });

    // -------------------------------------------------------------------------
    // clear removes all keys
    // -------------------------------------------------------------------------

    test('load returns null after clear', () async {
      await tokenStore.save(_makeToken());
      await tokenStore.clear();

      final result = await tokenStore.load();
      expect(result, isNull);
    });

    // -------------------------------------------------------------------------
    // isValid — non-expired token
    // -------------------------------------------------------------------------

    test('isValid returns true for a token that expires in the future', () async {
      await tokenStore.save(_makeToken(offset: const Duration(hours: 1)));

      final valid = await tokenStore.isValid();
      expect(valid, isTrue);
    });

    // -------------------------------------------------------------------------
    // isValid — expired token
    // -------------------------------------------------------------------------

    test('isValid returns false for a token that has already expired', () async {
      await tokenStore.save(_makeToken(offset: const Duration(hours: -1)));

      final valid = await tokenStore.isValid();
      expect(valid, isFalse);
    });

    // -------------------------------------------------------------------------
    // isValid — no token stored
    // -------------------------------------------------------------------------

    test('isValid returns false when no token is stored', () async {
      final valid = await tokenStore.isValid();
      expect(valid, isFalse);
    });
  });
}
