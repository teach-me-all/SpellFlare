//
//  ThemeService.swift
//  Shared
//
//  Maps theme IDs to background gradient colors.
//

import SwiftUI

enum ThemeService {

    static let defaultColors: [Color] = [
        Color(red: 0.4, green: 0.2, blue: 0.9),
        Color(red: 0.5, green: 0.3, blue: 0.95),
        Color(red: 0.45, green: 0.25, blue: 0.85)
    ]

    static func backgroundColors(for themeID: String?) -> [Color] {
        guard let themeID = themeID else { return defaultColors }

        switch themeID {
        case "bg_default":
            return defaultColors

        case "bg_space":
            return [
                Color(red: 0.05, green: 0.05, blue: 0.2),
                Color(red: 0.1, green: 0.1, blue: 0.35),
                Color(red: 0.08, green: 0.05, blue: 0.25)
            ]

        case "bg_ocean":
            return [
                Color(red: 0.0, green: 0.3, blue: 0.6),
                Color(red: 0.0, green: 0.45, blue: 0.7),
                Color(red: 0.0, green: 0.35, blue: 0.55)
            ]

        case "bg_candy":
            return [
                Color(red: 0.9, green: 0.3, blue: 0.5),
                Color(red: 0.95, green: 0.45, blue: 0.6),
                Color(red: 0.85, green: 0.35, blue: 0.55)
            ]

        case "bg_forest":
            return [
                Color(red: 0.1, green: 0.4, blue: 0.2),
                Color(red: 0.15, green: 0.5, blue: 0.25),
                Color(red: 0.1, green: 0.35, blue: 0.18)
            ]

        default:
            return defaultColors
        }
    }

    // Two-color variant for Watch (simpler gradients)
    static func watchBackgroundColors(for themeID: String?) -> [Color] {
        let colors = backgroundColors(for: themeID)
        if colors.count >= 2 {
            return [colors[0], colors[1]]
        }
        return colors
    }

    // MARK: - Celebration Colors

    static func celebrationColors(for effectID: String?) -> [Color] {
        guard let effectID = effectID else {
            return [.yellow, .cyan, .green, .blue, .pink, .purple, .red, .white]
        }

        switch effectID {
        case "cel_default":
            return [.yellow, .cyan, .green, .blue, .pink, .purple, .red, .white]

        case "cel_confetti":
            return [.yellow, .orange, Color(red: 1.0, green: 0.84, blue: 0.0), .white]

        case "cel_fireworks":
            return [.red, .orange, .yellow, .white, .cyan]

        case "cel_rainbow":
            return [.red, .orange, .yellow, .green, .blue, .purple]

        case "cel_stars":
            return [.white, .cyan, .yellow, Color(red: 0.8, green: 0.8, blue: 1.0)]

        default:
            return [.yellow, .cyan, .green, .blue, .pink, .purple, .red, .white]
        }
    }

    // MARK: - Bee Skin Emoji

    static func beeSkinEmoji(for skinID: String?) -> String {
        guard let skinID = skinID else { return "\u{1F41D}" } // bee emoji

        switch skinID {
        case "bee_default": return "\u{1F41D}"     // bee
        case "bee_super": return "\u{1F9B8}"       // superhero
        case "bee_ninja": return "\u{1F977}"       // ninja
        case "bee_astronaut": return "\u{1F680}"   // rocket
        case "bee_royal": return "\u{1F451}"       // crown
        default: return "\u{1F41D}"
        }
    }

    // MARK: - SF Symbols for Shop Display

    static func shopIcon(for itemID: String) -> String {
        switch itemID {
        // Bee skins
        case "bee_default": return "ant.fill"
        case "bee_super": return "bolt.fill"
        case "bee_ninja": return "eye.slash.fill"
        case "bee_astronaut": return "airplane"
        case "bee_royal": return "crown.fill"
        // Themes
        case "bg_default": return "paintpalette.fill"
        case "bg_space": return "moon.stars.fill"
        case "bg_ocean": return "water.waves"
        case "bg_candy": return "birthday.cake.fill"
        case "bg_forest": return "leaf.fill"
        // Celebrations
        case "cel_default": return "party.popper.fill"
        case "cel_confetti": return "sparkles"
        case "cel_fireworks": return "flame.fill"
        case "cel_rainbow": return "rainbow"
        case "cel_stars": return "star.fill"
        default: return "questionmark.circle"
        }
    }
}
