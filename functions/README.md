# SpellFlare Cloud Functions

Firebase Cloud Functions (Node.js 20, TypeScript) for the SpellFlare iOS app.

## Directory Structure

```
functions/
├── src/
│   ├── index.ts          # Exports all functions
│   ├── types.ts          # Shared Firestore document interfaces
│   ├── competitions.ts   # Competition lifecycle & matchmaking
│   ├── coins.ts          # Coin submission
│   ├── users.ts          # User management (username, FCM token)
│   ├── notifications.ts  # Push notifications (all types)
│   └── rewards.ts        # End-of-competition reward distribution
└── README.md
```

## Deploy

```bash
cd functions
npm run build          # Compile TypeScript
cd ..
npx firebase deploy --only functions              # Deploy all
npx firebase deploy --only functions:functionName # Deploy one
```

---

## Push Notifications

All notification logic lives in `src/notifications.ts`. **No app update is required** to change wording, add new notification types, or adjust targeting — everything is server-side.

### How it works

1. The iOS app requests permission and registers an FCM token on first launch after sign-in.
2. The token is stored in `users/{uid}.fcmToken` via the `registerFCMToken` callable.
3. Functions read `fcmToken` from Firestore and send messages via `admin.messaging().send()`.
4. Tapping a notification opens the app and navigates to the competition leaderboard if a `competitionId` is included in the data payload, otherwise to the competitions list.

### Anti-spam cooldown

A shared 2-hour cooldown (`lastNotificationAt` on the user doc) prevents any single user from receiving more than one notification every 2 hours across all types.

| Field | Location | Purpose |
|-------|----------|---------|
| `fcmToken` | `users/{uid}` | Device push token |
| `lastNotificationAt` | `users/{uid}` | Cooldown timestamp |
| `lastActiveAt` | `users/{uid}` | Used by inactivity nudge |

### Existing notification types

| Type | Function | Trigger | Schedule |
|------|----------|---------|---------|
| `rank_drop` | `checkRankChanges` | User drops in leaderboard rank | Every 15 min |
| `final_24h` | `notifyFinal24Hours` | Competition ends within 24 hours | Every 60 min |
| `reward_won` | `notifyRewardWon` | User finishes top 10% | On competition close |
| `inactive_user` | `checkInactiveUsers` | User inactive 24–48 hours | Every 60 min |

---

## Adding a New Notification (no app update needed)

1. Open `src/notifications.ts`.

2. Add your function. Use this pattern:

```typescript
export const myNewNotification = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    // 1. Query the users/competitions you want to target
    const usersSnap = await admin.firestore()
      .collection("users")
      .where("someField", "==", someValue)
      .get();

    for (const userDoc of usersSnap.docs) {
      const fcmToken = userDoc.data()?.fcmToken as string | undefined;
      if (!fcmToken) continue;
      if (!await isCooledDown(userDoc.id)) continue; // respect anti-spam

      admin.messaging().send({
        token: fcmToken,
        notification: {
          title: "Your title here",
          body: "Your message here",
        },
        data: {
          type: "my_new_type",
          competitionId: "optional — include to deep-link to leaderboard",
        },
        apns: { payload: { aps: { sound: "default" } } },
      })
        .then(() => markNotificationSent(userDoc.id)) // stamp cooldown
        .catch((err: Error) => {
          functions.logger.warn("FCM my_new_type send failed", { error: err.message });
        });
    }
  });
```

3. Export it from `src/index.ts`:

```typescript
export { checkRankChanges, notifyFinal24Hours, checkInactiveUsers, myNewNotification } from "./notifications";
```

4. Deploy:

```bash
npm run build && npx firebase deploy --only functions:myNewNotification
```

### Tap navigation (no app update needed for existing screens)

The `data.competitionId` field controls where the notification tap navigates:

| `data` payload | iOS navigates to |
|----------------|-----------------|
| `{ competitionId: "abc123" }` | Competition leaderboard for that competition |
| _(no competitionId)_ | Competitions list |

**An app update is only required if you want a tap to open a brand-new screen that doesn't exist yet in the app.**

### One-off / manual notification

To send a notification to a specific user without a scheduled function, run a script against Firestore directly:

```bash
GOOGLE_APPLICATION_CREDENTIALS=~/.config/firebase/ravitej_sistla_gmail.com_application_default_credentials.json \
  node my-script.js
```

See `/tmp/run-bot-coins.js` for an example of a one-off admin script pattern.
