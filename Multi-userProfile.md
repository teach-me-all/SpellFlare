# Spellflare – Extended Requirements (Post Phase 1)

Sections 1–10 of the original Coin Shop requirements are already implemented in the app.
This document now only defines **new and upcoming features starting from Section 11 onward**.

---

## 11. Multiple Player Profiles (Household Mode)

The app must support **multiple child profiles** on the same device so families with more than one child can keep progress separate.

This is a **local profile system** tied to the device, while purchases remain shared.

### 11.1 Profile Basics

* The app supports **multiple player profiles** (minimum 4, scalable later)
* Each profile represents one child/player
* Profiles are selected at app launch or from a profile switcher on the home screen

Each profile must have:

* Profile name
* Avatar icon (choose from preset kid-friendly icons)
* Grade selection

---

### 11.2 Data That Must Be Separate Per Profile

All gameplay and rewards data must be isolated per profile.

Per-profile data includes:

**Learning Progress**

* Current grade
* Levels completed (all grades)
* Current level progress
* Accuracy stats

**Economy**

* Coin balance
* Coin earning history (optional analytics)

**Rewards & Customization**

* Unlocked shop items
* Equipped bee skin
* Equipped theme
* Equipped celebration effect

**Achievements & Activity**

* Achievement progress (non–Game Center)
* Streaks (daily/weekly)
* Best scores
* Activity history used for achievements

**Leaderboards (future)**

* Scores submitted to monthly/state/country boards must be tied to the active profile

Switching profiles must instantly switch all of the above data.

---

### 11.3 Data That Is Shared Across All Profiles

The following must remain **device-wide and shared**:

* In‑App Purchase entitlements (e.g., Full Version unlock)
* Ads removal entitlement
* Any future paid subscriptions

If one profile unlocks Full Version via IAP, all profiles on the device benefit.

Coins, items, and progress must **NOT** be shared.

---

### 11.4 Storage Model

The app should store a separate local data bundle per profile.

Conceptually:

```swift
struct PlayerProfile {
    let id: UUID
    var name: String
    var grade: Int
    var coins: Int
    var levelProgress: [String: Any]
    var unlockedItemIDs: [String]
    var equippedItems: [ShopCategory: String]
    var achievementProgress: [String: Double]
    var streakData: [String: Int]
    var lastUpdated: Date
}
```

A `ProfileManager` controls:

* Creating profiles
* Deleting profiles
* Switching active profile
* Persisting and loading profile data

---

### 11.5 Cloud Sync Behavior (Important)

Each profile must sync **independently** to CloudKit.

Cloud structure:

* One `PlayerProfile` record per child profile
* Each record linked to the Game Center player ID

This ensures:

* Sibling A deleting progress does not affect Sibling B
* Reinstall restores all child profiles

---

### 11.6 Profile Switching UX

* Add a **Profile Switcher button** on the home screen
* Tapping shows all profiles with avatar + name
* Option to **Add New Profile**
* Optional parental gate (simple math question) before deleting a profile

Switching profiles should:

* Immediately reload coins
* Reload equipped cosmetics
* Reload level progress
* Refresh UI without app restart

---

### 11.7 Apple Watch Behavior

Watch app must mirror the **currently selected phone profile**.

When profile changes on phone:

* Sync active profile ID to Watch
* Watch loads that profile’s progress and cosmetics

Watch does NOT manage multiple profiles independently.

---

### 11.8 Edge Cases

| Scenario                     | Expected Behavior                |
| ---------------------------- | -------------------------------- |
| One child resets progress    | Only that profile resets         |
| One child deletes profile    | Other profiles unaffected        |
| IAP purchased on one profile | Available to all profiles        |
| App reinstalled              | All profiles restored from cloud |

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

