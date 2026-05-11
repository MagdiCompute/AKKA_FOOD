import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/recommendation_system/data/datasources/cloud_function_recommendation_data_source.dart';
import 'package:akka_food/features/recommendation_system/domain/entities/recommendation_result.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// A fake [HttpsCallableResult] that returns a predefined [data] map.
class FakeHttpsCallableResult implements HttpsCallableResult<Map<String, dynamic>> {
  FakeHttpsCallableResult(this.data);

  @override
  final Map<String, dynamic> data;
}

/// A fake [HttpsCallable] that either returns a result or throws an exception.
class FakeHttpsCallable implements HttpsCallable {
  FakeHttpsCallable({this.result, this.exception});

  final HttpsCallableResult<Map<String, dynamic>>? result;
  final Exception? exception;

  String? lastCalledWith;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic data]) async {
    if (exception != null) throw exception!;
    return result! as HttpsCallableResult<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A fake [FirebaseFunctions] that returns a predefined [HttpsCallable].
class FakeFirebaseFunctions implements FirebaseFunctions {
  FakeFirebaseFunctions({required this.callable});

  final FakeHttpsCallable callable;
  String? lastCalledFunctionName;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    lastCalledFunctionName = name;
    return callable;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CloudFunctionRecommendationDataSource', () {
    group('fetchRecommendations', () {
      test('calls computeRecommendations Cloud Function', () async {
        final callable = FakeHttpsCallable(
          result: FakeHttpsCallableResult({
            'mealIds': ['meal_1', 'meal_2', 'meal_3'],
            'isPersonalized': true,
          }),
        );
        final functions = FakeFirebaseFunctions(callable: callable);
        final dataSource =
            CloudFunctionRecommendationDataSource(functions: functions);

        await dataSource.fetchRecommendations();

        expect(functions.lastCalledFunctionName, 'computeRecommendations');
      });

      test('returns RecommendationResult with personalized meals', () async {
        final callable = FakeHttpsCallable(
          result: FakeHttpsCallableResult({
            'mealIds': ['meal_1', 'meal_2', 'meal_3'],
            'isPersonalized': true,
          }),
        );
        final functions = FakeFirebaseFunctions(callable: callable);
        final dataSource =
            CloudFunctionRecommendationDataSource(functions: functions);

        final result = await dataSource.fetchRecommendations();

        expect(result, isA<RecommendationResult>());
        expect(result.mealIds, ['meal_1', 'meal_2', 'meal_3']);
        expect(result.isPersonalized, isTrue);
        expect(result.computedAt, isNotNull);
      });

      test('returns cold-start result with isPersonalized false', () async {
        final callable = FakeHttpsCallable(
          result: FakeHttpsCallableResult({
            'mealIds': ['popular_1', 'popular_2'],
            'isPersonalized': false,
          }),
        );
        final functions = FakeFirebaseFunctions(callable: callable);
        final dataSource =
            CloudFunctionRecommendationDataSource(functions: functions);

        final result = await dataSource.fetchRecommendations();

        expect(result.mealIds, ['popular_1', 'popular_2']);
        expect(result.isPersonalized, isFalse);
      });

      test('handles empty mealIds gracefully', () async {
        final callable = FakeHttpsCallable(
          result: FakeHttpsCallableResult({
            'mealIds': <String>[],
            'isPersonalized': false,
          }),
        );
        final functions = FakeFirebaseFunctions(callable: callable);
        final dataSource =
            CloudFunctionRecommendationDataSource(functions: functions);

        final result = await dataSource.fetchRecommendations();

        expect(result.mealIds, isEmpty);
        expect(result.isPersonalized, isFalse);
      });

      test('defaults mealIds to empty list when null in response', () async {
        final callable = FakeHttpsCallable(
          result: FakeHttpsCallableResult({
            'isPersonalized': true,
          }),
        );
        final functions = FakeFirebaseFunctions(callable: callable);
        final dataSource =
            CloudFunctionRecommendationDataSource(functions: functions);

        final result = await dataSource.fetchRecommendations();

        expect(result.mealIds, isEmpty);
      });

      test('defaults isPersonalized to false when null in response', () async {
        final callable = FakeHttpsCallable(
          result: FakeHttpsCallableResult({
            'mealIds': ['meal_1'],
          }),
        );
        final functions = FakeFirebaseFunctions(callable: callable);
        final dataSource =
            CloudFunctionRecommendationDataSource(functions: functions);

        final result = await dataSource.fetchRecommendations();

        expect(result.isPersonalized, isFalse);
      });

      test('sets computedAt to approximately now', () async {
        final callable = FakeHttpsCallable(
          result: FakeHttpsCallableResult({
            'mealIds': ['meal_1'],
            'isPersonalized': true,
          }),
        );
        final functions = FakeFirebaseFunctions(callable: callable);
        final dataSource =
            CloudFunctionRecommendationDataSource(functions: functions);

        final before = DateTime.now();
        final result = await dataSource.fetchRecommendations();
        final after = DateTime.now();

        expect(
          result.computedAt.isAfter(before) ||
              result.computedAt.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          result.computedAt.isBefore(after) ||
              result.computedAt.isAtSameMomentAs(after),
          isTrue,
        );
      });

      test(
          'throws RecommendationFetchException on FirebaseFunctionsException',
          () async {
        final callable = FakeHttpsCallable(
          exception: FirebaseFunctionsException(
            code: 'internal',
            message: 'Server error',
          ),
        );
        final functions = FakeFirebaseFunctions(callable: callable);
        final dataSource =
            CloudFunctionRecommendationDataSource(functions: functions);

        expect(
          () => dataSource.fetchRecommendations(),
          throwsA(isA<RecommendationFetchException>()),
        );
      });

      test('RecommendationFetchException contains error details', () async {
        final callable = FakeHttpsCallable(
          exception: FirebaseFunctionsException(
            code: 'unavailable',
            message: 'Service unavailable',
          ),
        );
        final functions = FakeFirebaseFunctions(callable: callable);
        final dataSource =
            CloudFunctionRecommendationDataSource(functions: functions);

        try {
          await dataSource.fetchRecommendations();
          fail('Should have thrown');
        } on RecommendationFetchException catch (e) {
          expect(e.message, 'Service unavailable');
          expect(e.code, 'unavailable');
          expect(e.toString(), contains('RecommendationFetchException'));
          expect(e.toString(), contains('unavailable'));
        }
      });

      test(
          'throws RecommendationNetworkException on generic Exception',
          () async {
        final callable = FakeHttpsCallable(
          exception: Exception('No internet connection'),
        );
        final functions = FakeFirebaseFunctions(callable: callable);
        final dataSource =
            CloudFunctionRecommendationDataSource(functions: functions);

        expect(
          () => dataSource.fetchRecommendations(),
          throwsA(isA<RecommendationNetworkException>()),
        );
      });

      test('RecommendationNetworkException contains error message', () async {
        final callable = FakeHttpsCallable(
          exception: Exception('Timeout'),
        );
        final functions = FakeFirebaseFunctions(callable: callable);
        final dataSource =
            CloudFunctionRecommendationDataSource(functions: functions);

        try {
          await dataSource.fetchRecommendations();
          fail('Should have thrown');
        } on RecommendationNetworkException catch (e) {
          expect(e.message, contains('Timeout'));
          expect(e.toString(), contains('RecommendationNetworkException'));
        }
      });
    });
  });
}
