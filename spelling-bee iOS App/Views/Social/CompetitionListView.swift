//
//  CompetitionListView.swift
//  spelling-bee iOS App
//
//  Lists the user's active competitions; entry point for creating/joining.
//  Supports 1 public + up to 4 private competitions simultaneously.
//

import SwiftUI

struct CompetitionListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CompetitionViewModel()
    @State private var showJoinSheet = false
    @State private var showCreateSheet = false
    @State private var showHistory = false
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

                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 4)

                    Button {
                        appState.navigateToFriends()
                    } label: {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 4)
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

                            // Slot indicator bar
                            SlotsIndicatorView(
                                publicCount: viewModel.allCompetitions.filter { $0.type == .public }.count,
                                privateCount: viewModel.allCompetitions.filter { $0.type == .private }.count
                            )
                            .padding(.top, 4)

                            // Competition cards
                            if viewModel.allCompetitions.isEmpty {
                                // Empty state
                                VStack(spacing: 16) {
                                    Text("🏆")
                                        .font(.system(size: 56))
                                    VStack(spacing: 8) {
                                        Text("No Active Competitions")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text("Join a public competition or create a private one with friends to earn special rewards!")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.75))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 32)
                                    }
                                }
                                .padding(.top, 16)
                            } else {
                                ForEach(viewModel.allCompetitions) { comp in
                                    ActiveCompetitionCard(competition: comp) {
                                        appState.navigateToLeaderboard(competitionId: comp.id)
                                    } onLeave: {
                                        Task { await viewModel.leaveCompetition(id: comp.id) }
                                    }
                                }
                            }

                            // Action buttons (shown when slots are available)
                            VStack(spacing: 12) {
                                if viewModel.canJoinPublic {
                                    CompButton(title: "Join Public Competition", icon: "globe") {
                                        if FirebaseManager.shared.isSignedIn {
                                            Task {
                                                await viewModel.joinPublicMatchmaking(
                                                    username: appState.profile?.name ?? "Speller",
                                                    avatarIcon: appState.profile?.avatarIcon ?? "🐝"
                                                )
                                                if let comp = viewModel.activeCompetition {
                                                    appState.navigateToLeaderboard(competitionId: comp.id)
                                                }
                                            }
                                        } else {
                                            showOnboarding = true
                                        }
                                    }
                                }

                                if viewModel.canJoinPrivate {
                                    CompButton(title: "Create Private Competition", icon: "person.2.fill", style: .secondary) {
                                        if FirebaseManager.shared.isSignedIn {
                                            showCreateSheet = true
                                        } else {
                                            showOnboarding = true
                                        }
                                    }

                                    CompButton(title: "Join by Invite Code", icon: "link", style: .secondary) {
                                        if FirebaseManager.shared.isSignedIn {
                                            showJoinSheet = true
                                        } else {
                                            showOnboarding = true
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, viewModel.allCompetitions.isEmpty ? 8 : 16)
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
        .sheet(isPresented: $showHistory) {
            CompetitionHistoryView()
        }
    }
}

// MARK: - Slots Indicator

private struct SlotsIndicatorView: View {
    let publicCount: Int
    let privateCount: Int

    var body: some View {
        HStack(spacing: 12) {
            SlotPill(
                icon: "globe",
                label: "Public",
                used: publicCount,
                max: CompetitionService.maxPublic,
                color: .cyan
            )
            SlotPill(
                icon: "lock.fill",
                label: "Private",
                used: privateCount,
                max: CompetitionService.maxPrivate,
                color: .yellow
            )
        }
    }
}

private struct SlotPill: View {
    let icon: String
    let label: String
    let used: Int
    let max: Int
    let color: Color

    var isFull: Bool { used >= max }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)

            Text("\(label): \(used)/\(max)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isFull ? color.opacity(0.5) : color)

            if isFull {
                Text("FULL")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(color.opacity(0.6))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(color.opacity(0.15)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(isFull ? 0.2 : 0.4), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active Competition Card

private struct ActiveCompetitionCard: View {
    let competition: Competition
    let onViewLeaderboard: () -> Void
    let onLeave: () -> Void

    @State private var showShareSheet = false
    @State private var showLeaveConfirm = false

    private var inviteLink: String {
        "spellflare://join?code=\(competition.inviteCode)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(competition.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)

                        Text(competition.type == .public ? "PUBLIC" : "PRIVATE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(competition.type == .public ? .cyan : .yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(competition.type == .public ? Color.cyan.opacity(0.2) : Color.yellow.opacity(0.2))
                            )
                    }

                    Text(competition.statusLabel)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(competition.participantCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("players")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(16)

            Divider()
                .background(Color.white.opacity(0.2))

            // Bottom row
            HStack(spacing: 10) {
                Button("Leaderboard", action: onViewLeaderboard)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white))

                Button {
                    showShareSheet = true
                    AnalyticsManager.shared.logInviteSent()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12))
                        Text("Invite")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.2)))
                }

                Spacer()

                Button {
                    showLeaveConfirm = true
                } label: {
                    Text("Leave")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .confirmationDialog(
                    "Leave \(competition.name)?",
                    isPresented: $showLeaveConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Leave Competition", role: .destructive) { onLeave() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Your spot and leaderboard coins will be lost. Your personal coins are not affected. You can rejoin but will start from 0 competition coins.")
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            competition.type == .public ? Color.cyan.opacity(0.3) : Color.yellow.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [inviteLink])
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
