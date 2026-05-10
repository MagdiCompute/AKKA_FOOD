import 'package:cloud_functions/cloud_functions.dart';

/// Handles all Cloud Function calls for admin write operations.
///
/// All admin writes (create, update, delete) go through Cloud Functions
/// rather than direct Firestore client writes, as required by the
/// admin dashboard security design.
class CloudFunctionAdminDataSource {
  CloudFunctionAdminDataSource({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Calls the `adminCreateMeal` Cloud Function to create a new meal.
  ///
  /// [data] must include at minimum `name`, `price`, and `categoryId`.
  /// Returns the new meal's ID on success.
  /// Throws a [FirebaseFunctionsException] on error.
  Future<String> createMeal(Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('adminCreateMeal');
    final result = await callable.call<Map<String, dynamic>>(data);
    return result.data['mealId'] as String;
  }

  /// Calls the `adminUpdateMeal` Cloud Function to update an existing meal.
  ///
  /// [mealId] identifies the meal to update; [data] contains the fields to
  /// update. Throws a [FirebaseFunctionsException] on error (e.g. permission
  /// denied, meal not found).
  Future<void> updateMeal(String mealId, Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('adminUpdateMeal');
    await callable.call<void>({'mealId': mealId, ...data});
  }

  /// Calls the `adminDeleteMeal` Cloud Function to delete the meal with [mealId].
  ///
  /// Throws a [FirebaseFunctionsException] on error (e.g. permission denied,
  /// meal not found).
  Future<void> deleteMeal(String mealId) async {
    final callable = _functions.httpsCallable('adminDeleteMeal');
    await callable.call<void>({'mealId': mealId});
  }

  /// Calls the `adminManageCategory` Cloud Function.
  ///
  /// [data] must include `action` ('create' | 'update' | 'deactivate' |
  /// 'activate') and any action-specific fields.
  ///
  /// Returns the response data map (e.g. `{'success': true, 'categoryId': '…'}`
  /// for create).
  /// Throws a [FirebaseFunctionsException] on error (e.g. permission denied,
  /// duplicate name).
  Future<Map<String, dynamic>> manageCategory(
    Map<String, dynamic> data,
  ) async {
    final callable = _functions.httpsCallable('adminManageCategory');
    final result = await callable.call<Map<String, dynamic>>(data);
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Calls the `adminUpdateOrderStatus` Cloud Function.
  ///
  /// [orderId] identifies the order to update.
  /// [status] is the new delivery status string (e.g. `'out_for_delivery'`).
  /// [etaMinutes] is required when [status] is `'out_for_delivery'`.
  ///
  /// Throws a [FirebaseFunctionsException] on error (e.g. permission denied,
  /// order not found, missing etaMinutes).
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    int? etaMinutes,
  }) async {
    final callable = _functions.httpsCallable('adminUpdateOrderStatus');
    final payload = <String, dynamic>{
      'orderId': orderId,
      'status': status,
      if (etaMinutes != null) 'etaMinutes': etaMinutes,
    };
    await callable.call<void>(payload);
  }
}
