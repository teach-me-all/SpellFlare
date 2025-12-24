//
//  SettingsView.swift
//  spelling-bee Watch App
//
//  Settings screen for changing grade, voice, and viewing profile.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var speechService = SpeechService.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedGrade: Int = 1
    @State private var showResetConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Profile Info
                if let profile = appState.profile {
                    VStack(spacing: 4) {
                        Text("\(profile.name)")
                            .font(.headline)
                            .foregroundColor(.cyan)

                        Text("\(profile.completedLevels.count) levels done")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 8)
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                // Grade Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Grade")
                        .font(.caption)
                        .foregroundColor(.cyan)

                    Picker("Grade", selection: $selectedGrade) {
                        ForEach(1...7, id: \.self) { grade in
                            Text("Grade \(grade)").tag(grade)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 50)
                    .onChange(of: selectedGrade) { newValue in
                        appState.updateGrade(newValue)
                    }
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                // Voice Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Voice")
                        .font(.caption)
                        .foregroundColor(.cyan)

                    Picker("Voice", selection: $speechService.selectedVoice) {
                        ForEach(speechService.availableVoices) { voice in
                            Text(voice.name).tag(voice)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 50)

                    Button {
                        speechService.previewVoice(speechService.selectedVoice)
                    } label: {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .font(.caption2)
                            Text("Preview")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.cyan)
                    .disabled(speechService.isSpeaking)
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                // Reset Button
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Reset Progress", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedGrade = appState.profile?.grade ?? 1
        }
        .alert("Reset Progress?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                appState.resetApp()
                dismiss()
            }
        } message: {
            Text("This will delete all your progress.")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            SettingsView()
                .environmentObject(AppState())
        }
    }
}
