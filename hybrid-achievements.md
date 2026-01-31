# Hybrid Achievements System – Implementation Specification

## Goal

Implement a **hybrid achievements architecture** that combines:

1. **In-App Achievements (Primary System)**

   * Seasonal
   * Coin rewards
   * Kid-friendly badges and animations
   * Fully functional offline

2. **Game Center Achievements (Secondary System)**

   * Lifetime prestige milestones
   * No coin rewards
   * Never reset
   * Used for long-term credibility and future competitive features

This system must work on **iPhone and Apple Watch** and remain functional even if Game Center is unavailable.

---

## 1. Core Architecture

The in-app system is the **source of truth**.
Game Center is a **secondary reporting layer** for selected lifetime milestones.

Game Center must never block gameplay or rewards.

---

## 2. Achievement Data Model

Create a unified model for all achievements:

```swift
struct Achievement {
    let id: String                 // internal identifier
    let title: String
    let description: String
    let coinReward: Int?           // nil if no coins
    let isSeasonal: Bool           // true if resets monthly
    let gameCenterID: String?      // nil if not linked to Game Center
    var isUnlocked: Bool
    var progress: Double           // 0.0 – 1.0 for progressive goals
}
```

---

## 3. Achievement Categories

### 3.1 In-App Only (No Game Center)

These may reset or repeat.

* 3 Day Streak
* 7 Day Streak
* Earn 500 coins in a month
* Perfect levels in current season
* Beat your best weekly score

`gameCenterID = nil`

### 3.2 Hybrid Achievements (Also Report to Game Center)

These are **lifetime milestones**.

| In-App Achievement            | Game Center ID     |
| ----------------------------- | ------------------ |
| Complete 25 levels            | gc_levels_25       |
| Complete 100 levels           | gc_levels_100      |
| Earn 5,000 lifetime coins     | gc_coins_5000      |
| 30-day streak (lifetime best) | gc_streak_30       |
| Complete all Grade 1          | gc_grade1_complete |

These achievements:

* Unlock once
* Never reset
* May grant coins in-app, but Game Center itself does not

---

## 4. Unlock Flow

When player action triggers progress:

```swift
func updateAchievementProgress(id: String, progress: Double) {
    var achievement = loadAchievement(id)
    achievement.progress = progress

    if progress >= 1.0 && !achievement.isUnlocked {
        unlockAchievement(achievement)
    }

    saveAchievement(achievement)
}
```

### Unlock Logic

```swift
func unlockAchievement(_ achievement: Achievement) {
    achievement.isUnlocked = true

    if let coins = achievement.coinReward {
        addCoins(coins)
    }

    showAchievementAnimation(achievement)
    saveAchievement(achievement)

    if let gcID = achievement.gameCenterID {
        reportGameCenterAchievement(id: gcID)
    }
}
```

---

## 5. Game Center Integration

### 5.1 Requirements

* Enable **Game Center capability** in Xcode
* Authenticate player silently at app launch
* Do not force login popups repeatedly

### 5.2 Reporting Achievement

```swift
func reportGameCenterAchievement(id: String) {
    let achievement = GKAchievement(identifier: id)
    achievement.percentComplete = 100
    achievement.showsCompletionBanner = false

    GKAchievement.report([achievement]) { error in
        // Fail silently — never affect gameplay
    }
}
```

Rules:

* Only report once per achievement
* Ignore errors
* Never block UI or rewards

---

## 6. Monthly Reset Behavior

At the start of a new month:

Reset only achievements where:

```
isSeasonal == true
```

Do NOT reset:

* Lifetime achievements
* Game Center–linked achievements

---

## 7. UI Requirements

### Achievements Screen (iPhone)

* Grid of badge icons
* Locked = silhouette
* Tap shows description and progress

### Achievements Screen (Watch)

* List view
* Icon + title + progress bar

### Unlock Animation

* Badge appears
* Title + reward coins shown
* Confetti or sparkle effect
* Auto-dismiss

---

## 8. Data Persistence

Store locally:

* Unlock states
* Progress values
* Seasonal flags

Sync between iPhone and Watch using WatchConnectivity.

Phone acts as source of truth when reachable.

---

## 9. Failure Safety

If Game Center is:

* Offline
* Player not signed in
* Reporting fails

Then:

* Achievement still unlocks locally
* Coins still awarded
* No error shown to user

---

## 10. Deliverables for Claude Code

Claude should implement:

1. Unified achievement model
2. In-app achievement engine
3. Seasonal reset logic
4. Coin reward integration
5. Achievement UI screens (iPhone + Watch)
6. Unlock animations
7. Game Center authentication
8. Reporting of selected lifetime achievements
9. Safe fallback when Game Center is unavailable

---

**End of Hybrid Achievements Implementation Spec**

