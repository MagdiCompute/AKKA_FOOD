import 'package:freezed_annotation/freezed_annotation.dart';

part 'coin_balance.freezed.dart';

/// Domain value object representing a user's computed coin balance.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// [total] is the aggregate sum of all coin transactions.
/// [nextThreshold] is the next multiple of 1000 above [total].
/// [coinsToNext] is [nextThreshold] minus [total].
///
/// Use [CoinBalance.fromTotal] to compute all fields from a single total value.
@freezed
abstract class CoinBalance with _$CoinBalance {
  const CoinBalance._();

  const factory CoinBalance({
    required int total,
    required int nextThreshold,
    required int coinsToNext,
  }) = _CoinBalance;

  /// Computes [nextThreshold] and [coinsToNext] from a raw [total].
  ///
  /// - `nextThreshold` = next multiple of 1000 strictly above [total]
  ///   (e.g. total=0 → 1000, total=500 → 1000, total=1000 → 2000)
  /// - `coinsToNext` = nextThreshold - total
  factory CoinBalance.fromTotal(int total) {
    final nextThreshold = ((total ~/ 1000) + 1) * 1000;
    final coinsToNext = nextThreshold - total;
    return CoinBalance(
      total: total,
      nextThreshold: nextThreshold,
      coinsToNext: coinsToNext,
    );
  }

  /// Progress toward the next 1000-coin redemption threshold.
  ///
  /// Returns a value between 0.0 (inclusive) and 1.0 (exclusive).
  /// Useful for rendering a progress bar in the UI.
  double get progress => (total % 1000) / 1000.0;
}
