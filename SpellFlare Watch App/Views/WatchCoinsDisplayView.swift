//
//  WatchCoinsDisplayView.swift
//  SpellFlare Watch App
//
//  Compact coins display for Watch.
//

import SwiftUI

struct WatchCoinsDisplayView: View {
    let coins: Int
    var compact: Bool = false
    var large: Bool = false
    var onTap: (() -> Void)? = nil

    private var iconSize: CGFloat {
        if compact { return 11 }
        if large { return 18 }
        return 14
    }

    private var textSize: CGFloat {
        if compact { return 10 }
        if large { return 15 }
        return 12
    }

    private var hPadding: CGFloat {
        if compact { return 5 }
        if large { return 10 }
        return 8
    }

    private var vPadding: CGFloat {
        if compact { return 2 }
        if large { return 5 }
        return 4
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: compact ? 2 : (large ? 5 : 4)) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("\(coins)")
                    .font(.system(size: textSize, weight: .bold))
                    .foregroundColor(.yellow)
                    .monospacedDigit()
            }
            .padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}

/// Coins earned animation for Watch
struct WatchCoinsEarnedView: View {
    let amount: Int
    var isSmallWatch: Bool = false
    var isLargeWatch: Bool = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    private var iconSize: CGFloat {
        if isSmallWatch { return 14 }
        if isLargeWatch { return 22 }
        return 18
    }

    private var textSize: CGFloat {
        if isSmallWatch { return 13 }
        if isLargeWatch { return 20 }
        return 16
    }

    var body: some View {
        HStack(spacing: isSmallWatch ? 3 : (isLargeWatch ? 5 : 4)) {
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("+\(amount)")
                .font(.system(size: textSize, weight: .bold, design: .rounded))
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, isSmallWatch ? 8 : (isLargeWatch ? 16 : 12))
        .padding(.vertical, isSmallWatch ? 4 : (isLargeWatch ? 8 : 6))
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                )
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WatchCoinsDisplayView(coins: 450)
        WatchCoinsEarnedView(amount: 100)
    }
}
