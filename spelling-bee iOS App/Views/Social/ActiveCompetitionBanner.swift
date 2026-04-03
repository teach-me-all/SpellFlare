//
//  ActiveCompetitionBanner.swift
//  spelling-bee iOS App
//
//  A compact inline banner shown in HomeView when the user is in an active competition.
//

import SwiftUI

struct ActiveCompetitionBanner: View {
    @ObservedObject private var service = CompetitionService.shared

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            if let comp = service.activeCompetition {
                VStack(alignment: .leading, spacing: 1) {
                    Text(comp.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(comp.statusLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.75))
                }
            }

            Spacer()

            if let rank = service.myRankInActiveCompetition {
                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.yellow)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
