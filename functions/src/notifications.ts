import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { ParticipantDoc, CompetitionDoc } from "./types";

// Scheduled: check rank changes every 15 minutes and notify users who dropped
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
      const notifications: Array<{ token: string; body: string; competitionId: string }> = [];

      for (let i = 0; i < participantsSnap.docs.length; i++) {
        const doc = participantsSnap.docs[i];
        const participant = doc.data() as ParticipantDoc;
        const currentRank = i + 1;
        const prevRank = participant.prevRank;

        if (prevRank !== undefined && currentRank > prevRank) {
          // Rank dropped - queue notification
          const userSnap = await admin
            .firestore()
            .collection("users")
            .doc(doc.id)
            .get();
          const fcmToken = userSnap.data()?.fcmToken as string | undefined;
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
        }).catch((err: Error) => {
          functions.logger.warn("FCM send failed", { error: err.message });
        });
      }
    }
  });

// Scheduled: notify users in competitions ending within the next 25 hours (runs hourly)
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
      const participantsSnap = await compDoc.ref
        .collection("participants")
        .get();

      for (const pDoc of participantsSnap.docs) {
        const userSnap = await admin
          .firestore()
          .collection("users")
          .doc(pDoc.id)
          .get();
        const fcmToken = userSnap.data()?.fcmToken as string | undefined;
        if (!fcmToken) continue;

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
        }).catch((err: Error) => {
          functions.logger.warn("FCM final24h send failed", { error: err.message });
        });
      }
    }
  });
