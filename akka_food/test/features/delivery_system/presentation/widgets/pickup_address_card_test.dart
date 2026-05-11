import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/delivery_system/presentation/widgets/pickup_address_card.dart';

void main() {
  group('PickupAddressCard', () {
    const restaurantName = 'AKKA Restaurant';
    const restaurantAddress = '45 Boulevard de la République, Dakar';

    Widget buildWidget({
      String name = restaurantName,
      String address = restaurantAddress,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PickupAddressCard(
            restaurantName: name,
            restaurantAddress: address,
          ),
        ),
      );
    }

    testWidgets('displays the restaurant name', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text(restaurantName), findsOneWidget);
    });

    testWidgets('displays the restaurant address', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text(restaurantAddress), findsOneWidget);
    });

    testWidgets('shows storefront icon', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    });

    testWidgets('shows directions hint', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Get directions'), findsOneWidget);
      expect(find.byIcon(Icons.directions_outlined), findsOneWidget);
    });

    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(
        find.bySemanticsLabel('Pickup address for $restaurantName'),
        findsOneWidget,
      );
    });

    testWidgets('renders within a Card widget', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('displays different restaurant details', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          name: 'Chez Fatou',
          address: '12 Rue des Almadies, Dakar',
        ),
      );

      expect(find.text('Chez Fatou'), findsOneWidget);
      expect(find.text('12 Rue des Almadies, Dakar'), findsOneWidget);
    });

    testWidgets('semantic label updates with restaurant name', (tester) async {
      await tester.pumpWidget(
        buildWidget(name: 'Le Petit Bistro'),
      );

      expect(
        find.bySemanticsLabel('Pickup address for Le Petit Bistro'),
        findsOneWidget,
      );
    });
  });
}
