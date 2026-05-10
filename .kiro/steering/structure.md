# Project Structure

## Root

```
akka_food/
├── lib/                  # All Dart source code
├── test/                 # Unit and widget tests
├── android/              # Android platform project
├── ios/                  # iOS platform project
├── pubspec.yaml          # Dependencies and metadata
└── analysis_options.yaml # Lint configuration
```

## lib/ Layout

```
lib/
├── main.dart             # App entry point; wraps with ProviderScope
├── core/                 # Shared, feature-agnostic code
│   ├── router/           # GoRouter setup (app_router.dart, AppRoutes constants)
│   └── entities/         # Shared domain entities (if cross-feature)
└── features/             # One sub-folder per product feature
    └── <feature>/
        ├── data/
        │   ├── datasources/    # Firestore / Algolia / remote data sources
        │   └── repositories/   # Repository implementations
        ├── domain/
        │   ├── entities/       # Plain Dart model classes
        │   ├── repositories/   # Abstract repository interfaces (I*Repository)
        │   └── usecases/       # Single-responsibility use case classes
        └── presentation/
            ├── notifiers/      # Riverpod Notifier / AsyncNotifier classes
            ├── screens/        # Full-page widgets
            └── widgets/        # Reusable UI components scoped to this feature
```

## Feature List

| Folder | Description |
|---|---|
| `auth` | Sign-in, registration, account linking |
| `meal_catalog` | Browse, search, filter meals |
| `cart` | Cart management and checkout |
| `payment_processing` | Payment flow |
| `coins` | Loyalty coin balance and history |
| `leaderboard` | User rankings |
| `delivery_system` | Order tracking and delivery status |
| `recommendation_system` | Personalized meal suggestions |
| `user_profile` | Profile view and editing |
| `admin_dashboard` | Admin-only management screens |

## Architecture Rules

- **Clean Architecture** — strict layer separation: Presentation → Domain → Data
- Domain layer has **zero Flutter/Firebase imports**; only pure Dart
- Data sources depend on Firebase packages; domain never does
- Repository interfaces live in `domain/repositories/`; implementations in `data/repositories/`
- Use cases are single-method classes (`call()`) in `domain/usecases/`

## Naming Conventions

| Artifact | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `firestore_user_data_source.dart` |
| Classes | `PascalCase` | `FirestoreUserDataSource` |
| Providers | `camelCase` + `Provider` suffix | `currentUserProvider` |
| Notifiers | `PascalCase` + `Notifier` suffix | `CatalogNotifier` |
| Repository interfaces | `I` prefix | `IMealRepository` |
| Route constants | `camelCase` in `AppRoutes` abstract class | `AppRoutes.home` |
| Screens | `PascalCase` + `Screen` suffix | `MealDetailScreen` |
| Widgets | `PascalCase` + `Widget` suffix (or descriptive name) | `MealCard`, `CoinBalanceWidget` |

## Code Style

- Entities are **immutable** — use `final` fields, `const` constructors, and `copyWith()`
- Entities not yet using `freezed` implement `==`, `hashCode`, `toString()`, and `copyWith()` manually (see `AppUser`)
- New entities should use `@freezed` for code generation
- Firestore serialization: `fromMap(Map<String, dynamic>)` factory + `toMap()` method
- Firestore `Timestamp` → `DateTime` conversion handled via a local `_parseDateTime` helper
- Admin role check: always use `AppUser.isAdmin` getter, never compare `role` string directly
- Client-side coin validation is a pre-check only; Cloud Functions are the authoritative source
- Route guards are pure functions returning `String?` (redirect path or null) for testability
