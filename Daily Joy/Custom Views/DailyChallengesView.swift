//
//  ChallengesView.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/31/25.
//

import SwiftUI
import SwiftData

struct DailyChallengesView: View {

    init() {}

    @Environment(\.modelContext) private var modelContext
    @State private var todaysChallenge: DailyChallenge?
    @State private var challengeManager: ChallengeManager?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    if let challenge = todaysChallenge {
                        challengeCard(
                            title: "Challenge 1",
                            prompt: challenge.challenge1,
                            isCompleted: challenge.challenge1Completed,
                            color: .purple
                        )

                        challengeCard(
                            title: "Challenge 2",
                            prompt: challenge.challenge2,
                            isCompleted: challenge.challenge2Completed,
                            color: .blue
                        )
                    }

                    instructionsSection
                }
                .padding()
            }
            .navigationTitle("Daily Challenges")
            .onAppear {
                loadTodaysChallenge()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Today's Challenges")
                .font(.largeTitle.bold())

            Text("Complete these actions and create a moment to celebrate!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
    }

    private func challengeCard(
        title: String,
        prompt: String,
        isCompleted: Bool,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(color)

                Spacer()

                if isCompleted {
                    Label("Completed!", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                } else {
                    Label("Pending", systemImage: "circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(prompt)
                .font(.title3)
                .fontWeight(.medium)

            if !isCompleted {
                Text("Create a moment after completing this challenge!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isCompleted ? color.opacity(0.1) : Color(.systemBackground))
                .shadow(color: color.opacity(0.2), radius: 10)
        )
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How It Works", systemImage: "lightbulb.fill")

            instructionRow(number: "1", text: "Do one of the challenges above")
            instructionRow(number: "2", text: "Create a moment describing what you did")
            instructionRow(number: "3", text: "We'll automatically detect completion")

            Divider()

            Text("New challenges appear every day at midnight")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.purple))

            Text(text)
                .font(.subheadline)
        }
    }

    private func loadTodaysChallenge() {
        if challengeManager == nil {
            challengeManager = ChallengeManager(modelContext: modelContext)
        }
        todaysChallenge = challengeManager?.getTodaysChallenge()
    }
}

#Preview {
    DailyChallengesView()
        .sampleDataContainer()
}

