# Tech Stack

## Platform & Language

- **Flutter** (Dart SDK `^3.9.2`) — cross-platform mobile (Android & iOS)
- **Dart** — primary language; follow `flutter_lints` rules (`analysis_options.yaml`)

## Backend — Firebase

| Service | Package | Purpose |
|---|---|---|
| Firebase Auth | `firebase_auth ^5.5.4` | Authentication |
| Cloud Firestore | `cloud_firestore ^5.6.9` | Primary database |
| Firebase Storage | `firebase_storage ^12.4.6` | Image/file storage |
| Cloud Functions | (server-side JS) | Business logic, coin crediting, Algolia sync |

## State Management

- **Riverpod** (`flutter_riverpod ^2.6.1`) with code generation (`riverpod_generator ^2.6.5`, `riverpod_annotation ^2.6.1`)
- Use `@riverpod` annotations and `AsyncNotifier` / `Notifier` classes
- Root widget wraps with `ProviderScope`

## Navigation

- **go_router** `^15.1.2`
- Route paths defined as constants in `AppRoutes` (abstract final class)
- Route guards implemented as pure functions (e.g., `evaluateAdminGuard`) for testability

## Code Generation

- **freezed** `^3.1.0` + `freezed_annotation ^3.0.0` — immutable data classes
- **json_serializable** `^6.9.5` + `json_annotation ^4.9.0` — JSON serialization
- **build_runner** `^2.4.15` — runs all generators

## Local Storage & Caching

- **Hive** (`hive_flutter ^1.1.0`) — local cache with 5-minute TTL; boxes named `catalog_cache`, `category_cache`, `featured_cache`
- **flutter_secure_storage** `^9.2.4` — sensitive credential storage

## Search

- **Algolia** — full-text meal search; synced from Firestore via Cloud Function triggers
- Debounce: 300ms before firing queries
- Fallback: Firestore prefix search when Algolia is unavailable

## Social Sign-In

- `google_sign_in ^6.2.2`
- `flutter_facebook_auth ^7.1.1`

## Linting

- `flutter_lints ^5.0.0` — base lint rules
- Run `flutter analyze` to check for issues

---

## Common Commands

```bash
# Get dependencies
flutter pub get

# Run code generation (freezed, json_serializable, riverpod_generator)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
dart run build_runner watch --delete-conflicting-outputs

# Analyze code
flutter analyze

# Run tests
flutter test

# Build Android APK (debug)
flutter build apk --debug

# Build iOS (release)
flutter build ios --release

# Run on connected device
flutter run
```
