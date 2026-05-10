# Requirements Document

## Introduction

This document defines the requirements for the **User Authentication** feature of AKKA Food, a Flutter-based mobile e-restaurant application. The authentication system enables users to create accounts, sign in securely, manage their sessions, recover access to their accounts, and verify their identity. It serves as the foundation for all personalized features including cart management, order history, coin rewards, leaderboard participation, and delivery preferences.

## Glossary

- **User**: A person who installs and uses the AKKA Food mobile application.
- **Auth_Service**: The backend service responsible for handling authentication logic, token issuance, and session management.
- **Token_Store**: The secure local storage on the device used to persist authentication tokens (e.g., Flutter Secure Storage).
- **Access_Token**: A short-lived JWT issued by the Auth_Service upon successful authentication, used to authorize API requests.
- **Refresh_Token**: A long-lived token issued alongside the Access_Token, used to obtain new Access_Tokens without re-authentication.
- **Credential**: A combination of identifier (email or phone number) and secret (password) used to authenticate a User.
- **OTP**: A one-time password sent via SMS or email used for account verification or password reset.
- **Social_Provider**: A third-party identity provider (Google or Facebook) used for federated authentication.
- **Session**: An authenticated state on the device, represented by a valid Access_Token and Refresh_Token pair.
- **Profile_Service**: The backend service responsible for managing user profile data linked to an authenticated account.
- **Admin**: A privileged user who accesses the AKKA Food admin dashboard; admin authentication is out of scope for this document.

---

## Requirements

### Requirement 1: User Registration with Email and Password

**User Story:** As a new user, I want to create an account with my email address and a password, so that I can access personalized features of AKKA Food.

#### Acceptance Criteria

1. THE Auth_Service SHALL accept a registration request containing a valid email address, a password, and a display name.
2. WHEN a registration request is received with an email address already associated with an existing account, THE Auth_Service SHALL return an error indicating the email is already in use.
3. WHEN a registration request is received with a password shorter than 8 characters, THE Auth_Service SHALL return a validation error specifying the minimum length requirement.
4. WHEN a registration request is received with a password that does not contain at least one uppercase letter, one lowercase letter, and one digit, THE Auth_Service SHALL return a validation error describing the unmet criteria.
5. WHEN a valid registration request is received, THE Auth_Service SHALL create a new user account and send a verification OTP to the provided email address within 30 seconds.
6. WHEN a valid registration request is received, THE Auth_Service SHALL return an unverified Access_Token and Refresh_Token so the User can navigate the app while verification is pending.
7. THE Auth_Service SHALL store passwords as salted cryptographic hashes using bcrypt with a minimum cost factor of 12; THE Auth_Service SHALL NOT store plaintext passwords.

---

### Requirement 2: User Registration with Phone Number

**User Story:** As a new user, I want to register using my phone number, so that I can create an account without an email address.

#### Acceptance Criteria

1. THE Auth_Service SHALL accept a registration request containing a valid phone number in E.164 format, a password, and a display name.
2. WHEN a registration request is received with a phone number already associated with an existing account, THE Auth_Service SHALL return an error indicating the phone number is already in use.
3. WHEN a valid phone registration request is received, THE Auth_Service SHALL send a 6-digit OTP to the provided phone number via SMS within 60 seconds.
4. WHEN a valid phone registration request is received, THE Auth_Service SHALL return an unverified Access_Token and Refresh_Token so the User can navigate the app while verification is pending.

---

### Requirement 3: Account Verification

**User Story:** As a newly registered user, I want to verify my account via OTP, so that AKKA Food can confirm my identity and unlock full account features.

#### Acceptance Criteria

1. WHEN a User submits a correct OTP within 10 minutes of its issuance, THE Auth_Service SHALL mark the account as verified and return a verified Access_Token.
2. WHEN a User submits an incorrect OTP, THE Auth_Service SHALL return a verification error and increment the failed attempt counter for that OTP.
3. WHEN a User submits an OTP after it has expired (older than 10 minutes), THE Auth_Service SHALL return an expiry error and invalidate the OTP.
4. WHEN a User has submitted 5 consecutive incorrect OTPs for the same verification request, THE Auth_Service SHALL invalidate the OTP and require the User to request a new one.
5. WHEN a User requests OTP resend, THE Auth_Service SHALL generate a new OTP, invalidate the previous OTP, and deliver the new OTP within the channel-specific time limit (30 seconds for email, 60 seconds for SMS).
6. WHILE an account is unverified, THE Auth_Service SHALL restrict access to order placement, coin earning, and leaderboard participation.

---

### Requirement 4: Sign-In with Email and Password

**User Story:** As a registered user, I want to sign in with my email and password, so that I can access my account and personalized features.

#### Acceptance Criteria

1. WHEN a sign-in request is received with a valid email and correct password for a verified account, THE Auth_Service SHALL return a new Access_Token and Refresh_Token.
2. WHEN a sign-in request is received with an email that does not correspond to any account, THE Auth_Service SHALL return a generic authentication error without revealing whether the email exists.
3. WHEN a sign-in request is received with a correct email but incorrect password, THE Auth_Service SHALL return a generic authentication error and increment the failed attempt counter for that account.
4. WHEN a sign-in request is received with a correct email but incorrect password for the 5th consecutive time within 15 minutes, THE Auth_Service SHALL lock the account for 15 minutes and return a lockout error indicating the remaining lockout duration.
5. WHEN a sign-in request is received for a locked account, THE Auth_Service SHALL return a lockout error indicating the remaining lockout duration.
6. WHEN a sign-in request is received with a valid email and correct password for an unverified account, THE Auth_Service SHALL return an unverified Access_Token and prompt the User to complete verification.

---

### Requirement 5: Sign-In with Phone Number and Password

**User Story:** As a registered user, I want to sign in with my phone number and password, so that I can access my account using my preferred identifier.

#### Acceptance Criteria

1. WHEN a sign-in request is received with a valid E.164 phone number and correct password for a verified account, THE Auth_Service SHALL return a new Access_Token and Refresh_Token.
2. WHEN a sign-in request is received with a phone number that does not correspond to any account, THE Auth_Service SHALL return a generic authentication error without revealing whether the phone number exists.
3. WHEN a sign-in request is received with a correct phone number but incorrect password, THE Auth_Service SHALL apply the same lockout policy defined in Requirement 4, Criteria 3 and 4.

---

### Requirement 6: Social Login (Google and Facebook)

**User Story:** As a user, I want to sign in or register using my Google or Facebook account, so that I can authenticate quickly without managing a separate password.

#### Acceptance Criteria

1. WHERE Google login is enabled, WHEN a User initiates Google sign-in, THE Auth_Service SHALL validate the Google ID token received from the Flutter app and return an Access_Token and Refresh_Token upon successful validation.
2. WHERE Facebook login is enabled, WHEN a User initiates Facebook sign-in, THE Auth_Service SHALL validate the Facebook access token received from the Flutter app and return an Access_Token and Refresh_Token upon successful validation.
3. WHEN a Social_Provider token is validated for an email address not yet registered in AKKA Food, THE Auth_Service SHALL automatically create a new verified account using the email and display name from the Social_Provider.
4. WHEN a Social_Provider token is validated for an email address already registered via email/password, THE Auth_Service SHALL link the social identity to the existing account and return a valid Session.
5. IF a Social_Provider token validation fails or is rejected by the provider, THEN THE Auth_Service SHALL return an authentication error without creating or modifying any account.
6. WHEN a social account is created, THE Auth_Service SHALL mark it as verified without requiring OTP confirmation, since the Social_Provider has already verified the identity.

---

### Requirement 7: Session Management and Token Handling

**User Story:** As a signed-in user, I want my session to be maintained securely across app restarts, so that I do not have to sign in repeatedly.

#### Acceptance Criteria

1. THE Auth_Service SHALL issue Access_Tokens with an expiry of 15 minutes and Refresh_Tokens with an expiry of 30 days.
2. WHEN the Flutter app receives an Access_Token and Refresh_Token, THE Token_Store SHALL persist both tokens in encrypted device storage.
3. WHEN an API request is made with an expired Access_Token and a valid Refresh_Token, THE Auth_Service SHALL issue a new Access_Token and a rotated Refresh_Token, and invalidate the previous Refresh_Token.
4. WHEN an API request is made with an expired Access_Token and an expired or invalid Refresh_Token, THE Auth_Service SHALL return a 401 Unauthorized response and THE Flutter app SHALL redirect the User to the sign-in screen.
5. WHEN a Refresh_Token that has already been used is presented (replay attack), THE Auth_Service SHALL invalidate the entire token family for that account and return a 401 Unauthorized response.
6. WHEN the app is launched, THE Token_Store SHALL check for a persisted valid Refresh_Token; IF a valid Refresh_Token exists, THEN THE Auth_Service SHALL silently refresh the Session without requiring the User to sign in again.
7. THE Token_Store SHALL use Flutter Secure Storage (backed by Android Keystore and iOS Keychain) to persist tokens; THE Token_Store SHALL NOT store tokens in SharedPreferences or any unencrypted storage.

---

### Requirement 8: Sign-Out

**User Story:** As a signed-in user, I want to sign out of my account, so that my session is terminated and my credentials are removed from the device.

#### Acceptance Criteria

1. WHEN a User initiates sign-out, THE Auth_Service SHALL invalidate the current Refresh_Token on the server side.
2. WHEN a User initiates sign-out, THE Token_Store SHALL delete the Access_Token and Refresh_Token from encrypted device storage.
3. WHEN sign-out is complete, THE Flutter app SHALL redirect the User to the sign-in screen and clear all in-memory user state.
4. IF the sign-out API call fails due to a network error, THEN THE Token_Store SHALL still delete the local tokens and THE Flutter app SHALL redirect the User to the sign-in screen.

---

### Requirement 9: Forgot Password and Password Reset

**User Story:** As a user who has forgotten their password, I want to reset it via a verified channel, so that I can regain access to my account.

#### Acceptance Criteria

1. WHEN a password reset request is submitted with a registered email address, THE Auth_Service SHALL send a 6-digit OTP to that email address within 30 seconds.
2. WHEN a password reset request is submitted with a registered phone number, THE Auth_Service SHALL send a 6-digit OTP to that phone number via SMS within 60 seconds.
3. WHEN a password reset request is submitted with an identifier that does not match any account, THE Auth_Service SHALL return a success-like response without revealing whether the identifier is registered.
4. WHEN a User submits a valid reset OTP and a new password that meets the complexity requirements defined in Requirement 1, THE Auth_Service SHALL update the account password and invalidate all existing Refresh_Tokens for that account.
5. WHEN a User submits a reset OTP that has expired (older than 10 minutes) or has already been used, THE Auth_Service SHALL return an error and require the User to request a new OTP.
6. WHEN a password reset is completed successfully, THE Auth_Service SHALL return a new Access_Token and Refresh_Token so the User is immediately signed in.

---

### Requirement 10: Change Password (Authenticated)

**User Story:** As a signed-in user, I want to change my password from within the app, so that I can update my credentials without going through the reset flow.

#### Acceptance Criteria

1. WHEN an authenticated User submits a change-password request with the correct current password and a new password meeting complexity requirements, THE Auth_Service SHALL update the password and invalidate all other active Refresh_Tokens for that account except the current Session.
2. WHEN an authenticated User submits a change-password request with an incorrect current password, THE Auth_Service SHALL return an authentication error.
3. WHEN an authenticated User submits a change-password request where the new password is identical to the current password, THE Auth_Service SHALL return a validation error.

---

### Requirement 11: Secure Credential Storage and Transmission

**User Story:** As a user, I want my credentials and tokens to be stored and transmitted securely, so that my account is protected against unauthorized access.

#### Acceptance Criteria

1. THE Auth_Service SHALL enforce HTTPS (TLS 1.2 or higher) for all authentication-related API endpoints; THE Auth_Service SHALL reject connections over unencrypted HTTP.
2. THE Flutter app SHALL implement certificate pinning for all requests to the Auth_Service to prevent man-in-the-middle attacks.
3. THE Token_Store SHALL encrypt all stored tokens using AES-256 encryption backed by the device's hardware security module where available.
4. THE Auth_Service SHALL NOT include password values in any server-side logs, error messages, or API responses.
5. THE Auth_Service SHALL rate-limit OTP delivery to a maximum of 5 OTP requests per phone number or email address per hour.

---

### Requirement 12: Integration with Profile Service

**User Story:** As a newly registered user, I want my profile to be automatically initialized, so that I can immediately use personalized features like coin tracking and order history.

#### Acceptance Criteria

1. WHEN a new account is successfully created (via email, phone, or social login), THE Auth_Service SHALL emit an account-created event that triggers THE Profile_Service to initialize a user profile with a coin balance of 0.
2. WHEN an Access_Token is issued, THE Auth_Service SHALL embed the user's unique account identifier in the token payload so that downstream services including THE Profile_Service can identify the User without additional lookups.
3. WHEN an account is deleted, THE Auth_Service SHALL emit an account-deleted event that triggers THE Profile_Service to anonymize or delete the associated profile data.
