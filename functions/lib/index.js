"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onOrderStatusChanged = exports.createOrder = exports.expireStaleTransactions = exports.orangeMoneyCallback = exports.initiatePayment = exports.onNutritionalInfoValidationUpdated = exports.onNutritionalInfoValidationCreated = exports.onMealWriteValidationUpdated = exports.onMealWriteValidationCreated = exports.onCategoryDeactivated = exports.onMealDeleted = exports.onMealUpdated = exports.onMealCreated = exports.checkOtpRateLimit = exports.resetLoginAttempts = exports.recordFailedLoginAttempt = exports.checkAccountLock = exports.onUserDeleted = exports.onUserCreated = exports.aggregateAnalytics = exports.adminManageUser = exports.adminManageCategory = exports.adminDeleteMeal = exports.adminUpdateMeal = exports.adminCreateMeal = exports.adminUpdateOrderStatus = void 0;
const admin = __importStar(require("firebase-admin"));
// Initialize Firebase Admin SDK once
if (!admin.apps.length) {
    admin.initializeApp();
}
// Admin Cloud Functions
var adminUpdateOrderStatus_1 = require("./admin/adminUpdateOrderStatus");
Object.defineProperty(exports, "adminUpdateOrderStatus", { enumerable: true, get: function () { return adminUpdateOrderStatus_1.adminUpdateOrderStatus; } });
var adminMeal_1 = require("./admin/adminMeal");
Object.defineProperty(exports, "adminCreateMeal", { enumerable: true, get: function () { return adminMeal_1.adminCreateMeal; } });
Object.defineProperty(exports, "adminUpdateMeal", { enumerable: true, get: function () { return adminMeal_1.adminUpdateMeal; } });
Object.defineProperty(exports, "adminDeleteMeal", { enumerable: true, get: function () { return adminMeal_1.adminDeleteMeal; } });
var adminManageCategory_1 = require("./admin/adminManageCategory");
Object.defineProperty(exports, "adminManageCategory", { enumerable: true, get: function () { return adminManageCategory_1.adminManageCategory; } });
var adminManageUser_1 = require("./admin/adminManageUser");
Object.defineProperty(exports, "adminManageUser", { enumerable: true, get: function () { return adminManageUser_1.adminManageUser; } });
var aggregateAnalytics_1 = require("./admin/aggregateAnalytics");
Object.defineProperty(exports, "aggregateAnalytics", { enumerable: true, get: function () { return aggregateAnalytics_1.aggregateAnalytics; } });
// Auth Cloud Functions
var onUserCreated_1 = require("./auth/onUserCreated");
Object.defineProperty(exports, "onUserCreated", { enumerable: true, get: function () { return onUserCreated_1.onUserCreated; } });
var onUserDeleted_1 = require("./auth/onUserDeleted");
Object.defineProperty(exports, "onUserDeleted", { enumerable: true, get: function () { return onUserDeleted_1.onUserDeleted; } });
var checkAccountLock_1 = require("./auth/checkAccountLock");
Object.defineProperty(exports, "checkAccountLock", { enumerable: true, get: function () { return checkAccountLock_1.checkAccountLock; } });
Object.defineProperty(exports, "recordFailedLoginAttempt", { enumerable: true, get: function () { return checkAccountLock_1.recordFailedLoginAttempt; } });
Object.defineProperty(exports, "resetLoginAttempts", { enumerable: true, get: function () { return checkAccountLock_1.resetLoginAttempts; } });
var otpRateLimit_1 = require("./auth/otpRateLimit");
Object.defineProperty(exports, "checkOtpRateLimit", { enumerable: true, get: function () { return otpRateLimit_1.checkOtpRateLimit; } });
// Meal Catalog — Algolia sync
var algolia_sync_1 = require("./meal_catalog/algolia_sync");
Object.defineProperty(exports, "onMealCreated", { enumerable: true, get: function () { return algolia_sync_1.onMealCreated; } });
Object.defineProperty(exports, "onMealUpdated", { enumerable: true, get: function () { return algolia_sync_1.onMealUpdated; } });
Object.defineProperty(exports, "onMealDeleted", { enumerable: true, get: function () { return algolia_sync_1.onMealDeleted; } });
// Meal Catalog — Category deactivation cascade
var category_deactivated_1 = require("./meal_catalog/category_deactivated");
Object.defineProperty(exports, "onCategoryDeactivated", { enumerable: true, get: function () { return category_deactivated_1.onCategoryDeactivated; } });
// Meal Catalog — Meal validation (price, name uniqueness, nutritional info)
var meal_validation_1 = require("./meal_catalog/meal_validation");
Object.defineProperty(exports, "onMealWriteValidationCreated", { enumerable: true, get: function () { return meal_validation_1.onMealWriteValidationCreated; } });
Object.defineProperty(exports, "onMealWriteValidationUpdated", { enumerable: true, get: function () { return meal_validation_1.onMealWriteValidationUpdated; } });
Object.defineProperty(exports, "onNutritionalInfoValidationCreated", { enumerable: true, get: function () { return meal_validation_1.onNutritionalInfoValidationCreated; } });
Object.defineProperty(exports, "onNutritionalInfoValidationUpdated", { enumerable: true, get: function () { return meal_validation_1.onNutritionalInfoValidationUpdated; } });
// Payment Processing
var initiatePayment_1 = require("./payment/initiatePayment");
Object.defineProperty(exports, "initiatePayment", { enumerable: true, get: function () { return initiatePayment_1.initiatePayment; } });
var orangeMoneyCallback_1 = require("./payment/orangeMoneyCallback");
Object.defineProperty(exports, "orangeMoneyCallback", { enumerable: true, get: function () { return orangeMoneyCallback_1.orangeMoneyCallback; } });
var expireStaleTransactions_1 = require("./payment/expireStaleTransactions");
Object.defineProperty(exports, "expireStaleTransactions", { enumerable: true, get: function () { return expireStaleTransactions_1.expireStaleTransactions; } });
var createOrder_1 = require("./payment/createOrder");
Object.defineProperty(exports, "createOrder", { enumerable: true, get: function () { return createOrder_1.createOrder; } });
// Delivery System
var onOrderStatusChanged_1 = require("./delivery/onOrderStatusChanged");
Object.defineProperty(exports, "onOrderStatusChanged", { enumerable: true, get: function () { return onOrderStatusChanged_1.onOrderStatusChanged; } });
//# sourceMappingURL=index.js.map