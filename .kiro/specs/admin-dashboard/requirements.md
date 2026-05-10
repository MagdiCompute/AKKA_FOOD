# Requirements Document — Admin Dashboard

## Introduction

The Admin Dashboard provides privileged users of AKKA Food with tools to manage the restaurant's operations: meals, categories, orders, delivery statuses, users, and analytics. It is accessible only to authenticated users with the `admin` role.

## Glossary

- **Admin**: An authenticated user with the `admin` role in Firestore.
- **Admin_Dashboard**: The set of screens and functions available exclusively to Admin users.
- **Order_Management**: The Admin capability to view, filter, and update order statuses.
- **Analytics**: Aggregated metrics on orders, revenue, and user activity.

---

## Requirements

### Requirement 1: Admin Authentication and Access Control

**User Story:** As an admin, I want to access a protected dashboard, so that only authorized personnel can manage the restaurant.

#### Acceptance Criteria

1. WHEN a User with the `admin` role signs in, THE Flutter app SHALL display an Admin Dashboard entry point in the navigation.
2. WHEN a User without the `admin` role attempts to access any Admin route, THE Flutter app SHALL redirect them to the home screen.
3. THE Admin_Dashboard SHALL enforce role checks on every Cloud Function call; requests from non-admin tokens SHALL be rejected with a 403 error.

---

### Requirement 2: Meal Management

**User Story:** As an admin, I want to add, edit, delete, and toggle availability of meals, so that the menu stays accurate.

#### Acceptance Criteria

1. THE Admin_Dashboard SHALL display a list of all meals (available and unavailable) with name, price, category, and availability status.
2. WHEN an Admin creates a new meal with all required fields, THE Admin_Dashboard SHALL persist the meal and make it visible in the catalog per its availability setting.
3. WHEN an Admin edits a meal, THE Admin_Dashboard SHALL persist the changes and reflect them in the catalog within 60 seconds.
4. WHEN an Admin toggles a meal's availability, THE Admin_Dashboard SHALL update the meal's status immediately.
5. WHEN an Admin deletes a meal, THE Admin_Dashboard SHALL remove it from the catalog and prevent users from accessing its detail screen.
6. WHEN an Admin marks a meal as featured, THE Admin_Dashboard SHALL include it in the Featured section of the catalog.

---

### Requirement 3: Category Management

**User Story:** As an admin, I want to manage meal categories, so that the catalog remains organized.

#### Acceptance Criteria

1. THE Admin_Dashboard SHALL display all categories with their name, image, and active status.
2. WHEN an Admin creates a category with a unique name, THE Admin_Dashboard SHALL persist it and display it in the catalog.
3. WHEN an Admin deactivates a category, THE Admin_Dashboard SHALL hide it from users and set all its meals to unavailable.
4. IF an Admin attempts to create a category with a duplicate name, THE Admin_Dashboard SHALL reject the request with a descriptive error.

---

### Requirement 4: Order Management

**User Story:** As an admin, I want to view and manage all orders, so that I can ensure timely preparation and delivery.

#### Acceptance Criteria

1. THE Admin_Dashboard SHALL display all active orders (status not `delivered` or `cancelled`) sorted by creation time ascending.
2. WHEN an Admin selects an order, THE Admin_Dashboard SHALL display full order details: items, total, user info, delivery option, address, and current status.
3. WHEN an Admin updates an order's delivery status, THE Admin_Dashboard SHALL persist the change and trigger a push notification to the customer.
4. THE Admin_Dashboard SHALL allow filtering orders by status, date range, and delivery option.
5. WHEN an Admin marks an order as `out_for_delivery`, THE Admin_Dashboard SHALL require the Admin to set an ETA in minutes.

---

### Requirement 5: Analytics

**User Story:** As an admin, I want to view key metrics, so that I can monitor the restaurant's performance.

#### Acceptance Criteria

1. THE Admin_Dashboard SHALL display total orders, total revenue (XOF), and total active users for the current day, week, and month.
2. THE Admin_Dashboard SHALL display the top 5 best-selling meals by order count for the selected period.
3. THE Admin_Dashboard SHALL display a chart of daily order counts for the past 30 days.
4. Analytics data SHALL be refreshed at least every 5 minutes.

---

### Requirement 6: User Management

**User Story:** As an admin, I want to view and manage user accounts, so that I can handle support requests and policy violations.

#### Acceptance Criteria

1. THE Admin_Dashboard SHALL display a searchable list of all registered users with display name, email, registration date, and order count.
2. WHEN an Admin deactivates a user account, THE Admin_Dashboard SHALL prevent that user from signing in.
3. WHEN an Admin reactivates a user account, THE Admin_Dashboard SHALL restore the user's ability to sign in.
4. THE Admin_Dashboard SHALL display a user's order history and coin balance when the Admin selects a user.
