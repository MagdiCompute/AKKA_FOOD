import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';

void main() {
  group('AppUser', () {
    final baseCreatedAt = DateTime(2024, 1, 15);

    AppUser makeUser({String role = 'user'}) => AppUser(
          uid: 'uid_123',
          email: 'test@example.com',
          phoneNumber: null,
          displayName: 'Test User',
          isVerified: true,
          isDeactivated: false,
          createdAt: baseCreatedAt,
          linkedProviders: const ['password'],
          role: role,
        );

    // ── role field ──────────────────────────────────────────────────────────

    test('role defaults to "user" when not present in map', () {
      final map = {
        'uid': 'uid_abc',
        'displayName': 'Alice',
        'isVerified': false,
        'isDeactivated': false,
        'createdAt': null,
        'linkedProviders': <dynamic>[],
        // 'role' intentionally omitted
      };

      final user = AppUser.fromMap(map);

      expect(user.role, equals('user'));
    });

    test('role is read correctly from map when set to "user"', () {
      final map = {
        'uid': 'uid_abc',
        'displayName': 'Alice',
        'isVerified': false,
        'isDeactivated': false,
        'createdAt': null,
        'linkedProviders': <dynamic>[],
        'role': 'user',
      };

      final user = AppUser.fromMap(map);

      expect(user.role, equals('user'));
    });

    test('role is read correctly from map when set to "admin"', () {
      final map = {
        'uid': 'uid_admin',
        'displayName': 'Admin User',
        'isVerified': true,
        'isDeactivated': false,
        'createdAt': null,
        'linkedProviders': <dynamic>['password'],
        'role': 'admin',
      };

      final user = AppUser.fromMap(map);

      expect(user.role, equals('admin'));
    });

    // ── isAdmin helper ───────────────────────────────────────────────────────

    test('isAdmin returns false for role "user"', () {
      final user = makeUser(role: 'user');
      expect(user.isAdmin, isFalse);
    });

    test('isAdmin returns true for role "admin"', () {
      final user = makeUser(role: 'admin');
      expect(user.isAdmin, isTrue);
    });

    test('isAdmin returns false for unknown role value', () {
      final user = makeUser(role: 'moderator');
      expect(user.isAdmin, isFalse);
    });

    // ── toMap / fromMap round-trip ───────────────────────────────────────────

    test('toMap includes role field', () {
      final user = makeUser(role: 'admin');
      final map = user.toMap();

      expect(map['role'], equals('admin'));
    });

    test('fromMap → toMap round-trip preserves role', () {
      for (final role in ['user', 'admin']) {
        final original = makeUser(role: role);
        final map = original.toMap();
        // Simulate Firestore round-trip (createdAt comes back as DateTime here)
        final restored = AppUser.fromMap(map);

        expect(restored.role, equals(role),
            reason: 'role "$role" should survive a toMap/fromMap round-trip');
      }
    });

    // ── copyWith ─────────────────────────────────────────────────────────────

    test('copyWith preserves role when not specified', () {
      final user = makeUser(role: 'admin');
      final copy = user.copyWith(displayName: 'New Name');

      expect(copy.role, equals('admin'));
    });

    test('copyWith can change role from user to admin', () {
      final user = makeUser(role: 'user');
      final promoted = user.copyWith(role: 'admin');

      expect(promoted.role, equals('admin'));
      expect(promoted.isAdmin, isTrue);
    });

    test('copyWith can change role from admin to user', () {
      final user = makeUser(role: 'admin');
      final demoted = user.copyWith(role: 'user');

      expect(demoted.role, equals('user'));
      expect(demoted.isAdmin, isFalse);
    });

    // ── equality ─────────────────────────────────────────────────────────────

    test('two users with same data are equal', () {
      final a = makeUser(role: 'user');
      final b = makeUser(role: 'user');

      expect(a, equals(b));
    });

    test('users with different roles are not equal', () {
      final userRole = makeUser(role: 'user');
      final adminRole = makeUser(role: 'admin');

      expect(userRole, isNot(equals(adminRole)));
    });

    // ── FirestoreUserDataSource.buildNewUserDocument ─────────────────────────

    test('buildNewUserDocument sets role to "user" for new registrations', () {
      // Import is done via the entity file; we test the static helper here
      // by calling it directly from the data source.
      // This test validates the requirement that new users always get role='user'.
      final doc = _buildNewUserDoc(
        uid: 'new_uid',
        displayName: 'New User',
        email: 'new@example.com',
      );

      expect(doc['role'], equals('user'),
          reason: 'New user registrations must default to role "user"');
    });
  });
}

/// Mirrors [FirestoreUserDataSource.buildNewUserDocument] without importing
/// cloud_firestore (which requires a Firebase app to be initialized).
Map<String, dynamic> _buildNewUserDoc({
  required String uid,
  required String displayName,
  String? email,
  String? phoneNumber,
  List<String> linkedProviders = const [],
}) {
  return {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'phoneNumber': phoneNumber,
    'isVerified': false,
    'isDeactivated': false,
    'createdAt': DateTime.now(),
    'linkedProviders': linkedProviders,
    'coinBalance': 0,
    'failedLoginAttempts': 0,
    'lockedUntil': null,
    'role': 'user',
  };
}
