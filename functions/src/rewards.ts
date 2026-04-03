import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { RewardDoc } from "./types";

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
  });

  // Mark competition rewards as distributed atomically with reward writes
  batch.update(competitionRef, { rewardsDistributed: true });

  await batch.commit();

  functions.logger.info(
    `Distributed rewards for competition ${competitionId}: ${top10PercentCount} winners out of ${total}`
  );
}
