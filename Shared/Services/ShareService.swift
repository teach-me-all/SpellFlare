//
//  ShareService.swift
//  Shared
//
//  Service for generating shareable content for social sharing.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

class ShareService {
    static let shared = ShareService()
    static let appStoreURL = "https://apps.apple.com/us/app/spellflare/id6757255748"

    private init() {}

    // MARK: - Message Templates

    private let commonMessages = [
        "Just unlocked [TITLE]! Can you beat me at SpellFlare?",
        "I earned the [TITLE] achievement! Think you can spell that well?",
        "New achievement unlocked: [TITLE]! Challenge accepted?"
    ]

    private let rareMessages = [
        "Whoa! RARE achievement unlocked: [TITLE]! Think you can spell your way there?",
        "Just got a RARE badge: [TITLE]! Can you match my spelling skills?",
        "RARE unlock: [TITLE]! Who's brave enough to challenge me?"
    ]

    private let epicMessages = [
        "EPIC WIN! Just earned: [TITLE]! Who wants to challenge me?",
        "EPIC achievement unlocked: [TITLE]! I'm on fire!",
        "Can you believe it? EPIC badge: [TITLE]! Try to beat that!"
    ]

    private let legendaryMessages = [
        "LEGENDARY! I unlocked [TITLE]! Are you brave enough to try SpellFlare?",
        "I just earned a LEGENDARY achievement: [TITLE]! Think you've got what it takes?",
        "LEGENDARY spelling skills! [TITLE] is mine! Can anyone top this?"
    ]

    private let levelMessages = [
        "Crushed Level [LEVEL] in SpellFlare! Can you spell your way past me?",
        "Just beat Level [LEVEL]! Think you can do better?",
        "Level [LEVEL] complete! Who wants to challenge the spelling champ?"
    ]

    // MARK: - Message Generation

    func generateAchievementMessage(title: String, rarity: AchievementRarity) -> String {
        let templates: [String]
        let emoji: String

        switch rarity {
        case .common:
            templates = commonMessages
            emoji = "\u{1F41D}" // bee
        case .rare:
            templates = rareMessages
            emoji = "\u{1F31F}" // star
        case .epic:
            templates = epicMessages
            emoji = "\u{1F525}" // fire
        case .legendary:
            templates = legendaryMessages
            emoji = "\u{1F3C6}" // trophy
        }

        let template = templates.randomElement() ?? templates[0]
        return "\(emoji) \(template.replacingOccurrences(of: "[TITLE]", with: title))"
    }

    func generateLevelMessage(level: Int, coinsEarned: Int) -> String {
        let template = levelMessages.randomElement() ?? levelMessages[0]
        return "\u{2B50} \(template.replacingOccurrences(of: "[LEVEL]", with: "\(level)"))"
    }

    // MARK: - Image Generation

    #if canImport(UIKit)
    func generateShareImage(symbolName: String, rarity: AchievementRarity) -> UIImage? {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let cgContext = context.cgContext

            // Background gradient
            let colors = gradientColors(for: rarity)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let cgColors = colors.map { $0.cgColor } as CFArray
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: [0, 1]) else { return }

            cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            // Draw circle background
            let circleRect = CGRect(x: 50, y: 50, width: 200, height: 200)
            cgContext.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            cgContext.fillEllipse(in: circleRect)

            // Draw rarity border
            cgContext.setStrokeColor(borderColor(for: rarity).cgColor)
            cgContext.setLineWidth(borderWidth(for: rarity))
            cgContext.strokeEllipse(in: circleRect)

            // Draw SF Symbol
            let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .medium)
            if let symbolImage = UIImage(systemName: symbolName, withConfiguration: config) {
                let symbolSize = symbolImage.size
                let symbolRect = CGRect(
                    x: (size.width - symbolSize.width) / 2,
                    y: (size.height - symbolSize.height) / 2,
                    width: symbolSize.width,
                    height: symbolSize.height
                )
                symbolImage.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: symbolRect)
            }

            // Draw "SpellFlare" text at bottom
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let text = "SpellFlare"
            let textSize = text.size(withAttributes: textAttributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: size.height - 50,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: textAttributes)
        }
    }

    func generateLevelImage(level: Int, didPass: Bool) -> UIImage? {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let cgContext = context.cgContext

            // Background gradient (purple theme)
            let colors = [
                UIColor(red: 0.4, green: 0.2, blue: 0.9, alpha: 1),
                UIColor(red: 0.5, green: 0.3, blue: 0.95, alpha: 1)
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let cgColors = colors.map { $0.cgColor } as CFArray
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: [0, 1]) else { return }

            cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            // Draw circle background
            let circleRect = CGRect(x: 50, y: 40, width: 200, height: 200)
            cgContext.setFillColor(UIColor.cyan.withAlphaComponent(0.3).cgColor)
            cgContext.fillEllipse(in: circleRect)

            cgContext.setStrokeColor(UIColor.cyan.cgColor)
            cgContext.setLineWidth(3)
            cgContext.strokeEllipse(in: circleRect)

            // Draw star or emoji
            let symbolText = didPass ? "\u{2B50}" : "\u{1F622}"
            let symbolAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 80)
            ]
            let symbolSize = symbolText.size(withAttributes: symbolAttributes)
            let symbolRect = CGRect(
                x: (size.width - symbolSize.width) / 2,
                y: (200 - symbolSize.height) / 2 + 40,
                width: symbolSize.width,
                height: symbolSize.height
            )
            symbolText.draw(in: symbolRect, withAttributes: symbolAttributes)

            // Draw "Level X" text
            let levelText = "Level \(level)"
            let levelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let levelSize = levelText.size(withAttributes: levelAttributes)
            let levelRect = CGRect(
                x: (size.width - levelSize.width) / 2,
                y: size.height - 80,
                width: levelSize.width,
                height: levelSize.height
            )
            levelText.draw(in: levelRect, withAttributes: levelAttributes)

            // Draw "SpellFlare" text at bottom
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            let text = "SpellFlare"
            let textSize = text.size(withAttributes: textAttributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: size.height - 45,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: textAttributes)
        }
    }

    // MARK: - Private Helpers

    private func gradientColors(for rarity: AchievementRarity) -> [UIColor] {
        switch rarity {
        case .common:
            return [
                UIColor(red: 0.4, green: 0.2, blue: 0.9, alpha: 1),
                UIColor(red: 0.5, green: 0.3, blue: 0.95, alpha: 1)
            ]
        case .rare:
            return [
                UIColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 1),
                UIColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1)
            ]
        case .epic:
            return [
                UIColor(red: 0.5, green: 0.0, blue: 0.8, alpha: 1),
                UIColor(red: 0.7, green: 0.2, blue: 1.0, alpha: 1)
            ]
        case .legendary:
            return [
                UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1),
                UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1)
            ]
        }
    }

    private func borderColor(for rarity: AchievementRarity) -> UIColor {
        switch rarity {
        case .common:
            return .yellow
        case .rare:
            return UIColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1)
        case .epic:
            return .purple
        case .legendary:
            return UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)
        }
    }

    private func borderWidth(for rarity: AchievementRarity) -> CGFloat {
        switch rarity {
        case .common: return 3
        case .rare: return 4
        case .epic: return 5
        case .legendary: return 6
        }
    }
    #endif
}
