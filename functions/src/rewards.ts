import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { RewardDoc } from "./types";
import { notifyRewardWon } from "./notifications";

function coinsForRank(rank: number): number {
  if (rank === 1) return 500;
  if (rank <= 3) return 300;
  return 100;
}

export async function distributeRewards(competitionId: string): Promise<void> {
  const competitionRef = admin
    .firestore()
    .collection("competitions")
    .doc(competitionId);

  const compSnap = await competitionRef.get();
  if (!compSnap.exists) return;

  const comp = compSnap.data()!;

  // Idempotency guard
  if (comp.rewardsDistributed === true) {
    functions.logger.info(
      `Rewards already distributed for competition ${competitionId}, skipping`
    );
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

  participantsSnap.docs.forEach((doc, index) => {
    const rank = index + 1;
    const userId = doc.id;

    // Store final rank on every participant doc (used for history view)
    const participantRef = competitionRef.collection("participants").doc(userId);
    batch.update(participantRef, { finalRank: rank, totalParticipants: total });

    // Distribute coins reward to top 10%
    if (rank <= top10PercentCount) {
      // Deterministic reward doc ID → idempotent on double-invoke
      const rewardRef = admin
        .firestore()
        .collection("rewards")
        .doc(userId)
        .collection("earned")
        .doc(`${competitionId}_reward`);

      const reward: RewardDoc = {
        competitionId,
        competitionName: comp.name as string,
        rank,
        totalParticipants: total,
        rewardType: "coins",
        coinsAmount: coinsForRank(rank),
        claimed: false,
        createdAt: admin.firestore.Timestamp.now(),
      };

      batch.set(rewardRef, reward, { merge: false });
    }
  });

  // Mark competition rewards as distributed atomically with reward writes
  batch.update(competitionRef, { rewardsDistributed: true });

  await batch.commit();

  functions.logger.info(
    `Distributed rewards for competition ${competitionId}: ${top10PercentCount} winners out of ${total}`
  );

  // Notify top-10% winners (fire-and-forget — never block reward distribution)
  const winnerIds = participantsSnap.docs
    .slice(0, top10PercentCount)
    .filter(d => !d.data().isBot)
    .map(d => d.id);

  if (winnerIds.length > 0) {
    notifyRewardWon(competitionId, comp.name as string, winnerIds).catch(err =>
      functions.logger.warn("notifyRewardWon failed", { error: String(err) })
    );
  }

  // Return bots to the pool so they can join future competitions
  const botParticipants = participantsSnap.docs.filter(d => d.data().isBot === true);
  if (botParticipants.length > 0) {
    const returnBatch = admin.firestore().batch();
    for (const p of botParticipants) {
      const botRef = admin.firestore().collection("bots").doc(p.id);
      returnBatch.update(botRef, {
        isAvailable: true,
        currentCompetitionId: admin.firestore.FieldValue.delete(),
      });
    }
    await returnBatch.commit();
    functions.logger.info(
      `Returned ${botParticipants.length} bots to pool from competition ${competitionId}`
    );
  }
}
