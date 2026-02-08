//
//  LevelMistakeOptionsSheet.swift
//  spelling-bee iOS App
//
//  Post-level modal shown when user had mistakes, offering practice options.
//

import SwiftUI

struct LevelMistakeOptionsSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let level: Int
    let incorrectWords: [Word]
    let onRedoFullLevel: () -> Void
    let onPracticeTrickyWords: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Level \(level) Complete!")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("You have \(incorrectWords.count) \(incorrectWords.count == 1 ? "word" : "words") to practice")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 24)

            // Word list preview
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(incorrectWords.prefix(5)) { word in
                        Text(word.text)
                            .font(.callout.bold())
                            .foregroundColor(.purple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(16)
                    }
                    if incorrectWords.count > 5 {
                        Text("+\(incorrectWords.count - 5) more")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                // Practice Tricky Words - Primary action
                Button {
                    dismiss()
                    onPracticeTrickyWords()
                } label: {
                    HStack {
                        Image(systemName: "target")
                            .font(.system(size: 18))
                        Text("Practice Tricky Words")
                            .font(.headline)
                    }
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }

                // Redo Full Level
                Button {
                    dismiss()
                    onRedoFullLevel()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                        Text("Redo Full Level")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }

                // Continue
                Button {
                    dismiss()
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
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

struct LevelMistakeOptionsSheet_Previews: PreviewProvider {
    static var previews: some View {
        LevelMistakeOptionsSheet(
            level: 5,
            incorrectWords: [
                Word(text: "beautiful", difficulty: 4),
                Word(text: "necessary", difficulty: 5),
                Word(text: "rhythm", difficulty: 6)
            ],
            onRedoFullLevel: {},
            onPracticeTrickyWords: {},
            onContinue: {}
        )
        .environmentObject(AppState())
    }
}
