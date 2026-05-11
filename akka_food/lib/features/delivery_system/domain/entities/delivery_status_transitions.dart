import 'delivery_status.dart';

/// Valid status transitions for the delivery pipeline.
///
/// Pure Dart — no Flutter or Firebase imports.
///
/// Transition graph:
///   pending → confirmed → preparing → outForDelivery → delivered
///                                                    → failed
///
/// Terminal states (delivered, failed) have no outgoing transitions.
const Map<DeliveryStatus, List<DeliveryStatus>> validStatusTransitions = {
  DeliveryStatus.pending: [DeliveryStatus.confirmed],
  DeliveryStatus.confirmed: [DeliveryStatus.preparing],
  DeliveryStatus.preparing: [DeliveryStatus.outForDelivery],
  DeliveryStatus.outForDelivery: [DeliveryStatus.delivered, DeliveryStatus.failed],
  DeliveryStatus.delivered: [],
  DeliveryStatus.failed: [],
};

/// Returns `true` if transitioning from [from] to [to] is a valid
/// status change according to the delivery pipeline rules.
bool isValidTransition(DeliveryStatus from, DeliveryStatus to) {
  final allowed = validStatusTransitions[from];
  if (allowed == null) return false;
  return allowed.contains(to);
}
