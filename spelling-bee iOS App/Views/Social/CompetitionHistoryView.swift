//
//  CompetitionHistoryView.swift
//  spelling-bee iOS App
//
//  Shows all completed competitions the user participated in,
//  with their final rank and coins earned in each.
//

import SwiftUI

struct CompetitionHistoryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var entries: [CompetitionHistoryEntry] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.purple.opacity(0.9), Color.indigo],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                } else if entries.isEmpty {
                    VStack(spacing: 16) {
                        Text("🏆")
                            .font(.system(size: 56))
                        Text("No Past Competitions")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Completed competitions will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(entries) { entry in
                                HistoryCard(entry: entry)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Competition History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .task {
            guard let uid = FirebaseManager.shared.currentUID else {
                isLoading = false
                return
            }
            entries = await CompetitionService.shared.loadCompetitionHistory(uid: uid)
            isLoading = false
        }
    }
}

// MARK: - History Card

private struct HistoryCard: View {
    let entry: CompetitionHistoryEntry

    private var rankLabel: String {
        guard let rank = entry.myFinalRank else { return "—" }
        return "#\(rank)"
    }

    private var rankColor: Color {
        guard let rank = entry.myFinalRank else { return .white.opacity(0.5) }
        switch rank {
        case 1: return .yellow
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .white
        }
    }

    private var rankIcon: String? {
        guard let rank = entry.myFinalRank else { return nil }
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return nil
        }
    }

    private var topPercentLabel: String? {
        guard let rank = entry.myFinalRank, entry.totalParticipants > 0 else { return nil }
        let pct = Int(ceil(Double(rank) / Double(entry.totalParticipants) * 100))
        return "Top \(pct)%"
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 52, height: 52)

                if let icon = rankIcon {
                    Text(icon)
                        .font(.system(size: 26))
                } else {
                    Text(rankLabel)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(rankColor)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(entry.type == .public ? "PUBLIC" : "PRIVATE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(entry.type == .public ? .cyan : .yellow)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(entry.type == .public ? Color.cyan.opacity(0.2) : Color.yellow.opacity(0.2))
                        )
                }

                HStack(spacing: 10) {
                    // Date
                    Label(Self.dateFormatter.string(from: entry.endTime), systemImage: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))

                    // Players
                    Label("\(entry.totalParticipants) players", systemImage: "person.2")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }

                if let pct = topPercentLabel {
                    Text(pct)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green.opacity(0.9))
                }
            }

            Spacer()

            // Coins earned
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.yellow)
                    Text("\(entry.myCoinsEarned)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("coins")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            entry.type == .public ? Color.cyan.opacity(0.2) : Color.yellow.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
}
