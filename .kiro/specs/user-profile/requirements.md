# Requirements Document

## Introduction

This document defines the requirements for the **User Profile** feature of AKKA Food, a Flutter-based mobile e-restaurant application. The user profile system allows authenticated users to view and edit their personal information, manage delivery addresses, consult their order history, track their coin balance and transaction history, configure notification preferences, and request account deletion or deactivation. This feature integrates with the authentication system (Auth_Service), the coin rewards engine (Coin_Service), and the order management system (Order_Service).

## Glossary

- **User**: An authenticated person using the AKKA Food mobile application.
- **Profile_Service**: The backend service responsible for storing and managing user profile data, including personal information, addresses, and preferences.
- **Auth_Service**: The backend service responsible for authentication, session management, and account lifecycle events, as defined in the User Authentication spec.
- **Order_Service**: The backend service responsible for managing orders, order states, and order history.
- **Coin_Service**: The backend service responsible for computing coin balances, recording coin transactions, and processing coin redemptions.
- **Notification_Service**: The backend service responsible for delivering push notifications, SMS alerts, and email communications to users.
- **Profile**: The set of personal data associated with a User account, including display name, avatar, phone number, email address, and delivery addresses.
- **Avatar**: A profile picture uploaded by the User, stored as an image file.
- **Delivery_Address**: A named physical address associated with a User account, used as the destination for food delivery orders.
- **Default_Address**: The single Delivery_Address marked by the User as the preferred address pre-selected at checkout.
- **Coin_Balance**: The current number of coins held by a User, computed from all credited and debited coin transactions.
- **Coin_Transaction**: A record of a single coin credit or debit event, including the amount, reason, and timestamp.
- **Order_Summary**: A condensed record of a past order, including order identifier, date, item list, total amount, and final status.
- **Notification_Preference**: A User-controlled setting that enables or disables a specific category of notifications (order updates, promotions, coin events).
- **Access_Token**: A short-lived JWT issued by the Auth_Service, used to authorize requests to the Profile_Service and other backend services.

---

## Requirements

### Requirement 1: View Profile Information

**User Story:** As a signed-in user, I want to view my profile information, so that I can confirm my personal details are correct.

#### Acceptance Criteria

1. WHEN an authenticated User opens the profile screen, THE Profile_Service SHALL return the User's current display name, email address, phone number, and avatar URL.
2. WHEN an authenticated User opens the profile screen, THE Profile_Service SHALL return the response within 2 seconds under normal network conditions.
3. IF the Profile_Service is unreachable, THEN THE Flutter app SHALL display the last successfully fetched profile data from local cache and show a connectivity warning.
4. THE Profile_Service SHALL only return profile data to requests bearing a valid Access_Token whose embedded user identifier matches the requested profile.

---

### Requirement 2: Edit Profile Information

**User Story:** As a signed-in user, I want to edit my display name, phone number, and email address, so that my profile stays up to date.

#### Acceptance Criteria

1. WHEN an authenticated User submits a profile update with a new display name containing between 2 and 50 characters, THE Profile_Service SHALL persist the updated display name and return the updated Profile.
2. WHEN an authenticated User submits a profile update with a display name shorter than 2 characters or longer than 50 characters, THE Profile_Service SHALL return a validation error specifying the length constraint.
3. WHEN an authenticated User submits a profile update with a new email address, THE Auth_Service SHALL send a verification OTP to the new email address before THE Profile_Service persists the change.
4. WHEN an authenticated User submits a profile update with a new phone number in E.164 format, THE Auth_Service SHALL send a verification OTP to the new phone number via SMS before THE Profile_Service persists the change.
5. WHEN an authenticated User submits a profile update with a phone number not in E.164 format, THE Profile_Service SHALL return a validation error specifying the required format.
6. WHEN an authenticated User submits a profile update with an email address already associated with another account, THE Profile_Service SHALL return an error indicating the email is already in use.
7. WHEN an authenticated User submits a profile update with a phone number already associated with another account, THE Profile_Service SHALL return an error indicating the phone number is already in use.
8. WHEN a profile update is persisted successfully, THE Profile_Service SHALL return the complete updated Profile within 2 seconds.

---

### Requirement 3: Upload and Update Avatar

**User Story:** As a signed-in user, I want to upload or change my profile picture, so that my account reflects my identity.

#### Acceptance Criteria

1. WHEN an authenticated User submits an avatar upload with an image file in JPEG or PNG format not exceeding 5 MB, THE Profile_Service SHALL store the image, generate a publicly accessible URL, and update the User's avatar URL in the Profile.
2. WHEN an authenticated User submits an avatar upload with a file exceeding 5 MB, THE Profile_Service SHALL return a validation error specifying the maximum allowed file size.
3. WHEN an authenticated User submits an avatar upload with a file in a format other than JPEG or PNG, THE Profile_Service SHALL return a validation error specifying the accepted formats.
4. WHEN an avatar is updated successfully, THE Profile_Service SHALL delete the previously stored avatar file to avoid orphaned storage.
5. WHEN an authenticated User removes their avatar without uploading a replacement, THE Profile_Service SHALL set the avatar URL to a default placeholder image URL.

---

### Requirement 4: Manage Delivery Addresses

**User Story:** As a signed-in user, I want to add, edit, delete, and set a default delivery address, so that I can manage where my orders are delivered.

#### Acceptance Criteria

1. WHEN an authenticated User submits a new Delivery_Address containing a label, a street address, a city, and geographic coordinates, THE Profile_Service SHALL persist the address and associate it with the User's account.
2. WHEN an authenticated User submits a new Delivery_Address with a missing required field (label, street address, or city), THE Profile_Service SHALL return a validation error identifying the missing field.
3. WHEN an authenticated User submits an update to an existing Delivery_Address, THE Profile_Service SHALL persist the changes and return the updated address.
4. WHEN an authenticated User deletes a Delivery_Address that is not the Default_Address, THE Profile_Service SHALL remove the address from the User's account.
5. WHEN an authenticated User deletes the current Default_Address, THE Profile_Service SHALL remove the address and clear the Default_Address designation; THE Flutter app SHALL prompt the User to select a new Default_Address.
6. WHEN an authenticated User designates a Delivery_Address as the Default_Address, THE Profile_Service SHALL mark that address as default and remove the default designation from any previously default address.
7. THE Profile_Service SHALL allow a User to store a maximum of 10 Delivery_Addresses per account; WHEN a User attempts to add an 11th address, THE Profile_Service SHALL return an error indicating the address limit has been reached.
8. WHEN an authenticated User retrieves their address list, THE Profile_Service SHALL return all Delivery_Addresses sorted with the Default_Address first, followed by remaining addresses in creation order.

---

### Requirement 5: View Order History

**User Story:** As a signed-in user, I want to view my past orders, so that I can track what I have ordered and reorder items I enjoyed.

#### Acceptance Criteria

1. WHEN an authenticated User requests their order history, THE Order_Service SHALL return a paginated list of Order_Summaries for that User, ordered by order date descending, with a default page size of 20.
2. WHEN an authenticated User requests a specific page of order history, THE Order_Service SHALL return the correct page of Order_Summaries and include the total order count and total page count in the response.
3. WHEN an authenticated User selects an Order_Summary, THE Order_Service SHALL return the full order details including item names, quantities, unit prices, total amount, delivery address, payment method, and final order status.
4. WHEN an authenticated User has no past orders, THE Order_Service SHALL return an empty list and THE Flutter app SHALL display an empty-state message.
5. IF the Order_Service is unreachable when the User requests order history, THEN THE Flutter app SHALL display the last successfully fetched order history page from local cache and show a connectivity warning.

---

### Requirement 6: View Coin Balance and Transaction History

**User Story:** As a signed-in user, I want to see my current coin balance and the history of how I earned and spent coins, so that I can track my rewards.

#### Acceptance Criteria

1. WHEN an authenticated User opens the coins section of their profile, THE Coin_Service SHALL return the User's current Coin_Balance.
2. WHEN an authenticated User requests their coin transaction history, THE Coin_Service SHALL return a paginated list of Coin_Transactions ordered by timestamp descending, with a default page size of 20.
3. THE Coin_Service SHALL include in each Coin_Transaction record: the transaction identifier, the coin amount (positive for credits, negative for debits), the reason (e.g., "Purchase reward", "Redemption"), the related order identifier where applicable, and the timestamp.
4. WHEN an authenticated User requests a specific page of coin transaction history, THE Coin_Service SHALL return the correct page and include the total transaction count in the response.
5. WHEN an authenticated User has no coin transactions, THE Coin_Service SHALL return a Coin_Balance of 0 and an empty transaction list, and THE Flutter app SHALL display an empty-state message.
6. WHEN an authenticated User's Coin_Balance changes due to a new transaction, THE Flutter app SHALL reflect the updated Coin_Balance within 5 seconds without requiring a manual refresh.

---

### Requirement 7: Manage Notification Preferences

**User Story:** As a signed-in user, I want to enable or disable specific notification categories, so that I only receive communications that are relevant to me.

#### Acceptance Criteria

1. THE Profile_Service SHALL maintain a Notification_Preference record for each User containing independent toggles for: order status updates, promotional offers, and coin reward events.
2. WHEN an authenticated User updates a Notification_Preference toggle, THE Profile_Service SHALL persist the change and THE Notification_Service SHALL apply the updated preference to all subsequent notifications of that category within 60 seconds.
3. WHEN an authenticated User disables order status update notifications, THE Notification_Service SHALL suppress push notifications for order events but SHALL continue to record order status changes in the Order_Service.
4. WHEN a new User account is created, THE Profile_Service SHALL initialize all Notification_Preference toggles to enabled by default.
5. WHEN an authenticated User retrieves their notification preferences, THE Profile_Service SHALL return the current state of all Notification_Preference toggles within 2 seconds.

---

### Requirement 8: Account Deactivation

**User Story:** As a signed-in user, I want to temporarily deactivate my account, so that I can pause my activity without permanently losing my data.

#### Acceptance Criteria

1. WHEN an authenticated User submits an account deactivation request with their current password, THE Auth_Service SHALL verify the password and, upon success, mark the account as deactivated and invalidate all active Refresh_Tokens for that account.
2. WHEN an account is deactivated, THE Auth_Service SHALL reject all sign-in attempts for that account and return an error indicating the account is deactivated, with instructions on how to reactivate it.
3. WHEN a deactivated User submits a reactivation request via the sign-in screen with valid credentials, THE Auth_Service SHALL reactivate the account, restore all associated profile data, and issue a new Access_Token and Refresh_Token.
4. WHEN an account is deactivated, THE Profile_Service SHALL retain all profile data, delivery addresses, order history, and coin balance without modification.
5. WHEN an authenticated User submits an account deactivation request with an incorrect password, THE Auth_Service SHALL return an authentication error without deactivating the account.

---

### Requirement 9: Account Deletion

**User Story:** As a signed-in user, I want to permanently delete my account, so that all my personal data is removed from AKKA Food.

#### Acceptance Criteria

1. WHEN an authenticated User submits an account deletion request with their current password, THE Auth_Service SHALL verify the password and, upon success, initiate the account deletion process.
2. WHEN account deletion is initiated, THE Auth_Service SHALL invalidate all active Refresh_Tokens for that account and emit an account-deleted event.
3. WHEN an account-deleted event is received, THE Profile_Service SHALL anonymize or permanently delete all personal data associated with the account, including display name, email, phone number, avatar, and delivery addresses, within 30 days.
4. WHEN an account-deleted event is received, THE Order_Service SHALL retain order records for legal and financial compliance purposes but SHALL replace all personally identifiable fields with anonymized placeholders.
5. WHEN an account-deleted event is received, THE Coin_Service SHALL permanently delete the User's Coin_Balance and all associated Coin_Transactions.
6. WHEN an authenticated User submits an account deletion request with an incorrect password, THE Auth_Service SHALL return an authentication error without initiating deletion.
7. WHEN account deletion is complete, THE Flutter app SHALL sign the User out, clear all local data, and redirect to the sign-in screen.
8. WHEN an account deletion request is submitted, THE Flutter app SHALL display a confirmation dialog clearly stating that the action is irreversible before submitting the request to THE Auth_Service.

---

### Requirement 10: Profile Data Consistency Across Services

**User Story:** As a signed-in user, I want my profile information to be consistent across all parts of the app, so that I do not see stale or conflicting data.

#### Acceptance Criteria

1. WHEN the Profile_Service persists a profile update, THE Profile_Service SHALL emit a profile-updated event so that downstream services can synchronize cached user data.
2. WHEN the Auth_Service emits an account-deleted event, THE Profile_Service, THE Order_Service, and THE Coin_Service SHALL each process the event independently and idempotently; processing the same event twice SHALL produce the same result as processing it once.
3. WHEN the Flutter app fetches profile data, coin balance, and order history concurrently, THE Flutter app SHALL display each section as it loads independently rather than waiting for all sections to complete.
4. THE Profile_Service SHALL validate that the user identifier embedded in the Access_Token matches the profile being read or modified on every request; IF the identifiers do not match, THEN THE Profile_Service SHALL return a 403 Forbidden response.
