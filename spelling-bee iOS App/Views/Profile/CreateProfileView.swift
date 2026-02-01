//
//  CreateProfileView.swift
//  spelling-bee iOS App
//
//  Form for creating a new player profile.
//

import SwiftUI

struct CreateProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var selectedAvatar = "🐝"
    @State private var selectedGrade = 1

    private let avatars = ProfileManager.avatarOptions

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.95),
                    Color(red: 0.45, green: 0.25, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Back button
                    HStack {
                        Button {
                            if appState.profileManager.allProfiles.isEmpty {
                                appState.currentScreen = .onboarding
                            } else {
                                appState.showProfilePicker()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                    .padding(.top, 8)

                    Text("New Player")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // Avatar preview
                    Text(selectedAvatar)
                        .font(.system(size: 80))

                    // Avatar picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose an Avatar")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                            ForEach(avatars, id: \.self) { avatar in
                                Button {
                                    selectedAvatar = avatar
                                } label: {
                                    Text(avatar)
                                        .font(.system(size: 30))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            selectedAvatar == avatar
                                                ? Color.white.opacity(0.3)
                                                : Color.clear
                                        )
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))

                        TextField("Enter name", text: $name)
                            .font(.title3)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(12)
                    }

                    // Grade picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grade")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(1...7, id: \.self) { grade in
                                Button {
                                    selectedGrade = grade
                                } label: {
                                    Text("\(grade)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .frame(width: 56, height: 56)
                                        .foregroundColor(selectedGrade == grade ? .white : .primary)
                                        .background(selectedGrade == grade ? Color.purple : Color.white.opacity(0.8))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }

                    // Create button
                    Button {
                        let finalName = name.isEmpty ? "Player" : name
                        appState.createNewProfile(name: finalName, avatarIcon: selectedAvatar, grade: selectedGrade)
                    } label: {
                        Text("Create Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cyan)
                            .cornerRadius(16)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
