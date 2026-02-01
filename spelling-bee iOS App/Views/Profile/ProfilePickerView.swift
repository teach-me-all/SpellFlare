//
//  ProfilePickerView.swift
//  spelling-bee iOS App
//
//  Full-screen profile selection at launch or from switcher.
//

import SwiftUI

struct ProfilePickerView: View {
    @EnvironmentObject var appState: AppState

    private var profiles: [ProfileMetadata] {
        appState.profileManager.allProfiles
    }

    private var canAddMore: Bool {
        appState.profileManager.canCreateMoreProfiles()
    }

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

            VStack(spacing: 30) {
                Spacer()

                Text("Who's Playing?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Profile grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(profiles) { meta in
                        ProfileCard(metadata: meta) {
                            appState.switchProfile(to: meta.id)
                        }
                    }

                    if canAddMore {
                        AddProfileCard {
                            appState.showCreateProfile()
                        }
                    }
                }
                .padding(.horizontal, 30)

                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Profile Card
struct ProfileCard: View {
    let metadata: ProfileMetadata
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Text(metadata.avatarIcon)
                    .font(.system(size: 50))

                Text(metadata.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("Grade \(metadata.grade)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.white.opacity(0.15))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Profile Card
struct AddProfileCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.6))

                Text("Add Player")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
        .buttonStyle(.plain)
    }
}
