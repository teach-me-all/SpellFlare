//
//  WatchSettingsView.swift
//  SpellFlare Watch App
//
//  Settings screen for changing grade and viewing purchase info.
//

import SwiftUI

struct WatchSettingsView: View {
    @EnvironmentObject var appState: WatchAppState
    @EnvironmentObject var syncHelper: WatchSyncHelper

    @State private var selectedGrade: Int = 1
    @State private var showNameInput = false
    @State private var newName = ""
    @State private var showAvatarPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with back button
                HStack {
                    Button {
                        appState.navigateToHome()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(.cyan)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Settings")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    // Spacer for balance
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .opacity(0)
                }
                .padding(.horizontal)

                // Profile Section
                VStack(spacing: 8) {
                    Button {
                        showAvatarPicker = true
                    } label: {
                        Text(syncHelper.profile?.avatarIcon ?? "🐝")
                            .font(.system(size: 36))
                    }
                    .buttonStyle(.plain)

                    Text(syncHelper.profile?.name ?? "Player")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 16) {
                        Button {
                            newName = syncHelper.profile?.name ?? ""
                            showNameInput = true
                        } label: {
                            Text("Name")
                                .font(.caption)
                                .foregroundColor(.cyan)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showAvatarPicker = true
                        } label: {
                            Text("Avatar")
                                .font(.caption)
                                .foregroundColor(.cyan)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)

                Divider()
                    .background(Color.gray.opacity(0.3))

                // Grade Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Grade Level")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Grade", selection: $selectedGrade) {
                        ForEach(1...7, id: \.self) { grade in
                            Text("Grade \(grade)").tag(grade)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 80)
                    .onChange(of: selectedGrade) { oldValue, newValue in
                        syncHelper.updateGradeLocally(newValue)
                    }
                }
                .padding(.horizontal)

                Divider()
                    .background(Color.gray.opacity(0.3))

                // Purchases Section
                VStack(spacing: 12) {
                    Text("Purchases")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if syncHelper.isWatchUnlocked {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("All Levels Unlocked")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.yellow)
                            Text("Levels 6+ Locked")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("Purchase on iPhone to unlock")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)
                .padding(.horizontal)

                // Stats Section
                VStack(spacing: 8) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        VStack {
                            Text("\(syncHelper.profile?.completedLevels.count ?? 0)")
                                .font(.headline)
                                .foregroundColor(.cyan)
                            Text("Levels")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        VStack {
                            Text("\(syncHelper.profile?.totalCoins ?? 0)")
                                .font(.headline)
                                .foregroundColor(.yellow)
                            Text("Coins")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)
                .padding(.horizontal)

                // App Version
                Text(watchAppVersion)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 8)

                Spacer(minLength: 20)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.9),
                    Color(red: 0.3, green: 0.15, blue: 0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            selectedGrade = syncHelper.profile?.grade ?? 1
        }
        .sheet(isPresented: $showNameInput) {
            NameInputSheet(name: $newName) {
                if !newName.isEmpty {
                    updateName(newName)
                }
                showNameInput = false
            }
        }
        .sheet(isPresented: $showAvatarPicker) {
            WatchAvatarPickerView { avatar in
                updateAvatar(avatar)
                showAvatarPicker = false
            }
        }
    }

    private var watchAppVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "Version \(version) (\(build))"
    }

    private func updateName(_ name: String) {
        guard var profile = syncHelper.profile else { return }
        profile.name = name
        syncHelper.profile = profile

        let syncable = SyncableProfile(
            profile: profile,
            deviceIdentifier: DeviceIdentifier.current
        )
        LocalCacheService.shared.saveSyncableProfile(syncable)
    }

    private func updateAvatar(_ avatar: String) {
        guard var profile = syncHelper.profile else { return }
        profile.avatarIcon = avatar
        syncHelper.profile = profile

        let syncable = SyncableProfile(
            profile: profile,
            deviceIdentifier: DeviceIdentifier.current
        )
        LocalCacheService.shared.saveSyncableProfile(syncable)
    }
}

// MARK: - Name Input Sheet
struct NameInputSheet: View {
    @Binding var name: String
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Your Name")
                .font(.headline)

            TextField("Name", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .medium))
                .multilineTextAlignment(.center)

            Button("Save") {
                onSave()
            }
            .disabled(name.isEmpty)
        }
        .padding()
    }
}

// MARK: - Watch Avatar Picker
struct WatchAvatarPickerView: View {
    let onSelect: (String) -> Void

    private let avatars = ProfileManager.avatarOptions
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Choose Avatar")
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(avatars, id: \.self) { avatar in
                        Button {
                            onSelect(avatar)
                        } label: {
                            Text(avatar)
                                .font(.system(size: 28))
                                .frame(width: 38, height: 38)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    WatchSettingsView()
        .environmentObject(WatchAppState())
        .environmentObject(WatchSyncHelper.shared)
}
