//
//  UserProfileView.swift
//  spelling-bee iOS App
//
//  Facebook-style public profile page.
//  Shown when tapping a user in the leaderboard or friends list.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var appState: AppState
    let userId: String
    let initialUsername: String

    @StateObject private var viewModel: UserProfileViewModel

    init(userId: String, username: String) {
        self.userId = userId
        self.initialUsername = username
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(userId: userId, username: username))
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.purple.opacity(0.9), Color.indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    Button {
                        appState.navigateBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text("Profile")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            profileHeader
                            statsRow
                            if !viewModel.badges.isEmpty {
                                badgesSection
                            }
                            historySection
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task { await viewModel.load() }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Large avatar
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 90, height: 90)

                Text(viewModel.avatarIcon)
                    .font(.system(size: 50))
            }
            .padding(.top, 8)

            // Username
            Text(viewModel.username)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            // Coins
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
                Text("\(viewModel.totalCoins) coins")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.1)))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            StatCard(value: "\(viewModel.totalCompetitions)", label: "Competitions")
            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 40)
            StatCard(value: viewModel.bestRank.map { "#\($0)" } ?? "—", label: "Best Rank")
            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 40)
            StatCard(value: "\(viewModel.totalCoinsEarned)", label: "Coins Earned")
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 16)
    }

    // MARK: - Badges

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "Achievements")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.badges) { badge in
                        VStack(spacing: 6) {
                            Text(badge.icon)
                                .font(.system(size: 30))
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.white.opacity(0.12)))

                            Text(badge.label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Competition History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(title: "Competition History")
                .padding(.bottom, 4)

            if viewModel.history.isEmpty {
                Text("No completed competitions yet.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.history) { entry in
                        HistoryRow(entry: entry)
                        if entry.id != viewModel.history.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 20)
                        }
                    }
                }
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Supporting views

private struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }
}

private struct HistoryRow: View {
    let entry: CompetitionHistoryEntry

    private var rankText: String {
        guard let rank = entry.myFinalRank else { return "—" }
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }

    private var dateText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        return fmt.string(from: entry.endTime)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Type icon
            Text(entry.type == .public ? "🌐" : "🔒")
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(0.08)))

            // Name + date
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text(dateText)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            // Rank
            Text(rankText)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(minWidth: 36, alignment: .trailing)

            // Coins
            HStack(spacing: 3) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text("\(entry.myCoinsEarned)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
