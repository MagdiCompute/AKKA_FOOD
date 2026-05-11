// integration_test/delivery_option_selection_test.dart
//
// Task 10.4 — Delivery option selection in cart
//
// Verifies the delivery option selection flow:
// - "Delivery" is selected by default
// - Switching to "Pickup" hides the delivery address selector and shows the
//   pickup address card
// - Switching back to "Delivery" shows the delivery address selector and hides
//   the pickup address card
// - Validation: when Delivery is selected but no address is set, shows error
//
// Uses widget-level integration testing with the delivery system widgets
// directly. No real Firebase connection needed.
//
// Satisfies Requirement 1 AC1, AC2, AC3.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/features/delivery_system/domain/entities/delivery_address.dart';
import 'package:akka_food/features/delivery_system/domain/entities/delivery_option.dart';
import 'package:akka_food/features/delivery_system/presentation/widgets/delivery_address_selector.dart';
import 'package:akka_food/features/delivery_system/presentation/widgets/delivery_option_toggle.dart';
import 'package:akka_food/features/delivery_system/presentation/widgets/pickup_address_card.dart';

// =============================================================================
// Test fixtures
// =============================================================================

const _restaurantName = 'AKKA Restaurant';
const _restaurantAddress = '123 Rue de la Paix, Dakar';

const _testAddress = DeliveryAddress(
  street: '45 Avenue Cheikh Anta Diop',
  city: 'Dakar',
  latitude: 14.6928,
  longitude: -17.4467,
  label: 'Home',
);

// =============================================================================
// Stateful test harness — simulates the cart delivery option flow
// =============================================================================

/// A stateful wrapper that composes the delivery widgets together,
/// simulating how they interact in the cart screen.
class _DeliveryOptionTestHarness extends StatefulWidget {
  const _DeliveryOptionTestHarness({
    this.initialAddress,
  });

  final DeliveryAddress? initialAddress;

  @override
  State<_DeliveryOptionTestHarness> createState() =>
      _DeliveryOptionTestHarnessState();
}

class _DeliveryOptionTestHarnessState
    extends State<_DeliveryOptionTestHarness> {
  late DeliveryOption _selectedOption;
  late DeliveryAddress? _address;
  late bool _showError;

  @override
  void initState() {
    super.initState();
    _selectedOption = DeliveryOption.delivery;
    _address = widget.initialAddress;
    _showError = false;
  }

  void _onOptionChanged(DeliveryOption option) {
    setState(() {
      _selectedOption = option;
    });
  }

  void _onValidate() {
    setState(() {
      _showError = _selectedOption == DeliveryOption.delivery && _address == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              DeliveryOptionToggle(
                value: _selectedOption,
                onChanged: _onOptionChanged,
              ),
              const SizedBox(height: 16),
              if (_selectedOption == DeliveryOption.delivery)
                DeliveryAddressSelector(
                  address: _address,
                  onAddressChanged: () {},
                  showError: _showError,
                ),
              if (_selectedOption == DeliveryOption.pickup)
                const PickupAddressCard(
                  restaurantName: _restaurantName,
                  restaurantAddress: _restaurantAddress,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('validate_button'),
                onPressed: _onValidate,
                child: const Text('Proceed to Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Test: Delivery is selected by default (Req 1 AC1)
  // ---------------------------------------------------------------------------
  testWidgets(
    'Delivery option is selected by default',
    (WidgetTester tester) async {
      await tester.pumpWidget(const _DeliveryOptionTestHarness());
      await tester.pumpAndSettle();

      // The DeliveryOptionToggle should be present
      expect(find.byType(DeliveryOptionToggle), findsOneWidget);

      // "Delivery" text should be present in the toggle
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Pickup'), findsOneWidget);

      // Delivery address selector should be visible (delivery is default)
      expect(find.byType(DeliveryAddressSelector), findsOneWidget);

      // Pickup address card should NOT be visible
      expect(find.byType(PickupAddressCard), findsNothing);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: Tap Pickup → hides delivery address, shows pickup address (Req 1 AC3)
  // ---------------------------------------------------------------------------
  testWidgets(
    'selecting Pickup hides delivery address selector and shows pickup address card',
    (WidgetTester tester) async {
      await tester.pumpWidget(const _DeliveryOptionTestHarness());
      await tester.pumpAndSettle();

      // Verify initial state: delivery address selector visible
      expect(find.byType(DeliveryAddressSelector), findsOneWidget);
      expect(find.byType(PickupAddressCard), findsNothing);

      // Tap "Pickup" in the segmented button
      await tester.tap(find.text('Pickup'));
      await tester.pumpAndSettle();

      // Delivery address selector should be hidden
      expect(find.byType(DeliveryAddressSelector), findsNothing);

      // Pickup address card should be shown with restaurant info
      expect(find.byType(PickupAddressCard), findsOneWidget);
      expect(find.text(_restaurantName), findsOneWidget);
      expect(find.text(_restaurantAddress), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: Tap Delivery again → shows delivery address, hides pickup (Req 1 AC1, AC2)
  // ---------------------------------------------------------------------------
  testWidgets(
    'switching back to Delivery shows delivery address selector and hides pickup card',
    (WidgetTester tester) async {
      await tester.pumpWidget(const _DeliveryOptionTestHarness());
      await tester.pumpAndSettle();

      // Switch to Pickup first
      await tester.tap(find.text('Pickup'));
      await tester.pumpAndSettle();

      // Verify Pickup state
      expect(find.byType(PickupAddressCard), findsOneWidget);
      expect(find.byType(DeliveryAddressSelector), findsNothing);

      // Switch back to Delivery
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();

      // Delivery address selector should be visible again
      expect(find.byType(DeliveryAddressSelector), findsOneWidget);

      // Pickup address card should be hidden
      expect(find.byType(PickupAddressCard), findsNothing);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: Validation error when Delivery selected but no address set (Req 1 AC2)
  // ---------------------------------------------------------------------------
  testWidgets(
    'shows validation error when Delivery is selected but no address is set',
    (WidgetTester tester) async {
      await tester.pumpWidget(const _DeliveryOptionTestHarness());
      await tester.pumpAndSettle();

      // Verify no error is shown initially
      expect(find.text('Delivery address is required'), findsNothing);

      // Tap the validate button to trigger validation
      await tester.tap(find.byKey(const Key('validate_button')));
      await tester.pumpAndSettle();

      // Error message should be displayed
      expect(find.text('Delivery address is required'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // Test: No validation error when address is provided (Req 1 AC2)
  // ---------------------------------------------------------------------------
  testWidgets(
    'no validation error when Delivery is selected and address is provided',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const _DeliveryOptionTestHarness(initialAddress: _testAddress),
      );
      await tester.pumpAndSettle();

      // Verify the address is displayed
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('45 Avenue Cheikh Anta Diop, Dakar'), findsOneWidget);

      // Tap the validate button
      await tester.tap(find.byKey(const Key('validate_button')));
      await tester.pumpAndSettle();

      // No error should be shown
      expect(find.text('Delivery address is required'), findsNothing);
    },
  );
}
