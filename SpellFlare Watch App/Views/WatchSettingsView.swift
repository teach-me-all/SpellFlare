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
    @ObservedObject var storeManager = WatchStoreManager.shared

    @State private var selectedGrade: Int = 1
    @State private var showNameInput = false
    @State private var newName = ""
    @State private var showAvatarPicker = false
    @State private var isRestoring = false

    var body: some View {
        GeometryReader { geometry in
            let isSmallWatch = geometry.size.height < 180
            let avatarSize: CGFloat = isSmallWatch ? 28 : 36
            let pickerHeight: CGFloat = isSmallWatch ? 60 : 80
            let sectionPadding: CGFloat = isSmallWatch ? 8 : 12

            ScrollView {
                VStack(spacing: isSmallWatch ? 10 : 16) {
                    // Header with back button
                    HStack {
                        Button {
                            appState.navigateToHome()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: isSmallWatch ? 14 : 17, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("Settings")
                            .font(.system(size: isSmallWatch ? 14 : 17, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        // Spacer for balance
                        Image(systemName: "chevron.left")
                            .font(.system(size: isSmallWatch ? 14 : 17, weight: .semibold))
                            .opacity(0)
                    }
                    .padding(.horizontal, isSmallWatch ? 6 : 8)

                    // Profile Section
                    VStack(spacing: isSmallWatch ? 4 : 8) {
                        Button {
                            showAvatarPicker = true
                        } label: {
                            Text(syncHelper.profile?.avatarIcon ?? "🐝")
                                .font(.system(size: avatarSize))
                        }
                        .buttonStyle(.plain)

                        Text(syncHelper.profile?.name ?? "Player")
                            .font(.system(size: isSmallWatch ? 14 : 17, weight: .semibold))
                            .foregroundColor(.white)

                        HStack(spacing: isSmallWatch ? 12 : 16) {
                            Button {
                                newName = syncHelper.profile?.name ?? ""
                                showNameInput = true
                            } label: {
                                Text("Name")
                                    .font(.system(size: isSmallWatch ? 11 : 12))
                                    .foregroundColor(.cyan)
                            }
                            .buttonStyle(.plain)

                            Button {
                                showAvatarPicker = true
                            } label: {
                                Text("Avatar")
                                    .font(.system(size: isSmallWatch ? 11 : 12))
                                    .foregroundColor(.cyan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, isSmallWatch ? 4 : 8)

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    // Grade Section
                    VStack(alignment: .leading, spacing: isSmallWatch ? 4 : 8) {
                        Text("Grade Level")
                            .font(.system(size: isSmallWatch ? 10 : 12))
                            .foregroundColor(.secondary)

                        Picker("Grade", selection: $selectedGrade) {
                            ForEach(1...7, id: \.self) { grade in
                                Text("Grade \(grade)").tag(grade)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: pickerHeight)
                        .onChange(of: selectedGrade) { oldValue, newValue in
                            syncHelper.updateGradeLocally(newValue)
                        }
                    }
                    .padding(.horizontal, isSmallWatch ? 6 : 8)

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    // Purchases Section
                    VStack(spacing: isSmallWatch ? 6 : 12) {
                        Text("Purchases")
                            .font(.system(size: isSmallWatch ? 10 : 12))
                            .foregroundColor(.secondary)

                        if syncHelper.isWatchUnlocked || storeManager.isWatchUnlocked {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: isSmallWatch ? 12 : 14))
                                    .foregroundColor(.green)
                                Text("All Levels Unlocked")
                                    .font(.system(size: isSmallWatch ? 10 : 12))
                                    .foregroundColor(.green)
                            }
                        } else {
                            VStack(spacing: isSmallWatch ? 3 : 6) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: isSmallWatch ? 14 : 18))
                                    .foregroundColor(.yellow)
                                Text("Levels 6+ Locked")
                                    .font(.system(size: isSmallWatch ? 10 : 12))
                                    .foregroundColor(.yellow)

                                // Restore Purchase button
                                Button {
                                    Task {
                                        isRestoring = true
                                        _ = await storeManager.restorePurchases()
                                        isRestoring = false
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        if isRestoring {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                                                .scaleEffect(isSmallWatch ? 0.5 : 0.6)
                                        }
                                        Text("Restore Purchase")
                                            .font(.system(size: isSmallWatch ? 9 : 11))
                                            .foregroundColor(.cyan)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(isRestoring)
                                .padding(.top, isSmallWatch ? 2 : 4)
                            }
                        }
                    }
                    .padding(sectionPadding)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(isSmallWatch ? 8 : 12)
                    .padding(.horizontal, isSmallWatch ? 6 : 8)

                    // Stats Section
                    VStack(spacing: isSmallWatch ? 4 : 8) {
                        Text("Progress")
                            .font(.system(size: isSmallWatch ? 10 : 12))
                            .foregroundColor(.secondary)

                        HStack(spacing: isSmallWatch ? 12 : 16) {
                            VStack {
                                Text("\(syncHelper.profile?.completedLevels.count ?? 0)")
                                    .font(.system(size: isSmallWatch ? 14 : 17, weight: .semibold))
                                    .foregroundColor(.cyan)
                                Text("Levels")
                                    .font(.system(size: isSmallWatch ? 8 : 10))
                                    .foregroundColor(.secondary)
                            }

                            VStack {
                                Text("\(syncHelper.profile?.totalCoins ?? 0)")
                                    .font(.system(size: isSmallWatch ? 14 : 17, weight: .semibold))
                                    .foregroundColor(.yellow)
                                Text("Coins")
                                    .font(.system(size: isSmallWatch ? 8 : 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(sectionPadding)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(isSmallWatch ? 8 : 12)
                    .padding(.horizontal, isSmallWatch ? 6 : 8)

                    // App Version
                    Text(watchAppVersion)
                        .font(.system(size: isSmallWatch ? 8 : 10))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, isSmallWatch ? 4 : 8)

                    Spacer(minLength: isSmallWatch ? 10 : 20)
                }
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
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
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
