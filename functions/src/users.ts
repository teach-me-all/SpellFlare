import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const USERNAME_REGEX = /^[a-zA-Z0-9_]{3,20}$/;

// Callable: set or update a user's username, enforcing uniqueness
export const setUsername = functions.https.onCall(
  async (data: { username: string; avatarIcon?: string }, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required"
      );
    }

    const userId = context.auth.uid;
    const { username, avatarIcon } = data;

    if (!username || !USERNAME_REGEX.test(username)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Username must be 3-20 characters: letters, numbers, and underscores only"
      );
    }

    // Check uniqueness
    let existing;
    try {
      existing = await admin
        .firestore()
        .collection("users")
        .where("username", "==", username)
        .limit(1)
        .get();
    } catch (err) {
      functions.logger.error("Firestore username check failed", { err });
      throw new functions.https.HttpsError(
        "internal",
        "Failed to check username availability: " + String(err)
      );
    }

    if (!existing.empty && existing.docs[0].id !== userId) {
      throw new functions.https.HttpsError(
        "already-exists",
        "Username is already taken"
      );
    }

    const update: Record<string, unknown> = {
      username,
      lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (avatarIcon) {
      update.avatarIcon = avatarIcon;
    }

    // Ensure user doc exists with required fields on first set
    try {
      await admin.firestore().collection("users").doc(userId).set(
        {
          ...update,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    } catch (err) {
      functions.logger.error("Firestore user doc write failed", { err });
      throw new functions.https.HttpsError(
        "internal",
        "Failed to save username: " + String(err)
      );
    }

    return { success: true };
  }
);

// Callable: register or update FCM token for notifications
export const registerFCMToken = functions.https.onCall(
  async (data: { token: string }, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required"
      );
    }

    const userId = context.auth.uid;
    const { token } = data;

    if (!token) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "FCM token required"
      );
    }

    await admin.firestore().collection("users").doc(userId).set(
      { fcmToken: token, lastActiveAt: admin.firestore.Timestamp.now() },
      { merge: true }
    );

    return { success: true };
  }
);
