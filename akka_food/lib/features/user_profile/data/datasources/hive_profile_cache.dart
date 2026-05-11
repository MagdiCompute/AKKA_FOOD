import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/coin_transaction.dart';
import '../../domain/entities/delivery_address.dart';
import '../../domain/entities/order_summary.dart';
import '../../domain/entities/user_profile.dart';

// ---------------------------------------------------------------------------
// Box name constants
// ---------------------------------------------------------------------------

/// Hive box name for cached [UserProfile] data.
const String kProfileCacheBox = 'profile_cache';

/// Hive box name for cached [DeliveryAddress] list data.
const String kAddressCacheBox = 'address_cache';

/// Hive box name for cached [OrderSummary] list data.
const String kOrderHistoryCacheBox = 'order_history_cache';

/// Hive box name for cached [CoinTransaction] list data.
const String kCoinHistoryCacheBox = 'coin_history_cache';

// ---------------------------------------------------------------------------
// HiveProfileCache
// ---------------------------------------------------------------------------

/// Local cache for user profile data backed by Hive.
///
/// Each box stores data keyed by the user's [uid] as a JSON string.
/// The JSON payload is wrapped with a `cachedAt` ISO-8601 timestamp so that
/// TTL enforcement is self-contained within each entry:
///
/// ```json
/// { "cachedAt": "2024-01-01T12:00:00.000Z", "data": { ... } }
/// ```
///
/// A 5-minute TTL ([cacheTtl]) is enforced on every read: if the entry is
/// older than 5 minutes the getter returns `null` (cache miss), causing the
/// caller to fall back to a fresh Firestore fetch.
///
/// The four boxes must be opened before this class is used. Call
/// [HiveProfileCache.open] during app initialisation (e.g. in `main.dart`
/// before `runApp`).
class HiveProfileCache {
  HiveProfileCache({
    required Box<String> profileBox,
    required Box<String> addressBox,
    required Box<String> orderHistoryBox,
    required Box<String> coinHistoryBox,
  })  : _profileBox = profileBox,
        _addressBox = addressBox,
        _orderHistoryBox = orderHistoryBox,
        _coinHistoryBox = coinHistoryBox;

  final Box<String> _profileBox;
  final Box<String> _addressBox;
  final Box<String> _orderHistoryBox;
  final Box<String> _coinHistoryBox;

  /// Cache time-to-live. Entries older than this are treated as stale.
  static const Duration cacheTtl = Duration(minutes: 5);

  // -------------------------------------------------------------------------
  // Factory — open boxes and construct instance
  // -------------------------------------------------------------------------

  /// Opens all four Hive boxes and returns a ready-to-use [HiveProfileCache].
  ///
  /// Safe to call multiple times — Hive returns the already-open box if it
  /// was opened previously.
  static Future<HiveProfileCache> open() async {
    final profileBox = await Hive.openBox<String>(kProfileCacheBox);
    final addressBox = await Hive.openBox<String>(kAddressCacheBox);
    final orderHistoryBox = await Hive.openBox<String>(kOrderHistoryCacheBox);
    final coinHistoryBox = await Hive.openBox<String>(kCoinHistoryCacheBox);

    return HiveProfileCache(
      profileBox: profileBox,
      addressBox: addressBox,
      orderHistoryBox: orderHistoryBox,
      coinHistoryBox: coinHistoryBox,
    );
  }

  // -------------------------------------------------------------------------
  // TTL helpers
  // -------------------------------------------------------------------------

  /// Wraps [data] with a `cachedAt` timestamp envelope before storing.
  String _wrap(Object data) {
    return jsonEncode({
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    });
  }

  /// Unwraps the stored envelope and returns the inner `data` value, or
  /// `null` if the entry is missing, malformed, or older than [cacheTtl].
  ///
  /// [raw] is the raw string stored in the Hive box.
  Object? _unwrapIfFresh(String? raw) {
    if (raw == null) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAtStr = envelope['cachedAt'] as String?;
      if (cachedAtStr == null) return null;

      final cachedAt = DateTime.parse(cachedAtStr);
      final age = DateTime.now().toUtc().difference(cachedAt.toUtc());
      if (age > cacheTtl) return null; // stale — treat as cache miss

      return envelope['data'];
    } catch (_) {
      return null;
    }
  }

  /// Returns `true` when the cached entry for [uid] in [box] exists and is
  /// within the [cacheTtl] window.
  ///
  /// Useful for callers that only need to check validity without decoding the
  /// full payload.
  bool isCacheValid(String uid, Box<String> box) {
    final raw = box.get(uid);
    return _unwrapIfFresh(raw) != null;
  }

  // -------------------------------------------------------------------------
  // Profile
  // -------------------------------------------------------------------------

  /// Persists [profile] to the local cache, keyed by [profile.uid].
  ///
  /// The entry is stamped with the current UTC time and will be considered
  /// stale after [cacheTtl].
  Future<void> saveProfile(UserProfile profile) async {
    final wrapped = _wrap(profile.toMap());
    await _profileBox.put(profile.uid, wrapped);
  }

  /// Returns the cached [UserProfile] for [uid], or `null` if not cached or
  /// the entry is older than [cacheTtl].
  UserProfile? getProfile(String uid) {
    final data = _unwrapIfFresh(_profileBox.get(uid));
    if (data == null) return null;
    try {
      return UserProfile.fromMap(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Returns the cached [UserProfile] for [uid] regardless of TTL, or `null`
  /// if no entry exists at all.
  ///
  /// Used as a last-resort fallback when the network is unavailable.
  UserProfile? getProfileStale(String uid) {
    final raw = _profileBox.get(uid);
    if (raw == null) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final data = envelope['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return UserProfile.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Addresses
  // -------------------------------------------------------------------------

  /// Persists [addresses] to the local cache, keyed by [uid].
  Future<void> saveAddresses(
    String uid,
    List<DeliveryAddress> addresses,
  ) async {
    final wrapped = _wrap(addresses.map((a) => a.toMap()).toList());
    await _addressBox.put(uid, wrapped);
  }

  /// Returns the cached address list for [uid], or `null` if not cached or
  /// the entry is older than [cacheTtl].
  List<DeliveryAddress>? getAddresses(String uid) {
    final data = _unwrapIfFresh(_addressBox.get(uid));
    if (data == null) return null;
    try {
      final list = data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(DeliveryAddress.fromMap)
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Returns the cached address list for [uid] regardless of TTL, or `null`
  /// if no entry exists at all.
  List<DeliveryAddress>? getAddressesStale(String uid) {
    final raw = _addressBox.get(uid);
    if (raw == null) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final list = envelope['data'] as List<dynamic>?;
      if (list == null) return null;
      return list
          .whereType<Map<String, dynamic>>()
          .map(DeliveryAddress.fromMap)
          .toList();
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Order history
  // -------------------------------------------------------------------------

  /// Persists [orders] to the local cache, keyed by [uid].
  Future<void> saveOrderHistory(
    String uid,
    List<OrderSummary> orders,
  ) async {
    final wrapped = _wrap(orders.map((o) => o.toMap()).toList());
    await _orderHistoryBox.put(uid, wrapped);
  }

  /// Returns the cached order history for [uid], or `null` if not cached or
  /// the entry is older than [cacheTtl].
  List<OrderSummary>? getOrderHistory(String uid) {
    final data = _unwrapIfFresh(_orderHistoryBox.get(uid));
    if (data == null) return null;
    try {
      final list = data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(OrderSummary.fromMap)
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Returns the cached order history for [uid] regardless of TTL, or `null`
  /// if no entry exists at all.
  List<OrderSummary>? getOrderHistoryStale(String uid) {
    final raw = _orderHistoryBox.get(uid);
    if (raw == null) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final list = envelope['data'] as List<dynamic>?;
      if (list == null) return null;
      return list
          .whereType<Map<String, dynamic>>()
          .map(OrderSummary.fromMap)
          .toList();
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Coin history
  // -------------------------------------------------------------------------

  /// Persists [transactions] to the local cache, keyed by [uid].
  Future<void> saveCoinHistory(
    String uid,
    List<CoinTransaction> transactions,
  ) async {
    final wrapped = _wrap(transactions.map((t) => t.toMap()).toList());
    await _coinHistoryBox.put(uid, wrapped);
  }

  /// Returns the cached coin transaction history for [uid], or `null` if not
  /// cached or the entry is older than [cacheTtl].
  List<CoinTransaction>? getCoinHistory(String uid) {
    final data = _unwrapIfFresh(_coinHistoryBox.get(uid));
    if (data == null) return null;
    try {
      final list = data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(CoinTransaction.fromMap)
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Returns the cached coin history for [uid] regardless of TTL, or `null`
  /// if no entry exists at all.
  List<CoinTransaction>? getCoinHistoryStale(String uid) {
    final raw = _coinHistoryBox.get(uid);
    if (raw == null) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final list = envelope['data'] as List<dynamic>?;
      if (list == null) return null;
      return list
          .whereType<Map<String, dynamic>>()
          .map(CoinTransaction.fromMap)
          .toList();
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Clear
  // -------------------------------------------------------------------------

  /// Removes all cached data for [uid] across all four boxes.
  ///
  /// Call this on sign-out or account deletion to avoid stale data leaking
  /// between sessions.
  Future<void> clearAll(String uid) async {
    await Future.wait([
      _profileBox.delete(uid),
      _addressBox.delete(uid),
      _orderHistoryBox.delete(uid),
      _coinHistoryBox.delete(uid),
    ]);
  }
}
