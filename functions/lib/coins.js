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
exports.submitCompetitionCoins = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
// Maximum coins that can be submitted in a single batch.
// 5 perfect levels × 100 coins = 500. Any higher is suspicious.
const MAX_BATCH_DELTA = 500;
// If delta > 300 arrives in under 30 seconds → flag (warn) but allow.
// If delta > 500 arrives in under 30 seconds → hard reject.
const RATE_LIMIT_WINDOW_SECONDS = 30;
const RATE_LIMIT_HARD_REJECT_DELTA = 500;
exports.submitCompetitionCoins = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    const { competitionId, delta } = data;
    const userId = context.auth.uid;
    // Validate delta range
    if (!Number.isInteger(delta) || delta <= 0 || delta > MAX_BATCH_DELTA) {
        throw new functions.https.HttpsError("invalid-argument", `Coin delta must be between 1 and ${MAX_BATCH_DELTA}`);
    }
    const competitionRef = admin
        .firestore()
        .collection("competitions")
        .doc(competitionId);
    const participantRef = competitionRef
        .collection("participants")
        .doc(userId);
    // Read competition and participant in parallel
    const [compSnap, participantSnap] = await Promise.all([
        competitionRef.get(),
        participantRef.get(),
    ]);
    if (!compSnap.exists) {
        throw new functions.https.HttpsError("not-found", "Competition not found");
    }
    const comp = compSnap.data();
    if (comp.status !== "active") {
        throw new functions.https.HttpsError("failed-precondition", "Competition is not active");
    }
    const now = admin.firestore.Timestamp.now();
    if (now.toDate() > comp.endTime.toDate()) {
        throw new functions.https.HttpsError("failed-precondition", "Competition has ended");
    }
    if (!participantSnap.exists) {
        throw new functions.https.HttpsError("not-found", "User is not a participant in this competition");
    }
    const participant = participantSnap.data();
    // Rate limiting check
    if (participant.lastUpdatedAt) {
        const secondsSinceLast = now.seconds - participant.lastUpdatedAt.seconds;
        if (secondsSinceLast < RATE_LIMIT_WINDOW_SECONDS &&
            delta > RATE_LIMIT_HARD_REJECT_DELTA) {
            functions.logger.warn("Anti-cheat: hard rate limit triggered", {
                userId,
                competitionId,
                delta,
                secondsSinceLast,
            });
            throw new functions.https.HttpsError("resource-exhausted", "Coin submission rate limit exceeded");
        }
        // Soft flag for suspicious but allowed activity
        if (secondsSinceLast < RATE_LIMIT_WINDOW_SECONDS && delta > 300) {
            functions.logger.warn("Anti-cheat: suspicious coin spike (allowed)", {
                userId,
                competitionId,
                delta,
                secondsSinceLast,
            });
        }
    }
    // Atomic increment
    await participantRef.update({
        coinsEarned: admin.firestore.FieldValue.increment(delta),
        lastUpdatedAt: now,
    });
    return { success: true };
});
//# sourceMappingURL=coins.js.map