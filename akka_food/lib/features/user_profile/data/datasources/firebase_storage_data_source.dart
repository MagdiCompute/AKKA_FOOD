import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Validates avatar image files before upload.
///
/// Extracted into a standalone class so it can be unit-tested without
/// requiring a live [FirebaseStorage] instance.
///
/// Rules:
/// - File size must not exceed 5 MB.
/// - File format must be JPEG or PNG (detected via magic bytes, not extension).
class AvatarFileValidator {
  const AvatarFileValidator();

  /// Maximum allowed avatar file size: 5 MB.
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  // JPEG magic bytes: FF D8 FF
  static const List<int> _jpegMagic = [0xFF, 0xD8, 0xFF];

  // PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
  static const List<int> _pngMagic = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  ];

  /// Validates [file] against size and format rules.
  ///
  /// Throws [AvatarFileTooLargeException] if the file exceeds 5 MB.
  /// Throws [AvatarUnsupportedFormatException] if the file is not JPEG or PNG.
  Future<void> validate(File file) async {
    final sizeBytes = await file.length();
    if (sizeBytes > maxFileSizeBytes) {
      throw AvatarFileTooLargeException(
        'Avatar file size ${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB '
        'exceeds the maximum allowed size of 5 MB.',
      );
    }

    final header = await _readFileHeader(file, 8);
    if (!_isJpeg(header) && !_isPng(header)) {
      throw AvatarUnsupportedFormatException(
        'Avatar file format is not supported. '
        'Only JPEG and PNG files are accepted.',
      );
    }
  }

  /// Reads the first [byteCount] bytes of [file] for magic-byte detection.
  Future<List<int>> _readFileHeader(File file, int byteCount) async {
    final sizeBytes = await file.length();
    if (sizeBytes == 0) return [];

    final raf = await file.open();
    try {
      final count = sizeBytes < byteCount ? sizeBytes.toInt() : byteCount;
      final buffer = List<int>.filled(count, 0);
      await raf.readInto(buffer);
      return buffer;
    } finally {
      await raf.close();
    }
  }

  /// Returns `true` if [header] starts with the JPEG magic bytes.
  bool _isJpeg(List<int> header) {
    if (header.length < _jpegMagic.length) return false;
    for (var i = 0; i < _jpegMagic.length; i++) {
      if (header[i] != _jpegMagic[i]) return false;
    }
    return true;
  }

  /// Returns `true` if [header] starts with the PNG magic bytes.
  bool _isPng(List<int> header) {
    if (header.length < _pngMagic.length) return false;
    for (var i = 0; i < _pngMagic.length; i++) {
      if (header[i] != _pngMagic[i]) return false;
    }
    return true;
  }
}

/// Handles all Firebase Storage operations for the user profile feature.
///
/// Responsibilities:
/// - Upload avatar images to `/avatars/{uid}/{timestamp}.jpg`
/// - Return the publicly accessible download URL after upload
/// - Delete old avatar files from Storage (cleanup of orphaned files)
///
/// Validation is delegated to [AvatarFileValidator] and runs before any
/// network call is made.
///
/// Accepts optional [FirebaseStorage] and [AvatarFileValidator] instances
/// for testability; defaults to production singletons.
class FirebaseStorageDataSource {
  FirebaseStorageDataSource({
    FirebaseStorage? storage,
    AvatarFileValidator? validator,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _validator = validator ?? const AvatarFileValidator();

  final FirebaseStorage _storage;
  final AvatarFileValidator _validator;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Validates [imageFile], uploads it to `/avatars/{uid}/{timestamp}.jpg`,
  /// and returns the publicly accessible download URL.
  ///
  /// Throws [AvatarFileTooLargeException] if the file exceeds 5 MB.
  /// Throws [AvatarUnsupportedFormatException] if the file is not JPEG or PNG.
  /// Throws [FirebaseException] on Storage errors.
  Future<String> uploadAvatar(String uid, File imageFile) async {
    await _validator.validate(imageFile);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'avatars/$uid/$timestamp.jpg';

    final ref = _storage.ref(storagePath);

    await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return ref.getDownloadURL();
  }

  /// Deletes the avatar file identified by [avatarUrl] from Firebase Storage.
  ///
  /// [avatarUrl] must be a valid Firebase Storage download URL. If the file
  /// does not exist, the error is silently ignored (idempotent delete).
  ///
  /// Throws [FirebaseException] on other Storage errors.
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      final ref = _storage.refFromURL(avatarUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      // object-not-found means the file is already gone — treat as success.
      if (e.code == 'object-not-found') return;
      rethrow;
    }
  }
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

/// Thrown when an avatar file exceeds the maximum allowed size (5 MB).
class AvatarFileTooLargeException implements Exception {
  const AvatarFileTooLargeException(this.message);

  final String message;

  @override
  String toString() => 'AvatarFileTooLargeException: $message';
}

/// Thrown when an avatar file is not in a supported format (JPEG or PNG).
class AvatarUnsupportedFormatException implements Exception {
  const AvatarUnsupportedFormatException(this.message);

  final String message;

  @override
  String toString() => 'AvatarUnsupportedFormatException: $message';
}
