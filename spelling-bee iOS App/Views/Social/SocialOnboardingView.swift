//
//  SocialOnboardingView.swift
//  spelling-bee iOS App
//
//  Shown the first time a user opens social features.
//  Prompts them to choose a username and signs them in anonymously.
//

import SwiftUI

struct SocialOnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var isCheckingAvailability = false
    @State private var isUsernameTaken = false
    @State private var isSubmitting = false
    @State private var error: String?

    private var isUsernameValid: Bool {
        guard username.count >= 3, username.count <= 20 else { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        return username.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.indigo],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Icon
                    Text("🏆")
                        .font(.system(size: 64))

                    VStack(spacing: 12) {
                        Text("Join Competitions")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Choose a username to compete with friends and other spellers!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Username field
                    VStack(spacing: 8) {
                        HStack {
                            TextField("Username (e.g. SpellBee42)", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                                .onChange(of: username) { _ in
                                    checkAvailability()
                                }

                            if isCheckingAvailability {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else if isUsernameValid {
                                Image(systemName: isUsernameTaken ? "xmark.circle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(isUsernameTaken ? .red : .green)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)

                        if !username.isEmpty && !isUsernameValid {
                            Text("3-20 characters: letters, numbers, underscores")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        } else if isUsernameTaken {
                            Text("Username already taken")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.9))
                        }

                        if let error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 32)

                    // Submit button
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.purple)
                                    .padding(.trailing, 4)
                            }
                            Text("Get Started")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isUsernameValid && !isUsernameTaken ? Color.white : Color.white.opacity(0.4))
                        .foregroundColor(isUsernameValid && !isUsernameTaken ? .purple : .white.opacity(0.6))
                        .cornerRadius(16)
                    }
                    .disabled(!isUsernameValid || isUsernameTaken || isSubmitting)
                    .padding(.horizontal, 32)

                    Spacer()

                    Text("No email required. Your username is how other players see you.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func checkAvailability() {
        guard isUsernameValid else {
            isUsernameTaken = false
            return
        }

        isCheckingAvailability = true
        Task {
            do {
                let uid = FirebaseManager.shared.currentUID ?? ""
                let taken = try await FriendsService.shared.isUsernameTaken(username, excludingUID: uid)
                await MainActor.run {
                    isUsernameTaken = taken
                    isCheckingAvailability = false
                }
            } catch {
                await MainActor.run { isCheckingAvailability = false }
            }
        }
    }

    private func submit() async {
        guard isUsernameValid, !isUsernameTaken else { return }
        guard let profile = appState.profile else { return }

        isSubmitting = true
        error = nil

        do {
            // Sign in anonymously if not already signed in
            try await FirebaseManager.shared.signIn(for: profile.id)

            guard let uid = FirebaseManager.shared.currentUID else {
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign-in failed"])
            }

            // Set username in Firestore
            try await FriendsService.shared.setUserProfile(
                uid: uid,
                username: username,
                avatarIcon: profile.avatarIcon,
                profileId: profile.id
            )

            dismiss()
        } catch {
            self.error = error.localizedDescription
        }

        isSubmitting = false
    }
}
