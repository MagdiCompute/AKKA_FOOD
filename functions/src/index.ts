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
