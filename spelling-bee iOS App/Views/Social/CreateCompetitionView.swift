//
//  CreateCompetitionView.swift
//  spelling-bee iOS App
//
//  Create a private competition and share the invite code.
//

import SwiftUI

struct CreateCompetitionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CompetitionViewModel()

    @State private var competitionName: String = ""
    @State private var createdCompetition: Competition?
    @State private var showShareSheet = false

    var inviteLink: String {
        guard let comp = createdCompetition else { return "" }
        return "spellflare://join?code=\(comp.inviteCode)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if let comp = createdCompetition {
                    // Success state: show invite code
                    createdView(comp: comp)
                } else {
                    // Creation form
                    formView
                }
            }
            .navigationTitle(createdCompetition == nil ? "New Competition" : "Competition Created!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            competitionName = "\(appState.profile?.name ?? "My") Spelling Bee"
        }
    }

    private var formView: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Competition name", text: $competitionName)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Your friends will see this name in their competition list.")
                }

                Section {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.purple)
                        Text("Up to 10 players")
                        Spacer()
                        Text("7 days")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.purple)
                        Text("Private – invite only")
                    }
                } header: {
                    Text("Details")
                }
            }

            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Button {
                Task { await create() }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 4)
                    }
                    Text("Create Competition")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(competitionName.isEmpty ? Color.gray : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .disabled(competitionName.isEmpty || viewModel.isLoading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private func createdView(comp: Competition) -> some View {
        VStack(spacing: 32) {
            Spacer()

            Text("🎉")
                .font(.system(size: 64))

            VStack(spacing: 8) {
                Text(comp.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Share the invite code with your friends!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Invite code display
            VStack(spacing: 8) {
                Text("Invite Code")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Text(comp.inviteCode)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.purple.opacity(0.1))
                    )
            }

            // Share button
            Button {
                showShareSheet = true
                AnalyticsManager.shared.logInviteSent()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Invite Link")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .padding(.horizontal, 40)

            // Copy code button
            Button {
                UIPasteboard.general.string = comp.inviteCode
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Code")
                }
                .foregroundColor(.purple)
            }

            Spacer()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [inviteLink])
        }
    }

    private func create() async {
        await viewModel.createPrivateCompetition(
            name: competitionName,
            username: appState.profile?.name ?? "Speller",
            avatarIcon: appState.profile?.avatarIcon ?? "🐝"
        )
        createdCompetition = viewModel.activeCompetition
    }
}

// MARK: - UIKit share sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
