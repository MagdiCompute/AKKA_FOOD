import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/coins/data/datasources/firestore_coin_data_source.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreCoinDataSource dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirestoreCoinDataSource(firestore: fakeFirestore);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> seedUserWithBalance(String uid, int balance) async {
    await fakeFirestore.collection('users').doc(uid).set({
      'coinBalance': balance,
      'name': 'Test User',
    });
  }

  Future<void> seedUserWithoutBalance(String uid) async {
    await fakeFirestore.collection('users').doc(uid).set({
      'name': 'Test User',
    });
  }

  /// Seeds [count] coin transactions for [uid] with timestamps spaced 1 day
  /// apart. The first transaction has the earliest timestamp, the last has the
  /// most recent.
  Future<void> seedTransactions(String uid, int count) async {
    for (int i = 0; i < count; i++) {
      await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('coinTransactions')
          .add({
        'amount': (i + 1) * 100,
        'reason': i.isEven ? 'Purchase reward' : 'Redemption',
        'orderId': 'order_$i',
        'timestamp': Timestamp.fromDate(DateTime(2024, 1, i + 1)),
      });
    }
  }

  // ---------------------------------------------------------------------------
  // watchBalance
  // ---------------------------------------------------------------------------

  group('watchBalance', () {
    test('emits 0 when user document does not exist', () async {
      final stream = dataSource.watchBalance('nonexistent_uid');

      await expectLater(
        stream,
        emits(equals(0)),
      );
    });

    test('emits 0 when coinBalance field is absent', () async {
      await seedUserWithoutBalance('uid_no_balance');

      final stream = dataSource.watchBalance('uid_no_balance');

      await expectLater(
        stream,
        emits(equals(0)),
      );
    });

    test('emits the coinBalance value from the user document', () async {
      await seedUserWithBalance('uid_1', 2500);

      final stream = dataSource.watchBalance('uid_1');

      await expectLater(
        stream,
        emits(equals(2500)),
      );
    });

    test('emits 0 when coinBalance is explicitly 0', () async {
      await seedUserWithBalance('uid_zero', 0);

      final stream = dataSource.watchBalance('uid_zero');

      await expectLater(
        stream,
        emits(equals(0)),
      );
    });

    test('emits updated value when coinBalance changes', () async {
      await seedUserWithBalance('uid_update', 1000);

      final emissions = <int>[];
      final subscription = dataSource.watchBalance('uid_update').listen(
        emissions.add,
      );

      // Allow the first snapshot to be delivered
      await Future<void>.delayed(Duration.zero);
      expect(emissions, contains(1000));

      // Update the balance
      await fakeFirestore.collection('users').doc('uid_update').update({
        'coinBalance': 1500,
      });

      // Allow the updated snapshot to be delivered
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last, equals(1500));

      await subscription.cancel();
    });

    test('emits 0 when coinBalance field is null', () async {
      await fakeFirestore.collection('users').doc('uid_null').set({
        'coinBalance': null,
        'name': 'Test User',
      });

      final stream = dataSource.watchBalance('uid_null');

      await expectLater(
        stream,
        emits(equals(0)),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getCoinTransactions — paginated query (Req 4 AC1, AC2)
  // ---------------------------------------------------------------------------

  group('getCoinTransactions', () {
    test('returns empty list when no transactions exist', () async {
      final result = await dataSource.getCoinTransactions('uid_empty');

      expect(result, isEmpty);
    });

    test('returns up to 20 transactions ordered by timestamp descending',
        () async {
      // Seed 25 transactions so we can verify the page size limit
      await seedTransactions('uid_page', 25);

      final result = await dataSource.getCoinTransactions('uid_page');

      // Default page size is 20
      expect(result.length, equals(20));

      // Verify descending order: first result should have the latest timestamp
      for (int i = 0; i < result.length - 1; i++) {
        expect(
          result[i].timestamp.isAfter(result[i + 1].timestamp) ||
              result[i].timestamp.isAtSameMomentAs(result[i + 1].timestamp),
          isTrue,
          reason:
              'Transaction at index $i should have a timestamp >= index ${i + 1}',
        );
      }
    });

    test('second page uses cursor from first page with no overlap', () async {
      // Seed 5 transactions for a manageable test
      await seedTransactions('uid_cursor', 5);

      // Use the data source's own getCoinTransactionsSnapshot to get the first
      // page — this ensures the DocumentSnapshot is from the same query path.
      final firstPageSnapshot = await dataSource.getCoinTransactionsSnapshot(
        'uid_cursor',
        pageSize: 2,
      );

      expect(firstPageSnapshot.docs.length, equals(2));
      final firstPageIds =
          firstPageSnapshot.docs.map((d) => d.id).toSet();

      // Use the last document as cursor for the second page.
      // Note: fake_cloud_firestore has limited startAfterDocument support,
      // so we verify the method accepts the cursor without error and that
      // any returned results do not overlap with the first page.
      final lastDoc = firstPageSnapshot.docs.last;
      final secondPage = await dataSource.getCoinTransactions(
        'uid_cursor',
        pageSize: 2,
        lastDocument: lastDoc,
      );

      // No overlap between first and second page
      final secondPageIds = secondPage.map((t) => t.id).toSet();
      expect(
        firstPageIds.intersection(secondPageIds),
        isEmpty,
        reason: 'Second page must not contain documents from the first page',
      );
    });

    test('correctly maps Firestore document data to CoinTransaction entity',
        () async {
      final timestamp = DateTime(2024, 6, 15, 10, 30, 0);
      await fakeFirestore
          .collection('users')
          .doc('uid_map')
          .collection('coinTransactions')
          .doc('tx_mapping')
          .set({
        'amount': 500,
        'reason': 'Purchase reward',
        'orderId': 'order_abc123',
        'timestamp': Timestamp.fromDate(timestamp),
      });

      final result = await dataSource.getCoinTransactions('uid_map');

      expect(result.length, equals(1));
      final tx = result.first;
      expect(tx.id, equals('tx_mapping'));
      expect(tx.uid, equals('uid_map'));
      expect(tx.amount, equals(500));
      expect(tx.reason, equals('Purchase reward'));
      expect(tx.orderId, equals('order_abc123'));
      expect(tx.timestamp, equals(timestamp));
    });

    test('maps transaction with null orderId correctly', () async {
      final timestamp = DateTime(2024, 3, 10, 8, 0, 0);
      await fakeFirestore
          .collection('users')
          .doc('uid_null_order')
          .collection('coinTransactions')
          .doc('tx_no_order')
          .set({
        'amount': -1000,
        'reason': 'Redemption',
        'orderId': null,
        'timestamp': Timestamp.fromDate(timestamp),
      });

      final result = await dataSource.getCoinTransactions('uid_null_order');

      expect(result.length, equals(1));
      final tx = result.first;
      expect(tx.orderId, isNull);
      expect(tx.amount, equals(-1000));
      expect(tx.reason, equals('Redemption'));
    });

    test('custom pageSize parameter limits results correctly', () async {
      // Seed 10 transactions
      await seedTransactions('uid_pagesize', 10);

      final result = await dataSource.getCoinTransactions(
        'uid_pagesize',
        pageSize: 5,
      );

      expect(result.length, equals(5));
    });

    test('returns fewer than pageSize when not enough transactions exist',
        () async {
      // Seed only 3 transactions
      await seedTransactions('uid_few', 3);

      final result = await dataSource.getCoinTransactions('uid_few');

      // Default page size is 20, but only 3 exist
      expect(result.length, equals(3));
    });
  });

  // ---------------------------------------------------------------------------
  // getCoinTransactionsSnapshot
  // ---------------------------------------------------------------------------

  group('getCoinTransactionsSnapshot', () {
    test('returns a QuerySnapshot with correct number of documents', () async {
      await seedTransactions('uid_snap', 5);

      final snapshot =
          await dataSource.getCoinTransactionsSnapshot('uid_snap');

      expect(snapshot.docs.length, equals(5));
    });

    test('snapshot documents are ordered by timestamp descending', () async {
      await seedTransactions('uid_snap_order', 10);

      final snapshot =
          await dataSource.getCoinTransactionsSnapshot('uid_snap_order');

      for (int i = 0; i < snapshot.docs.length - 1; i++) {
        final currentTs =
            (snapshot.docs[i].data()['timestamp'] as Timestamp).toDate();
        final nextTs =
            (snapshot.docs[i + 1].data()['timestamp'] as Timestamp).toDate();
        expect(
          currentTs.isAfter(nextTs) || currentTs.isAtSameMomentAs(nextTs),
          isTrue,
        );
      }
    });

    test('snapshot can be used as cursor for pagination', () async {
      await seedTransactions('uid_snap_cursor', 5);

      // Use the data source's own method to get the first page
      final firstSnapshot = await dataSource.getCoinTransactionsSnapshot(
        'uid_snap_cursor',
        pageSize: 3,
      );
      expect(firstSnapshot.docs.length, equals(3));

      // Verify the method accepts a cursor without error and returns no
      // overlapping documents. (fake_cloud_firestore has limited
      // startAfterDocument support.)
      final secondSnapshot = await dataSource.getCoinTransactionsSnapshot(
        'uid_snap_cursor',
        pageSize: 3,
        lastDocument: firstSnapshot.docs.last,
      );

      // No overlap
      final firstIds = firstSnapshot.docs.map((d) => d.id).toSet();
      final secondIds = secondSnapshot.docs.map((d) => d.id).toSet();
      expect(firstIds.intersection(secondIds), isEmpty);
    });
  });
}
