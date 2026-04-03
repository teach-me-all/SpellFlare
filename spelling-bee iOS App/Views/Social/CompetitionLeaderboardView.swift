//
//  CompetitionLeaderboardView.swift
//  spelling-bee iOS App
//
//  Full-screen leaderboard for a competition.
//  Pull-to-refresh, pagination, current user highlighted and pinned at top if outside top 50.
//

import SwiftUI

struct CompetitionLeaderboardView: View {
    @EnvironmentObject var appState: AppState
    let competitionId: String

    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    private var competition: Competition? { CompetitionService.shared.activeCompetition }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.9), Color.indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Button {
                            appState.navigateToCompetitions()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Text("Leaderboard")
                            .font(.headline)
                            .foregroundColor(.white)

                        Spacer()

                        Button {
                            if let comp = competition {
                                shareItems = ["spellflare://join?code=\(comp.inviteCode)" as Any]
                                showShareSheet = true
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                    }

                    if let comp = competition {
                        HStack {
                            Text(comp.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                            Spacer()
                            Label(comp.statusLabel, systemImage: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                if viewModel.isLoading && viewModel.entries.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            // Pinned user row (if outside top 50)
                            if let pinned = viewModel.pinnedUserEntry {
                                Section {
                                    LeaderboardRow(entry: pinned, isPinned: true)
                                    Divider()
                                        .background(Color.white.opacity(0.2))
                                } header: {
                                    Text("YOUR RANK")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.9))
                                }
                            }

                            // Full leaderboard
                            Section {
                                ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { _, entry in
                                    LeaderboardRow(entry: entry, isPinned: false)
                                    if entry.id != viewModel.entries.last?.id {
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                            .padding(.leading, 64)
                                    }
                                }

                                // Load more button
                                if viewModel.hasMore {
                                    Button {
                                        Task { await viewModel.loadNextPage() }
                                    } label: {
                                        HStack {
                                            if viewModel.isLoadingMore {
                                                ProgressView().tint(.white)
                                            } else {
                                                Text("Load More")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                    }
                                }
                            } header: {
                                Text("TOP SPELLERS")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.9))
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.loadLeaderboard(competitionId: competitionId, forceRefresh: true)
                    }
                }

                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.9))
                        .padding(12)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadLeaderboard(competitionId: competitionId)
            viewModel.startAutoRefresh()
            // Fire competition_completed once when viewing a finished competition
            if let comp = competition, comp.isCompleted {
                let userEntry = viewModel.pinnedUserEntry
                    ?? viewModel.entries.first(where: { $0.isCurrentUser })
                if let entry = userEntry {
                    AnalyticsManager.shared.logCompetitionCompleted(
                        rank: entry.rank,
                        totalPlayers: comp.participantCount,
                        coinsEarned: entry.coinsEarned
                    )
                }
            }
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
    }
}

// MARK: - Leaderboard Row

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isPinned: Bool

    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .white.opacity(0.7)
        }
    }

    private var rankIcon: String? {
        switch entry.rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return nil
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Rank
            if let icon = rankIcon {
                Text(icon)
                    .font(.system(size: 22))
                    .frame(width: 36)
            } else {
                Text("#\(entry.rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(rankColor)
                    .frame(width: 36)
            }

            // Avatar
            Text(entry.avatarIcon)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(entry.isCurrentUser ? Color.yellow.opacity(0.25) : Color.white.opacity(0.1))
                )

            // Username
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.system(size: 15, weight: entry.isCurrentUser ? .bold : .medium))
                    .foregroundColor(.white)
                if entry.isCurrentUser {
                    Text("You")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.yellow)
                        .textCase(.uppercase)
                }
            }

            Spacer()

            // Coins
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.yellow)
                Text("\(entry.coinsEarned)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            entry.isCurrentUser
                ? Color.yellow.opacity(0.1)
                : (isPinned ? Color.white.opacity(0.05) : Color.clear)
        )
    }
}
