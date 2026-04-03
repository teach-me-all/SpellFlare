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
exports.distributeRewards = distributeRewards;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
function coinsForRank(rank) {
    if (rank === 1)
        return 500;
    if (rank <= 3)
        return 300;
    return 100;
}
async function distributeRewards(competitionId) {
    const competitionRef = admin
        .firestore()
        .collection("competitions")
        .doc(competitionId);
    const compSnap = await competitionRef.get();
    if (!compSnap.exists)
        return;
    const comp = compSnap.data();
    // Idempotency guard
    if (comp.rewardsDistributed === true) {
        functions.logger.info(`Rewards already distributed for competition ${competitionId}, skipping`);
        return;
    }
    const participantsSnap = await competitionRef
        .collection("participants")
        .orderBy("coinsEarned", "desc")
        .get();
    const total = participantsSnap.docs.length;
    if (total === 0) {
        // Nothing to distribute; still mark as distributed to prevent re-runs
        await competitionRef.update({ rewardsDistributed: true });
        return;
    }
    const top10PercentCount = Math.max(1, Math.ceil(total * 0.1));
    const batch = admin.firestore().batch();
    participantsSnap.docs.slice(0, top10PercentCount).forEach((doc, index) => {
        const rank = index + 1;
        const userId = doc.id;
        // Deterministic reward doc ID → idempotent on double-invoke
        const rewardRef = admin
            .firestore()
            .collection("rewards")
            .doc(userId)
            .collection("earned")
            .doc(`${competitionId}_reward`);
        const reward = {
            competitionId,
            competitionName: comp.name,
            rank,
            totalParticipants: total,
            rewardType: "coins",
            coinsAmount: coinsForRank(rank),
            claimed: false,
            createdAt: admin.firestore.Timestamp.now(),
        };
        batch.set(rewardRef, reward, { merge: false });
    });
    // Mark competition rewards as distributed atomically with reward writes
    batch.update(competitionRef, { rewardsDistributed: true });
    await batch.commit();
    functions.logger.info(`Distributed rewards for competition ${competitionId}: ${top10PercentCount} winners out of ${total}`);
}
//# sourceMappingURL=rewards.js.map