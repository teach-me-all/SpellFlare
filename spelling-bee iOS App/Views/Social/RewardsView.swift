//
//  RewardsView.swift
//  spelling-bee iOS App
//
//  Shows unclaimed competition rewards and allows claiming them.
//  Rewards are awarded coins to the local UserProfile.
//

import SwiftUI

struct RewardsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var rewards: [CompetitionReward] = []
    @State private var isLoading = false
    @State private var claimingId: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else if rewards.isEmpty {
                    VStack(spacing: 16) {
                        Text("🏅")
                            .font(.system(size: 56))
                        Text("No Rewards Yet")
                            .font(.headline)
                        Text("Finish in the top 10% of a competition to earn rewards!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List(rewards) { reward in
                        RewardRow(reward: reward, isClaiming: claimingId == reward.id) {
                            Task { await claimReward(reward) }
                        }
                    }
                }
            }
            .navigationTitle("Rewards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await loadRewards()
        }
    }

    private func loadRewards() async {
        guard let uid = FirebaseManager.shared.currentUID else { return }
        isLoading = true
        rewards = (try? await CompetitionService.shared.fetchUnclaimedRewards(uid: uid)) ?? []
        isLoading = false
    }

    private func claimReward(_ reward: CompetitionReward) async {
        guard let uid = FirebaseManager.shared.currentUID else { return }
        claimingId = reward.id

        do {
            try await CompetitionService.shared.claimReward(reward, uid: uid)
            // Award coins to local profile
            appState.awardCoins(reward.coinsAmount)
            // Remove from list
            rewards.removeAll { $0.id == reward.id }
        } catch {
            // Keep in list if claim fails
        }

        claimingId = nil
    }
}

// MARK: - Reward Row

private struct RewardRow: View {
    let reward: CompetitionReward
    let isClaiming: Bool
    let onClaim: () -> Void

    var rankLabel: String {
        switch reward.rank {
        case 1: return "🥇 1st Place"
        case 2: return "🥈 2nd Place"
        case 3: return "🥉 3rd Place"
        default: return "#\(reward.rank) Place"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Trophy icon
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 50, height: 50)
                Text(reward.rank <= 3 ? ["🥇","🥈","🥉"][reward.rank - 1] : "🏅")
                    .font(.system(size: 26))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.competitionName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                Text(rankLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text("of \(reward.totalParticipants) spellers")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Claim button
            Button {
                onClaim()
            } label: {
                if isClaiming {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 72)
                } else {
                    Text("+\(reward.coinsAmount)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.purple))
                }
            }
            .disabled(isClaiming)
        }
        .padding(.vertical, 4)
    }
}
