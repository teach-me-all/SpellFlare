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
exports.registerFCMToken = exports.setUsername = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const USERNAME_REGEX = /^[a-zA-Z0-9_]{3,20}$/;
// Callable: set or update a user's username, enforcing uniqueness
exports.setUsername = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    const userId = context.auth.uid;
    const { username, avatarIcon } = data;
    if (!username || !USERNAME_REGEX.test(username)) {
        throw new functions.https.HttpsError("invalid-argument", "Username must be 3-20 characters: letters, numbers, and underscores only");
    }
    // Check uniqueness
    const existing = await admin
        .firestore()
        .collection("users")
        .where("username", "==", username)
        .limit(1)
        .get();
    if (!existing.empty && existing.docs[0].id !== userId) {
        throw new functions.https.HttpsError("already-exists", "Username is already taken");
    }
    const update = {
        username,
        lastActiveAt: admin.firestore.Timestamp.now(),
    };
    if (avatarIcon) {
        update.avatarIcon = avatarIcon;
    }
    // Ensure user doc exists with required fields on first set
    await admin.firestore().collection("users").doc(userId).set({
        ...update,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { success: true };
});
// Callable: register or update FCM token for notifications
exports.registerFCMToken = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    const userId = context.auth.uid;
    const { token } = data;
    if (!token) {
        throw new functions.https.HttpsError("invalid-argument", "FCM token required");
    }
    await admin.firestore().collection("users").doc(userId).set({ fcmToken: token, lastActiveAt: admin.firestore.Timestamp.now() }, { merge: true });
    return { success: true };
});
//# sourceMappingURL=users.js.map