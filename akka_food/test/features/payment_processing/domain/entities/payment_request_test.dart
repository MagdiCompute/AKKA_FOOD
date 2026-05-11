import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/cart/domain/entities/cart_item.dart';
import 'package:akka_food/features/cart/domain/entities/cart_summary.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/payment_processing/domain/entities/payment_request.dart';

void main() {
  group('PaymentRequest', () {
    CartSummary makeCartSummary({
      double total = 2500.0,
      double subtotal = 2500.0,
      double deliveryFee = 500.0,
      double discount = 0.0,
      int redeemedCoins = 0,
    }) =>
        CartSummary(
          items: [
            const CartItem(
              mealId: 'meal_001',
              mealName: 'Riz au gras',
              mealImageUrl: 'https://example.com/riz.jpg',
              unitPrice: 1500.0,
              quantity: 1,
              isAvailable: true,
            ),
            const CartItem(
              mealId: 'meal_002',
              mealName: 'Jus de bissap',
              mealImageUrl: 'https://example.com/bissap.jpg',
              unitPrice: 500.0,
              quantity: 2,
              isAvailable: true,
            ),
          ],
          subtotal: subtotal,
          deliveryFee: deliveryFee,
          discount: discount,
          total: total,
          redeemedCoins: redeemedCoins,
          deliveryOption: DeliveryOption.delivery,
        );

    PaymentRequest makePaymentRequest({
      CartSummary? cartSummary,
      String phoneNumber = '+22370000000',
    }) =>
        PaymentRequest(
          cartSummary: cartSummary ?? makeCartSummary(),
          phoneNumber: phoneNumber,
        );

    // ── Construction ─────────────────────────────────────────────────────────

    test('creates a PaymentRequest with required fields', () {
      final request = makePaymentRequest();

      expect(request.phoneNumber, equals('+22370000000'));
      expect(request.cartSummary.total, equals(2500.0));
      expect(request.cartSummary.items.length, equals(2));
    });

    test('cartSummary contains correct item details', () {
      final request = makePaymentRequest();

      final firstItem = request.cartSummary.items.first;
      expect(firstItem.mealId, equals('meal_001'));
      expect(firstItem.mealName, equals('Riz au gras'));
      expect(firstItem.unitPrice, equals(1500.0));
      expect(firstItem.quantity, equals(1));
    });

    // ── fromMap / toMap round-trip ─────────────────────────────────────────

    test('toMap → fromMap round-trip preserves all fields', () {
      final original = makePaymentRequest();
      // Use jsonEncode/jsonDecode to simulate a real serialization round-trip
      // (forces deep serialization of nested objects)
      final jsonString = jsonEncode(original.toMap());
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = PaymentRequest.fromMap(map);

      expect(restored, equals(original));
    });

    test('toJson → fromJson round-trip preserves all fields', () {
      final original = makePaymentRequest(
        phoneNumber: '+22376543210',
        cartSummary: makeCartSummary(total: 5000.0, subtotal: 4500.0),
      );
      final jsonString = jsonEncode(original.toJson());
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = PaymentRequest.fromJson(json);

      expect(restored, equals(original));
      expect(restored.phoneNumber, equals('+22376543210'));
      expect(restored.cartSummary.total, equals(5000.0));
    });

    test('toMap produces expected keys', () {
      final request = makePaymentRequest();
      final jsonString = jsonEncode(request.toMap());
      final map = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(map.containsKey('cartSummary'), isTrue);
      expect(map.containsKey('phoneNumber'), isTrue);
      expect(map['phoneNumber'], equals('+22370000000'));
      expect(map['cartSummary'], isA<Map<String, dynamic>>());
    });

    // ── copyWith ─────────────────────────────────────────────────────────────

    test('copyWith updates phoneNumber while preserving cartSummary', () {
      final original = makePaymentRequest(phoneNumber: '+22370000000');
      final updated = original.copyWith(phoneNumber: '+22399999999');

      expect(updated.phoneNumber, equals('+22399999999'));
      expect(updated.cartSummary, equals(original.cartSummary));
    });

    test('copyWith updates cartSummary while preserving phoneNumber', () {
      final original = makePaymentRequest();
      final newSummary = makeCartSummary(total: 8000.0);
      final updated = original.copyWith(cartSummary: newSummary);

      expect(updated.cartSummary.total, equals(8000.0));
      expect(updated.phoneNumber, equals(original.phoneNumber));
    });

    // ── equality ─────────────────────────────────────────────────────────────

    test('two PaymentRequests with same data are equal', () {
      final a = makePaymentRequest();
      final b = makePaymentRequest();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('PaymentRequests with different phoneNumber are not equal', () {
      final a = makePaymentRequest(phoneNumber: '+22370000000');
      final b = makePaymentRequest(phoneNumber: '+22399999999');

      expect(a, isNot(equals(b)));
    });

    test('PaymentRequests with different cartSummary are not equal', () {
      final a = makePaymentRequest(cartSummary: makeCartSummary(total: 1000.0));
      final b = makePaymentRequest(cartSummary: makeCartSummary(total: 2000.0));

      expect(a, isNot(equals(b)));
    });
  });
}
