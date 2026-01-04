//
//  OnboardingView.swift
//  spelling-bee iOS App
//
//  Onboarding flow for new users.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var name = ""
    @State private var selectedGrade = 1

    var body: some View {
        ZStack {
            // Background gradient
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

            VStack(spacing: 30) {
                Spacer()

                switch currentStep {
                case 0:
                    WelcomeStep(onContinue: { currentStep = 1 })
                case 1:
                    NameStep(name: $name, onContinue: { currentStep = 2 })
                case 2:
                    GradeStep(selectedGrade: $selectedGrade, onComplete: completeOnboarding)
                default:
                    EmptyView()
                }

                Spacer()

                // Progress dots
                HStack(spacing: 12) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index == currentStep ? Color.cyan : Color.white.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
    }

    private func completeOnboarding() {
        appState.createProfile(name: name.isEmpty ? "Speller" : name, grade: selectedGrade)
    }
}

// MARK: - Welcome Step
struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("🐝")
                .font(.system(size: 100))

            Text("SpellFlare")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Learn to spell with fun!")
                .font(.title3)
                .foregroundColor(.secondary)

            Button(action: onContinue) {
                Text("Let's Start!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cyan)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
    }
}

// MARK: - Name Step
struct NameStep: View {
    @Binding var name: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("👋")
                .font(.system(size: 80))

            Text("What's your name?")
                .font(.title)
                .fontWeight(.bold)

            TextField("Enter your name", text: $name)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)
                .padding(.horizontal, 40)

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cyan)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Grade Step
struct GradeStep: View {
    @Binding var selectedGrade: Int
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("📚")
                .font(.system(size: 80))

            Text("What grade are you in?")
                .font(.title)
                .fontWeight(.bold)

            // Grade picker grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(1...7, id: \.self) { grade in
                    Button {
                        selectedGrade = grade
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(grade)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Grade")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 70)
                        .foregroundColor(selectedGrade == grade ? .white : .primary)
                        .background(selectedGrade == grade ? Color.purple : Color.white.opacity(0.8))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 20)

            Button(action: onComplete) {
                Text("Start Learning!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cyan)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AppState())
    }
}
