# Requirements Document

## Introduction

The Meal Catalog feature is the core browsing experience of AKKA Food, a Flutter-based mobile e-restaurant app. It enables users to discover, search, filter, and sort available meals, view detailed meal information, and access personalized recommendations. It also provides administrators with tools to manage meals and categories. The catalog serves as the primary entry point for the ordering flow, integrating with the cart, recommendation system, and loyalty (coins) features.

---

## Glossary

- **Meal_Catalog**: The full collection of meals available for ordering in the AKKA Food app.
- **Meal**: A food item offered by the restaurant, characterized by a name, description, price, images, category, availability status, nutritional information, and dietary tags.
- **Category**: A grouping label for meals (e.g., Burgers, Salads, Drinks, Desserts).
- **Dietary_Tag**: A label indicating a meal's dietary properties (e.g., Vegetarian, Vegan, Gluten-Free, Spicy, Halal).
- **Featured_Meal**: A meal promoted by the admin to appear in a highlighted section of the catalog.
- **Recommendation_Engine**: The backend system that analyzes a user's purchase history to suggest relevant meals.
- **Search_Service**: The component responsible for querying meals by name or keyword.
- **Filter_Service**: The component responsible for narrowing the meal list by category, price range, availability, or dietary tags.
- **Sort_Service**: The component responsible for ordering the meal list by price, popularity, or recency.
- **Admin**: An authenticated user with administrative privileges who can manage meals and categories.
- **User**: An authenticated or guest customer browsing the AKKA Food app.
- **Availability**: A boolean status indicating whether a meal is currently orderable.
- **Nutritional_Info**: Structured data attached to a meal including calories, proteins, carbohydrates, and fats.
- **Popularity_Score**: A computed metric derived from the number of times a meal has been ordered.
- **Cart**: The in-app container holding meals selected by the User for purchase.

---

## Requirements

### Requirement 1: Display Meal Catalog

**User Story:** As a User, I want to see a list of all available meals, so that I can browse what the restaurant offers and decide what to order.

#### Acceptance Criteria

1. WHEN the User opens the Meal_Catalog screen, THE Meal_Catalog SHALL display all meals that have Availability set to true.
2. THE Meal_Catalog SHALL display each meal with its name, primary image, price, category, and Availability status.
3. WHEN the Meal_Catalog is loading data from the backend, THE Meal_Catalog SHALL display a loading indicator to the User.
4. IF the backend returns an error while fetching meals, THEN THE Meal_Catalog SHALL display an error message and a retry action to the User.
5. IF no meals are available, THEN THE Meal_Catalog SHALL display an empty-state message informing the User that no meals are currently available.
6. THE Meal_Catalog SHALL support paginated or infinite-scroll loading, fetching additional meals when the User scrolls to the end of the list.

---

### Requirement 2: View Meal Details

**User Story:** As a User, I want to view the full details of a meal, so that I can make an informed decision before adding it to my cart.

#### Acceptance Criteria

1. WHEN the User selects a meal from the Meal_Catalog, THE Meal_Catalog SHALL navigate to a Meal Detail screen displaying the meal's name, full description, price, all images, category, Availability, Nutritional_Info, and Dietary_Tags.
2. THE Meal Detail screen SHALL display Nutritional_Info including calories, proteins, carbohydrates, and fats in clearly labeled fields.
3. WHILE a meal's Availability is false, THE Meal Detail screen SHALL display the meal as unavailable and SHALL disable the add-to-cart action.
4. WHEN the User views a meal's images, THE Meal Detail screen SHALL allow the User to swipe through multiple images when more than one image is present.
5. THE Meal Detail screen SHALL display a button to add the meal to the Cart when Availability is true.

---

### Requirement 3: Search Meals

**User Story:** As a User, I want to search for meals by name or keyword, so that I can quickly find a specific meal without scrolling through the entire catalog.

#### Acceptance Criteria

1. THE Meal_Catalog SHALL provide a search input field accessible from the catalog screen.
2. WHEN the User enters a query of at least 2 characters in the search input, THE Search_Service SHALL return meals whose name or description contains the query string, case-insensitively.
3. WHEN the search query is cleared, THE Meal_Catalog SHALL restore the full unfiltered meal list.
4. IF the Search_Service returns no results for a given query, THEN THE Meal_Catalog SHALL display a no-results message that includes the searched query.
5. WHEN the User is typing in the search input, THE Search_Service SHALL debounce requests by at least 300 milliseconds before querying the backend.

---

### Requirement 4: Filter Meals

**User Story:** As a User, I want to filter meals by category, price range, availability, and dietary tags, so that I can narrow down the catalog to meals that match my preferences.

#### Acceptance Criteria

1. THE Filter_Service SHALL support filtering meals by one or more Categories simultaneously.
2. THE Filter_Service SHALL support filtering meals by a price range defined by a minimum price and a maximum price, both expressed in the app's base currency (XOF).
3. THE Filter_Service SHALL support filtering meals by Availability, showing only meals with Availability set to true when the availability filter is active.
4. THE Filter_Service SHALL support filtering meals by one or more Dietary_Tags simultaneously.
5. WHEN the User applies one or more filters, THE Meal_Catalog SHALL update the displayed meal list to show only meals matching all active filter criteria.
6. WHEN the User clears all active filters, THE Meal_Catalog SHALL restore the full unfiltered meal list.
7. THE Meal_Catalog SHALL display the count of currently active filters to the User.

---

### Requirement 5: Sort Meals

**User Story:** As a User, I want to sort the meal list by price, popularity, or newest additions, so that I can find the most relevant meals for my needs.

#### Acceptance Criteria

1. THE Sort_Service SHALL support sorting meals in ascending order of price.
2. THE Sort_Service SHALL support sorting meals in descending order of price.
3. THE Sort_Service SHALL support sorting meals in descending order of Popularity_Score.
4. THE Sort_Service SHALL support sorting meals in descending order of creation date (newest first).
5. WHEN the User selects a sort option, THE Meal_Catalog SHALL reorder the displayed meal list according to the selected sort criterion without clearing active filters.
6. THE Meal_Catalog SHALL display the currently active sort option to the User.

---

### Requirement 6: Browse Meal Categories

**User Story:** As a User, I want to browse meals by category, so that I can quickly navigate to the type of food I am interested in.

#### Acceptance Criteria

1. THE Meal_Catalog SHALL display a horizontally scrollable list of all active Categories at the top of the catalog screen.
2. WHEN the User selects a Category from the category list, THE Meal_Catalog SHALL filter the displayed meals to show only meals belonging to that Category.
3. WHEN the User selects an already-active Category, THE Meal_Catalog SHALL deselect it and restore the full unfiltered meal list.
4. THE Meal_Catalog SHALL display each Category with its name and an icon or image when one is available.
5. IF a Category contains no available meals, THEN THE Meal_Catalog SHALL still display the Category but SHALL indicate that no meals are currently available in it.

---

### Requirement 7: Featured and Promoted Meals

**User Story:** As a User, I want to see featured and promoted meals highlighted at the top of the catalog, so that I can discover special offers and popular items quickly.

#### Acceptance Criteria

1. THE Meal_Catalog SHALL display a dedicated Featured section above the main meal list when at least one Featured_Meal exists.
2. THE Meal_Catalog SHALL display each Featured_Meal in the Featured section with its name, primary image, price, and a promotional label.
3. WHEN the User selects a Featured_Meal, THE Meal_Catalog SHALL navigate to the Meal Detail screen for that meal.
4. IF no Featured_Meals are configured by the Admin, THEN THE Meal_Catalog SHALL hide the Featured section entirely.
5. THE Meal_Catalog SHALL display Featured_Meals in the order defined by the Admin.

---

### Requirement 8: Recommended Meals

**User Story:** As a User, I want to see meals recommended based on my purchase history, so that I can quickly reorder favorites or discover similar meals I am likely to enjoy.

#### Acceptance Criteria

1. WHEN an authenticated User opens the Meal_Catalog, THE Recommendation_Engine SHALL provide a list of up to 10 recommended meals based on the User's purchase history.
2. THE Meal_Catalog SHALL display recommended meals in a dedicated Recommended section, showing each meal's name, primary image, and price.
3. WHEN the User selects a recommended meal, THE Meal_Catalog SHALL navigate to the Meal Detail screen for that meal.
4. IF the Recommendation_Engine returns fewer than 3 recommendations for a User, THEN THE Meal_Catalog SHALL hide the Recommended section for that User.
5. WHILE the User is not authenticated, THE Meal_Catalog SHALL hide the Recommended section.
6. IF the Recommendation_Engine returns an error, THEN THE Meal_Catalog SHALL hide the Recommended section without displaying an error to the User.

---

### Requirement 9: Admin — Manage Meals

**User Story:** As an Admin, I want to add, edit, and delete meals in the catalog, so that I can keep the menu accurate and up to date.

#### Acceptance Criteria

1. WHEN an Admin submits a new meal with a name, price, category, at least one image, and Availability status, THE Meal_Catalog SHALL persist the new meal and make it visible in the catalog according to its Availability.
2. WHEN an Admin updates an existing meal's fields, THE Meal_Catalog SHALL persist the changes and reflect them immediately in the catalog.
3. WHEN an Admin sets a meal's Availability to false, THE Meal_Catalog SHALL hide the meal from the User-facing catalog within 60 seconds.
4. WHEN an Admin deletes a meal, THE Meal_Catalog SHALL remove the meal from the catalog and SHALL prevent Users from accessing its detail screen.
5. IF an Admin submits a new meal without a required field (name, price, category, or at least one image), THEN THE Meal_Catalog SHALL reject the submission and display a descriptive validation error identifying the missing field.
6. WHEN an Admin marks a meal as a Featured_Meal, THE Meal_Catalog SHALL include the meal in the Featured section for all Users.
7. THE Meal_Catalog SHALL allow an Admin to upload between 1 and 5 images per meal.
8. WHEN an Admin sets Nutritional_Info on a meal, THE Meal_Catalog SHALL validate that calories, proteins, carbohydrates, and fats are each non-negative numeric values before persisting.

---

### Requirement 10: Admin — Manage Categories

**User Story:** As an Admin, I want to create, edit, and deactivate meal categories, so that the catalog remains organized and reflects the current menu structure.

#### Acceptance Criteria

1. WHEN an Admin creates a new Category with a unique name, THE Meal_Catalog SHALL persist the Category and display it in the category list for Users.
2. WHEN an Admin updates a Category's name or image, THE Meal_Catalog SHALL persist the changes and reflect them in the User-facing category list.
3. WHEN an Admin deactivates a Category, THE Meal_Catalog SHALL hide the Category from the User-facing category list and SHALL not display meals belonging solely to that Category in the main catalog.
4. IF an Admin attempts to create a Category with a name that already exists, THEN THE Meal_Catalog SHALL reject the request and display a duplicate-name error.
5. THE Meal_Catalog SHALL display all active Categories to the Admin in a management interface, including Categories that contain no available meals.

---

### Requirement 11: Meal Data Integrity

**User Story:** As a system operator, I want meal data to be consistent and valid at all times, so that Users always see accurate information and the ordering flow is reliable.

#### Acceptance Criteria

1. THE Meal_Catalog SHALL ensure that each meal's price is a positive numeric value greater than 0 XOF.
2. THE Meal_Catalog SHALL ensure that each meal belongs to exactly one active Category.
3. WHEN a Category is deactivated, THE Meal_Catalog SHALL set the Availability of all meals belonging solely to that Category to false.
4. THE Meal_Catalog SHALL ensure that meal names are unique within the catalog, rejecting duplicates with a descriptive error.
5. FOR ALL meals stored in the Meal_Catalog, serializing a meal to its data representation and then deserializing it SHALL produce a meal object equivalent to the original (round-trip property).
