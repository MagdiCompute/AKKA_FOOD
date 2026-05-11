import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/user_profile/data/datasources/firestore_coin_data_source.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Seeds [count] coin transactions into [fakeFirestore] for [uid].
///
/// Transactions are seeded with timestamps spaced 1 day apart, with index 0
/// being the oldest and index [count-1] being the newest.
///
/// [amounts] can optionally override the default amount (100 * (i+1)) for
/// each transaction. If provided, its length must equal [count].
Future<void> _seedTransactions(
  FakeFirebaseFirestore fakeFirestore,
  String uid,
  int count, {
  List<int>? amounts,
}) async {
  assert(amounts == null || amounts.length == count);
  for (var i = 0; i < count; i++) {
    await fakeFirestore
        .collection('users')
        .doc(uid)
        .collection('coinTransactions')
        .add({
      'amount': amounts != null ? amounts[i] : 100 * (i + 1),
      'reason': 'Purchase reward',
      'orderId': 'order-$i',
      'timestamp': Timestamp.fromDate(DateTime(2024, 1, i + 1)),
    });
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreCoinDataSource dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirestoreCoinDataSource(firestore: fakeFirestore);
  });

  // -------------------------------------------------------------------------
  // getCoinTransactions
  // -------------------------------------------------------------------------

  group('getCoinTransactions', () {
    test('returns empty list when user has no transactions', () async {
      final result = await dataSource.getCoinTransactions('user-1');
      expect(result, isEmpty);
    });

    test('returns transactions for the given uid only', () async {
      await _seedTransactions(fakeFirestore, 'user-1', 3);
      await _seedTransactions(fakeFirestore, 'user-2', 5);

      final result = await dataSource.getCoinTransactions('user-1');

      expect(result, hasLength(3));
    });

    test('transactions are sorted by timestamp descending (newest first)',
        () async {
      await _seedTransactions(fakeFirestore, 'user-1', 3);

      final result = await dataSource.getCoinTransactions('user-1');

      expect(result, hasLength(3));
      for (var i = 0; i < result.length - 1; i++) {
        expect(
          result[i].timestamp.isAfter(result[i + 1].timestamp) ||
              result[i]
                  .timestamp
                  .isAtSameMomentAs(result[i + 1].timestamp),
          isTrue,
          reason: 'Transactions should be sorted newest-first',
        );
      }
    });

    test('respects pageSize — returns at most pageSize results', () async {
      await _seedTransactions(fakeFirestore, 'user-1', 10);

      final result =
          await dataSource.getCoinTransactions('user-1', pageSize: 5);

      expect(result, hasLength(5));
    });

    test('default pageSize is 20', () async {
      await _seedTransactions(fakeFirestore, 'user-1', 25);

      final result = await dataSource.getCoinTransactions('user-1');

      expect(result, hasLength(20));
    });

    test(
        'cursor-based pagination: second page returns next set of results '
        'with no overlap', () async {
      await _seedTransactions(fakeFirestore, 'user-1', 5);

      // Fetch the first page snapshot using the same query structure as the
      // data source so the DocumentSnapshot is compatible with
      // startAfterDocument.
      final firstPageSnapshot = await fakeFirestore
          .collection('users')
          .doc('user-1')
          .collection('coinTransactions')
          .orderBy('timestamp', descending: true)
          .limit(2)
          .get();

      expect(firstPageSnapshot.docs, hasLength(2));
      final firstPageIds = firstPageSnapshot.docs.map((d) => d.id).toSet();

      final lastDoc = firstPageSnapshot.docs.last;
      final secondPage = await dataSource.getCoinTransactions(
        'user-1',
        pageSize: 2,
        lastDocument: lastDoc,
      );

      final secondIds = secondPage.map((t) => t.id).toSet();
      expect(firstPageIds.intersection(secondIds), isEmpty,
          reason: 'Second page must not contain documents from the first page');
    });

    test('returns empty list when cursor is past the last document', () async {
      await _seedTransactions(fakeFirestore, 'user-1', 3);

      final allSnapshot = await fakeFirestore
          .collection('users')
          .doc('user-1')
          .collection('coinTransactions')
          .orderBy('timestamp', descending: true)
          .get();

      expect(allSnapshot.docs, hasLength(3));

      final lastDoc = allSnapshot.docs.last;
      final result = await dataSource.getCoinTransactions(
        'user-1',
        pageSize: 20,
        lastDocument: lastDoc,
      );

      expect(result, isEmpty);
    });

    test('maps id from document id', () async {
      await _seedTransactions(fakeFirestore, 'user-1', 1);

      final result = await dataSource.getCoinTransactions('user-1');

      expect(result.first.id, isNotEmpty);
    });

    test('maps uid correctly', () async {
      await _seedTransactions(fakeFirestore, 'user-42', 1);

      final result = await dataSource.getCoinTransactions('user-42');

      expect(result.first.uid, 'user-42');
    });

    test('maps amount, reason, orderId, and timestamp correctly', () async {
      await fakeFirestore
          .collection('users')
          .doc('user-1')
          .collection('coinTransactions')
          .add({
        'amount': -500,
        'reason': 'Redemption',
        'orderId': 'order-abc',
        'timestamp': Timestamp.fromDate(DateTime(2024, 6, 15)),
      });

      final result = await dataSource.getCoinTransactions('user-1');

      expect(result, hasLength(1));
      expect(result.first.amount, -500);
      expect(result.first.reason, 'Redemption');
      expect(result.first.orderId, 'order-abc');
      expect(result.first.timestamp, DateTime(2024, 6, 15));
    });

    test('handles null orderId gracefully', () async {
      await fakeFirestore
          .collection('users')
          .doc('user-1')
          .collection('coinTransactions')
          .add({
        'amount': 200,
        'reason': 'Bonus',
        'timestamp': Timestamp.fromDate(DateTime(2024, 3, 1)),
      });

      final result = await dataSource.getCoinTransactions('user-1');

      expect(result.first.orderId, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // watchCoinBalance
  // -------------------------------------------------------------------------

  group('watchCoinBalance', () {
    test('emits 0 when user has no transactions (Requirement 6.5)', () async {
      final balance = await dataSource.watchCoinBalance('user-1').first;
      expect(balance, 0);
    });

    test('emits correct sum of all transaction amounts', () async {
      // Credits: 500 + 300 = 800; Debit: -200; Net: 600
      await _seedTransactions(
        fakeFirestore,
        'user-1',
        3,
        amounts: [500, 300, -200],
      );

      final balance = await dataSource.watchCoinBalance('user-1').first;
      expect(balance, 600);
    });

    test('emits updated balance when a new transaction is added', () async {
      await _seedTransactions(fakeFirestore, 'user-1', 1, amounts: [100]);

      final stream = dataSource.watchCoinBalance('user-1');

      // Collect two emissions: initial balance, then updated balance.
      final emissions = <int>[];
      final subscription = stream.listen(emissions.add);

      // Allow the first emission to be processed.
      await Future<void>.delayed(Duration.zero);
      expect(emissions, [100]);

      // Add a new transaction.
      await fakeFirestore
          .collection('users')
          .doc('user-1')
          .collection('coinTransactions')
          .add({
        'amount': 250,
        'reason': 'Purchase reward',
        'timestamp': Timestamp.fromDate(DateTime(2024, 7, 1)),
      });

      // Allow the second emission to be processed.
      await Future<void>.delayed(Duration.zero);
      expect(emissions, [100, 350]);

      await subscription.cancel();
    });

    test('balance is 0 when all transactions cancel out', () async {
      await _seedTransactions(
        fakeFirestore,
        'user-1',
        2,
        amounts: [1000, -1000],
      );

      final balance = await dataSource.watchCoinBalance('user-1').first;
      expect(balance, 0);
    });

    test('stream is scoped to the given uid', () async {
      await _seedTransactions(fakeFirestore, 'user-1', 1, amounts: [500]);
      await _seedTransactions(fakeFirestore, 'user-2', 1, amounts: [9999]);

      final balance = await dataSource.watchCoinBalance('user-1').first;
      expect(balance, 500);
    });
  });
}
