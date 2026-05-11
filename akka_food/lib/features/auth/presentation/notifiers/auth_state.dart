import '../../domain/entities/app_user.dart';
import '../../domain/entities/otp_request.dart';

/// Represents the current authentication status.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  unverified,
  error,
}

/// Immutable state object held by [AuthNotifier].
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implements [copyWith], [==], [hashCode], and [toString] manually
/// per project conventions (same pattern as [AppUser]).
class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  /// Holds the pending [OtpRequest] during the phone OTP flow so the UI
  /// knows to show the OTP verification screen.
  final OtpRequest? pendingOtpRequest;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.pendingOtpRequest,
  });

  // ---------------------------------------------------------------------------
  // Named constructors for convenience
  // ---------------------------------------------------------------------------

  const AuthState.initial() : this(status: AuthStatus.initial);

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated(AppUser user)
      : this(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.unverified(AppUser user)
      : this(status: AuthStatus.unverified, user: user);

  const AuthState.error(String message)
      : this(status: AuthStatus.error, errorMessage: message);

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  AuthState copyWith({
    AuthStatus? status,
    Object? user = _sentinel,
    Object? errorMessage = _sentinel,
    Object? pendingOtpRequest = _sentinel,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user == _sentinel ? this.user : user as AppUser?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      pendingOtpRequest: pendingOtpRequest == _sentinel
          ? this.pendingOtpRequest
          : pendingOtpRequest as OtpRequest?,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & hashing
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AuthState) return false;
    if (status != other.status) return false;
    if (user != other.user) return false;
    if (errorMessage != other.errorMessage) return false;
    if (pendingOtpRequest != other.pendingOtpRequest) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        status,
        user,
        errorMessage,
        pendingOtpRequest,
      );

  // ---------------------------------------------------------------------------
  // toString
  // ---------------------------------------------------------------------------

  @override
  String toString() {
    return 'AuthState('
        'status: $status, '
        'user: $user, '
        'errorMessage: $errorMessage, '
        'pendingOtpRequest: $pendingOtpRequest'
        ')';
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Sentinel object used by [AuthState.copyWith] to distinguish between
/// "caller passed null explicitly" and "caller omitted the argument".
const Object _sentinel = Object();
