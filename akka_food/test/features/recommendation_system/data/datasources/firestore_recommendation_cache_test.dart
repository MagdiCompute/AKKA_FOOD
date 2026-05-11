import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/recommendation_system/data/datasources/firestore_recommendation_cache.dart';

void main() {
  group('FirestoreRecommendationCache', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DateTime fixedNow;
    late FirestoreRecommendationCache cache;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      fixedNow = DateTime(2024, 6, 15, 12, 0, 0);
      cache = FirestoreRecommendationCache(
        firestore: fakeFirestore,
        clock: () => fixedNow,
      );
    });

    group('getCachedRecommendations', () {
      test('returns null when document does not exist', () async {
        final result = await cache.getCachedRecommendations('user_123');

        expect(result, isNull);
      });

      test('returns RecommendationResult when cache is fresh', () async {
        // computedAt is 30 minutes ago (within 60-min TTL)
        final computedAt = fixedNow.subtract(const Duration(minutes: 30));
        await fakeFirestore.collection('recommendations').doc('user_123').set({
          'mealIds': ['meal_1', 'meal_2', 'meal_3'],
          'isPersonalized': true,
          'computedAt': Timestamp.fromDate(computedAt),
        });

        final result = await cache.getCachedRecommendations('user_123');

        expect(result, isNotNull);
        expect(result!.mealIds, ['meal_1', 'meal_2', 'meal_3']);
        expect(result.isPersonalized, isTrue);
        expect(result.computedAt, computedAt);
      });

      test('returns null when cache is stale (exactly 60 minutes)', () async {
        // computedAt is exactly 60 minutes ago (at TTL boundary)
        final computedAt = fixedNow.subtract(const Duration(minutes: 60));
        await fakeFirestore.collection('recommendations').doc('user_123').set({
          'mealIds': ['meal_1', 'meal_2'],
          'isPersonalized': true,
          'computedAt': Timestamp.fromDate(computedAt),
        });

        final result = await cache.getCachedRecommendations('user_123');

        expect(result, isNull);
      });

      test('returns null when cache is stale (older than 60 minutes)', () async {
        // computedAt is 90 minutes ago (beyond TTL)
        final computedAt = fixedNow.subtract(const Duration(minutes: 90));
        await fakeFirestore.collection('recommendations').doc('user_123').set({
          'mealIds': ['meal_1'],
          'isPersonalized': false,
          'computedAt': Timestamp.fromDate(computedAt),
        });

        final result = await cache.getCachedRecommendations('user_123');

        expect(result, isNull);
      });

      test('returns result when cache is just under TTL (59 minutes)', () async {
        // computedAt is 59 minutes ago (just within TTL)
        final computedAt = fixedNow.subtract(const Duration(minutes: 59));
        await fakeFirestore.collection('recommendations').doc('user_123').set({
          'mealIds': ['meal_a', 'meal_b'],
          'isPersonalized': false,
          'computedAt': Timestamp.fromDate(computedAt),
        });

        final result = await cache.getCachedRecommendations('user_123');

        expect(result, isNotNull);
        expect(result!.mealIds, ['meal_a', 'meal_b']);
        expect(result.isPersonalized, isFalse);
      });

      test('returns cold-start result with isPersonalized false', () async {
        final computedAt = fixedNow.subtract(const Duration(minutes: 10));
        await fakeFirestore.collection('recommendations').doc('user_456').set({
          'mealIds': ['popular_1', 'popular_2', 'popular_3'],
          'isPersonalized': false,
          'computedAt': Timestamp.fromDate(computedAt),
        });

        final result = await cache.getCachedRecommendations('user_456');

        expect(result, isNotNull);
        expect(result!.isPersonalized, isFalse);
        expect(result.mealIds, ['popular_1', 'popular_2', 'popular_3']);
      });

      test('reads from correct document path for given uid', () async {
        final computedAt = fixedNow.subtract(const Duration(minutes: 5));

        // Set up two different users
        await fakeFirestore.collection('recommendations').doc('user_A').set({
          'mealIds': ['meal_for_A'],
          'isPersonalized': true,
          'computedAt': Timestamp.fromDate(computedAt),
        });
        await fakeFirestore.collection('recommendations').doc('user_B').set({
          'mealIds': ['meal_for_B'],
          'isPersonalized': false,
          'computedAt': Timestamp.fromDate(computedAt),
        });

        final resultA = await cache.getCachedRecommendations('user_A');
        final resultB = await cache.getCachedRecommendations('user_B');

        expect(resultA!.mealIds, ['meal_for_A']);
        expect(resultB!.mealIds, ['meal_for_B']);
      });

      test('handles empty mealIds list', () async {
        final computedAt = fixedNow.subtract(const Duration(minutes: 5));
        await fakeFirestore.collection('recommendations').doc('user_123').set({
          'mealIds': <String>[],
          'isPersonalized': false,
          'computedAt': Timestamp.fromDate(computedAt),
        });

        final result = await cache.getCachedRecommendations('user_123');

        expect(result, isNotNull);
        expect(result!.mealIds, isEmpty);
      });

      test('handles freshly computed cache (0 minutes old)', () async {
        await fakeFirestore.collection('recommendations').doc('user_123').set({
          'mealIds': ['meal_1', 'meal_2'],
          'isPersonalized': true,
          'computedAt': Timestamp.fromDate(fixedNow),
        });

        final result = await cache.getCachedRecommendations('user_123');

        expect(result, isNotNull);
        expect(result!.mealIds, ['meal_1', 'meal_2']);
        expect(result.isPersonalized, isTrue);
      });
    });

    group('cacheTtl constant', () {
      test('is 60 minutes', () {
        expect(
          FirestoreRecommendationCache.cacheTtl,
          const Duration(minutes: 60),
        );
      });
    });
  });
}
