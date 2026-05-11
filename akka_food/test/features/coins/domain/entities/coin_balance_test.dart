import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/coins/domain/entities/coin_balance.dart';

void main() {
  // ---------------------------------------------------------------------------
  // CoinBalance.fromTotal — normal values
  // ---------------------------------------------------------------------------

  group('CoinBalance.fromTotal — normal values', () {
    test('total=2500 → nextThreshold=3000, coinsToNext=500', () {
      final balance = CoinBalance.fromTotal(2500);

      expect(balance.total, equals(2500));
      expect(balance.nextThreshold, equals(3000));
      expect(balance.coinsToNext, equals(500));
    });

    test('total=1 → nextThreshold=1000, coinsToNext=999', () {
      final balance = CoinBalance.fromTotal(1);

      expect(balance.total, equals(1));
      expect(balance.nextThreshold, equals(1000));
      expect(balance.coinsToNext, equals(999));
    });

    test('total=999 → nextThreshold=1000, coinsToNext=1', () {
      final balance = CoinBalance.fromTotal(999);

      expect(balance.total, equals(999));
      expect(balance.nextThreshold, equals(1000));
      expect(balance.coinsToNext, equals(1));
    });

    test('total=1500 → nextThreshold=2000, coinsToNext=500', () {
      final balance = CoinBalance.fromTotal(1500);

      expect(balance.total, equals(1500));
      expect(balance.nextThreshold, equals(2000));
      expect(balance.coinsToNext, equals(500));
    });
  });

  // ---------------------------------------------------------------------------
  // CoinBalance.fromTotal — exact multiples of 1000
  // ---------------------------------------------------------------------------

  group('CoinBalance.fromTotal — exact multiples of 1000', () {
    test('total=1000 → nextThreshold=2000, coinsToNext=1000', () {
      final balance = CoinBalance.fromTotal(1000);

      expect(balance.total, equals(1000));
      expect(balance.nextThreshold, equals(2000));
      expect(balance.coinsToNext, equals(1000));
    });

    test('total=3000 → nextThreshold=4000, coinsToNext=1000', () {
      final balance = CoinBalance.fromTotal(3000);

      expect(balance.total, equals(3000));
      expect(balance.nextThreshold, equals(4000));
      expect(balance.coinsToNext, equals(1000));
    });

    test('total=5000 → nextThreshold=6000, coinsToNext=1000', () {
      final balance = CoinBalance.fromTotal(5000);

      expect(balance.total, equals(5000));
      expect(balance.nextThreshold, equals(6000));
      expect(balance.coinsToNext, equals(1000));
    });
  });

  // ---------------------------------------------------------------------------
  // CoinBalance.fromTotal — zero balance
  // ---------------------------------------------------------------------------

  group('CoinBalance.fromTotal — zero balance', () {
    test('total=0 → nextThreshold=1000, coinsToNext=1000', () {
      final balance = CoinBalance.fromTotal(0);

      expect(balance.total, equals(0));
      expect(balance.nextThreshold, equals(1000));
      expect(balance.coinsToNext, equals(1000));
    });
  });

  // ---------------------------------------------------------------------------
  // CoinBalance.fromTotal — large values
  // ---------------------------------------------------------------------------

  group('CoinBalance.fromTotal — large values', () {
    test('total=99999 → nextThreshold=100000, coinsToNext=1', () {
      final balance = CoinBalance.fromTotal(99999);

      expect(balance.total, equals(99999));
      expect(balance.nextThreshold, equals(100000));
      expect(balance.coinsToNext, equals(1));
    });

    test('total=100000 → nextThreshold=101000, coinsToNext=1000', () {
      final balance = CoinBalance.fromTotal(100000);

      expect(balance.total, equals(100000));
      expect(balance.nextThreshold, equals(101000));
      expect(balance.coinsToNext, equals(1000));
    });

    test('total=1234567 → nextThreshold=1235000, coinsToNext=433', () {
      final balance = CoinBalance.fromTotal(1234567);

      expect(balance.total, equals(1234567));
      expect(balance.nextThreshold, equals(1235000));
      expect(balance.coinsToNext, equals(433));
    });
  });

  // ---------------------------------------------------------------------------
  // CoinBalance.progress getter
  // ---------------------------------------------------------------------------

  group('CoinBalance.progress getter', () {
    test('total=0 → progress=0.0', () {
      final balance = CoinBalance.fromTotal(0);

      expect(balance.progress, equals(0.0));
    });

    test('total=500 → progress=0.5', () {
      final balance = CoinBalance.fromTotal(500);

      expect(balance.progress, equals(0.5));
    });

    test('total=250 → progress=0.25', () {
      final balance = CoinBalance.fromTotal(250);

      expect(balance.progress, equals(0.25));
    });

    test('total=999 → progress=0.999', () {
      final balance = CoinBalance.fromTotal(999);

      expect(balance.progress, equals(0.999));
    });

    test('total=1000 (exact multiple) → progress=0.0', () {
      final balance = CoinBalance.fromTotal(1000);

      expect(balance.progress, equals(0.0));
    });

    test('total=2500 → progress=0.5', () {
      final balance = CoinBalance.fromTotal(2500);

      expect(balance.progress, equals(0.5));
    });

    test('total=3750 → progress=0.75', () {
      final balance = CoinBalance.fromTotal(3750);

      expect(balance.progress, equals(0.75));
    });
  });

  // ---------------------------------------------------------------------------
  // CoinBalance — invariants
  // ---------------------------------------------------------------------------

  group('CoinBalance — invariants', () {
    test('coinsToNext always equals nextThreshold - total', () {
      for (final total in [0, 1, 500, 999, 1000, 1001, 2500, 3000, 99999]) {
        final balance = CoinBalance.fromTotal(total);
        expect(
          balance.coinsToNext,
          equals(balance.nextThreshold - balance.total),
          reason: 'Failed for total=$total',
        );
      }
    });

    test('nextThreshold is always strictly greater than total', () {
      for (final total in [0, 1, 500, 999, 1000, 1001, 2500, 3000, 99999]) {
        final balance = CoinBalance.fromTotal(total);
        expect(
          balance.nextThreshold,
          greaterThan(balance.total),
          reason: 'Failed for total=$total',
        );
      }
    });

    test('nextThreshold is always a multiple of 1000', () {
      for (final total in [0, 1, 500, 999, 1000, 1001, 2500, 3000, 99999]) {
        final balance = CoinBalance.fromTotal(total);
        expect(
          balance.nextThreshold % 1000,
          equals(0),
          reason: 'Failed for total=$total',
        );
      }
    });

    test('coinsToNext is always between 1 and 1000 inclusive', () {
      for (final total in [0, 1, 500, 999, 1000, 1001, 2500, 3000, 99999]) {
        final balance = CoinBalance.fromTotal(total);
        expect(
          balance.coinsToNext,
          greaterThanOrEqualTo(1),
          reason: 'Failed for total=$total',
        );
        expect(
          balance.coinsToNext,
          lessThanOrEqualTo(1000),
          reason: 'Failed for total=$total',
        );
      }
    });

    test('progress is always between 0.0 (inclusive) and 1.0 (exclusive)', () {
      for (final total in [0, 1, 500, 999, 1000, 1001, 2500, 3000, 99999]) {
        final balance = CoinBalance.fromTotal(total);
        expect(
          balance.progress,
          greaterThanOrEqualTo(0.0),
          reason: 'Failed for total=$total',
        );
        expect(
          balance.progress,
          lessThan(1.0),
          reason: 'Failed for total=$total',
        );
      }
    });
  });
}
