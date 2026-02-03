You are updating an existing iOS + watchOS kids spelling game app.
All core systems (profiles, coin shop, coins, achievements, sync) already exist.

Implement the following feature updates.

1️⃣ Profile Settings — Change Avatar After Creation (iPhone)
Goal

Allow users to change their avatar anytime from Settings.

Requirements

Add a new row in Settings → Profile Section

Label: “Change Avatar”

Opens the same avatar picker used during profile creation

Avatar picker must:

Show preset avatar options

Highlight current avatar

Save avatar to the active profile

After change:

Immediately refresh UI (home screen, profile switcher, headers)

Sync updated avatar with cloud profile record

2️⃣ Settings Cleanup — Remove Voice Selection (iPhone)
Goal

Remove unused voice selector.

Requirements

Remove the Voice Selection section from Settings UI

Remove unused dropdown UI code

Keep existing TTS voice internally (no logic change)

Ensure no broken references remain

3️⃣ Daily Check-In Reward System (iPhone + Watch)
Goal

Increase daily engagement with predictable rewards.

Rewards
Action	Reward
Daily check-in	50 coins
5 check-ins in same week	Bonus 50 coins

Max weekly total = 300 coins

Check-In Logic

A check-in occurs when the player:

Opens the app and

Completes at least one level

Rules:

Only 1 check-in per calendar day

Week resets using device locale calendar

Start of week = system calendar first weekday

Per-Profile Data
lastCheckInDate: Date?
weeklyCheckInDates: [Date]
weeklyBonusAwarded: Bool

Reward Flow

When a level is completed:

If today not yet checked in

Add today to weeklyCheckInDates

Award 50 coins

Show “Daily Reward +50” animation

If weeklyCheckInDates.count == 5 and bonus not awarded

Award extra 50 coins

Set weeklyBonusAwarded = true

Show “Weekly Bonus +50” celebration animation

Reset weekly data when a new week begins.

UI — Weekly Tracker
iPhone Home Screen

Add a Check-In Tracker card:

7 circles labeled by weekday

Filled = completed check-in

Empty = not yet

Text below:

“Check in 5 days this week to earn a 50-coin bonus!”

If bonus earned:

“Weekly bonus earned! 🎉”

Watch Home Screen

Add a compact tracker row:

7 small dots

Filled vs empty states

Tap opens detail screen explaining rewards

4️⃣ Coin Shop Price Rebalance (iPhone + Watch)
Goal

Adjust economy to match new coin rewards.

Requirement

Multiply cost of all shop items by 3×

Example:

Item	Old	New
Super Bee	800	2400
Astronaut Bee	1500	4500
Confetti Burst	700	2100

Rules:

Do NOT change item IDs

Do NOT relock previously unlocked items

Update prices everywhere displayed (iPhone + Watch)

5️⃣ Watch UI Improvements
5.1 Increase Top Row Icon Sizes

Increase size of the following icons by +2 points:

Bee icon

Achievements icon

Any other icons in the top row

Do not change layout structure — only increase icon size for better readability.

5.2 Achievements View Simplification (Watch)

In the Achievements list screen:

Remove the color rarity label row (Common, Rare, Epic, etc.)

Keep rarity info only in the Achievement Detail screen

Reduce row height accordingly for cleaner layout

5.3 Reorder Top Row Icons (Watch)

Update top row layout so it becomes:

[Bee Icon] [Achievements Icon] [Coins]

Specifically:

Move Achievements icon to the right side, just before the coin count

Maintain tap targets and accessibility labels

5.4 Show App Version in Watch Settings

Add the app version number to the Watch Settings screen.

Requirements:

Display at the bottom of the Settings list

Format:

Version X.Y.Z

Pull version dynamically from bundle:

Bundle.main.infoDictionary?["CFBundleShortVersionString"]


Optional:

Also show build number:

Version 1.4.2 (Build 37)

This is read-only informational text, not interactive.

6️⃣ Sync Requirements

Sync per profile across iPhone and Watch:

Avatar selection

Daily check-in data

Weekly bonus state

Coin balance changes

Shop price display (shared config)

✅ Acceptance Criteria

✔ Users can change avatar anytime
✔ Voice section removed
✔ Daily check-ins award coins correctly
✔ Weekly bonus triggers at 5 check-ins
✔ Tracker visible on iPhone + Watch
✔ Shop prices increased 3× everywhere
✔ No loss of unlocked items
✔ Watch top-row icons visibly larger
✔ Watch Achievements list simplified
✔ Watch icon order updated
✔ Watch Settings shows app version
✔ All new data syncs properly

Keep UI playful, readable for kids, and consistent with existing theme system.
