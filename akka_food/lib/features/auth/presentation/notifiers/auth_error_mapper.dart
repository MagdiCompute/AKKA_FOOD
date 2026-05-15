import 'package:firebase_auth/firebase_auth.dart';

/// Maps a Firebase Auth error (or any other error) to a user-friendly
/// French string.
///
/// All [FirebaseAuthException] codes are mapped to human-readable messages.
/// Unknown Firebase codes fall back to [FirebaseAuthException.message].
/// Non-Firebase errors return a generic fallback message.
String mapAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Cet e-mail est déjà utilisé.';
      case 'wrong-password':
        return 'Identifiants incorrects.';
      case 'user-not-found':
        return 'Identifiants incorrects.';
      case 'invalid-credential':
        return 'Identifiants incorrects.';
      case 'too-many-requests':
        return 'Compte bloqué. Réessayez dans 15 minutes.';
      case 'invalid-verification-code':
        return 'Code OTP invalide. Veuillez réessayer.';
      case 'network-request-failed':
        return 'Pas de connexion internet.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'invalid-email':
        return 'Veuillez entrer une adresse e-mail valide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'operation-not-allowed':
        return 'Cette méthode de connexion n\'est pas activée.';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec cet e-mail.';
      case 'sign-in-cancelled':
        return 'Connexion annulée.';
      case 'no-current-user':
        return 'Session expirée. Veuillez vous reconnecter.';
      default:
        return error.message ?? 'Une erreur est survenue.';
    }
  }

  return 'Une erreur inattendue est survenue.';
}
