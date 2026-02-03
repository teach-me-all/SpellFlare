# Spellflare Coin Shop – Phase 1 (Cosmetic Rewards)

## Goal

Introduce a **coins redemption system** that allows players to spend earned coins on fun, kid-friendly cosmetic rewards.

This system must:

* Work offline
* Sync between iPhone and Apple Watch
* Not affect gameplay difficulty or learning balance
* Encourage continued play and coin earning

Phase 1 includes:

1. Bee character skins
2. Background themes
3. Celebration effects

---

## 1. Core Shop Rules

* Coins are earned from gameplay and achievements
* Coins can only be spent on cosmetic items
* All purchases are permanent unlocks
* No random rewards or loot boxes
* No real money purchases tied to coins

---

## 2. Shop Categories

### 🐝 Bee Skins

Changes the appearance of the main bee character.

Example items:

| Item ID       | Name            | Cost           |
| ------------- | --------------- | -------------- |
| bee_default   | Classic Bee     | Free (default) |
| bee_super     | Super Bee       | 800 coins      |
| bee_astronaut | Astronaut Bee   | 1,500 coins    |
| bee_ninja     | Ninja Bee       | 1,200 coins    |
| bee_royal     | Royal Crown Bee | 2,000 coins    |

Effects:

* Used in home screen
* Used in level completion animations
* Used in achievements celebrations

---

### 🎨 Background Themes

Changes background visuals in menus and gameplay screens.

Example items:

| Item ID       | Name             | Cost        |
| ------------- | ---------------- | ----------- |
| theme_default | Sunny Meadow     | Free        |
| theme_space   | Space Adventure  | 1,000 coins |
| theme_ocean   | Underwater World | 1,200 coins |
| theme_candy   | Candy Land       | 1,500 coins |
| theme_forest  | Magic Forest     | 1,800 coins |

Themes should be subtle and not reduce text readability.

---

### 🎉 Celebration Effects

Visual effects shown after completing levels or unlocking achievements.

Example items:

| Item ID               | Name           | Cost        |
| --------------------- | -------------- | ----------- |
| celebration_default   | Sparkle Pop    | Free        |
| celebration_confetti  | Confetti Burst | 700 coins   |
| celebration_fireworks | Fireworks Show | 1,300 coins |
| celebration_rainbow   | Rainbow Trail  | 1,600 coins |
| celebration_stars     | Shooting Stars | 1,900 coins |

Effects must be short and non-blocking.

---

## 3. Data Model

```swift
struct ShopItem {
    let id: String
    let name: String
    let category: ShopCategory
    let cost: Int
    var isUnlocked: Bool
    var isEquipped: Bool
}

enum ShopCategory {
    case beeSkin
    case theme
    case celebration
}
```

Store locally:

* Unlocked items
* Currently equipped bee skin
* Current theme
* Current celebration effect

---

## 4. Purchase Flow

When player taps a locked item:

1. Check if player has enough coins
2. If yes:

   * Deduct coins
   * Mark item as unlocked
   * Auto-equip item
   * Show purchase animation
3. If no:

   * Show friendly message: “Keep playing to earn more coins!”

All logic must work offline.

---

## 5. Equip Flow

Players can switch between unlocked items anytime.
Only one item per category can be equipped at a time.

---

## 6. UI Requirements

### Shop Screen (iPhone)

* Tabs for: Bee Skins | Themes | Celebrations
* Grid layout
* Locked items show price tag with coin icon
* Equipped item shows “Equipped” badge

### Shop Screen (Watch)

* List layout
* Tap to purchase/equip
* Simplified previews

---

## 7. Animations

### Purchase Animation

* Coin count decreases with rolling number animation
* Item pops with glow

### Equip Animation

* Short bounce or shine effect

---

## 8. Sync Requirements

Sync between iPhone and Watch:

* Coin balance
* Unlocked items
* Equipped items

Phone acts as source of truth when reachable.

---

## 9. Non-Functional Requirements

* No ads tied to purchases
* No timers or pressure mechanics
* Kid-friendly language
* Fast loading

---

## 10. Deliverables for Claude Code

Claude should implement:

1. Shop data model
2. Coin deduction logic
3. Unlock + equip system
4. Shop UI screens (iPhone + Watch)
5. Purchase and equip animations
6. Local persistence
7. WatchConnectivity sync

---

**End of Phase 1 Coin Shop Requirements**

## Cloud Save & Restore Requirements

The app must persist player progress beyond local device storage using iCloud (CloudKit) tied to the user’s Game Center account when available.

### Data That Must Be Backed Up

The following player data must be saved to the user’s private CloudKit database and restored on reinstall or device change:

* Coins balance
* Unlocked shop items
* Equipped items (active bee skin, theme, celebration, etc.)
* Achievements progress (in addition to Game Center where applicable)
* Streaks (daily/weekly streak state and counters)
* Level progress (highest level reached, stars/scores per level if applicable)

### Save Triggers

Cloud save must occur automatically when any of the following changes:

* Coins earned or spent
* A shop item is unlocked or equipped
* Achievement progress changes
* Streak value updates
* Level completion or progress changes

### Restore Logic

On app launch:

1. Authenticate Game Center player.
2. Attempt to fetch the player profile from CloudKit.
3. If a cloud record exists, restore all fields listed above to local storage.
4. If no cloud record exists, create a new profile and begin local tracking.

### Offline Behavior

* Gameplay must continue using local storage when offline.
* Changes made offline must sync to CloudKit on the next successful connection.

### Non–Game Center Users

* If the user is not signed into Game Center, progress is stored locally only.
* If the app is deleted while not signed into Game Center, progress may be lost.
* The app may show a non-blocking prompt encouraging Game Center sign-in for backup.

### Data Structure (Conceptual)

Each player will have one CloudKit record (e.g., `PlayerProfile`) containing:

* totalCoins: Int
* unlockedItemIDs: [String]
* equippedItemIDs: Dictionary<String, String>
* achievementProgress: Dictionary<String, Double>
* streakData: Dictionary<String, Int>
* levelProgress: Dictionary<String, Any>
* lastUpdated: Date

### Conflict Resolution

If both local and cloud data exist:

* Use the record with the most recent `lastUpdated` timestamp.
* Never silently delete player progress; always prefer the more advanced state.

