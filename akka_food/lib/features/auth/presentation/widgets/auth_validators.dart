// Form validator functions for auth screens.
//
// All functions return `null` when the value is valid, or a non-null error
// string when validation fails. This matches the signature expected by
// Flutter's [FormField.validator] callback.
//
// Pure Dart — no Flutter widget imports required.

// ---------------------------------------------------------------------------
// Email
// ---------------------------------------------------------------------------

/// Validates that [value] is a non-empty, well-formed email address.
///
/// Uses a basic RFC-5322-inspired regex that covers the vast majority of
/// real-world addresses without being overly strict.
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email address is required.';
  }
  // Basic email pattern: local@domain.tld
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Please enter a valid email address.';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Password
// ---------------------------------------------------------------------------

/// Validates that [value] meets the password complexity requirements.
///
/// Rules (Requirement 1.3 and 1.4):
/// - Minimum 8 characters.
/// - At least one uppercase letter (A–Z).
/// - At least one lowercase letter (a–z).
/// - At least one digit (0–9).
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required.';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters.';
  }
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Password must contain at least one uppercase letter.';
  }
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return 'Password must contain at least one lowercase letter.';
  }
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'Password must contain at least one digit.';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Phone number
// ---------------------------------------------------------------------------

/// Validates that [value] is a phone number in E.164 format.
///
/// E.164 format: `+` followed by 7–15 digits (country code + subscriber
/// number), e.g. `+22670000000`.
///
/// Satisfies Requirement 2.1.
String? validatePhoneNumber(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Phone number is required.';
  }
  // E.164: + then 7 to 15 digits
  final e164Regex = RegExp(r'^\+[1-9]\d{6,14}$');
  if (!e164Regex.hasMatch(value.trim())) {
    return 'Enter a valid phone number in E.164 format (e.g. +22670000000).';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Display name
// ---------------------------------------------------------------------------

/// Validates that [value] is a non-empty display name of at least 2 characters.
String? validateDisplayName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Display name is required.';
  }
  if (value.trim().length < 2) {
    return 'Display name must be at least 2 characters.';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Confirm password
// ---------------------------------------------------------------------------

/// Validates that [value] matches [password].
///
/// Both [value] and [password] must be non-null and identical.
String? validateConfirmPassword(String? value, String? password) {
  if (value == null || value.isEmpty) {
    return 'Please confirm your password.';
  }
  if (value != password) {
    return 'Passwords do not match.';
  }
  return null;
}
