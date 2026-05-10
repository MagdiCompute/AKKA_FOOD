# AKKA Food — Product Overview

AKKA Food is a Flutter-based mobile food delivery application targeting Android and iOS. It allows customers to browse a meal catalog, place orders, track deliveries, and earn/redeem loyalty coins. An admin role provides a dashboard for managing meals, categories, orders, and users.

## Core Features

- **User Authentication** — Email/password, Google, and Facebook sign-in; phone number support; account linking
- **Meal Catalog** — Browse meals by category, search via Algolia, filter and sort, featured and recommended sections
- **Cart & Checkout** — Add meals, apply coin redemptions, proceed to payment
- **Payment Processing** — Handles order payments; triggers coin credit on success
- **Coins / Loyalty System** — Earn 5% of order value as coins; redeem in multiples of 1,000 coins (1,000 coins = 1,000 XOF discount)
- **Leaderboard** — Ranks users by coin balance or order activity
- **Delivery System** — Real-time order tracking and delivery status updates
- **Recommendation System** — Personalized meal suggestions via Cloud Function endpoint
- **User Profile** — View and edit profile, linked providers, coin balance, order history
- **Admin Dashboard** — Manage meals, categories, orders, users, and delivery assignments

## Currency

All prices are in **XOF** (West African CFA franc).

## User Roles

- `user` — default role for all registered customers
- `admin` — elevated role granting access to the admin dashboard; assigned via Firebase Console or provisioning script only
