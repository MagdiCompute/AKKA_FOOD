import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/cart.dart';

// ---------------------------------------------------------------------------
// Box name constant
// ---------------------------------------------------------------------------

/// Hive box name for persisting the user's [Cart].
///
/// The cart is stored as a JSON string keyed by the user's [uid].
/// Unlike the profile cache boxes, the cart does not use TTL wrapping —
/// it persists indefinitely until explicitly cleared or overwritten.
const String kCartBox = 'cart';

// ---------------------------------------------------------------------------
// HiveCartDataSource
// ---------------------------------------------------------------------------

/// Local data source for persisting and loading the user's cart using Hive.
///
/// The cart is serialized to JSON and stored as a string in the [kCartBox]
/// Hive box, keyed by the user's [uid]. This allows each user to have their
/// own cart that survives app restarts.
///
/// The box must be opened before this class is used. Call
/// [HiveCartDataSource.open] during app initialisation (e.g. in `main.dart`
/// before `runApp`).
class HiveCartDataSource {
  HiveCartDataSource({required Box<String> cartBox}) : _cartBox = cartBox;

  final Box<String> _cartBox;

  // -------------------------------------------------------------------------
  // Factory — open box and construct instance
  // -------------------------------------------------------------------------

  /// Opens the [kCartBox] Hive box and returns a ready-to-use
  /// [HiveCartDataSource].
  ///
  /// Safe to call multiple times — Hive returns the already-open box if it
  /// was opened previously.
  static Future<HiveCartDataSource> open() async {
    final cartBox = await Hive.openBox<String>(kCartBox);
    return HiveCartDataSource(cartBox: cartBox);
  }

  // -------------------------------------------------------------------------
  // Save
  // -------------------------------------------------------------------------

  /// Persists [cart] to local storage, keyed by [uid].
  ///
  /// The cart is serialized to JSON using the generated [Cart.toJson] method.
  Future<void> saveCart(String uid, Cart cart) async {
    final json = cart.toJson();
    final jsonString = jsonEncode(json);
    await _cartBox.put(uid, jsonString);
  }

  // -------------------------------------------------------------------------
  // Load
  // -------------------------------------------------------------------------

  /// Returns the persisted [Cart] for [uid], or `null` if no cart is stored.
  ///
  /// If the stored JSON is malformed or cannot be deserialized, returns `null`.
  Cart? loadCart(String uid) {
    final jsonString = _cartBox.get(uid);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Cart.fromJson(json);
    } catch (e) {
      // Log error silently and return null — cart will be treated as empty.
      // In production, consider logging to a crash reporting service.
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Clear
  // -------------------------------------------------------------------------

  /// Removes the persisted cart for [uid].
  ///
  /// Call this on sign-out or when the user explicitly clears their cart.
  Future<void> clearCart(String uid) async {
    await _cartBox.delete(uid);
  }

  // -------------------------------------------------------------------------
  // Clear all
  // -------------------------------------------------------------------------

  /// Removes all carts from the box.
  ///
  /// Useful for testing or administrative cleanup. Not typically called in
  /// production code.
  Future<void> clearAll() async {
    await _cartBox.clear();
  }
}
