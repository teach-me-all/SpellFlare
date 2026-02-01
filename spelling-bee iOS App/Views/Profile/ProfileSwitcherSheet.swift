//
//  ProfileSwitcherSheet.swift
//  spelling-bee iOS App
//
//  Sheet overlay for switching profiles from the home screen.
//

import SwiftUI

struct ProfileSwitcherSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false
    @State private var profileToDelete: UUID?
    @State private var showParentGate = false

    private var profiles: [ProfileMetadata] {
        appState.profileManager.allProfiles
    }

    var body: some View {
        NavigationStack {
            List {
                // Existing profiles
                Section("Players") {
                    ForEach(profiles) { meta in
                        Button {
                            appState.switchProfile(to: meta.id)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                Text(meta.avatarIcon)
                                    .font(.system(size: 36))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(meta.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Grade \(meta.grade)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if meta.id == appState.profileManager.activeProfileID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.purple)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Add new
                if appState.profileManager.canCreateMoreProfiles() {
                    Section {
                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                appState.showCreateProfile()
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.cyan)

                                Text("Add New Player")
                                    .font(.headline)
                                    .foregroundColor(.cyan)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Manage (delete)
                if profiles.count > 1 {
                    Section("Manage") {
                        Button {
                            showParentGate = true
                        } label: {
                            Label("Remove a Player", systemImage: "person.crop.circle.badge.minus")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Switch Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showParentGate) {
                ParentGateView {
                    showParentGate = false
                    showDeleteConfirm = true
                }
            }
            .confirmationDialog("Remove Player", isPresented: $showDeleteConfirm) {
                ForEach(profiles.filter { $0.id != appState.profileManager.activeProfileID }) { meta in
                    Button(role: .destructive) {
                        appState.deleteProfile(id: meta.id)
                    } label: {
                        Text("\(meta.avatarIcon) \(meta.name)")
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose a player to remove. This cannot be undone.")
            }
        }
        .presentationDetents([.medium, .large])
    }
}
