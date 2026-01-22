//
//  WatchAppState.swift
//  SpellFlare Watch App
//
//  Global app state and navigation for the Watch app.
//

import SwiftUI
import WatchConnectivity

// MARK: - Screen Navigation
enum WatchScreen: Equatable {
    case loading
    case home
    case settings
    case game(level: Int)
    case levelComplete(level: Int, score: Int, coinsEarned: Int, didPass: Bool)
}

// MARK: - Watch Mode
enum WatchMode {
    case companion    // iPhone paired and reachable
    case standalone   // No iPhone or unreachable
}

// MARK: - App State
@MainActor
class WatchAppState: ObservableObject {
    @Published var currentScreen: WatchScreen = .loading
    @Published var mode: WatchMode = .standalone

    init() {
        updateMode()
    }

    // MARK: - Mode Detection
    func updateMode() {
        guard WCSession.isSupported() else {
            mode = .standalone
            return
        }
        let session = WCSession.default
        mode = session.isReachable ? .companion : .standalone
    }

    // MARK: - Navigation
    func navigateToHome() {
        currentScreen = .home
    }

    func startGame(level: Int) {
        currentScreen = .game(level: level)
    }

    func showLevelComplete(level: Int, score: Int, coinsEarned: Int, didPass: Bool) {
        currentScreen = .levelComplete(level: level, score: score, coinsEarned: coinsEarned, didPass: didPass)
    }

    func startNextLevel(after level: Int) {
        currentScreen = .game(level: level + 1)
    }

    func navigateToSettings() {
        currentScreen = .settings
    }
}
