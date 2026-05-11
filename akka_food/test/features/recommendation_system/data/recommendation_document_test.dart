import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/recommendation_system/data/recommendation_document.dart';
import 'package:akka_food/features/recommendation_system/domain/entities/recommendation_result.dart';

void main() {
  group('RecommendationDocument', () {
    final testDate = DateTime(2024, 6, 15, 10, 30);
    final testMealIds = ['meal_1', 'meal_2', 'meal_3'];

    group('fromMap', () {
      test('parses a valid Firestore document map with Timestamp', () {
        final map = <String, dynamic>{
          'mealIds': ['meal_1', 'meal_2', 'meal_3'],
          'isPersonalized': true,
          'computedAt': Timestamp.fromDate(testDate),
        };

        final doc = RecommendationDocument.fromMap(map);

        expect(doc.mealIds, testMealIds);
        expect(doc.isPersonalized, isTrue);
        expect(doc.computedAt, testDate);
      });

      test('parses computedAt from ISO-8601 string', () {
        final map = <String, dynamic>{
          'mealIds': ['meal_1'],
          'isPersonalized': false,
          'computedAt': testDate.toIso8601String(),
        };

        final doc = RecommendationDocument.fromMap(map);

        expect(doc.computedAt, testDate);
      });

      test('defaults isPersonalized to false when missing', () {
        final map = <String, dynamic>{
          'mealIds': <String>[],
          'computedAt': Timestamp.fromDate(testDate),
        };

        final doc = RecommendationDocument.fromMap(map);

        expect(doc.isPersonalized, isFalse);
      });

      test('defaults mealIds to empty list when missing', () {
        final map = <String, dynamic>{
          'isPersonalized': true,
          'computedAt': Timestamp.fromDate(testDate),
        };

        final doc = RecommendationDocument.fromMap(map);

        expect(doc.mealIds, isEmpty);
      });

      test('defaults computedAt to DateTime.now when null', () {
        final map = <String, dynamic>{
          'mealIds': <String>[],
          'isPersonalized': false,
          'computedAt': null,
        };

        final before = DateTime.now();
        final doc = RecommendationDocument.fromMap(map);
        final after = DateTime.now();

        expect(doc.computedAt.isAfter(before) || doc.computedAt == before,
            isTrue);
        expect(doc.computedAt.isBefore(after) || doc.computedAt == after,
            isTrue);
      });
    });

    group('toMap', () {
      test('produces a valid Firestore map with Timestamp', () {
        final doc = RecommendationDocument(
          mealIds: testMealIds,
          isPersonalized: true,
          computedAt: testDate,
        );

        final map = doc.toMap();

        expect(map['mealIds'], testMealIds);
        expect(map['isPersonalized'], isTrue);
        expect(map['computedAt'], isA<Timestamp>());
        expect((map['computedAt'] as Timestamp).toDate(), testDate);
      });

      test('cold-start document has isPersonalized false', () {
        final doc = RecommendationDocument(
          mealIds: testMealIds,
          isPersonalized: false,
          computedAt: testDate,
        );

        final map = doc.toMap();

        expect(map['isPersonalized'], isFalse);
      });
    });

    group('toDomain', () {
      test('converts to RecommendationResult domain entity', () {
        final doc = RecommendationDocument(
          mealIds: testMealIds,
          isPersonalized: true,
          computedAt: testDate,
        );

        final result = doc.toDomain();

        expect(result, isA<RecommendationResult>());
        expect(result.mealIds, testMealIds);
        expect(result.isPersonalized, isTrue);
        expect(result.computedAt, testDate);
      });
    });

    group('fromDomain', () {
      test('creates document from RecommendationResult domain entity', () {
        final result = RecommendationResult(
          mealIds: testMealIds,
          isPersonalized: false,
          computedAt: testDate,
        );

        final doc = RecommendationDocument.fromDomain(result);

        expect(doc.mealIds, testMealIds);
        expect(doc.isPersonalized, isFalse);
        expect(doc.computedAt, testDate);
      });
    });

    group('roundtrip', () {
      test('fromMap → toMap preserves all fields', () {
        final original = <String, dynamic>{
          'mealIds': ['meal_a', 'meal_b', 'meal_c', 'meal_d', 'meal_e'],
          'isPersonalized': true,
          'computedAt': Timestamp.fromDate(testDate),
        };

        final doc = RecommendationDocument.fromMap(original);
        final roundtripped = doc.toMap();

        expect(roundtripped['mealIds'], original['mealIds']);
        expect(roundtripped['isPersonalized'], original['isPersonalized']);
        expect(roundtripped['computedAt'], original['computedAt']);
      });

      test('domain → document → domain preserves all fields', () {
        final original = RecommendationResult(
          mealIds: testMealIds,
          isPersonalized: true,
          computedAt: testDate,
        );

        final roundtripped =
            RecommendationDocument.fromDomain(original).toDomain();

        expect(roundtripped.mealIds, original.mealIds);
        expect(roundtripped.isPersonalized, original.isPersonalized);
        expect(roundtripped.computedAt, original.computedAt);
      });
    });

    group('equality', () {
      test('two documents with same fields are equal', () {
        final a = RecommendationDocument(
          mealIds: testMealIds,
          isPersonalized: true,
          computedAt: testDate,
        );
        final b = RecommendationDocument(
          mealIds: List<String>.from(testMealIds),
          isPersonalized: true,
          computedAt: testDate,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('documents with different mealIds are not equal', () {
        final a = RecommendationDocument(
          mealIds: ['meal_1'],
          isPersonalized: true,
          computedAt: testDate,
        );
        final b = RecommendationDocument(
          mealIds: ['meal_2'],
          isPersonalized: true,
          computedAt: testDate,
        );

        expect(a, isNot(equals(b)));
      });
    });
  });
}
