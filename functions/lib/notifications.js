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
exports.notifyFinal24Hours = exports.checkRankChanges = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
// Scheduled: check rank changes every 15 minutes and notify users who dropped
exports.checkRankChanges = functions.pubsub
    .schedule("every 15 minutes")
    .onRun(async () => {
    const activeSnap = await admin
        .firestore()
        .collection("competitions")
        .where("status", "==", "active")
        .get();
    for (const compDoc of activeSnap.docs) {
        const participantsSnap = await compDoc.ref
            .collection("participants")
            .orderBy("coinsEarned", "desc")
            .get();
        if (participantsSnap.empty)
            continue;
        const batch = admin.firestore().batch();
        const notifications = [];
        for (let i = 0; i < participantsSnap.docs.length; i++) {
            const doc = participantsSnap.docs[i];
            const participant = doc.data();
            const currentRank = i + 1;
            const prevRank = participant.prevRank;
            if (prevRank !== undefined && currentRank > prevRank) {
                // Rank dropped - queue notification
                const userSnap = await admin
                    .firestore()
                    .collection("users")
                    .doc(doc.id)
                    .get();
                const fcmToken = userSnap.data()?.fcmToken;
                if (fcmToken) {
                    notifications.push({
                        token: fcmToken,
                        body: `You dropped to #${currentRank} in your spelling competition!`,
                        competitionId: compDoc.id,
                    });
                }
            }
            batch.update(doc.ref, { prevRank: currentRank });
        }
        await batch.commit();
        // Send notifications (fire and forget, don't fail the function on FCM errors)
        for (const notif of notifications) {
            admin.messaging().send({
                token: notif.token,
                notification: {
                    title: "SpellFlare Competition",
                    body: notif.body,
                },
                data: {
                    type: "rank_drop",
                    competitionId: notif.competitionId,
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                        },
                    },
                },
            }).catch((err) => {
                functions.logger.warn("FCM send failed", { error: err.message });
            });
        }
    }
});
// Scheduled: notify users in competitions ending within the next 25 hours (runs hourly)
exports.notifyFinal24Hours = functions.pubsub
    .schedule("every 60 minutes")
    .onRun(async () => {
    const now = new Date();
    const in24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const in25h = new Date(now.getTime() + 25 * 60 * 60 * 1000);
    const nearEndSnap = await admin
        .firestore()
        .collection("competitions")
        .where("status", "==", "active")
        .where("endTime", ">=", admin.firestore.Timestamp.fromDate(in24h))
        .where("endTime", "<=", admin.firestore.Timestamp.fromDate(in25h))
        .get();
    for (const compDoc of nearEndSnap.docs) {
        const comp = compDoc.data();
        const participantsSnap = await compDoc.ref
            .collection("participants")
            .get();
        for (const pDoc of participantsSnap.docs) {
            const userSnap = await admin
                .firestore()
                .collection("users")
                .doc(pDoc.id)
                .get();
            const fcmToken = userSnap.data()?.fcmToken;
            if (!fcmToken)
                continue;
            admin.messaging().send({
                token: fcmToken,
                notification: {
                    title: "Final 24 Hours! ⏰",
                    body: `${comp.name} ends in less than 24 hours. Spell more words to climb the leaderboard!`,
                },
                data: {
                    type: "final_24h",
                    competitionId: compDoc.id,
                },
            }).catch((err) => {
                functions.logger.warn("FCM final24h send failed", { error: err.message });
            });
        }
    }
});
//# sourceMappingURL=notifications.js.map