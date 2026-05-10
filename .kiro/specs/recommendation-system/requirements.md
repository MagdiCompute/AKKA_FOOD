# Requirements Document — Recommendation System

## Introduction

The Recommendation System analyzes each user's purchase history to suggest meals they are likely to enjoy. Recommendations are displayed in the Meal Catalog and personalize the browsing experience. The system improves over time as users place more orders.

## Glossary

- **Recommendation_Engine**: The backend service that computes personalized meal recommendations.
- **Purchase_History**: The list of meals a User has ordered, weighted by recency and frequency.
- **Recommendation**: A meal suggested to a User based on their Purchase_History.
- **Cold_Start**: The state where a User has fewer than 3 completed orders, making personalized recommendations insufficient.
- **Popularity_Score**: A global metric reflecting how often a meal has been ordered across all users.

---

## Requirements

### Requirement 1: Generate Personalized Recommendations

**User Story:** As a user with order history, I want to see meal recommendations based on what I have ordered before, so that I can quickly find meals I am likely to enjoy.

#### Acceptance Criteria

1. WHEN an authenticated User with at least 3 completed orders opens the Meal Catalog, THE Recommendation_Engine SHALL return up to 10 recommended meals personalized to that User's Purchase_History.
2. THE Recommendation_Engine SHALL weight recommendations by: frequency (meals ordered most often rank higher) and recency (meals ordered in the last 30 days rank higher than older orders).
3. THE Recommendation_Engine SHALL NOT recommend meals that are currently unavailable (Availability = false).
4. THE Recommendation_Engine SHALL NOT recommend meals the User ordered in the last 24 hours (to encourage variety).
5. WHEN the Recommendation_Engine returns fewer than 3 personalized recommendations, THE Meal_Catalog SHALL fall back to popularity-based recommendations to fill up to 10 slots.

---

### Requirement 2: Cold Start — New Users

**User Story:** As a new user with no or few orders, I want to see popular meals recommended to me, so that I can discover what other customers enjoy.

#### Acceptance Criteria

1. WHEN an authenticated User has fewer than 3 completed orders, THE Recommendation_Engine SHALL return the top 10 meals by Popularity_Score as recommendations.
2. THE Recommendation_Engine SHALL NOT recommend unavailable meals in cold-start mode.
3. WHILE the User is not authenticated, THE Meal_Catalog SHALL hide the Recommended section entirely.

---

### Requirement 3: Recommendation Freshness

**User Story:** As a user, I want my recommendations to reflect my recent activity, so that they stay relevant as my tastes evolve.

#### Acceptance Criteria

1. THE Recommendation_Engine SHALL recompute recommendations for a User within 60 minutes of a new completed order.
2. THE Recommendation_Engine SHALL cache recommendations per User with a TTL of 60 minutes; cached recommendations SHALL be served for subsequent requests within the TTL window.
3. WHEN a recommended meal becomes unavailable, THE Recommendation_Engine SHALL exclude it from the next recommendation response without waiting for the TTL to expire.

---

### Requirement 4: Recommendation Display

**User Story:** As a user, I want recommendations displayed clearly in the catalog, so that I can easily act on them.

#### Acceptance Criteria

1. THE Meal_Catalog SHALL display recommended meals in a dedicated "Recommended for You" horizontal section.
2. EACH recommendation SHALL display the meal's name, primary image, and price.
3. WHEN the User taps a recommended meal, THE Meal_Catalog SHALL navigate to the Meal Detail screen.
4. IF the Recommendation_Engine returns an error or times out, THE Meal_Catalog SHALL hide the Recommended section silently without displaying an error to the User.

---

### Requirement 5: Popularity Score Maintenance

**User Story:** As a system operator, I want popularity scores to reflect actual order data, so that cold-start recommendations are meaningful.

#### Acceptance Criteria

1. WHEN an order is completed, THE Recommendation_Engine SHALL increment the Popularity_Score of each ordered meal by 1.
2. THE Popularity_Score SHALL be stored on the meal document in Firestore and updated atomically.
3. THE Recommendation_Engine SHALL recompute global popularity rankings at least once per hour.
