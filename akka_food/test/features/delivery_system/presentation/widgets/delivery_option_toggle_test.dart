import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/delivery_system/domain/entities/delivery_option.dart';
import 'package:akka_food/features/delivery_system/presentation/widgets/delivery_option_toggle.dart';

void main() {
  group('DeliveryOptionToggle', () {
    Widget buildWidget({
      required DeliveryOption value,
      required ValueChanged<DeliveryOption> onChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: DeliveryOptionToggle(
            value: value,
            onChanged: onChanged,
          ),
        ),
      );
    }

    testWidgets('renders Delivery and Pickup segments', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          value: DeliveryOption.delivery,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Pickup'), findsOneWidget);
    });

    testWidgets('configures segments with correct icons', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          value: DeliveryOption.delivery,
          onChanged: (_) {},
        ),
      );

      final segmentedButton = tester.widget<SegmentedButton<DeliveryOption>>(
        find.byType(SegmentedButton<DeliveryOption>),
      );

      // Verify the segments are configured with the correct icons.
      final deliverySegment = segmentedButton.segments
          .firstWhere((s) => s.value == DeliveryOption.delivery);
      final pickupSegment = segmentedButton.segments
          .firstWhere((s) => s.value == DeliveryOption.pickup);

      expect((deliverySegment.icon as Icon?)?.icon,
          Icons.local_shipping_outlined);
      expect(
          (pickupSegment.icon as Icon?)?.icon, Icons.storefront_outlined);
    });

    testWidgets('shows delivery as selected when value is delivery',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(
          value: DeliveryOption.delivery,
          onChanged: (_) {},
        ),
      );

      final segmentedButton = tester.widget<SegmentedButton<DeliveryOption>>(
        find.byType(SegmentedButton<DeliveryOption>),
      );
      expect(segmentedButton.selected, {DeliveryOption.delivery});
    });

    testWidgets('shows pickup as selected when value is pickup',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(
          value: DeliveryOption.pickup,
          onChanged: (_) {},
        ),
      );

      final segmentedButton = tester.widget<SegmentedButton<DeliveryOption>>(
        find.byType(SegmentedButton<DeliveryOption>),
      );
      expect(segmentedButton.selected, {DeliveryOption.pickup});
    });

    testWidgets('calls onChanged with pickup when Pickup is tapped',
        (tester) async {
      DeliveryOption? changedTo;

      await tester.pumpWidget(
        buildWidget(
          value: DeliveryOption.delivery,
          onChanged: (option) => changedTo = option,
        ),
      );

      await tester.tap(find.text('Pickup'));
      await tester.pumpAndSettle();

      expect(changedTo, DeliveryOption.pickup);
    });

    testWidgets('calls onChanged with delivery when Delivery is tapped',
        (tester) async {
      DeliveryOption? changedTo;

      await tester.pumpWidget(
        buildWidget(
          value: DeliveryOption.pickup,
          onChanged: (option) => changedTo = option,
        ),
      );

      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();

      expect(changedTo, DeliveryOption.delivery);
    });

    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          value: DeliveryOption.delivery,
          onChanged: (_) {},
        ),
      );

      expect(
        find.bySemanticsLabel('Delivery option selector'),
        findsOneWidget,
      );
    });
  });
}
