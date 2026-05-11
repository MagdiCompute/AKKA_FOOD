import 'package:firebase_auth/firebase_auth.dart';

/// Maps a Firebase Auth error (or any other error) to a user-friendly string.
///
/// All [FirebaseAuthException] codes are mapped to human-readable messages.
/// Unknown Firebase codes fall back to [FirebaseAuthException.message].
/// Non-Firebase errors return a generic fallback message.
String mapAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'wrong-password':
        return 'Incorrect credentials.';
      case 'user-not-found':
        return 'Incorrect credentials.';
      case 'too-many-requests':
        return 'Account locked. Try again in 15 minutes.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'weak-password':
        return 'Password must be at least 8 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email.';
      case 'sign-in-cancelled':
        return 'Sign-in was cancelled.';
      case 'no-current-user':
        return 'Session expired. Please sign in again.';
      default:
        return error.message ?? 'An error occurred.';
    }
  }

  return 'An unexpected error occurred.';
}
