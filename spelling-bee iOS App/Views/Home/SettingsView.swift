//
//  SettingsView.swift
//  spelling-bee iOS App
//
//  Settings screen for changing grade, purchases, and viewing profile.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var speechService = SpeechService.shared
    @ObservedObject var storeManager = StoreManager.shared
    @State private var selectedGrade: Int = 1
    @State private var showResetConfirm = false
    @State private var showParentGateForAds = false
    @State private var showParentGateForWatch = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var showPurchaseResult = false
    @State private var purchaseResultMessage = ""
    @State private var showProfileSwitcher = false

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        Text(appState.profile?.avatarIcon ?? "🐝")
                            .font(.system(size: 50))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.profile?.name ?? "Speller")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("\(appState.profile?.completedLevels.count ?? 0) levels completed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    Button {
                        showProfileSwitcher = true
                    } label: {
                        Label("Switch Player", systemImage: "person.2.fill")
                    }
                }

                // Grade Section
                Section("Grade Level") {
                    Picker("Current Grade", selection: $selectedGrade) {
                        ForEach(1...7, id: \.self) { grade in
                            Text("Grade \(grade)").tag(grade)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedGrade) { newValue in
                        appState.updateGrade(newValue)
                    }

                    Text("Words will match your grade level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Voice Section
                Section("Voice") {
                    Picker("Voice", selection: $speechService.selectedVoice) {
                        ForEach(speechService.availableVoices) { voice in
                            Text(voice.name).tag(voice)
                        }
                    }
                    .pickerStyle(.menu)

                    Button {
                        speechService.previewVoice(speechService.selectedVoice)
                    } label: {
                        HStack {
                            Label("Preview Voice", systemImage: "speaker.wave.2.fill")
                            Spacer()
                            if speechService.isSpeaking {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(speechService.isSpeaking)
                }

                // Speech Recognition Section
                Section("Speech Recognition") {
                    HStack {
                        Label("Microphone", systemImage: "mic.fill")
                        Spacer()
                        Text(speechService.speechAuthorizationStatus == .authorized ? "Enabled" : "Disabled")
                            .foregroundColor(.secondary)
                    }
                }

                // Purchases Section
                Section {
                    // Remove Ads
                    if storeManager.isAdsRemoved {
                        HStack {
                            Label("Ads Removed", systemImage: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Spacer()
                            Text("Purchased")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button {
                            showParentGateForAds = true
                        } label: {
                            HStack {
                                Label("Remove Ads", systemImage: "speaker.slash.fill")
                                Spacer()
                                if storeManager.purchaseInProgress {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text(storeManager.formattedRemoveAdsPrice)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .disabled(storeManager.purchaseInProgress)
                    }

                    // Unlock Watch Levels
                    if storeManager.isWatchUnlocked {
                        HStack {
                            Label("Watch Unlocked", systemImage: "applewatch")
                                .foregroundColor(.green)
                            Spacer()
                            Text("Purchased")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button {
                            showParentGateForWatch = true
                        } label: {
                            HStack {
                                Label("Unlock Watch Levels", systemImage: "applewatch")
                                Spacer()
                                if storeManager.purchaseInProgress {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text(storeManager.formattedUnlockWatchPrice)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .disabled(storeManager.purchaseInProgress)
                    }

                    Button {
                        Task {
                            let restored = await storeManager.restorePurchases()
                            restoreMessage = restored ? "Purchases restored successfully!" : "No purchases to restore."
                            showRestoreAlert = true
                        }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                } header: {
                    Text("Purchases")
                } footer: {
                    Text("Remove Ads removes ads on iPhone. Unlock Watch unlocks levels 6-50 on Apple Watch.")
                }

                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset All Progress", systemImage: "arrow.counterclockwise")
                    }
                } footer: {
                    Text("This will delete all your progress and start fresh.")
                }

                // App Info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        appState.navigateToHome()
                    }
                }
            }
            .onAppear {
                selectedGrade = appState.profile?.grade ?? 1
            }
            .alert("Reset Progress?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    appState.resetApp()
                }
            } message: {
                Text("This will reset your level progress for all grades. Your coins, achievements, and shop items will be kept.")
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage)
            }
            .sheet(isPresented: $showParentGateForAds) {
                ParentGateView {
                    // Parent verified, proceed with Remove Ads purchase
                    Task {
                        let success = await storeManager.purchaseRemoveAds()
                        if success {
                            purchaseResultMessage = "Ads removed successfully! Enjoy ad-free spelling practice."
                        } else {
                            purchaseResultMessage = storeManager.purchaseError ?? "Purchase failed. Please try again."
                        }
                        showPurchaseResult = true
                    }
                }
            }
            .sheet(isPresented: $showParentGateForWatch) {
                ParentGateView {
                    // Parent verified, proceed with Unlock Watch purchase
                    Task {
                        let success = await storeManager.purchaseUnlockWatch()
                        if success {
                            purchaseResultMessage = "Watch levels unlocked! Levels 6-50 are now available on Apple Watch."
                        } else {
                            purchaseResultMessage = storeManager.purchaseError ?? "Purchase failed. Please try again."
                        }
                        showPurchaseResult = true
                    }
                }
            }
            .alert("Purchase", isPresented: $showPurchaseResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(purchaseResultMessage)
            }
            .sheet(isPresented: $showProfileSwitcher) {
                ProfileSwitcherSheet()
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState())
    }
}
