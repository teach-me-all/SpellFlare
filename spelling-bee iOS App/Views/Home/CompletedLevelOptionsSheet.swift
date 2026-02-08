//
//  CompletedLevelOptionsSheet.swift
//  spelling-bee iOS App
//
//  Sheet shown when tapping a completed level that has recorded mistakes.
//

import SwiftUI

struct CompletedLevelOptionsSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let level: Int
    let mistakeCount: Int
    let onPlayFullLevel: () -> Void
    let onPracticeMistakes: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Level \(level)")
                    .font(.title.bold())
                    .foregroundColor(.white)

                if mistakeCount > 0 {
                    Text("\(mistakeCount) \(mistakeCount == 1 ? "word" : "words") to practice")
                        .font(.subheadline)
                        .foregroundColor(.cyan)
                } else {
                    Text("Completed!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            .padding(.top, 32)

            Spacer()

            // Options
            VStack(spacing: 12) {
                // Play Full Level
                Button {
                    dismiss()
                    onPlayFullLevel()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                        Text("Play Full Level")
                            .font(.headline)
                    }
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }

                // Practice Mistakes (only if mistakes exist)
                if mistakeCount > 0 {
                    Button {
                        dismiss()
                        onPracticeMistakes()
                    } label: {
                        HStack {
                            Image(systemName: "target")
                                .font(.system(size: 16))
                            Text("Practice Tricky Words")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cyan)
                        .cornerRadius(12)
                    }
                }

                // Cancel
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct CompletedLevelOptionsSheet_Previews: PreviewProvider {
    static var previews: some View {
        CompletedLevelOptionsSheet(
            level: 5,
            mistakeCount: 3,
            onPlayFullLevel: {},
            onPracticeMistakes: {}
        )
        .environmentObject(AppState())
    }
}
