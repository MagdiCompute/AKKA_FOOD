import 'dart:async';

import 'package:akka_food/features/cart/data/datasources/remote_config_service.dart';
import 'package:akka_food/features/cart/domain/entities/cart.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:akka_food/features/delivery_system/data/datasources/delivery_fee_service.dart';
import 'package:akka_food/features/delivery_system/presentation/widgets/delivery_fee_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeliveryFeeDisplay', () {
    Widget buildWidget({
      DeliveryOption deliveryOption = DeliveryOption.delivery,
      double fee = 500.0,
    }) {
      return ProviderScope(
        overrides: [
          cartNotifierProvider.overrideWith(() => _FakeCartNotifier(
                Cart(items: const [], deliveryOption: deliveryOption),
              )),
          deliveryFeeServiceProvider.overrideWith((ref) async {
            return DeliveryFeeService(
              _FakeRemoteConfigService(feeXof: fee),
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DeliveryFeeDisplay(),
          ),
        ),
      );
    }

    testWidgets('displays delivery fee when delivery is selected (Req 5.1)',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        deliveryOption: DeliveryOption.delivery,
        fee: 500.0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('500 XOF'), findsOneWidget);
    });

    testWidgets('displays "Free" when pickup is selected (Req 5.3)',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        deliveryOption: DeliveryOption.pickup,
        fee: 500.0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Delivery Fee'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('displays custom fee from Remote Config (Req 5.2)',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        deliveryOption: DeliveryOption.delivery,
        fee: 750.0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('750 XOF'), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching', (tester) async {
      // Use a Completer that never completes to simulate loading state
      final completer = Completer<DeliveryFeeService>();

      final widget = ProviderScope(
        overrides: [
          cartNotifierProvider.overrideWith(() => _FakeCartNotifier(
                const Cart(
                    items: [], deliveryOption: DeliveryOption.delivery),
              )),
          deliveryFeeServiceProvider.overrideWith((ref) {
            return completer.future;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DeliveryFeeDisplay(),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Delivery Fee'), findsOneWidget);

      // Complete the future to avoid pending timer issues
      completer.complete(DeliveryFeeService(
        _FakeRemoteConfigService(feeXof: 500.0),
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('shows delivery icon when delivery is selected',
        (tester) async {
      await tester.pumpWidget(buildWidget(
        deliveryOption: DeliveryOption.delivery,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delivery_dining), findsOneWidget);
    });

    testWidgets('shows store icon when pickup is selected', (tester) async {
      await tester.pumpWidget(buildWidget(
        deliveryOption: DeliveryOption.pickup,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.store), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

class _FakeCartNotifier extends CartNotifier {
  _FakeCartNotifier(this._cart);

  final Cart _cart;

  @override
  Cart build() => _cart;
}

class _FakeRemoteConfigService extends Fake implements RemoteConfigService {
  _FakeRemoteConfigService({this.feeXof = kDefaultDeliveryFeeXof});

  final double feeXof;

  @override
  double get deliveryFeeXof => feeXof > 0 ? feeXof : kDefaultDeliveryFeeXof;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> fetchAndActivate() async => true;
}
