import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/user_profile/data/datasources/firestore_address_data_source.dart';
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal [DeliveryAddress] for testing.
DeliveryAddress _makeAddress({
  String id = '',
  String uid = 'user-1',
  String label = 'Home',
  String streetAddress = '123 Main St',
  String city = 'Abidjan',
  bool isDefault = false,
  DateTime? createdAt,
}) {
  return DeliveryAddress(
    id: id,
    uid: uid,
    label: label,
    streetAddress: streetAddress,
    city: city,
    isDefault: isDefault,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
  );
}

/// Seeds [count] addresses into [fakeFirestore] for [uid] and returns them.
Future<List<DeliveryAddress>> _seedAddresses(
  FakeFirebaseFirestore fakeFirestore,
  String uid,
  int count, {
  int defaultIndex = -1, // -1 means no default
}) async {
  final seeded = <DeliveryAddress>[];
  for (var i = 0; i < count; i++) {
    final ref = await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .add({
      'label': 'Address $i',
      'streetAddress': '$i Street',
      'city': 'City',
      'isDefault': i == defaultIndex,
      'createdAt': Timestamp.fromDate(DateTime(2024, 1, i + 1)),
    });
    seeded.add(_makeAddress(
      id: ref.id,
      uid: uid,
      label: 'Address $i',
      streetAddress: '$i Street',
      isDefault: i == defaultIndex,
      createdAt: DateTime(2024, 1, i + 1),
    ));
  }
  return seeded;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreAddressDataSource dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirestoreAddressDataSource(firestore: fakeFirestore);
  });

  // -------------------------------------------------------------------------
  // getAddresses
  // -------------------------------------------------------------------------

  group('getAddresses', () {
    test('returns empty list when no addresses exist', () async {
      final result = await dataSource.getAddresses('user-1');
      expect(result, isEmpty);
    });

    test('returns all addresses for the given uid', () async {
      await _seedAddresses(fakeFirestore, 'user-1', 3);

      final result = await dataSource.getAddresses('user-1');

      expect(result, hasLength(3));
    });

    test('does not return addresses belonging to a different uid', () async {
      await _seedAddresses(fakeFirestore, 'user-1', 2);
      await _seedAddresses(fakeFirestore, 'user-2', 3);

      final result = await dataSource.getAddresses('user-1');

      expect(result, hasLength(2));
      expect(result.every((a) => a.uid == 'user-1'), isTrue);
    });

    test('default address is sorted first', () async {
      await _seedAddresses(fakeFirestore, 'user-1', 3, defaultIndex: 2);

      final result = await dataSource.getAddresses('user-1');

      expect(result.first.isDefault, isTrue);
      expect(result.first.label, 'Address 2');
    });

    test('non-default addresses are sorted by createdAt ascending', () async {
      await _seedAddresses(fakeFirestore, 'user-1', 3, defaultIndex: 0);

      final result = await dataSource.getAddresses('user-1');

      // First is the default; the rest should be in createdAt order.
      expect(result[0].isDefault, isTrue);
      expect(
        result[1].createdAt.isBefore(result[2].createdAt),
        isTrue,
        reason: 'Non-default addresses should be sorted oldest-first',
      );
    });

    test('populates id and uid from document path', () async {
      await _seedAddresses(fakeFirestore, 'user-1', 1);

      final result = await dataSource.getAddresses('user-1');

      expect(result.first.id, isNotEmpty);
      expect(result.first.uid, 'user-1');
    });
  });

  // -------------------------------------------------------------------------
  // addAddress
  // -------------------------------------------------------------------------

  group('addAddress', () {
    test('creates a new document and returns address with generated id',
        () async {
      final address = _makeAddress(uid: 'user-1', label: 'Office');

      final result = await dataSource.addAddress(address);

      expect(result.id, isNotEmpty);
      expect(result.label, 'Office');
      expect(result.uid, 'user-1');
    });

    test('persisted document is retrievable via getAddresses', () async {
      final address = _makeAddress(uid: 'user-1', label: 'Home');

      final saved = await dataSource.addAddress(address);
      final all = await dataSource.getAddresses('user-1');

      expect(all.any((a) => a.id == saved.id), isTrue);
    });

    test('throws StateError when 10 addresses already exist', () async {
      await _seedAddresses(fakeFirestore, 'user-1', 10);

      final eleventh = _makeAddress(uid: 'user-1', label: 'Eleventh');

      expect(
        () => dataSource.addAddress(eleventh),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('maximum is 10'),
          ),
        ),
      );
    });

    test('allows adding exactly 10 addresses (boundary)', () async {
      await _seedAddresses(fakeFirestore, 'user-1', 9);

      final tenth = _makeAddress(uid: 'user-1', label: 'Tenth');

      // Should not throw.
      final result = await dataSource.addAddress(tenth);
      expect(result.id, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // updateAddress
  // -------------------------------------------------------------------------

  group('updateAddress', () {
    test('updates fields on an existing document', () async {
      final seeded = await _seedAddresses(fakeFirestore, 'user-1', 1);
      final original = seeded.first;

      final updated = original.copyWith(label: 'Updated Label', city: 'Dakar');
      final result = await dataSource.updateAddress(updated);

      expect(result.label, 'Updated Label');
      expect(result.city, 'Dakar');

      // Verify the change is persisted.
      final all = await dataSource.getAddresses('user-1');
      final fetched = all.firstWhere((a) => a.id == original.id);
      expect(fetched.label, 'Updated Label');
      expect(fetched.city, 'Dakar');
    });

    test('throws StateError when address does not exist', () async {
      final nonExistent = _makeAddress(id: 'ghost-id', uid: 'user-1');

      expect(
        () => dataSource.updateAddress(nonExistent),
        throwsA(isA<StateError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // deleteAddress
  // -------------------------------------------------------------------------

  group('deleteAddress', () {
    test('removes the document from Firestore', () async {
      final seeded = await _seedAddresses(fakeFirestore, 'user-1', 2);
      final toDelete = seeded.first;

      await dataSource.deleteAddress('user-1', toDelete.id);

      final all = await dataSource.getAddresses('user-1');
      expect(all.any((a) => a.id == toDelete.id), isFalse);
      expect(all, hasLength(1));
    });

    test('throws StateError when address does not exist', () async {
      expect(
        () => dataSource.deleteAddress('user-1', 'non-existent-id'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // setDefaultAddress
  // -------------------------------------------------------------------------

  group('setDefaultAddress', () {
    test('marks target address as default', () async {
      final seeded = await _seedAddresses(fakeFirestore, 'user-1', 3);
      final target = seeded[1];

      await dataSource.setDefaultAddress('user-1', target.id);

      final all = await dataSource.getAddresses('user-1');
      final updated = all.firstWhere((a) => a.id == target.id);
      expect(updated.isDefault, isTrue);
    });

    test('clears isDefault on all other addresses', () async {
      final seeded =
          await _seedAddresses(fakeFirestore, 'user-1', 3, defaultIndex: 0);
      final newDefault = seeded[2];

      await dataSource.setDefaultAddress('user-1', newDefault.id);

      final all = await dataSource.getAddresses('user-1');
      final defaults = all.where((a) => a.isDefault).toList();

      expect(defaults, hasLength(1));
      expect(defaults.first.id, newDefault.id);
    });

    test('default address appears first in getAddresses result', () async {
      final seeded = await _seedAddresses(fakeFirestore, 'user-1', 3);
      final target = seeded[2];

      await dataSource.setDefaultAddress('user-1', target.id);

      final all = await dataSource.getAddresses('user-1');
      expect(all.first.id, target.id);
    });

    test('throws StateError when address does not exist', () async {
      expect(
        () => dataSource.setDefaultAddress('user-1', 'ghost-id'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
