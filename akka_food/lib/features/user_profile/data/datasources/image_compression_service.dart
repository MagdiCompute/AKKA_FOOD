import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// Compressor abstraction (for testability)
// ---------------------------------------------------------------------------

/// Abstraction over [FlutterImageCompress] so the service can be tested
/// without invoking the native codec.
abstract class ImageCompressor {
  /// Compresses the image at [inputPath] using the given settings.
  ///
  /// Returns the compressed bytes, or `null` if compression failed.
  Future<Uint8List?> compress({
    required String inputPath,
    required String outputPath,
    required int minWidth,
    required int minHeight,
    required int quality,
    required CompressFormat format,
  });
}

/// Production implementation that delegates to [FlutterImageCompress].
class FlutterImageCompressor implements ImageCompressor {
  const FlutterImageCompressor();

  @override
  Future<Uint8List?> compress({
    required String inputPath,
    required String outputPath,
    required int minWidth,
    required int minHeight,
    required int quality,
    required CompressFormat format,
  }) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      inputPath,
      outputPath,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: format,
    );
    if (result == null) return null;
    return result.readAsBytes();
  }
}

// ---------------------------------------------------------------------------
// TempDirectoryProvider abstraction (for testability)
// ---------------------------------------------------------------------------

/// Provides the path to the system's temporary directory.
///
/// Extracted so tests can supply a known directory without requiring the
/// Flutter platform channel (which needs [TestWidgetsFlutterBinding]).
abstract class TempDirectoryProvider {
  Future<String> getTempPath();
}

/// Production implementation that delegates to [getTemporaryDirectory].
class SystemTempDirectoryProvider implements TempDirectoryProvider {
  const SystemTempDirectoryProvider();

  @override
  Future<String> getTempPath() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }
}

// ---------------------------------------------------------------------------
// ImageCompressionService
// ---------------------------------------------------------------------------

/// Compresses avatar images before upload.
///
/// Compression settings (per design spec):
/// - Maximum dimensions: 800 × 800 px (aspect ratio preserved by the codec)
/// - Format: JPEG
/// - Quality: 85
///
/// The compressed image is written to a temporary file. The caller is
/// responsible for deleting the file after use.
///
/// Accepts optional [ImageCompressor] and [TempDirectoryProvider] dependencies
/// for testability; defaults to the production implementations.
class ImageCompressionService {
  ImageCompressionService({
    ImageCompressor? compressor,
    TempDirectoryProvider? tempDirectoryProvider,
  })  : _compressor = compressor ?? const FlutterImageCompressor(),
        _tempDirectoryProvider =
            tempDirectoryProvider ?? const SystemTempDirectoryProvider();

  final ImageCompressor _compressor;
  final TempDirectoryProvider _tempDirectoryProvider;

  /// Maximum width / height in pixels after compression.
  static const int maxDimension = 800;

  /// JPEG quality (0–100) used during compression.
  static const int jpegQuality = 85;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Compresses [imageFile] and returns a new temporary [File] containing
  /// the compressed JPEG bytes.
  ///
  /// The returned file is located in the system's temporary directory and
  /// should be deleted by the caller once it is no longer needed.
  ///
  /// Throws [ImageCompressionException] if the native compressor returns
  /// `null` (e.g., unsupported input format or native error).
  Future<File> compressAvatar(File imageFile) async {
    final outputPath = await _buildOutputPath(imageFile);

    final compressedBytes = await _compressor.compress(
      inputPath: imageFile.absolute.path,
      outputPath: outputPath,
      minWidth: maxDimension,
      minHeight: maxDimension,
      quality: jpegQuality,
      format: CompressFormat.jpeg,
    );

    if (compressedBytes == null) {
      throw ImageCompressionException(
        'Compression returned null for file: ${imageFile.path}. '
        'The file may be corrupt or in an unsupported format.',
      );
    }

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(compressedBytes);
    return outputFile;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Builds the output path for the compressed file inside the temporary
  /// directory provided by [_tempDirectoryProvider].
  Future<String> _buildOutputPath(File sourceFile) async {
    final tmpPath = await _tempDirectoryProvider.getTempPath();
    final baseName = p.basenameWithoutExtension(sourceFile.path);
    return p.join(tmpPath, '${baseName}_compressed.jpg');
  }
}

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

/// Thrown when [ImageCompressionService.compressAvatar] fails to produce
/// compressed output.
class ImageCompressionException implements Exception {
  const ImageCompressionException(this.message);

  final String message;

  @override
  String toString() => 'ImageCompressionException: $message';
}
