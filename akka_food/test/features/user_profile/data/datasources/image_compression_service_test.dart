import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/user_profile/data/datasources/image_compression_service.dart';

// ---------------------------------------------------------------------------
// Fake implementations
// ---------------------------------------------------------------------------

/// A fake [ImageCompressor] that records the last call's parameters and
/// returns [returnValue] as the compressed bytes.
class _FakeCompressor implements ImageCompressor {
  _FakeCompressor({required this.returnValue});

  final Uint8List? returnValue;

  // Captured call parameters
  String? capturedInputPath;
  String? capturedOutputPath;
  int? capturedMinWidth;
  int? capturedMinHeight;
  int? capturedQuality;
  CompressFormat? capturedFormat;

  @override
  Future<Uint8List?> compress({
    required String inputPath,
    required String outputPath,
    required int minWidth,
    required int minHeight,
    required int quality,
    required CompressFormat format,
  }) async {
    capturedInputPath = inputPath;
    capturedOutputPath = outputPath;
    capturedMinWidth = minWidth;
    capturedMinHeight = minHeight;
    capturedQuality = quality;
    capturedFormat = format;
    return returnValue;
  }
}

/// A fake [TempDirectoryProvider] that returns the system temp directory
/// without going through the Flutter platform channel.
class _FakeTempDirectoryProvider implements TempDirectoryProvider {
  _FakeTempDirectoryProvider(this._path);

  final String _path;

  @override
  Future<String> getTempPath() async => _path;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a temporary file with the given [bytes] and returns it.
File _makeTempFile(String name, List<int> bytes) {
  final file = File('${Directory.systemTemp.path}/$name');
  file.writeAsBytesSync(bytes);
  return file;
}

/// Minimal JPEG bytes (magic header + padding).
Uint8List _jpegBytes({int totalSize = 64}) {
  final bytes = Uint8List(totalSize);
  bytes[0] = 0xFF;
  bytes[1] = 0xD8;
  bytes[2] = 0xFF;
  bytes[3] = 0xE0;
  return bytes;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Use the system temp path directly — no platform channel needed.
  final tempPath = Directory.systemTemp.path;

  group('ImageCompressionService', () {
    late File sourceFile;

    setUp(() {
      sourceFile = _makeTempFile('compress_test_source.jpg', _jpegBytes());
    });

    tearDown(() {
      // Clean up temp files created during tests.
      final tmpDir = Directory.systemTemp;
      for (final entity in tmpDir.listSync()) {
        if (entity is File &&
            (entity.path.contains('compress_test_') ||
                entity.path.contains('_compressed.jpg'))) {
          try {
            entity.deleteSync();
          } catch (_) {
            // Ignore cleanup errors.
          }
        }
      }
    });

    /// Builds a service with fake dependencies for unit testing.
    ImageCompressionService _makeService({required Uint8List? compressedBytes}) {
      return ImageCompressionService(
        compressor: _FakeCompressor(returnValue: compressedBytes),
        tempDirectoryProvider: _FakeTempDirectoryProvider(tempPath),
      );
    }

    // -----------------------------------------------------------------------
    // Compression settings forwarded to the compressor
    // -----------------------------------------------------------------------

    group('compression settings', () {
      test('passes maxDimension (800) as both minWidth and minHeight', () async {
        final compressor = _FakeCompressor(returnValue: _jpegBytes());
        final service = ImageCompressionService(
          compressor: compressor,
          tempDirectoryProvider: _FakeTempDirectoryProvider(tempPath),
        );

        await service.compressAvatar(sourceFile);

        expect(compressor.capturedMinWidth, equals(800));
        expect(compressor.capturedMinHeight, equals(800));
      });

      test('passes JPEG quality 85', () async {
        final compressor = _FakeCompressor(returnValue: _jpegBytes());
        final service = ImageCompressionService(
          compressor: compressor,
          tempDirectoryProvider: _FakeTempDirectoryProvider(tempPath),
        );

        await service.compressAvatar(sourceFile);

        expect(compressor.capturedQuality, equals(85));
      });

      test('passes CompressFormat.jpeg as the output format', () async {
        final compressor = _FakeCompressor(returnValue: _jpegBytes());
        final service = ImageCompressionService(
          compressor: compressor,
          tempDirectoryProvider: _FakeTempDirectoryProvider(tempPath),
        );

        await service.compressAvatar(sourceFile);

        expect(compressor.capturedFormat, equals(CompressFormat.jpeg));
      });

      test('passes the absolute path of the source file as inputPath',
          () async {
        final compressor = _FakeCompressor(returnValue: _jpegBytes());
        final service = ImageCompressionService(
          compressor: compressor,
          tempDirectoryProvider: _FakeTempDirectoryProvider(tempPath),
        );

        await service.compressAvatar(sourceFile);

        expect(
          compressor.capturedInputPath,
          equals(sourceFile.absolute.path),
        );
      });
    });

    // -----------------------------------------------------------------------
    // Output file
    // -----------------------------------------------------------------------

    group('output file', () {
      test('returns a File containing the compressed bytes', () async {
        final fakeBytes = _jpegBytes(totalSize: 128);
        final service = _makeService(compressedBytes: fakeBytes);

        final result = await service.compressAvatar(sourceFile);

        expect(result, isA<File>());
        expect(await result.readAsBytes(), equals(fakeBytes));
      });

      test('output file path ends with _compressed.jpg', () async {
        final service = _makeService(compressedBytes: _jpegBytes());

        final result = await service.compressAvatar(sourceFile);

        expect(result.path, endsWith('_compressed.jpg'));
      });

      test('output file is placed in the temporary directory', () async {
        final service = _makeService(compressedBytes: _jpegBytes());

        final result = await service.compressAvatar(sourceFile);

        expect(result.path, startsWith(tempPath));
      });

      test('output path passed to compressor matches the returned file path',
          () async {
        final compressor = _FakeCompressor(returnValue: _jpegBytes());
        final service = ImageCompressionService(
          compressor: compressor,
          tempDirectoryProvider: _FakeTempDirectoryProvider(tempPath),
        );

        final result = await service.compressAvatar(sourceFile);

        expect(compressor.capturedOutputPath, equals(result.path));
      });
    });

    // -----------------------------------------------------------------------
    // Error handling
    // -----------------------------------------------------------------------

    group('error handling', () {
      test('throws ImageCompressionException when compressor returns null',
          () async {
        final service = _makeService(compressedBytes: null);

        await expectLater(
          service.compressAvatar(sourceFile),
          throwsA(isA<ImageCompressionException>()),
        );
      });

      test('exception message mentions the source file path', () async {
        final service = _makeService(compressedBytes: null);

        try {
          await service.compressAvatar(sourceFile);
          fail('Expected ImageCompressionException');
        } on ImageCompressionException catch (e) {
          expect(e.message, contains(sourceFile.path));
        }
      });
    });

    // -----------------------------------------------------------------------
    // Static constants
    // -----------------------------------------------------------------------

    group('static constants', () {
      test('maxDimension is 800', () {
        expect(ImageCompressionService.maxDimension, equals(800));
      });

      test('jpegQuality is 85', () {
        expect(ImageCompressionService.jpegQuality, equals(85));
      });
    });
  });

  // -----------------------------------------------------------------------
  // Exception type
  // -----------------------------------------------------------------------

  group('ImageCompressionException', () {
    test('toString includes class name and message', () {
      const e = ImageCompressionException('native codec failed');
      expect(e.toString(), contains('ImageCompressionException'));
      expect(e.toString(), contains('native codec failed'));
    });
  });
}
