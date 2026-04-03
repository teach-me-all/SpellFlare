//
//  FriendsViewModel.swift
//  spelling-bee iOS App
//
//  Manages friend list, pending requests, and username search with debouncing.
//

import Foundation
import Combine

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var pendingRequests: [Friend] = []
    @Published var searchResults: [UserSearchResult] = []
    @Published var searchQuery = ""
    @Published var isSearching = false
    @Published var isLoading = false
    @Published var error: String?

    private let service = FriendsService.shared
    private let auth = FirebaseManager.shared
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Debounce search: wait 500ms after last keystroke before querying
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }

    // MARK: - Load

    func load() async {
        guard let uid = auth.currentUID else { return }

        isLoading = true
        error = nil

        do {
            async let friends = service.fetchAcceptedFriends(uid: uid)
            async let pending = service.fetchPendingRequests(uid: uid)
            self.friends = try await friends
            self.pendingRequests = try await pending
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Search

    private func performSearch(query: String) {
        searchTask?.cancel()
        guard query.count >= 3 else {
            searchResults = []
            return
        }

        searchTask = Task {
            isSearching = true
            do {
                if let result = try await service.searchUser(username: query) {
                    // Exclude existing friends and self
                    let myUID = auth.currentUID
                    let friendIDs = Set(friends.map(\.id))
                    if result.id != myUID && !friendIDs.contains(result.id) {
                        searchResults = [result]
                    } else {
                        searchResults = []
                    }
                } else {
                    searchResults = []
                }
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }

    // MARK: - Actions

    func sendRequest(to user: UserSearchResult, myUsername: String, myAvatarIcon: String) async {
        guard let myUID = auth.currentUID else { return }
        error = nil

        do {
            try await service.sendFriendRequest(
                from: myUID,
                myUsername: myUsername,
                myAvatarIcon: myAvatarIcon,
                to: user.id,
                targetUsername: user.username,
                targetAvatarIcon: user.avatarIcon
            )
            // Remove from search results and add to friends as pending
            searchResults.removeAll { $0.id == user.id }
            friends.append(Friend(id: user.id, username: user.username, avatarIcon: user.avatarIcon, status: .pendingSent))
        } catch {
            self.error = error.localizedDescription
        }
    }

    func acceptRequest(_ request: Friend) async {
        guard let myUID = auth.currentUID else { return }
        error = nil

        do {
            try await service.acceptFriendRequest(myUID: myUID, fromUID: request.id)
            pendingRequests.removeAll { $0.id == request.id }
            friends.append(Friend(id: request.id, username: request.username, avatarIcon: request.avatarIcon, status: .accepted))
        } catch {
            self.error = error.localizedDescription
        }
    }

    func rejectRequest(_ request: Friend) async {
        guard let myUID = auth.currentUID else { return }
        error = nil

        do {
            try await service.rejectFriendRequest(myUID: myUID, fromUID: request.id)
            pendingRequests.removeAll { $0.id == request.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeFriend(_ friend: Friend) async {
        guard let myUID = auth.currentUID else { return }
        error = nil

        do {
            try await service.removeFriend(myUID: myUID, friendUID: friend.id)
            friends.removeAll { $0.id == friend.id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
