# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Spelling Bee Queen** - A kids spelling practice app for iOS and watchOS (Grades 1-7). The app speaks words aloud and children spell them using speech recognition or keyboard input.

## Build Commands

```bash
# Build iOS App
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project spelling-bee.xcodeproj -scheme "spelling-bee iOS App" -destination 'platform=iOS Simulator,name=iPhone 14 Pro' build

# Build Watch App
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project spelling-bee.xcodeproj -scheme "spelling-bee Watch App" -destination 'generic/platform=watchOS Simulator' build

# Run unit tests
xcodebuild -project spelling-bee.xcodeproj -scheme "spelling-bee Watch AppTests" -destination 'platform=watchOS Simulator,name=Apple Watch Series 8 (45mm)' test
```

## Architecture

- **Platforms**: iOS 16+, watchOS 9.1+
- **Language**: Swift 5, SwiftUI
- **Pattern**: MVVM with ObservableObject
- **Entry Points**:
  - iOS: `spelling_bee_iOS_App.swift` -> `ContentView.swift`
  - watchOS: `spelling_beeApp.swift` -> `ContentView.swift`

### App Flow

```
ContentView (root navigation)
├── OnboardingView (first launch: name + grade selection)
├── HomeView (level grid with progress)
│   └── SettingsView (grade, voice, purchases, reset)
└── GameView (gameplay per level)
    ├── WordPresentationView (TTS speaks word)
    ├── SpellingInputView (speech recognition / keyboard)
    ├── FeedbackView (correct/incorrect with retry option)
    └── LevelCompleteView (celebration + ads)
```

### Key Services

| Service | File | Purpose |
|---------|------|---------|
| **SpeechService** | `Services/SpeechService.swift` | TTS (AVSpeechSynthesizer) and speech recognition. Handles phonetic letter mappings. |
| **WordBankService** | `Services/WordBankService.swift` | Word selection by grade (1-7) and level (1-50). Difficulty = grade + (level-1)/10. |
| **PersistenceService** | `Services/PersistenceService.swift` | UserDefaults storage for UserProfile. |
| **StoreManager** | `Services/StoreManager.swift` | StoreKit 2 IAP handling for "Remove Ads" purchase. |
| **AdManager** | `Services/AdManager.swift` | (iOS only) Ad display logic - only after test completion. |

### State Management

- **AppState** (`ViewModels/AppState.swift`): Global state via @EnvironmentObject. Screen navigation enum: `.onboarding`, `.home`, `.game(level)`, `.settings`
- **GameViewModel** (`ViewModels/GameViewModel.swift`): Per-game session. GamePhase: `presenting` → `spelling` → `feedback` → `levelComplete`

### Data Models

- **UserProfile**: name, grade (1-7), completedLevels (Set<Int>), currentLevel
- **Word**: text, difficulty (1-12 scale)

## Targets

| Target | Description |
|--------|-------------|
| `spelling-bee` | iOS container app for Watch distribution |
| `spelling-bee iOS App` | Main iOS application |
| `spelling-bee Watch App` | Main watchOS application |
| `spelling-bee Watch AppTests` | Unit tests |
| `spelling-bee Watch AppUITests` | UI tests |

## Required Capabilities

**Info.plist entries:**
- `NSSpeechRecognitionUsageDescription` - "Spelling Bee needs to hear you spell words"
- `NSMicrophoneUsageDescription` - "Spelling Bee uses the microphone to listen to your spelling"

---

## Kids Category Compliance

This app is designed for the **Kids Category** on the App Store. All features must comply with Apple's guidelines for children's apps.

### Ads Implementation Rules

**CRITICAL: Ads are ONLY shown after test/level completion - NEVER during active gameplay.**

| Rule | Implementation |
|------|----------------|
| Timing | Only after completing a spelling test (all 10 words) |
| Type | Non-personalized ads only - no behavioral tracking |
| Content | Age-appropriate, no violent/mature content |
| Frequency | Maximum once per completed test |
| Skip | Users can skip after countdown (5 sec iOS, 3 sec watchOS) |

**Platform-specific behavior:**

| Platform | Ad Type | Duration | Notes |
|----------|---------|----------|-------|
| iOS | Full-screen interstitial | 5 sec countdown | Shows `PlaceholderAdView` before navigation |
| watchOS | Static banner/text | 3 sec countdown | Minimal `WatchAdView` - no video |

**AdManager Flow:**
```swift
// Called when test completes
adManager.onTestCompleted()

// Check before navigation
if adManager.shouldShowAd && !storeManager.isAdsRemoved {
    // Show ad, then navigate
}
```

### In-App Purchase: Remove Ads

**Product Details:**
- Product ID: `remove_ads`
- Type: Non-consumable (permanent, one-time purchase)
- Price: $0.99 USD
- Restoreable: Yes (via "Restore Purchases")

**StoreKit 2 Implementation:**

```swift
// StoreManager.swift key methods:
func loadProducts() async           // Load product from App Store
func checkEntitlements() async      // Check if user owns product
func purchaseRemoveAds() async      // Initiate purchase
func restorePurchases() async       // Restore on new device
```

**Transaction Verification:**
- Always verify transactions cryptographically
- Only grant entitlement for `.verified` transactions
- Listen for `Transaction.updates` for external purchases

**Promo Codes:**
- Use Apple's built-in promo code system
- No custom coupon/code entry UI needed
- Users redeem via App Store → Redeem Gift Card or Code

### Parent Gate

**Purpose:** Prevent accidental purchases by children.

**Implementation:** Math multiplication problem (e.g., "What is 8 × 7?")
- Numbers range: 6-12 × 4-9 (easy for adults, hard for young children)
- Maximum 3 attempts before lockout
- Required before any purchase flow

**File:** `Views/Common/ParentGateView.swift`

```swift
ParentGateView {
    // Called only after correct answer
    Task {
        await storeManager.purchaseRemoveAds()
    }
}
```

### Kids Category Don'ts

- ❌ No external links (websites, social media)
- ❌ No login/account creation
- ❌ No data collection beyond app functionality
- ❌ No push notifications asking to buy
- ❌ No "limited time" or pressure language for purchases
- ❌ No ads during gameplay
- ❌ No personalized/targeted advertising

---

## StoreKit Testing

### Debug Mode

In DEBUG builds, `StoreManager` has a debug mode that simulates purchases without StoreKit:

```swift
#if DEBUG
private let debugMode = true  // Simulates purchase instantly
#else
private let debugMode = false
#endif
```

### StoreKit Configuration File

For testing real StoreKit flow in simulator:

1. File: `spelling-bee iOS App/Products.storekit`
2. In Xcode: Edit Scheme → Options → StoreKit Configuration → Select `Products.storekit`

---

## Adding New Files to Xcode

After creating new Swift files via CLI:

1. Open `spelling-bee.xcodeproj` in Xcode
2. Right-click appropriate folder (iOS App or Watch App)
3. Select "Add Files to spelling-bee..."
4. Ensure correct target is checked

Or manually edit `project.pbxproj`:
1. Add `PBXFileReference` entry
2. Add `PBXBuildFile` entry
3. Add to appropriate `PBXGroup`
4. Add to `PBXSourcesBuildPhase`

---

## Navigation Fix

When navigating between levels, add `.id(level)` to force view recreation:

```swift
case .game(let level):
    GameView(level: level)
        .id(level)  // Forces new instance when level changes
```

This prevents SwiftUI from reusing the same view instance when going from level N to level N+1.

---

## File Structure

```
spelling-bee/
├── spelling-bee.xcodeproj/
├── spelling-bee iOS App/
│   ├── spelling_bee_iOS_App.swift    # App entry point
│   ├── ContentView.swift              # Root navigation
│   ├── Products.storekit              # StoreKit config for testing
│   ├── Models/
│   │   ├── UserProfile.swift
│   │   └── Word.swift
│   ├── Services/
│   │   ├── SpeechService.swift
│   │   ├── WordBankService.swift
│   │   ├── PersistenceService.swift
│   │   ├── StoreManager.swift         # IAP handling
│   │   └── AdManager.swift            # Ad logic
│   ├── ViewModels/
│   │   ├── AppState.swift
│   │   └── GameViewModel.swift
│   └── Views/
│       ├── Onboarding/OnboardingView.swift
│       ├── Home/
│       │   ├── HomeView.swift
│       │   └── SettingsView.swift
│       ├── Game/
│       │   ├── GameView.swift
│       │   ├── FeedbackView.swift
│       │   └── LevelCompleteView.swift
│       └── Common/
│           └── ParentGateView.swift
├── spelling-bee Watch App/
│   ├── spelling_beeApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   ├── Services/
│   │   ├── SpeechService.swift
│   │   ├── WordBankService.swift
│   │   ├── PersistenceService.swift
│   │   └── StoreManager.swift         # Entitlement check only
│   ├── ViewModels/
│   └── Views/
│       ├── Onboarding/
│       ├── Home/
│       └── Game/
└── CLAUDE.md
```

---

## Summary: Rebuilding This App

To rebuild this app from scratch:

1. **Create SwiftUI project** with iOS and watchOS targets
2. **Implement core features:**
   - Onboarding (name + grade selection)
   - Word bank with grade-based difficulty
   - Speech synthesis for word pronunciation
   - Speech recognition for spelling input
   - Level progression (50 levels, 10 words each)
3. **Add monetization:**
   - Ads only after test completion (never during gameplay)
   - "Remove Ads" IAP ($0.99, non-consumable)
   - Parent gate (math problem) before purchases
   - Restore purchases functionality
4. **Platform differences:**
   - iOS: Full interstitial ads, purchase UI in Settings
   - watchOS: Static minimal ads, purchases via iPhone
5. **Kids Category compliance:**
   - No tracking, no external links, no pressure language
   - Parent verification for purchases
   - Age-appropriate content only
