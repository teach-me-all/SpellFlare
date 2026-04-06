import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { ParticipantDoc, CompetitionDoc } from "./types";

// MARK: - Anti-spam cooldown helpers

const COOLDOWN_MS = 2 * 60 * 60 * 1000; // 2 hours

/** Returns true if this user hasn't received a notification in the last 2 hours. */
async function isCooledDown(userId: string): Promise<boolean> {
  const snap = await admin.firestore().collection("users").doc(userId).get();
  const last = snap.data()?.lastNotificationAt as admin.firestore.Timestamp | undefined;
  if (!last) return true;
  return Date.now() - last.toMillis() >= COOLDOWN_MS;
}

/** Stamps lastNotificationAt on the user doc. Call in .then() after a successful FCM send. */
async function markNotificationSent(userId: string): Promise<void> {
  await admin.firestore().collection("users").doc(userId).update({
    lastNotificationAt: admin.firestore.Timestamp.now(),
  });
}

// MARK: - Scheduled: check rank changes every 15 minutes

export const checkRankChanges = functions.pubsub
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

      if (participantsSnap.empty) continue;

      const batch = admin.firestore().batch();
      const notifications: Array<{ token: string; body: string; competitionId: string; userId: string }> = [];

      for (let i = 0; i < participantsSnap.docs.length; i++) {
        const doc = participantsSnap.docs[i];
        const participant = doc.data() as ParticipantDoc;
        const currentRank = i + 1;
        const prevRank = participant.prevRank;

        if (prevRank !== undefined && currentRank > prevRank && !participant.isBot) {
          const userSnap = await admin.firestore().collection("users").doc(doc.id).get();
          const fcmToken = userSnap.data()?.fcmToken as string | undefined;
          if (fcmToken && await isCooledDown(doc.id)) {
            notifications.push({
              token: fcmToken,
              body: `You dropped to #${currentRank} in your spelling competition!`,
              competitionId: compDoc.id,
              userId: doc.id,
            });
          }
        }

        batch.update(doc.ref, { prevRank: currentRank });
      }

      await batch.commit();

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
          apns: { payload: { aps: { sound: "default" } } },
        })
          .then(() => markNotificationSent(notif.userId))
          .catch((err: Error) => {
            functions.logger.warn("FCM rank_drop send failed", { error: err.message });
          });
      }
    }
  });

// MARK: - Scheduled: notify users 24 hours before competition ends

export const notifyFinal24Hours = functions.pubsub
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
      const comp = compDoc.data() as CompetitionDoc;
      const participantsSnap = await compDoc.ref.collection("participants").get();

      for (const pDoc of participantsSnap.docs) {
        const pData = pDoc.data() as ParticipantDoc;
        if (pData.isBot) continue;

        const userSnap = await admin.firestore().collection("users").doc(pDoc.id).get();
        const fcmToken = userSnap.data()?.fcmToken as string | undefined;
        if (!fcmToken) continue;
        if (!await isCooledDown(pDoc.id)) continue;

        admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "Final 24 Hours! ⏰",
            body: `${comp.name} ends soon. Spell more words to climb the leaderboard!`,
          },
          data: {
            type: "final_24h",
            competitionId: compDoc.id,
          },
          apns: { payload: { aps: { sound: "default" } } },
        })
          .then(() => markNotificationSent(pDoc.id))
          .catch((err: Error) => {
            functions.logger.warn("FCM final_24h send failed", { error: err.message });
          });
      }
    }
  });

// MARK: - Reward won notification (called from rewards.ts, not a Cloud Function endpoint)

export async function notifyRewardWon(
  competitionId: string,
  competitionName: string,
  winnerUserIds: string[]
): Promise<void> {
  for (const userId of winnerUserIds) {
    const userSnap = await admin.firestore().collection("users").doc(userId).get();
    const fcmToken = userSnap.data()?.fcmToken as string | undefined;
    if (!fcmToken) continue;
    if (!await isCooledDown(userId)) continue;

    admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "You won a reward! 🎉",
        body: `You finished in the top 10% of ${competitionName}. Claim your coins!`,
      },
      data: {
        type: "reward_won",
        competitionId,
      },
      apns: { payload: { aps: { sound: "default" } } },
    })
      .then(() => markNotificationSent(userId))
      .catch((err: Error) => {
        functions.logger.warn("FCM reward_won send failed", { error: err.message, userId });
      });
  }
}

// MARK: - Scheduled: nudge inactive users every hour

export const checkInactiveUsers = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    const TWENTY_FOUR_HOURS_MS = 24 * 60 * 60 * 1000;
    const FORTY_EIGHT_HOURS_MS = 48 * 60 * 60 * 1000;

    const activeSnap = await admin
      .firestore()
      .collection("competitions")
      .where("status", "==", "active")
      .get();

    for (const compDoc of activeSnap.docs) {
      const participantsSnap = await compDoc.ref.collection("participants").get();

      for (const pDoc of participantsSnap.docs) {
        const pData = pDoc.data() as ParticipantDoc;
        if (pData.isBot) continue;

        const userSnap = await admin.firestore().collection("users").doc(pDoc.id).get();
        const userData = userSnap.data();
        const fcmToken = userData?.fcmToken as string | undefined;
        if (!fcmToken) continue;

        const lastActive = userData?.lastActiveAt as admin.firestore.Timestamp | undefined;
        if (!lastActive) continue;

        const inactiveMs = Date.now() - lastActive.toMillis();
        // Only nudge users inactive between 6–12 hours (one nudge per idle stretch)
        if (inactiveMs < TWENTY_FOUR_HOURS_MS || inactiveMs > FORTY_EIGHT_HOURS_MS) continue;

        if (!await isCooledDown(pDoc.id)) continue;

        admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "You're falling behind! 😬",
            body: "Jump back in and climb the leaderboard!",
          },
          data: {
            type: "inactive_user",
            competitionId: compDoc.id,
          },
          apns: { payload: { aps: { sound: "default" } } },
        })
          .then(() => markNotificationSent(pDoc.id))
          .catch((err: Error) => {
            functions.logger.warn("FCM inactive_user send failed", { error: err.message });
          });
      }
    }
  });
