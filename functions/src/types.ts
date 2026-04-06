export interface UserDoc {
  username: string;
  avatarIcon: string;
  profileId: string;
  totalCoins: number;
  fcmToken?: string;
  createdAt: FirebaseFirestore.Timestamp;
  lastActiveAt: FirebaseFirestore.Timestamp;
  lastNotificationAt?: FirebaseFirestore.Timestamp;
}

export interface FriendEntry {
  status: "pending_sent" | "pending_received" | "accepted";
  username: string;
  avatarIcon: string;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface CompetitionDoc {
  type: "private" | "public";
  name: string;
  status: "waiting" | "active" | "completed";
  startTime: FirebaseFirestore.Timestamp;
  endTime: FirebaseFirestore.Timestamp;
  createdBy: string;
  maxPlayers: number;
  inviteCode: string;
  participantCount: number;
  rewardsDistributed: boolean;
}

export interface ParticipantDoc {
  userId: string;
  username: string;
  avatarIcon: string;
  coinsEarned: number;
  lastUpdatedAt: FirebaseFirestore.Timestamp;
  joinedAt: FirebaseFirestore.Timestamp;
  prevRank?: number;
  isBot?: boolean;
}

export interface BotDoc {
  userId: string;
  username: string;
  avatarIcon: string;
  isAvailable: boolean;
  currentCompetitionId?: string;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface RewardDoc {
  competitionId: string;
  competitionName: string;
  rank: number;
  totalParticipants: number;
  rewardType: "coins" | "badge";
  coinsAmount: number;
  claimed: boolean;
  createdAt: FirebaseFirestore.Timestamp;
}
