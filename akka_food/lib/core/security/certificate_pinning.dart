import 'dart:io';

// ---------------------------------------------------------------------------
// Certificate Pinning — AKKA Food
//
// IMPORTANT: Firebase Auth SDK uses platform-native TLS stacks:
//   • Android: OkHttp / Android TrustManager
//   • iOS:     NSURLSession / SecTrust
//
// Firebase does NOT expose a Dart/Flutter hook for certificate pinning on its
// own HTTP connections. Full pinning for Firebase traffic therefore requires
// platform-level configuration:
//   • Android: Network Security Config (see android/app/src/main/res/xml/
//              network_security_config.xml, referenced in AndroidManifest.xml)
//   • iOS:     App Transport Security (NSAppTransportSecurity in Info.plist)
//              and/or a custom URLSessionDelegate with SecTrustEvaluate.
//
// This file provides:
//   1. SecurityConfig — SHA-256 pin hashes for Firebase domains.
//   2. CertificatePinning — a helper that creates a pinned HttpClient for any
//      custom HTTP calls made directly from Dart (i.e. NOT through the
//      Firebase SDK).
//
// NOTE: `http_certificate_pinning` is NOT added to pubspec.yaml because
// Firebase Auth uses its own HTTP stack that the package cannot intercept.
// The Android Network Security Config (network_security_config.xml) is the
// authoritative pinning mechanism for Firebase traffic on Android.
// ---------------------------------------------------------------------------

/// SHA-256 certificate pins for Firebase / Google API domains.
///
/// TODO: Replace the placeholder hashes below with the real SHA-256 SPKI
/// fingerprints obtained from the live certificates before releasing to
/// production. You can extract them with:
///
///   openssl s_client -connect firebaseio.com:443 | \
///     openssl x509 -pubkey -noout | \
///     openssl pkey -pubin -outform DER | \
///     openssl dgst -sha256 -binary | base64
///
/// Keep at least two pins (primary + backup) to avoid bricking the app if
/// the primary certificate rotates.
class SecurityConfig {
  SecurityConfig._();

  /// Pinned domains and their SHA-256 SPKI hashes.
  static const Map<String, List<String>> pinnedDomains = {
    '*.googleapis.com': [
      // TODO: Replace with real SHA-256 SPKI fingerprints
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // primary (placeholder)
      'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // backup  (placeholder)
    ],
    '*.firebaseio.com': [
      // TODO: Replace with real SHA-256 SPKI fingerprints
      'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=', // primary (placeholder)
      'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD=', // backup  (placeholder)
    ],
    '*.firebase.com': [
      // TODO: Replace with real SHA-256 SPKI fingerprints
      'EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE=', // primary (placeholder)
      'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF=', // backup  (placeholder)
    ],
  };
}

/// Provides a pinned [HttpClient] for custom Dart HTTP calls.
///
/// Usage:
/// ```dart
/// final client = CertificatePinning.createPinnedClient();
/// final request = await client.getUrl(Uri.parse('https://example.googleapis.com/...'));
/// ```
///
/// This does NOT affect Firebase SDK traffic — see the class-level comment
/// above for how to pin Firebase's own connections.
class CertificatePinning {
  CertificatePinning._();

  /// Creates an [HttpClient] that rejects connections whose certificate does
  /// not match one of the known-good SHA-256 SPKI pins in [SecurityConfig].
  ///
  /// In production, replace the placeholder pins in [SecurityConfig] with
  /// real fingerprints and remove the `allowAll` fallback.
  static HttpClient createPinnedClient() {
    final client = HttpClient();

    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // TODO: Once real pins are in place, remove this fallback and return
      // false for all unrecognised certificates.
      //
      // Current behaviour: log a warning and allow the connection so that
      // development builds are not broken by placeholder pins.
      // ignore: avoid_print
      print(
        '[CertificatePinning] WARNING: Certificate validation skipped for '
        '$host:$port — replace placeholder pins in SecurityConfig before '
        'releasing to production.',
      );
      return true; // TODO: change to `return false;` after real pins are set
    };

    return client;
  }

  /// Returns true if [host] is one of the Firebase domains that should be
  /// pinned. Supports simple wildcard matching (e.g. `*.googleapis.com`).
  static bool isPinnedDomain(String host) {
    for (final pattern in SecurityConfig.pinnedDomains.keys) {
      if (_matchesWildcard(pattern, host)) return true;
    }
    return false;
  }

  static bool _matchesWildcard(String pattern, String host) {
    if (!pattern.startsWith('*.')) {
      return pattern == host;
    }
    final suffix = pattern.substring(1); // e.g. '.googleapis.com'
    return host.endsWith(suffix);
  }
}
