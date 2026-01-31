//
//  AchievementBadge.swift
//  spelling-bee iOS App
//
//  Individual badge tile for the achievements grid.
//

import SwiftUI

// MARK: - Rarity Color Helpers

enum RarityColors {
    static func fillColor(for rarity: AchievementRarity, unlocked: Bool) -> Color {
        guard unlocked else { return Color.white.opacity(0.1) }
        switch rarity {
        case .common: return Color.yellow.opacity(0.2)
        case .rare: return Color.orange.opacity(0.25)
        case .epic: return Color.purple.opacity(0.3)
        case .legendary: return Color.yellow.opacity(0.35)
        }
    }

    static func borderColor(for rarity: AchievementRarity) -> Color {
        switch rarity {
        case .common: return .yellow
        case .rare: return Color(red: 1.0, green: 0.7, blue: 0.2) // orange-gold
        case .epic: return .purple
        case .legendary: return Color(red: 1.0, green: 0.84, blue: 0.0) // gold
        }
    }

    static func borderWidth(for rarity: AchievementRarity) -> CGFloat {
        switch rarity {
        case .common: return 1.5
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 3.5
        }
    }

    static func iconTint(for rarity: AchievementRarity, unlocked: Bool) -> Color {
        guard unlocked else { return .white.opacity(0.3) }
        switch rarity {
        case .common: return .yellow
        case .rare: return .orange
        case .epic: return .purple
        case .legendary: return Color(red: 1.0, green: 0.84, blue: 0.0)
        }
    }

    static func progressTint(for rarity: AchievementRarity) -> Color {
        switch rarity {
        case .common: return .yellow
        case .rare: return .orange
        case .epic: return .purple
        case .legendary: return Color(red: 1.0, green: 0.84, blue: 0.0)
        }
    }

    static func rarityLabel(_ rarity: AchievementRarity) -> String {
        switch rarity {
        case .common: return "Common"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }
}

struct AchievementBadge: View {
    let definition: AchievementDefinition
    let progress: AchievementProgress?
    let profile: UserProfile?

    var isUnlocked: Bool {
        progress?.isUnlocked ?? false
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle with rarity fill
                Circle()
                    .fill(RarityColors.fillColor(for: definition.rarity, unlocked: isUnlocked))
                    .frame(width: 70, height: 70)

                // Border ring
                Circle()
                    .stroke(
                        isUnlocked ? RarityColors.borderColor(for: definition.rarity) : Color.white.opacity(0.15),
                        lineWidth: isUnlocked ? RarityColors.borderWidth(for: definition.rarity) : 1
                    )
                    .frame(width: 70, height: 70)

                // Circular progress ring (behind icon) for locked badges
                if !isUnlocked {
                    Circle()
                        .trim(from: 0, to: progressFraction)
                        .stroke(
                            RarityColors.progressTint(for: definition.rarity).opacity(0.5),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                }

                // Glow for rare+ unlocked
                if isUnlocked && definition.rarity != .common {
                    Circle()
                        .fill(RarityColors.borderColor(for: definition.rarity).opacity(0.15))
                        .frame(width: 80, height: 80)
                        .blur(radius: 8)
                }

                // Icon
                Image(systemName: definition.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(RarityColors.iconTint(for: definition.rarity, unlocked: isUnlocked))

                // Checkmark overlay for unlocked
                if isUnlocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                                .background(Circle().fill(Color.white).frame(width: 14, height: 14))
                        }
                    }
                    .frame(width: 70, height: 70)
                }
            }

            // Title
            Text(definition.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 28)
        }
        .frame(maxWidth: .infinity)
    }

    private var progressFraction: Double {
        guard let profile = profile else { return 0 }
        return AchievementsService.shared.progressFraction(for: definition.id, profile: profile)
    }
}
