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
exports.checkOtpRateLimit = exports.resetLoginAttempts = exports.recordFailedLoginAttempt = exports.checkAccountLock = exports.onUserDeleted = exports.onUserCreated = exports.aggregateAnalytics = exports.adminManageUser = exports.adminManageCategory = exports.adminDeleteMeal = exports.adminUpdateMeal = exports.adminCreateMeal = exports.adminUpdateOrderStatus = void 0;
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
//# sourceMappingURL=index.js.map