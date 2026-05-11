import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/recommendation_result.dart';
import '../recommendation_document.dart';
import '../repositories/recommendation_repository_impl.dart';

/// Data source that reads cached recommendations from Firestore.
///
/// Reads the `/recommendations/{uid}` document and checks whether the cached
/// result is still fresh (within the 60-minute TTL). If fresh, returns the
/// deserialized [RecommendationResult]; otherwise returns `null` to signal
/// that the Cloud Function should be called for fresh data.
///
/// Accepts a [FirebaseFirestore] instance for testability.
class FirestoreRecommendationCache implements IRecommendationCache {
  FirestoreRecommendationCache({
    required FirebaseFirestore firestore,
    DateTime Function()? clock,
  })  : _firestore = firestore,
        _clock = clock ?? DateTime.now;

  final FirebaseFirestore _firestore;

  /// Injectable clock for testability. Defaults to [DateTime.now].
  final DateTime Function() _clock;

  /// TTL duration for cached recommendations (60 minutes).
  static const cacheTtl = Duration(minutes: 60);

  /// Fetches cached recommendations for the given [uid].
  ///
  /// Returns a [RecommendationResult] if the document exists and was computed
  /// within the last 60 minutes. Returns `null` if:
  /// - The document does not exist.
  /// - The document data is null.
  /// - The `computedAt` timestamp is older than 60 minutes (stale).
  @override
  Future<RecommendationResult?> getCachedRecommendations(String uid) async {
    final docRef = _firestore.collection('recommendations').doc(uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) return null;

    final document = RecommendationDocument.fromMap(data);

    final now = _clock();
    final age = now.difference(document.computedAt);

    if (age >= cacheTtl) return null;

    return document.toDomain();
  }
}
