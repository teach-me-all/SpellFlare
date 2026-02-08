//
//  CoinsDisplayView.swift
//  spelling-bee iOS App
//
//  Displays the user's total coins with a subtle animation.
//

import SwiftUI

struct CoinsDisplayView: View {
    let coins: Int
    var onTap: (() -> Void)? = nil
    @State private var displayedCoins: Int = 0
    @State private var isAnimating = false

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 6) {
                // Trophy icon with subtle bounce on change
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.15 : 1.0)

                // Coin count with count-up animation
                Text("\(displayedCoins)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            displayedCoins = coins
        }
        .onChange(of: coins) { newValue in
            // Animate count-up when coins change
            if newValue > displayedCoins {
                animateCountUp(to: newValue)
            } else {
                displayedCoins = newValue
            }
        }
    }

    private func animateCountUp(to target: Int) {
        // Bounce animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            isAnimating = true
        }

        // Count up animation
        let steps = 10
        let increment = (target - displayedCoins) / steps
        let stepDuration = 0.05

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                if step == steps {
                    displayedCoins = target
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        isAnimating = false
                    }
                } else {
                    displayedCoins += increment
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.purple
        CoinsDisplayView(coins: 1250)
    }
}
