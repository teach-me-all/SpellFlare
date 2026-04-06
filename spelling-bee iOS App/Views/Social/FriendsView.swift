//
//  FriendsView.swift
//  spelling-bee iOS App
//
//  Friends list with search, pending requests, and accepted friends.
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = FriendsViewModel()
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

                    Text("Friends")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    // Placeholder for alignment
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.6))

                    TextField("Search by username", text: $viewModel.searchQuery)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundColor(.white)
                        .font(.system(size: 15))

                    if viewModel.isSearching {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else if !viewModel.searchQuery.isEmpty {
                        Button {
                            viewModel.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Search results
                        if !viewModel.searchResults.isEmpty {
                            SectionHeader(title: "Search Results")
                            ForEach(viewModel.searchResults) { user in
                                SearchResultRow(user: user) {
                                    Task {
                                        await viewModel.sendRequest(
                                            to: user,
                                            myUsername: appState.profile?.name ?? "",
                                            myAvatarIcon: appState.profile?.avatarIcon ?? "🐝"
                                        )
                                    }
                                }
                            }
                        }

                        // Pending requests
                        if !viewModel.pendingRequests.isEmpty {
                            SectionHeader(title: "Friend Requests")
                            ForEach(viewModel.pendingRequests) { request in
                                FriendRequestRow(friend: request) {
                                    Task { await viewModel.acceptRequest(request) }
                                } onReject: {
                                    Task { await viewModel.rejectRequest(request) }
                                }
                            }
                        }

                        // Accepted friends
                        if !viewModel.friends.filter({ $0.status == .accepted }).isEmpty {
                            SectionHeader(title: "Friends")
                            ForEach(viewModel.friends.filter { $0.status == .accepted }) { friend in
                                FriendRow(friend: friend) {
                                    Task { await viewModel.removeFriend(friend) }
                                } onTap: {
                                    appState.navigateToUserProfile(userId: friend.id, username: friend.username)
                                }
                            }
                        }

                        // Empty state
                        if viewModel.friends.isEmpty && viewModel.pendingRequests.isEmpty && viewModel.searchQuery.isEmpty {
                            VStack(spacing: 16) {
                                Text("👋")
                                    .font(.system(size: 48))
                                Text("No friends yet")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Search for friends by username to add them.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        }
                    }
                    .padding(.bottom, 20)
                }

                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
            }
        }
        .task {
            // Sign in + load if not already
            if appState.profile != nil {
                if !FirebaseManager.shared.isSignedIn {
                    showOnboarding = true
                } else {
                    if let uid = FirebaseManager.shared.currentUID {
                        _ = try? await FriendsService.shared.fetchAcceptedFriends(uid: uid)
                    }
                    await viewModel.load()
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            SocialOnboardingView()
                .onDisappear {
                    Task { await viewModel.load() }
                }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Supporting Views

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.6))
            .textCase(.uppercase)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 6)
    }
}

private struct SearchResultRow: View {
    let user: UserSearchResult
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(user.avatarIcon)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.15)))

            Text(user.username)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Button("Add", action: onAdd)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.purple)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

private struct FriendRequestRow: View {
    let friend: Friend
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(friend.avatarIcon)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.15)))

            Text(friend.username)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            HStack(spacing: 8) {
                Button(action: onReject) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }

                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.green))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

private struct FriendRow: View {
    let friend: Friend
    let onRemove: () -> Void
    let onTap: () -> Void
    @State private var showRemoveConfirm = false

    var body: some View {
        HStack(spacing: 12) {
            Text(friend.avatarIcon)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.15)))

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.username)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Text("View profile →")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .swipeActions(edge: .trailing) {
            Button("Remove", role: .destructive, action: onRemove)
        }
    }
}
