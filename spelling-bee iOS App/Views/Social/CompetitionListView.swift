//
//  CompetitionListView.swift
//  spelling-bee iOS App
//
//  Lists the user's active and past competitions; entry point for creating/joining.
//

import SwiftUI

struct CompetitionListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CompetitionViewModel()
    @State private var showJoinSheet = false
    @State private var showCreateSheet = false
    @State private var pendingCode: String = ""
    @State private var showOnboarding = false

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
                HStack {
                    Button {
                        appState.navigateToHome()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text("Competitions")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    // Add competition button
                    Button {
                        if !FirebaseManager.shared.isSignedIn {
                            showOnboarding = true
                        } else {
                            showJoinSheet = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
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
                        VStack(spacing: 16) {
                            // Active competition card
                            if let comp = viewModel.activeCompetition {
                                ActiveCompetitionCard(competition: comp) {
                                    appState.navigateToLeaderboard(competitionId: comp.id)
                                } onLeave: {
                                    Task { await viewModel.leaveCompetition() }
                                }
                            }

                            // Empty state
                            if !viewModel.isInCompetition {
                                VStack(spacing: 20) {
                                    Text("🏆")
                                        .font(.system(size: 56))

                                    VStack(spacing: 8) {
                                        Text("No Active Competition")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)

                                        Text("Compete with friends or join a public competition to earn special rewards!")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.75))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 32)
                                    }

                                    VStack(spacing: 12) {
                                        CompButton(title: "Join Public Competition", icon: "globe") {
                                            if FirebaseManager.shared.isSignedIn {
                                                Task {
                                                    await viewModel.joinPublicMatchmaking(
                                                        username: appState.profile?.name ?? "Speller",
                                                        avatarIcon: appState.profile?.avatarIcon ?? "🐝"
                                                    )
                                                }
                                            } else {
                                                showOnboarding = true
                                            }
                                        }

                                        CompButton(title: "Create Private Competition", icon: "person.2.fill", style: .secondary) {
                                            if FirebaseManager.shared.isSignedIn {
                                                showCreateSheet = true
                                            } else {
                                                showOnboarding = true
                                            }
                                        }

                                        CompButton(title: "Join by Invite Code", icon: "link", style: .secondary) {
                                            showJoinSheet = true
                                        }
                                    }
                                    .padding(.horizontal, 32)
                                }
                                .padding(.top, 32)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
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
            // Handle pending invite code from deep link
            if let code = appState.pendingInviteCode {
                pendingCode = code
                appState.pendingInviteCode = nil
                showJoinSheet = true
            }
            await viewModel.loadCompetitions()
        }
        .sheet(isPresented: $showOnboarding) {
            SocialOnboardingView()
                .onDisappear { Task { await viewModel.loadCompetitions() } }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateCompetitionView()
                .onDisappear { Task { await viewModel.loadCompetitions() } }
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinByCodeSheet(prefilledCode: pendingCode) { code in
                Task {
                    await viewModel.joinByCode(
                        code,
                        username: appState.profile?.name ?? "Speller",
                        avatarIcon: appState.profile?.avatarIcon ?? "🐝"
                    )
                }
            }
            .onDisappear { pendingCode = "" }
        }
        .sheet(isPresented: $viewModel.showSocialOnboarding) {
            SocialOnboardingView()
        }
    }
}

// MARK: - Active Competition Card

private struct ActiveCompetitionCard: View {
    let competition: Competition
    let onViewLeaderboard: () -> Void
    let onLeave: () -> Void
    @ObservedObject private var service = CompetitionService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Top row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(competition.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text(competition.statusLabel)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if let rank = service.myRankInActiveCompetition {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("#\(rank)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("Rank")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(16)

            Divider()
                .background(Color.white.opacity(0.2))

            // Bottom row
            HStack(spacing: 16) {
                // Coins
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                    Text("\(service.myCoinsInActiveCompetition) coins")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer()

                // Leaderboard button
                Button("Leaderboard", action: onViewLeaderboard)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white))
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .contextMenu {
            Button("Leave Competition", role: .destructive, action: onLeave)
        }
    }
}

// MARK: - Helpers

private struct CompButton: View {
    enum Style { case primary, secondary }
    let title: String
    let icon: String
    var style: Style = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            .foregroundColor(style == .primary ? .purple : .white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(style == .primary ? Color.white : Color.white.opacity(0.15))
            )
        }
    }
}

// MARK: - Join by Code Sheet

struct JoinByCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var code: String
    let onJoin: (String) -> Void

    init(prefilledCode: String = "", onJoin: @escaping (String) -> Void) {
        _code = State(initialValue: prefilledCode)
        self.onJoin = onJoin
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("🔗")
                    .font(.system(size: 48))
                    .padding(.top, 32)

                VStack(spacing: 8) {
                    Text("Enter Invite Code")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Ask your friend for their 6-character code")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                TextField("e.g. ABC123", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 40)

                Button("Join") {
                    onJoin(code.uppercased())
                    dismiss()
                }
                .disabled(code.count < 6)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()
            }
            .navigationTitle("Join by Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
