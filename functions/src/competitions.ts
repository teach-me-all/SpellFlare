import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { distributeRewards } from "./rewards";
import { CompetitionDoc, ParticipantDoc } from "./types";

function generateInviteCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // Omit 0/O, 1/I for readability
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
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

    // Check if user is already in an active competition
    const existingParticipation = await admin
      .firestore()
      .collectionGroup("participants")
      .where(admin.firestore.FieldPath.documentId(), "==", userId)
      .get();

    for (const pDoc of existingParticipation.docs) {
      const compRef = pDoc.ref.parent.parent!;
      const compSnap = await compRef.get();
      const comp = compSnap.data() as CompetitionDoc;
      if (comp.status === "active" || comp.status === "waiting") {
        return { competitionId: compRef.id, alreadyJoined: true };
      }
    }

    // Find a waiting public competition with space
    const waitingSnap = await admin
      .firestore()
      .collection("competitions")
      .where("type", "==", "public")
      .where("status", "==", "waiting")
      .where("participantCount", "<", 20)
      .orderBy("participantCount", "desc")
      .limit(1)
      .get();

    let competitionId: string;

    if (!waitingSnap.empty) {
      competitionId = waitingSnap.docs[0].id;
    } else {
      // Create a new public waiting competition
      const startTime = new Date(Date.now() + 60 * 60 * 1000); // starts in 1h
      const endTime = new Date(
        startTime.getTime() + 7 * 24 * 60 * 60 * 1000
      );
      const inviteCode = generateInviteCode();

      const newComp: CompetitionDoc = {
        type: "public",
        name: "Weekly Spelling Bee",
        status: "waiting",
        startTime: admin.firestore.Timestamp.fromDate(startTime),
        endTime: admin.firestore.Timestamp.fromDate(endTime),
        createdBy: userId,
        maxPlayers: 20,
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

    // Auto-start if full (20 players)
    const updatedCompSnap = await admin
      .firestore()
      .collection("competitions")
      .doc(competitionId)
      .get();
    const updatedComp = updatedCompSnap.data() as CompetitionDoc;

    if (updatedComp.participantCount >= 20 && updatedComp.status === "waiting") {
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
