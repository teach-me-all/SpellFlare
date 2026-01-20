//
//  HomeView.swift
//  spelling-bee iOS App
//
//  Main home screen showing levels and progress.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var speechService = SpeechService.shared
    @ObservedObject var updateService = AppUpdateService.shared
    @State private var showGradePicker = false
    @State private var showVoicePicker = false
    @State private var showUpdateAlert = false
    @State private var selectedLevelGroup = 0

    var profile: UserProfile? {
        appState.profile
    }

    var currentLevel: Int {
        profile?.currentLevel ?? 1
    }

    var body: some View {
        ZStack {
            // Vibrant Purple Gradient Background (like Image #4)
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.95),
                    Color(red: 0.45, green: 0.25, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header
                TopHeaderView(
                    profile: profile,
                    showGradePicker: $showGradePicker,
                    showVoicePicker: $showVoicePicker
                )

                // Level Group Selector (like date picker)
                LevelGroupSelector(
                    selectedGroup: $selectedLevelGroup,
                    currentLevel: currentLevel
                )

                // Levels List
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Levels")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Spacer()

                            Text("🐝")
                                .font(.title2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        LevelListView(
                            levelGroup: selectedLevelGroup,
                            currentLevel: currentLevel
                        )
                    }
                    .padding(.bottom, 30)
                }

                // Banner Ad at bottom (only if ads not removed)
                BannerAdView()
            }
        }
        .sheet(isPresented: $showGradePicker) {
            GradePickerSheet()
        }
        .sheet(isPresented: $showVoicePicker) {
            VoicePickerSheet()
        }
        .onAppear {
            // Set initial group based on current level
            selectedLevelGroup = (currentLevel - 1) / 10

            // Check for app updates (non-blocking)
            Task {
                await updateService.checkForUpdate()
                if updateService.updateAvailable {
                    showUpdateAlert = true
                }
            }
        }
        .alert("Update Available", isPresented: $showUpdateAlert) {
            Button("Update") {
                updateService.openAppStore()
            }
            Button("Later", role: .cancel) {
                updateService.dismissUpdate()
            }
        } message: {
            Text("A newer version of the app is available with improvements and fixes.")
        }
    }
}

// MARK: - Top Header View
struct TopHeaderView: View {
    @EnvironmentObject var appState: AppState
    let profile: UserProfile?
    @Binding var showGradePicker: Bool
    @Binding var showVoicePicker: Bool

    var completionPercent: Int {
        let completed = profile?.completedLevels.count ?? 0
        return Int((Double(completed) / 50.0) * 100)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Grade Button
                Button {
                    showGradePicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 16))
                        Text("Grade \(profile?.grade ?? 1)")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.9))
                    )
                }

                Spacer()

                // Progress Ring
                CompactProgressRing(percent: completionPercent)

                Spacer()

                // Settings Button
                Button {
                    appState.navigateToSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 20)

            // Welcome text
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hi, \(profile?.name ?? "Speller")!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Ready to practice spelling?")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Coins display
                CoinsDisplayView(coins: profile?.totalCoins ?? 0)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Compact Progress Ring
struct CompactProgressRing: View {
    let percent: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                .frame(width: 44, height: 44)

            Circle()
                .trim(from: 0, to: CGFloat(percent) / 100)
                .stroke(
                    LinearGradient(
                        colors: [.cyan, .white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))

            Text("\(percent)%")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Level Group Selector (like date picker in image)
struct LevelGroupSelector: View {
    @Binding var selectedGroup: Int
    let currentLevel: Int

    let groups = ["1-10", "11-20", "21-30", "31-40", "41-50"]

    var body: some View {
        VStack(spacing: 12) {
            // Group navigation
            HStack {
                Button {
                    if selectedGroup > 0 {
                        withAnimation { selectedGroup -= 1 }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        if selectedGroup > 0 {
                            Text(groups[selectedGroup - 1])
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(selectedGroup > 0 ? .white.opacity(0.7) : .clear)
                }
                .disabled(selectedGroup == 0)

                Spacer()

                Text("Levels \(groups[selectedGroup])")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                Button {
                    if selectedGroup < 4 {
                        withAnimation { selectedGroup += 1 }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if selectedGroup < 4 {
                            Text(groups[selectedGroup + 1])
                        }
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(selectedGroup < 4 ? .white.opacity(0.7) : .clear)
                }
                .disabled(selectedGroup == 4)
            }
            .padding(.horizontal, 20)

            // Level pills (like date pills in image)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(levelRange, id: \.self) { level in
                            LevelPill(
                                level: level,
                                isCurrentLevel: level == currentLevel,
                                currentLevel: currentLevel
                            )
                            .id(level)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .onAppear {
                    if levelRange.contains(currentLevel) {
                        proxy.scrollTo(currentLevel, anchor: .center)
                    }
                }
            }
        }
        .padding(.vertical, 16)
    }

    var levelRange: [Int] {
        let start = selectedGroup * 10 + 1
        return Array(start...(start + 9))
    }
}

// MARK: - Level Pill
struct LevelPill: View {
    @EnvironmentObject var appState: AppState
    let level: Int
    let isCurrentLevel: Bool
    let currentLevel: Int

    var isCompleted: Bool {
        appState.profile?.isLevelCompleted(level) ?? false
    }

    var isUnlocked: Bool {
        appState.profile?.isLevelUnlocked(level) ?? false
    }

    var body: some View {
        Button {
            if isUnlocked {
                appState.navigateToGame(level: level)
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(pillBackground)
                        .frame(width: 56, height: 56)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.purple)
                    } else if isUnlocked {
                        Text("\(level)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isCurrentLevel ? .purple : .white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Text(levelLabel)
                    .font(.system(size: 11))
                    .foregroundColor(isCurrentLevel ? .cyan : .white.opacity(0.7))
                    .fontWeight(isCurrentLevel ? .semibold : .regular)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    var pillBackground: Color {
        if isCurrentLevel {
            return .white
        } else if isCompleted {
            return .cyan
        } else if isUnlocked {
            return Color.white.opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }

    var levelLabel: String {
        if isCompleted {
            return "Done"
        } else if isCurrentLevel {
            return "Current"
        } else if isUnlocked {
            return "Play"
        } else {
            return "Locked"
        }
    }
}

// MARK: - Level List View (like schedule list in image)
struct LevelListView: View {
    @EnvironmentObject var appState: AppState
    let levelGroup: Int
    let currentLevel: Int

    var levelRange: [Int] {
        let start = levelGroup * 10 + 1
        return Array(start...(start + 9))
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(levelRange, id: \.self) { level in
                LevelRow(level: level, currentLevel: currentLevel)
            }
        }
    }
}

// MARK: - Level Row (like schedule row in image)
struct LevelRow: View {
    @EnvironmentObject var appState: AppState
    let level: Int
    let currentLevel: Int

    var isCompleted: Bool {
        appState.profile?.isLevelCompleted(level) ?? false
    }

    var isUnlocked: Bool {
        appState.profile?.isLevelUnlocked(level) ?? false
    }

    var isCurrent: Bool {
        level == currentLevel
    }

    var isLastInGroup: Bool {
        level % 10 == 0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Time/Level indicator column
            VStack(spacing: 4) {
                Text("Lv")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))

                Text("\(level)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isCurrent ? .cyan : .white)

                // Vertical line
                if !isLastInGroup {
                    Rectangle()
                        .fill(isCurrent ? Color.cyan : Color.white.opacity(0.2))
                        .frame(width: 2, height: 40)
                }
            }
            .frame(width: 40)

            // Current level indicator dot
            if isCurrent {
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 8, height: 8)
                    .offset(y: 20)
            }

            // Level Card
            Button {
                if isUnlocked {
                    appState.navigateToGame(level: level)
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(levelTitle)
                            .font(.headline)
                            .foregroundColor(cardTextColor)

                        Text(levelSubtitle)
                            .font(.caption)
                            .foregroundColor(cardTextColor.opacity(0.8))

                        HStack(spacing: 8) {
                            // Word count
                            HStack(spacing: 4) {
                                Image(systemName: "text.word.spacing")
                                    .font(.system(size: 10))
                                Text("10 words")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(cardTextColor.opacity(0.7))
                        }
                    }

                    Spacer()

                    // Status icon
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                    } else if isUnlocked {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(isCurrent ? .white.opacity(0.9) : .purple)
                    } else {
                        Image(systemName: "lock.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(16)
                .background(cardBackground)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .disabled(!isUnlocked)
        }
        .padding(.horizontal, 20)
    }

    var levelTitle: String {
        if isCompleted {
            return "Level \(level) - Completed"
        } else if isCurrent {
            return "Level \(level) - In Progress"
        } else if isUnlocked {
            return "Level \(level) - Ready"
        } else {
            return "Level \(level) - Locked"
        }
    }

    var levelSubtitle: String {
        let grade = appState.profile?.grade ?? 1
        return "Grade \(grade) spelling words"
    }

    var cardBackground: Color {
        if isCurrent {
            return Color(red: 0.3, green: 0.15, blue: 0.7)
        } else if isCompleted {
            return .cyan
        } else if isUnlocked {
            return Color.white.opacity(0.15)
        } else {
            return Color.white.opacity(0.08)
        }
    }

    var cardTextColor: Color {
        return .white
    }
}

// MARK: - Grade Picker Sheet (same style as voice picker)
struct GradePickerSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let gradeDescriptions = [
        1: "Basic words for beginners",
        2: "Simple everyday words",
        3: "Common vocabulary words",
        4: "Intermediate spelling words",
        5: "Advanced vocabulary",
        6: "Complex word patterns",
        7: "Challenging words"
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(1...7, id: \.self) { grade in
                    Button {
                        appState.updateGrade(grade)
                        dismiss()
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(appState.profile?.grade == grade ? Color.purple : Color.purple.opacity(0.1))
                                    .frame(width: 44, height: 44)

                                Text("\(grade)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(appState.profile?.grade == grade ? .white : .purple)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Grade \(grade)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(gradeDescriptions[grade] ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 8)

                            Spacer()

                            if appState.profile?.grade == grade {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Grade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Voice Picker Sheet
struct VoicePickerSheet: View {
    @ObservedObject var speechService = SpeechService.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(speechService.availableVoices) { voice in
                    Button {
                        speechService.selectedVoice = voice
                        speechService.previewVoice(voice)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(voice.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(voice.language)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if speechService.selectedVoice == voice {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            }

                            Button {
                                speechService.previewVoice(voice)
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState())
    }
}
