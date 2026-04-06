import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { distributeRewards } from "./rewards";
import { BotDoc, CompetitionDoc, ParticipantDoc } from "./types";

function generateInviteCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // Omit 0/O, 1/I for readability
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

// MARK: - Bot pool helpers

/**
 * Fetch available bots from the persistent bot pool.
 * Returns up to `limit` bots that are not currently in any active competition.
 */
async function fetchAvailableBots(limit: number): Promise<FirebaseFirestore.QueryDocumentSnapshot[]> {
  const snap = await admin
    .firestore()
    .collection("bots")
    .where("isAvailable", "==", true)
    .limit(limit)
    .get();
  return snap.docs;
}

// Scheduled: run every 60 minutes to close expired competitions and distribute rewards
export const closeExpiredCompetitions = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    const expiredSnap = await admin
      .firestore()
      .collection("competitions")
      .where("status", "==", "active")
      .where("endTime", "<=", now)
      .get();

    if (expiredSnap.empty) {
      functions.logger.info("No expired competitions to close");
      return;
    }

    functions.logger.info(
      `Closing ${expiredSnap.docs.length} expired competition(s)`
    );

    // Mark all as completed
    const batch = admin.firestore().batch();
    for (const doc of expiredSnap.docs) {
      batch.update(doc.ref, { status: "completed" });
    }
    await batch.commit();

    // Distribute rewards for each (serial to avoid overwhelming writes)
    for (const doc of expiredSnap.docs) {
      await distributeRewards(doc.id);
    }
  });

// Scheduled: auto-start waiting competitions that have been sitting >1h with ≥2 players
export const autoStartWaitingCompetitions = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const cutoff = admin.firestore.Timestamp.fromDate(oneHourAgo);

    const waitingSnap = await admin
      .firestore()
      .collection("competitions")
      .where("status", "==", "waiting")
      .where("startTime", "<=", cutoff)
      .get();

    if (waitingSnap.empty) return;

    const batch = admin.firestore().batch();
    const now = new Date();
    const endTime = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    for (const doc of waitingSnap.docs) {
      const comp = doc.data() as CompetitionDoc;
      if (comp.participantCount >= 2) {
        batch.update(doc.ref, {
          status: "active",
          startTime: admin.firestore.Timestamp.fromDate(now),
          endTime: admin.firestore.Timestamp.fromDate(endTime),
        });
      }
    }

    await batch.commit();
  });

// Callable: find or create a public competition and join it
export const joinPublicMatchmaking = functions.https.onCall(
  async (
    data: { username: string; avatarIcon: string },
    context
  ) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required"
      );
    }

    const userId = context.auth.uid;
    const { username, avatarIcon } = data;

    if (!username || username.length < 3) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Username required"
      );
    }

    const LATE_JOIN_WINDOW_MS = 3 * 24 * 60 * 60 * 1000; // 3 days in ms
    const threeDaysAgo = new Date(Date.now() - LATE_JOIN_WINDOW_MS);

    // 1. Find a waiting public competition with space
    const waitingSnap = await admin
      .firestore()
      .collection("competitions")
      .where("type", "==", "public")
      .where("status", "==", "waiting")
      .where("participantCount", "<", 100)
      .orderBy("participantCount", "desc")
      .limit(1)
      .get();

    let competitionId: string;
    let joiningActiveCompetition = false;

    if (!waitingSnap.empty) {
      competitionId = waitingSnap.docs[0].id;
    } else {
      // 2. Find an active public competition started within the last 3 days with space
      const activeSnap = await admin
        .firestore()
        .collection("competitions")
        .where("type", "==", "public")
        .where("status", "==", "active")
        .where("participantCount", "<", 100)
        .orderBy("participantCount", "desc")
        .limit(5)
        .get();

      const recentActive = activeSnap.docs.find((doc) => {
        const startTime = doc.data().startTime?.toDate() as Date | undefined;
        return startTime && startTime >= threeDaysAgo;
      });

      if (recentActive) {
        // Late join allowed — competition started less than 3 days ago
        competitionId = recentActive.id;
        joiningActiveCompetition = true;
      } else {
        // 3. No suitable competition found — create a new one
        const startTime = new Date(Date.now() + 60 * 60 * 1000); // starts in 1h
        const endTime = new Date(startTime.getTime() + 7 * 24 * 60 * 60 * 1000);
        const inviteCode = generateInviteCode();

        const newComp: CompetitionDoc = {
          type: "public",
          name: "Weekly Spelling Bee",
          status: "waiting",
          startTime: admin.firestore.Timestamp.fromDate(startTime),
          endTime: admin.firestore.Timestamp.fromDate(endTime),
          createdBy: userId,
          maxPlayers: 100,
          inviteCode,
          participantCount: 0,
          rewardsDistributed: false,
        };

        const newCompRef = await admin
          .firestore()
          .collection("competitions")
          .add(newComp);
        competitionId = newCompRef.id;
      }
    }

    // Add participant atomically
    await admin.firestore().runTransaction(async (tx) => {
      const compRef = admin
        .firestore()
        .collection("competitions")
        .doc(competitionId);
      const participantRef = compRef.collection("participants").doc(userId);

      const participantSnap = await tx.get(participantRef);
      if (participantSnap.exists) return; // Already joined

      const participant: ParticipantDoc = {
        userId,
        username,
        avatarIcon,
        coinsEarned: 0,
        joinedAt: admin.firestore.Timestamp.now(),
        lastUpdatedAt: admin.firestore.Timestamp.now(),
      };

      tx.set(participantRef, participant);
      tx.update(compRef, {
        participantCount: admin.firestore.FieldValue.increment(1),
      });
    });

    // Auto-start only if joining a waiting competition with ≥2 players
    if (!joiningActiveCompetition) {
      const updatedCompSnap = await admin
        .firestore()
        .collection("competitions")
        .doc(competitionId)
        .get();
      const updatedComp = updatedCompSnap.data() as CompetitionDoc;

      if (updatedComp.participantCount >= 2 && updatedComp.status === "waiting") {
        const now = new Date();
        const endTime = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
        await admin
          .firestore()
          .collection("competitions")
          .doc(competitionId)
          .update({
            status: "active",
            startTime: admin.firestore.Timestamp.fromDate(now),
            endTime: admin.firestore.Timestamp.fromDate(endTime),
          });
      }
    }

    return { competitionId, alreadyJoined: false };
  }
);

// Callable: join a private competition by invite code
export const joinByInviteCode = functions.https.onCall(
  async (
    data: { inviteCode: string; username: string; avatarIcon: string },
    context
  ) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required"
      );
    }

    const userId = context.auth.uid;
    const { inviteCode, username, avatarIcon } = data;

    const compSnap = await admin
      .firestore()
      .collection("competitions")
      .where("inviteCode", "==", inviteCode.toUpperCase())
      .limit(1)
      .get();

    if (compSnap.empty) {
      throw new functions.https.HttpsError(
        "not-found",
        "Invalid invite code"
      );
    }

    const compDoc = compSnap.docs[0];
    const comp = compDoc.data() as CompetitionDoc;

    if (comp.status === "completed") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Competition has already ended"
      );
    }

    if (comp.participantCount >= comp.maxPlayers) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Competition is full"
      );
    }

    const competitionId = compDoc.id;

    await admin.firestore().runTransaction(async (tx) => {
      const compRef = admin
        .firestore()
        .collection("competitions")
        .doc(competitionId);
      const participantRef = compRef.collection("participants").doc(userId);

      const participantSnap = await tx.get(participantRef);
      if (participantSnap.exists) return; // Already joined

      const participant: ParticipantDoc = {
        userId,
        username,
        avatarIcon,
        coinsEarned: 0,
        joinedAt: admin.firestore.Timestamp.now(),
        lastUpdatedAt: admin.firestore.Timestamp.now(),
      };

      tx.set(participantRef, participant);
      tx.update(compRef, {
        participantCount: admin.firestore.FieldValue.increment(1),
      });
    });

    return { competitionId };
  }
);

// Scheduled: hourly — fill public competitions that need bots using the persistent bot pool.
// Bots are drawn from the `bots` collection (isAvailable == true), added to the competition,
// and marked unavailable. They are returned to the pool when the competition ends.
export const fillSoloCompetitionsWithBots = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    // Waiting competitions where ≥1h has elapsed
    const waitingSnap = await admin
      .firestore()
      .collection("competitions")
      .where("type", "==", "public")
      .where("status", "==", "waiting")
      .where("startTime", "<=", now)
      .get();

    // Active competitions that may have started before bots were added
    const activeSnap = await admin
      .firestore()
      .collection("competitions")
      .where("type", "==", "public")
      .where("status", "==", "active")
      .get();

    const allDocs = [...waitingSnap.docs, ...activeSnap.docs];
    if (allDocs.length === 0) return;

    for (const compDoc of allDocs) {
      const participantsSnap = await compDoc.ref.collection("participants").get();
      let realPlayerCount = 0;
      let botCount = 0;

      for (const p of participantsSnap.docs) {
        const pData = p.data() as ParticipantDoc;
        if (pData.isBot) botCount++; else realPlayerCount++;
      }

      if (realPlayerCount === 0) {
        if (compDoc.data().status === "waiting") {
          const nextHour = new Date(Date.now() + 60 * 60 * 1000);
          await compDoc.ref.update({
            startTime: admin.firestore.Timestamp.fromDate(nextHour),
          });
          functions.logger.info(`Bumped startTime for empty competition ${compDoc.id}`);
        }
        continue;
      }

      if (realPlayerCount + botCount >= 40) continue;

      // Draw available bots from the pool — random count 20-50
      const availableBotDocs = await fetchAvailableBots(50);
      if (availableBotDocs.length === 0) {
        functions.logger.info("Bot pool exhausted — skipping fill for " + compDoc.id);
        continue;
      }

      const targetCount = Math.floor(Math.random() * 31) + 20; // 20–50
      const selectedBots = availableBotDocs.slice(0, Math.min(targetCount, availableBotDocs.length));

      functions.logger.info(
        `Filling competition ${compDoc.id} with ${selectedBots.length} pool bots (${realPlayerCount} real, ${botCount} existing bots)`
      );

      const joinedAt = admin.firestore.Timestamp.now();
      const batch = admin.firestore().batch();

      for (const botDoc of selectedBots) {
        const bot = botDoc.data() as BotDoc;

        // Add bot as participant
        batch.set(
          compDoc.ref.collection("participants").doc(bot.userId),
          {
            userId: bot.userId,
            username: bot.username,
            avatarIcon: bot.avatarIcon,
            coinsEarned: 0,
            isBot: true,
            joinedAt,
            lastUpdatedAt: joinedAt,
          } as ParticipantDoc
        );

        // Mark bot unavailable
        batch.update(botDoc.ref, {
          isAvailable: false,
          currentCompetitionId: compDoc.id,
        });
      }

      const updateFields: Record<string, any> = {
        participantCount: admin.firestore.FieldValue.increment(selectedBots.length),
      };

      if (compDoc.data().status === "waiting") {
        const startTime = new Date();
        const endTime = new Date(startTime.getTime() + 7 * 24 * 60 * 60 * 1000);
        updateFields.status = "active";
        updateFields.startTime = admin.firestore.Timestamp.fromDate(startTime);
        updateFields.endTime = admin.firestore.Timestamp.fromDate(endTime);
      }

      batch.update(compDoc.ref, updateFields);
      await batch.commit();
    }
  });

// Scheduled: every 24 hours — add random 100–1000 coins to every bot in active competitions
// Keeps the leaderboard dynamic so real players stay engaged.
export const addDailyBotCoins = functions.pubsub
  .schedule("every 6 hours")
  .onRun(async () => {
    const activeSnap = await admin
      .firestore()
      .collection("competitions")
      .where("status", "==", "active")
      .get();

    if (activeSnap.empty) return;

    for (const compDoc of activeSnap.docs) {
      const participantsSnap = await compDoc.ref.collection("participants").get();
      const batch = admin.firestore().batch();
      let updatedCount = 0;

      for (const pDoc of participantsSnap.docs) {
        const pData = pDoc.data() as ParticipantDoc;
        if (!pData.isBot) continue;

        const coins = Math.floor(Math.random() * 151) + 100; // 100–250
        batch.update(pDoc.ref, {
          coinsEarned: admin.firestore.FieldValue.increment(coins),
          lastUpdatedAt: admin.firestore.Timestamp.now(),
        });
        updatedCount++;
      }

      if (updatedCount > 0) {
        await batch.commit();
        functions.logger.info(
          `Added daily coins to ${updatedCount} bots in competition ${compDoc.id}`
        );
      }
    }
  });
