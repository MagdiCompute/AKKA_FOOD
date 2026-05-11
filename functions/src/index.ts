import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK once
if (!admin.apps.length) {
  admin.initializeApp();
}

// Admin Cloud Functions
export { adminUpdateOrderStatus } from "./admin/adminUpdateOrderStatus";
export { adminCreateMeal, adminUpdateMeal, adminDeleteMeal } from "./admin/adminMeal";
export { adminManageCategory } from "./admin/adminManageCategory";
export { adminManageUser } from "./admin/adminManageUser";
export { aggregateAnalytics } from "./admin/aggregateAnalytics";

// Auth Cloud Functions
export { onUserCreated } from "./auth/onUserCreated";
export { onUserDeleted } from "./auth/onUserDeleted";
export { checkAccountLock, recordFailedLoginAttempt, resetLoginAttempts } from "./auth/checkAccountLock";
export { checkOtpRateLimit } from "./auth/otpRateLimit";

// Meal Catalog — Algolia sync
export { onMealCreated, onMealUpdated, onMealDeleted } from "./meal_catalog/algolia_sync";

// Meal Catalog — Category deactivation cascade
export { onCategoryDeactivated } from "./meal_catalog/category_deactivated";

// Meal Catalog — Meal validation (price, name uniqueness, nutritional info)
export {
  onMealWriteValidationCreated,
  onMealWriteValidationUpdated,
  onNutritionalInfoValidationCreated,
  onNutritionalInfoValidationUpdated,
} from "./meal_catalog/meal_validation";

// Payment Processing
export { initiatePayment } from "./payment/initiatePayment";
export { orangeMoneyCallback } from "./payment/orangeMoneyCallback";
export { expireStaleTransactions } from "./payment/expireStaleTransactions";
export { createOrder } from "./payment/createOrder";

// Delivery System
export { onOrderStatusChanged } from "./delivery/onOrderStatusChanged";

// Recommendation System
export { computeRecommendations } from "./recommendations/computeRecommendations";
export { onOrderCompletedRecommendations } from "./recommendations/onOrderCompleted";
export { refreshPopularityRankings } from "./recommendations/refreshPopularityRankings";

// Coins — Loyalty System
export { onPaymentSuccess } from "./coins/onPaymentSuccess";
export { redeemCoins } from "./coins/redeemCoins";
