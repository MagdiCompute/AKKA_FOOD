import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/delivery_system/domain/entities/delivery_address.dart';
import 'package:akka_food/features/delivery_system/presentation/widgets/delivery_address_selector.dart';

void main() {
  group('DeliveryAddressSelector', () {
    const testAddress = DeliveryAddress(
      street: '123 Main Street',
      city: 'Dakar',
      latitude: 14.6928,
      longitude: -17.4467,
      label: 'Home',
    );

    const testAddressNoLabel = DeliveryAddress(
      street: '456 Market Ave',
      city: 'Abidjan',
      latitude: 5.3600,
      longitude: -4.0083,
    );

    Widget buildWidget({
      DeliveryAddress? address,
      VoidCallback? onAddressChanged,
      bool showError = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: DeliveryAddressSelector(
            address: address,
            onAddressChanged: onAddressChanged ?? () {},
            showError: showError,
          ),
        ),
      );
    }

    group('when address is set', () {
      testWidgets('displays the address label as title', (tester) async {
        await tester.pumpWidget(buildWidget(address: testAddress));

        expect(find.text('Home'), findsOneWidget);
      });

      testWidgets('displays street and city as subtitle', (tester) async {
        await tester.pumpWidget(buildWidget(address: testAddress));

        expect(find.text('123 Main Street, Dakar'), findsOneWidget);
      });

      testWidgets('shows "Delivery Address" when label is null',
          (tester) async {
        await tester.pumpWidget(buildWidget(address: testAddressNoLabel));

        expect(find.text('Delivery Address'), findsOneWidget);
        expect(find.text('456 Market Ave, Abidjan'), findsOneWidget);
      });

      testWidgets('shows location icon', (tester) async {
        await tester.pumpWidget(buildWidget(address: testAddress));

        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      });

      testWidgets('shows edit button', (tester) async {
        await tester.pumpWidget(buildWidget(address: testAddress));

        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      });

      testWidgets('calls onAddressChanged when edit button is tapped',
          (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildWidget(
            address: testAddress,
            onAddressChanged: () => tapped = true,
          ),
        );

        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('does not show validation error when address is set',
          (tester) async {
        await tester.pumpWidget(
          buildWidget(address: testAddress, showError: true),
        );

        expect(find.text('Delivery address is required'), findsNothing);
      });
    });

    group('when address is null', () {
      testWidgets('displays "Add delivery address" prompt', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('Add delivery address'), findsOneWidget);
      });

      testWidgets('shows add location icon', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(
            find.byIcon(Icons.add_location_alt_outlined), findsOneWidget);
      });

      testWidgets('shows chevron right icon', (tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('calls onAddressChanged when tapped', (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildWidget(onAddressChanged: () => tapped = true),
        );

        await tester.tap(find.text('Add delivery address'));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });
    });

    group('validation error', () {
      testWidgets(
          'shows error message when showError is true and address is null',
          (tester) async {
        await tester.pumpWidget(buildWidget(showError: true));

        expect(find.text('Delivery address is required'), findsOneWidget);
      });

      testWidgets(
          'does not show error message when showError is false',
          (tester) async {
        await tester.pumpWidget(buildWidget(showError: false));

        expect(find.text('Delivery address is required'), findsNothing);
      });
    });

    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(
        find.bySemanticsLabel('Delivery address selector'),
        findsOneWidget,
      );
    });
  });
}
