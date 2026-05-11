import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/coins/data/datasources/firestore_coin_data_source.dart';
import 'package:akka_food/features/coins/data/repositories/coin_repository.dart';

// =============================================================================
// Fakes for FirebaseFunctions
// =============================================================================

/// A fake [HttpsCallableResult] that returns predefined data.
class FakeHttpsCallableResult<T> implements HttpsCallableResult<T> {
  FakeHttpsCallableResult(this.data);

  @override
  final T data;
}

/// A fake [HttpsCallable] that records calls and can throw exceptions.
class FakeHttpsCallable implements HttpsCallable {
  FakeHttpsCallable({this.exception});

  final Exception? exception;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic data]) async {
    if (data is Map<String, dynamic>) {
      calls.add(data);
    }
    if (exception != null) throw exception!;
    return FakeHttpsCallableResult<T>(null as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A fake [FirebaseFunctions] that returns a predefined [HttpsCallable].
class FakeFirebaseFunctions implements FirebaseFunctions {
  FakeFirebaseFunctions({required this.callable});

  final FakeHttpsCallable callable;
  String? lastCalledFunctionName;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    lastCalledFunctionName = name;
    return callable;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreCoinDataSource dataSource;
  late FakeHttpsCallable fakeCallable;
  late FakeFirebaseFunctions fakeFunctions;
  late CoinRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirestoreCoinDataSource(firestore: fakeFirestore);
    fakeCallable = FakeHttpsCallable();
    fakeFunctions = FakeFirebaseFunctions(callable: fakeCallable);
    repository = CoinRepository(
      firestoreDataSource: dataSource,
      functions: fakeFunctions,
    );
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

  /// Seeds [count] coin transactions for [uid] with timestamps spaced 1 day
  /// apart. Transaction at index i has timestamp Jan (i+1), 2024.
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
    test('delegates to FirestoreCoinDataSource and emits balance', () async {
      await seedUserWithBalance('uid_1', 3500);

      final stream = repository.watchBalance('uid_1');

      await expectLater(stream, emits(equals(3500)));
    });

    test('emits 0 when user document does not exist', () async {
      final stream = repository.watchBalance('nonexistent');

      await expectLater(stream, emits(equals(0)));
    });

    test('emits updated value when balance changes', () async {
      await seedUserWithBalance('uid_update', 1000);

      final emissions = <int>[];
      final subscription = repository.watchBalance('uid_update').listen(
        emissions.add,
      );

      await Future<void>.delayed(Duration.zero);
      expect(emissions, contains(1000));

      await fakeFirestore.collection('users').doc('uid_update').update({
        'coinBalance': 2000,
      });

      await Future<void>.delayed(Duration.zero);
      expect(emissions.last, equals(2000));

      await subscription.cancel();
    });
  });

  // ---------------------------------------------------------------------------
  // getTransactionHistory
  // ---------------------------------------------------------------------------

  group('getTransactionHistory', () {
    test('returns empty list when no transactions exist', () async {
      final result = await repository.getTransactionHistory(uid: 'uid_empty');

      expect(result, isEmpty);
    });

    test('returns first page of transactions (page 0)', () async {
      await seedTransactions('uid_page0', 5);

      final result = await repository.getTransactionHistory(
        uid: 'uid_page0',
        page: 0,
        pageSize: 3,
      );

      expect(result.length, equals(3));
      // Verify descending order
      for (int i = 0; i < result.length - 1; i++) {
        expect(
          result[i].timestamp.isAfter(result[i + 1].timestamp) ||
              result[i].timestamp.isAtSameMomentAs(result[i + 1].timestamp),
          isTrue,
        );
      }
    });

    test('returns second page with no overlap with first page', () async {
      await seedTransactions('uid_pages', 5);

      final firstPage = await repository.getTransactionHistory(
        uid: 'uid_pages',
        page: 0,
        pageSize: 2,
      );

      final secondPage = await repository.getTransactionHistory(
        uid: 'uid_pages',
        page: 1,
        pageSize: 2,
      );

      final firstIds = firstPage.map((t) => t.id).toSet();
      final secondIds = secondPage.map((t) => t.id).toSet();
      expect(firstIds.intersection(secondIds), isEmpty);
    });

    test('returns empty list when page exceeds available data', () async {
      await seedTransactions('uid_exceed', 3);

      final result = await repository.getTransactionHistory(
        uid: 'uid_exceed',
        page: 5,
        pageSize: 20,
      );

      expect(result, isEmpty);
    });

    test('uses default pageSize of 20', () async {
      await seedTransactions('uid_default', 25);

      final result = await repository.getTransactionHistory(uid: 'uid_default');

      expect(result.length, equals(20));
    });

    test('correctly maps CoinTransaction fields', () async {
      final timestamp = DateTime(2024, 6, 15, 10, 30, 0);
      await fakeFirestore
          .collection('users')
          .doc('uid_map')
          .collection('coinTransactions')
          .doc('tx_1')
          .set({
        'amount': 500,
        'reason': 'Purchase reward',
        'orderId': 'order_abc',
        'timestamp': Timestamp.fromDate(timestamp),
      });

      final result = await repository.getTransactionHistory(uid: 'uid_map');

      expect(result.length, equals(1));
      final tx = result.first;
      expect(tx.id, equals('tx_1'));
      expect(tx.uid, equals('uid_map'));
      expect(tx.amount, equals(500));
      expect(tx.reason, equals('Purchase reward'));
      expect(tx.orderId, equals('order_abc'));
      expect(tx.timestamp, equals(timestamp));
    });
  });

  // ---------------------------------------------------------------------------
  // redeemCoins
  // ---------------------------------------------------------------------------

  group('redeemCoins', () {
    test('calls redeemCoins Cloud Function with correct parameters', () async {
      await repository.redeemCoins(
        uid: 'uid_redeem',
        amount: 2000,
        orderId: 'order_xyz',
      );

      expect(fakeFunctions.lastCalledFunctionName, equals('redeemCoins'));
      expect(fakeCallable.calls.length, equals(1));
      expect(fakeCallable.calls.first, equals({
        'uid': 'uid_redeem',
        'amount': 2000,
        'orderId': 'order_xyz',
      }));
    });

    test('propagates exception from Cloud Function', () async {
      final failingCallable = FakeHttpsCallable(
        exception: FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'Insufficient coins',
        ),
      );
      final failingFunctions =
          FakeFirebaseFunctions(callable: failingCallable);
      final failingRepo = CoinRepository(
        firestoreDataSource: dataSource,
        functions: failingFunctions,
      );

      expect(
        () => failingRepo.redeemCoins(
          uid: 'uid_fail',
          amount: 5000,
          orderId: 'order_fail',
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );
    });
  });
}
