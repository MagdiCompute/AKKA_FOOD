import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Service for uploading meal images to Firebase Storage.
///
/// Storage path: `/meals/{mealId}/{index}.jpg`
///
/// Satisfies Requirement 7.4 — image upload to Firebase Storage.
class MealImageUploadService {
  MealImageUploadService([FirebaseStorage? storage])
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads [imageFile] to `/meals/{mealId}/{index}.jpg` and returns the
  /// download URL.
  ///
  /// Uses `flutter_image_compress` to compress the image before upload
  /// (quality 85, max 1080px wide). Falls back to uploading the raw file if
  /// compression returns null.
  Future<String> uploadMealImage({
    required String mealId,
    required int index,
    required XFile imageFile,
  }) async {
    // Compress image before upload.
    final bytes = await FlutterImageCompress.compressWithFile(
      imageFile.path,
      quality: 85,
      minWidth: 1080,
      minHeight: 1080,
    );

    final ref = _storage.ref('meals/$mealId/$index.jpg');
    final SettableMetadata metadata =
        SettableMetadata(contentType: 'image/jpeg');

    final UploadTask uploadTask = bytes != null
        ? ref.putData(bytes, metadata)
        : ref.putFile(File(imageFile.path), metadata);

    final TaskSnapshot snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  /// Uploads multiple images for a meal and returns their download URLs in
  /// order.
  ///
  /// [startIndex] allows appending images to an existing set — pass
  /// `existingUrls.length` so new images are indexed after the existing ones.
  Future<List<String>> uploadMealImages({
    required String mealId,
    required List<XFile> images,
    int startIndex = 0,
  }) async {
    final urls = <String>[];
    for (int i = 0; i < images.length; i++) {
      final url = await uploadMealImage(
        mealId: mealId,
        index: startIndex + i,
        imageFile: images[i],
      );
      urls.add(url);
    }
    return urls;
  }

  /// Deletes a meal image identified by its [downloadUrl].
  ///
  /// Errors are silently swallowed — the file may have already been deleted or
  /// the URL may be invalid.
  Future<void> deleteMealImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {
      // Ignore deletion errors (file may not exist).
    }
  }
}
