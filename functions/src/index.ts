import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK once
admin.initializeApp();

// Export all Cloud Functions
export { submitCompetitionCoins } from "./coins";
export {
  closeExpiredCompetitions,
  autoStartWaitingCompetitions,
  joinPublicMatchmaking,
  joinByInviteCode,
  fillSoloCompetitionsWithBots,
  addDailyBotCoins,
} from "./competitions";
export { setUsername, registerFCMToken } from "./users";
export { checkRankChanges, notifyFinal24Hours, checkInactiveUsers } from "./notifications";
