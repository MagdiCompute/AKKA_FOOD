import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Service responsible for uploading and deleting meal images in Firebase Storage.
///
/// Images are stored at: `meals/{mealId}/{timestamp}_{filename}`
class MealImageUploadService {
  MealImageUploadService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Reads [imageFile] bytes and creates an [UploadTask] to Firebase Storage.
  ///
  /// The storage path is `meals/{mealId}/{timestamp}_{filename}`.
  /// Returns the [UploadTask] so callers can observe progress via
  /// [UploadTask.snapshotEvents] and retrieve the download URL on completion.
  Future<UploadTask> createUploadTask(String mealId, XFile imageFile) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = imageFile.name.isNotEmpty
        ? imageFile.name
        : 'image_$timestamp.jpg';
    final storagePath = 'meals/$mealId/${timestamp}_$filename';

    final ref = _storage.ref().child(storagePath);
    final bytes = await imageFile.readAsBytes();
    return ref.putData(bytes);
  }

  /// Returns the download URL from a completed [TaskSnapshot].
  Future<String> getDownloadUrl(TaskSnapshot snapshot) {
    return snapshot.ref.getDownloadURL();
  }

  /// Deletes the image at [imageUrl] from Firebase Storage.
  ///
  /// Silently ignores errors if the file no longer exists.
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      // object-not-found is acceptable — already deleted.
      if (e.code != 'object-not-found') {
        rethrow;
      }
    }
  }
}
