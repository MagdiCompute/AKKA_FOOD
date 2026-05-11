import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/user_profile/data/datasources/firebase_storage_data_source.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a temporary file with the given [bytes] and returns it.
File _makeTempFile(String name, List<int> bytes) {
  final file = File('${Directory.systemTemp.path}/$name');
  file.writeAsBytesSync(bytes);
  return file;
}

/// JPEG magic bytes (FF D8 FF E0) followed by padding to reach [totalSize].
List<int> _jpegBytes({int totalSize = 100}) {
  final bytes = [0xFF, 0xD8, 0xFF, 0xE0];
  while (bytes.length < totalSize) {
    bytes.add(0x00);
  }
  return bytes;
}

/// PNG magic bytes (89 50 4E 47 0D 0A 1A 0A) followed by padding.
List<int> _pngBytes({int totalSize = 100}) {
  final bytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  while (bytes.length < totalSize) {
    bytes.add(0x00);
  }
  return bytes;
}

/// Returns [totalSize] bytes of arbitrary non-image data.
List<int> _unknownBytes({int totalSize = 100}) {
  return List<int>.filled(totalSize, 0x41); // 'A' repeated
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // AvatarFileValidator is a pure Dart class with no Firebase dependency.
  // It can be instantiated and tested directly without any Firebase setup.

  group('AvatarFileValidator', () {
    late AvatarFileValidator validator;

    setUp(() {
      validator = const AvatarFileValidator();
    });

    tearDown(() {
      // Clean up temp files created during tests.
      final tmpDir = Directory.systemTemp;
      for (final entity in tmpDir.listSync()) {
        if (entity is File && entity.path.contains('avatar_test_')) {
          try {
            entity.deleteSync();
          } catch (_) {
            // Ignore cleanup errors.
          }
        }
      }
    });

    // -----------------------------------------------------------------------
    // Size validation
    // -----------------------------------------------------------------------

    group('size validation', () {
      test('accepts a JPEG file exactly at the 5 MB limit', () async {
        final fiveMb = AvatarFileValidator.maxFileSizeBytes;
        final file = _makeTempFile(
          'avatar_test_5mb.jpg',
          _jpegBytes(totalSize: fiveMb),
        );

        await expectLater(validator.validate(file), completes);
      });

      test('rejects a file that exceeds 5 MB', () async {
        final overLimit = AvatarFileValidator.maxFileSizeBytes + 1;
        final file = _makeTempFile(
          'avatar_test_over5mb.jpg',
          _jpegBytes(totalSize: overLimit),
        );

        await expectLater(
          validator.validate(file),
          throwsA(isA<AvatarFileTooLargeException>()),
        );
      });

      test('error message mentions the 5 MB limit', () async {
        final overLimit = AvatarFileValidator.maxFileSizeBytes + 1;
        final file = _makeTempFile(
          'avatar_test_over5mb_msg.jpg',
          _jpegBytes(totalSize: overLimit),
        );

        try {
          await validator.validate(file);
          fail('Expected AvatarFileTooLargeException');
        } on AvatarFileTooLargeException catch (e) {
          expect(e.message, contains('5 MB'));
        }
      });

      test('accepts a small JPEG file well under the limit', () async {
        final file = _makeTempFile(
          'avatar_test_small.jpg',
          _jpegBytes(totalSize: 1024),
        );

        await expectLater(validator.validate(file), completes);
      });
    });

    // -----------------------------------------------------------------------
    // Format validation — JPEG
    // -----------------------------------------------------------------------

    group('format validation — JPEG', () {
      test('accepts a file with JPEG magic bytes', () async {
        final file = _makeTempFile('avatar_test_valid.jpg', _jpegBytes());

        await expectLater(validator.validate(file), completes);
      });

      test('rejects a file with JPEG extension but wrong magic bytes', () async {
        final file = _makeTempFile('avatar_test_fake.jpg', _unknownBytes());

        await expectLater(
          validator.validate(file),
          throwsA(isA<AvatarUnsupportedFormatException>()),
        );
      });
    });

    // -----------------------------------------------------------------------
    // Format validation — PNG
    // -----------------------------------------------------------------------

    group('format validation — PNG', () {
      test('accepts a file with PNG magic bytes', () async {
        final file = _makeTempFile('avatar_test_valid.png', _pngBytes());

        await expectLater(validator.validate(file), completes);
      });

      test('rejects a file with PNG extension but wrong magic bytes', () async {
        final file = _makeTempFile('avatar_test_fake.png', _unknownBytes());

        await expectLater(
          validator.validate(file),
          throwsA(isA<AvatarUnsupportedFormatException>()),
        );
      });
    });

    // -----------------------------------------------------------------------
    // Format validation — unsupported formats
    // -----------------------------------------------------------------------

    group('format validation — unsupported formats', () {
      test('rejects a GIF file', () async {
        // GIF magic: 47 49 46 38
        final gifBytes = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x00, 0x00];
        final file = _makeTempFile('avatar_test_gif.gif', gifBytes);

        await expectLater(
          validator.validate(file),
          throwsA(isA<AvatarUnsupportedFormatException>()),
        );
      });

      test('rejects a WebP file', () async {
        // WebP starts with RIFF header: 52 49 46 46
        final webpBytes = [
          0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00,
        ];
        final file = _makeTempFile('avatar_test_webp.webp', webpBytes);

        await expectLater(
          validator.validate(file),
          throwsA(isA<AvatarUnsupportedFormatException>()),
        );
      });

      test('rejects an empty file', () async {
        final file = _makeTempFile('avatar_test_empty.jpg', []);

        await expectLater(
          validator.validate(file),
          throwsA(isA<AvatarUnsupportedFormatException>()),
        );
      });

      test('error message mentions JPEG and PNG', () async {
        final file = _makeTempFile(
          'avatar_test_unknown_msg.bin',
          _unknownBytes(),
        );

        try {
          await validator.validate(file);
          fail('Expected AvatarUnsupportedFormatException');
        } on AvatarUnsupportedFormatException catch (e) {
          expect(e.message, contains('JPEG'));
          expect(e.message, contains('PNG'));
        }
      });
    });

    // -----------------------------------------------------------------------
    // Size checked before format
    // -----------------------------------------------------------------------

    test('size error takes precedence over format error', () async {
      // A file that is both too large AND has unknown format.
      final overLimit = AvatarFileValidator.maxFileSizeBytes + 1;
      final file = _makeTempFile(
        'avatar_test_toolarge_unknown.bin',
        _unknownBytes(totalSize: overLimit),
      );

      await expectLater(
        validator.validate(file),
        throwsA(isA<AvatarFileTooLargeException>()),
      );
    });
  });

  // -----------------------------------------------------------------------
  // Exception types
  // -----------------------------------------------------------------------

  group('exception types', () {
    test('AvatarFileTooLargeException toString includes class name', () {
      const e = AvatarFileTooLargeException('file too big');
      expect(e.toString(), contains('AvatarFileTooLargeException'));
      expect(e.toString(), contains('file too big'));
    });

    test('AvatarUnsupportedFormatException toString includes class name', () {
      const e = AvatarUnsupportedFormatException('bad format');
      expect(e.toString(), contains('AvatarUnsupportedFormatException'));
      expect(e.toString(), contains('bad format'));
    });
  });
}
