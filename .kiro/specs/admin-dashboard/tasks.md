# Tasks — Admin Dashboard

## Task List

- [x] 1. Role-based access control
  - [x] 1.1 Add `role` field to `/users/{uid}` Firestore document (values: 'user', 'admin')
  - [x] 1.2 Implement GoRouter admin route guard: redirect non-admin users to home
  - [x] 1.3 Implement admin role check in all Cloud Functions (verify `role == 'admin'` from Firestore)
  - [x] 1.4 Add admin entry point to app navigation (visible only to admin role)

- [x] 2. Admin navigation shell
  - [x] 2.1 Implement `AdminHomeScreen` with bottom navigation: Orders | Meals | Analytics | Users
  - [x] 2.2 Implement admin-specific GoRouter routes under `/admin/**`

- [x] 3. Meal management (Admin)
  - [x] 3.1 Implement `AdminMealListScreen`: all meals list with availability toggle, search, filter by category
  - [x] 3.2 Implement `AdminMealFormScreen`: create/edit form (name, description, price, category, images, dietary tags, nutritional info, availability, featured toggle, featured order)
  - [x] 3.3 Implement image upload (1–5 images) to Firebase Storage with progress indicator
  - [x] 3.4 Implement availability toggle with immediate Firestore update
  - [x] 3.5 Implement meal delete with confirmation dialog
  - [x] 3.6 Implement `adminCreateMeal`, `adminUpdateMeal`, `adminDeleteMeal` Cloud Functions

- [x] 4. Category management (Admin)
  - [x] 4.1 Implement `AdminCategoryListScreen`: all categories with active/inactive status
  - [x] 4.2 Implement `AdminCategoryFormScreen`: name, image, active toggle
  - [x] 4.3 Implement `adminManageCategory` Cloud Function with deactivation cascade (batch-set meals unavailable)
  - [x] 4.4 Implement duplicate name validation in Cloud Function

- [x] 5. Order management (Admin)
  - [x] 5.1 Implement `AdminOrderListScreen`: real-time list of active orders, filter by status/date/delivery option
  - [x] 5.2 Implement `AdminOrderDetailScreen`: full order details, user info, status update controls
  - [x] 5.3 Implement status update UI: dropdown/buttons for valid next statuses, ETA input for `outForDelivery`
  - [x] 5.4 Implement `adminUpdateOrderStatus` Cloud Function with transition validation
  - [x] 5.5 Implement order search by order ID or user name

- [x] 6. Analytics
  - [x] 6.1 Implement `aggregateAnalytics` scheduled Cloud Function (every 5 min): compute totals, top meals, daily counts; write to `/analytics/summary`
  - [x] 6.2 Implement `AdminAnalyticsScreen`: summary cards (orders, revenue, active users), period selector (today/week/month)
  - [x] 6.3 Implement daily order count line chart using `fl_chart`
  - [x] 6.4 Implement top 5 meals bar chart using `fl_chart`
  - [x] 6.5 Implement real-time listener on `/analytics/summary` for auto-refresh

- [ ] 7. User management (Admin)
  - [x] 7.1 Implement `AdminUserListScreen`: searchable user list (display name, email, registration date, order count)
  - [x] 7.2 Implement `AdminUserDetailScreen`: user profile, order history, coin balance
  - [x] 7.3 Implement `adminManageUser` Cloud Function: deactivate/reactivate via `admin.auth().updateUser(uid, { disabled })`
  - [x] 7.4 Implement deactivate/reactivate buttons with confirmation dialog

- [ ] 8. Firestore Security Rules
  - [~] 8.1 Write rules: `/meals` and `/categories` writable only by admin role
  - [~] 8.2 Write rules: `/orders` readable by admin role (all orders)
  - [~] 8.3 Write rules: `/users` readable by admin role (limited fields: no tokens)
  - [~] 8.4 Write rules: `/analytics` readable by admin role

- [ ] 9. Integration testing
  - [~] 9.1 Write integration test: non-admin user cannot access admin routes
  - [~] 9.2 Write integration test: admin creates meal → appears in catalog
  - [~] 9.3 Write integration test: admin updates order status → customer receives notification
  - [~] 9.4 Write integration test: admin deactivates user → user cannot sign in
  - [~] 9.5 Write integration test: analytics data refreshes within 5 minutes
