import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:akka_food/features/user_profile/data/datasources/firestore_profile_data_source.dart';
import 'package:akka_food/features/user_profile/data/datasources/hive_profile_cache.dart';
import 'package:akka_food/features/user_profile/data/datasources/image_compression_service.dart';
import 'package:akka_food/features/user_profile/data/repositories/profile_repository.dart';
import 'package:akka_food/features/user_profile/domain/entities/notification_preference.dart';
import 'package:akka_food/features/user_profile/domain/entities/user_profile.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Pure-Dart fake [AvatarStorageClient] — no Firebase dependency.
class _FakeStorageClient implements AvatarStorageClient {
  /// URL returned by [uploadAvatar].
  String uploadResult = 'https://storage.example.com/avatars/uid/new.jpg';

  /// Tracks every URL passed to [deleteAvatar].
  final List<String> deletedUrls = [];

  /// When non-null, [uploadAvatar] throws this exception.
  Exception? uploadError;

  @override
  Future<String> uploadAvatar(String uid, File imageFile) async {
    if (uploadError != null) throw uploadError!;
    return uploadResult;
  }

  @override
  Future<void> deleteAvatar(String avatarUrl) async {
    deletedUrls.add(avatarUrl);
  }
}

/// Fake [ImageCompressionService] that returns a pre-built temp file without
/// invoking the native codec.
class _FakeCompressionService extends ImageCompressionService {
  _FakeCompressionService() : super();

  late File _compressedFile;

  /// Initialise with a real temp file so the repository can delete it.
  Future<void> init() async {
    _compressedFile = File(
      '${Directory.systemTemp.path}/fake_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await _compressedFile.writeAsBytes(Uint8List.fromList([0xFF, 0xD8, 0xFF]));
  }

  @override
  Future<File> compressAvatar(File imageFile) async => _compressedFile;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a [UserProfile] with sensible defaults.
UserProfile _makeProfile({
  String uid = 'user-1',
  String? avatarUrl,
}) {
  return UserProfile(
    uid: uid,
    displayName: 'Test User',
    email: 'test@example.com',
    phoneNumber: null,
    avatarUrl: avatarUrl,
    updatedAt: DateTime(2024),
  );
}

/// Creates a minimal JPEG temp file for use as the input image.
File _makeFakeInputFile() {
  final file = File(
    '${Directory.systemTemp.path}/input_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
  file.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
  return file;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreProfileDataSource firestoreDataSource;
  late _FakeStorageClient fakeStorage;
  late _FakeCompressionService fakeCompression;
  late ProfileRepository repository;
  late HiveProfileCache fakeCache;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreDataSource =
        FirestoreProfileDataSource(firestore: fakeFirestore);
    fakeStorage = _FakeStorageClient();
    fakeCompression = _FakeCompressionService();
    await fakeCompression.init();

    // Initialize Hive with a temp directory for the cache.
    final tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    fakeCache = await HiveProfileCache.open();

    repository = ProfileRepository(
      firestoreDataSource: firestoreDataSource,
      storageClient: fakeStorage,
      compressionService: fakeCompression,
      cache: fakeCache,
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  // -------------------------------------------------------------------------
  // Helpers to seed Firestore
  // -------------------------------------------------------------------------

  Future<void> _seedProfile(UserProfile profile) async {
    final data = profile.toMap()
      ..remove('uid')
      ..remove('updatedAt');
    await fakeFirestore
        .collection('users')
        .doc(profile.uid)
        .set({...data, 'updatedAt': DateTime.now().toIso8601String()});
  }

  // =========================================================================
  // getProfile
  // =========================================================================

  group('getProfile', () {
    test('returns the profile stored in Firestore', () async {
      final profile = _makeProfile(uid: 'u1', avatarUrl: null);
      await _seedProfile(profile);

      final result = await repository.getProfile('u1');

      expect(result.uid, 'u1');
      expect(result.displayName, 'Test User');
    });

    test('throws StateError when profile does not exist', () async {
      await expectLater(
        repository.getProfile('nonexistent'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // =========================================================================
  // updateProfile
  // =========================================================================

  group('updateProfile', () {
    test('persists updated display name', () async {
      final original = _makeProfile(uid: 'u2');
      await _seedProfile(original);

      final updated = original.copyWith(displayName: 'New Name');
      final result = await repository.updateProfile(updated);

      expect(result.displayName, 'New Name');

      // Verify it was written to Firestore.
      final fetched = await repository.getProfile('u2');
      expect(fetched.displayName, 'New Name');
    });
  });

  // =========================================================================
  // uploadAvatar
  // =========================================================================

  group('uploadAvatar', () {
    test('returns the new download URL', () async {
      final profile = _makeProfile(uid: 'u3', avatarUrl: null);
      await _seedProfile(profile);

      final inputFile = _makeFakeInputFile();
      addTearDown(
        () => inputFile.existsSync() ? inputFile.deleteSync() : null,
      );

      final url = await repository.uploadAvatar('u3', inputFile);

      expect(url, fakeStorage.uploadResult);
    });

    test('updates avatarUrl in Firestore after upload', () async {
      final profile = _makeProfile(uid: 'u4', avatarUrl: null);
      await _seedProfile(profile);

      final inputFile = _makeFakeInputFile();
      addTearDown(
        () => inputFile.existsSync() ? inputFile.deleteSync() : null,
      );

      await repository.uploadAvatar('u4', inputFile);

      final fetched = await repository.getProfile('u4');
      expect(fetched.avatarUrl, fakeStorage.uploadResult);
    });

    test('deletes the previous avatar URL when one exists (Requirement 3.4)',
        () async {
      const oldUrl = 'https://storage.example.com/avatars/u5/old.jpg';
      final profile = _makeProfile(uid: 'u5', avatarUrl: oldUrl);
      await _seedProfile(profile);

      final inputFile = _makeFakeInputFile();
      addTearDown(
        () => inputFile.existsSync() ? inputFile.deleteSync() : null,
      );

      await repository.uploadAvatar('u5', inputFile);

      expect(fakeStorage.deletedUrls, contains(oldUrl));
    });

    test('does NOT delete when previous avatarUrl is null', () async {
      final profile = _makeProfile(uid: 'u6', avatarUrl: null);
      await _seedProfile(profile);

      final inputFile = _makeFakeInputFile();
      addTearDown(
        () => inputFile.existsSync() ? inputFile.deleteSync() : null,
      );

      await repository.uploadAvatar('u6', inputFile);

      expect(fakeStorage.deletedUrls, isEmpty);
    });

    test('does NOT delete when previous avatarUrl is the placeholder',
        () async {
      final profile =
          _makeProfile(uid: 'u7', avatarUrl: kDefaultAvatarUrl);
      await _seedProfile(profile);

      final inputFile = _makeFakeInputFile();
      addTearDown(
        () => inputFile.existsSync() ? inputFile.deleteSync() : null,
      );

      await repository.uploadAvatar('u7', inputFile);

      expect(fakeStorage.deletedUrls, isEmpty);
    });

    test('does NOT delete when previous avatarUrl is empty string', () async {
      final profile = _makeProfile(uid: 'u8', avatarUrl: '');
      await _seedProfile(profile);

      final inputFile = _makeFakeInputFile();
      addTearDown(
        () => inputFile.existsSync() ? inputFile.deleteSync() : null,
      );

      await repository.uploadAvatar('u8', inputFile);

      expect(fakeStorage.deletedUrls, isEmpty);
    });

    test('cleans up the compressed temp file after successful upload',
        () async {
      final profile = _makeProfile(uid: 'u9', avatarUrl: null);
      await _seedProfile(profile);

      final inputFile = _makeFakeInputFile();
      addTearDown(
        () => inputFile.existsSync() ? inputFile.deleteSync() : null,
      );

      // Capture the compressed file path before upload.
      final compressedFile = await fakeCompression.compressAvatar(inputFile);
      final compressedPath = compressedFile.path;

      await repository.uploadAvatar('u9', inputFile);

      // The repository should have deleted the compressed temp file.
      expect(File(compressedPath).existsSync(), isFalse);
    });

    test('cleans up the compressed temp file even when upload throws',
        () async {
      fakeStorage.uploadError =
          Exception('Storage unavailable');

      final profile = _makeProfile(uid: 'u10', avatarUrl: null);
      await _seedProfile(profile);

      final inputFile = _makeFakeInputFile();
      addTearDown(
        () => inputFile.existsSync() ? inputFile.deleteSync() : null,
      );

      // Capture the compressed file path before upload.
      final compressedFile = await fakeCompression.compressAvatar(inputFile);
      final compressedPath = compressedFile.path;

      await expectLater(
        repository.uploadAvatar('u10', inputFile),
        throwsA(isA<Exception>()),
      );

      // Temp file must be cleaned up even on failure.
      expect(File(compressedPath).existsSync(), isFalse);
    });
  });

  // =========================================================================
  // removeAvatar
  // =========================================================================

  group('removeAvatar', () {
    test('sets avatarUrl to the default placeholder (Requirement 3.5)',
        () async {
      const oldUrl = 'https://storage.example.com/avatars/u11/photo.jpg';
      final profile = _makeProfile(uid: 'u11', avatarUrl: oldUrl);
      await _seedProfile(profile);

      await repository.removeAvatar('u11');

      final fetched = await repository.getProfile('u11');
      expect(fetched.avatarUrl, kDefaultAvatarUrl);
    });

    test('deletes the previous avatar from Storage when one exists', () async {
      const oldUrl = 'https://storage.example.com/avatars/u12/photo.jpg';
      final profile = _makeProfile(uid: 'u12', avatarUrl: oldUrl);
      await _seedProfile(profile);

      await repository.removeAvatar('u12');

      expect(fakeStorage.deletedUrls, contains(oldUrl));
    });

    test('does NOT call deleteAvatar when avatarUrl is already null', () async {
      final profile = _makeProfile(uid: 'u13', avatarUrl: null);
      await _seedProfile(profile);

      await repository.removeAvatar('u13');

      expect(fakeStorage.deletedUrls, isEmpty);
    });

    test('does NOT call deleteAvatar when avatarUrl is already the placeholder',
        () async {
      final profile =
          _makeProfile(uid: 'u14', avatarUrl: kDefaultAvatarUrl);
      await _seedProfile(profile);

      await repository.removeAvatar('u14');

      expect(fakeStorage.deletedUrls, isEmpty);
    });
  });

  // =========================================================================
  // Notification preferences (delegated to FirestoreProfileDataSource)
  // =========================================================================

  group('notification preferences', () {
    test('getNotificationPrefs returns defaults when no record exists',
        () async {
      final prefs = await repository.getNotificationPrefs('u15');

      expect(prefs.uid, 'u15');
      expect(prefs.orderUpdates, isTrue);
      expect(prefs.promotions, isTrue);
      expect(prefs.coinEvents, isTrue);
    });

    test('updateNotificationPrefs persists changes', () async {
      final prefs = NotificationPreference(
        uid: 'u16',
        orderUpdates: false,
        promotions: true,
        coinEvents: false,
      );

      await repository.updateNotificationPrefs(prefs);

      final fetched = await repository.getNotificationPrefs('u16');
      expect(fetched.orderUpdates, isFalse);
      expect(fetched.promotions, isTrue);
      expect(fetched.coinEvents, isFalse);
    });
  });
}
