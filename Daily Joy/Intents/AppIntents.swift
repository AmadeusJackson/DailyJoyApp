//
//  AppIntents.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/10/25.
//

import AppIntents
import SwiftData

// MARK: - Add Moment Intent
struct AddGratefulMomentIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Grateful Moment"
    static var description = IntentDescription("Create a new grateful moment")
    
    @Parameter(title: "What are you grateful for?")
    var title: String
    
    @Parameter(title: "Add a note (optional)")
    var note: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add moment: \(\.$title)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Moment.self, Badge.self, DailyChallenge.self)
        let context = ModelContext(container)
        
        let newMoment = Moment(
            title: title,
            note: note ?? "",
            imageData: nil,
            timestamp: .now
        )
        
        context.insert(newMoment)
        try context.save()
        
        let message = "Added '\(title)' to your grateful moments! 🎉"
        return .result(dialog: .init(stringLiteral: message))
    }
}

// MARK: - Check Streak Intent
struct CheckStreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Check My Streak"
    static var description = IntentDescription("Check your current grateful moments streak")
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Moment.self, Badge.self, DailyChallenge.self)
        let context = ModelContext(container)
        
        let descriptor = FetchDescriptor<Moment>(sortBy: [SortDescriptor(\.timestamp)])
        let moments = try context.fetch(descriptor)
        
        let streak = StreakCalculator().calculateStreak(for: moments)
        
        let message: String
        if streak == 0 {
            message = "You don't have a streak yet. Create your first moment today! 💪"
        } else if streak == 1 {
            message = "You're on a 1-day streak! Keep it going! 🔥"
        } else {
            message = "Amazing! You're on a \(streak)-day streak! 🔥"
        }
        
        return .result(dialog: .init(stringLiteral: message))
    }
}

// MARK: - Check Today's Challenges Intent
struct CheckTodaysChallengesIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Today's Challenges"
    static var description = IntentDescription("See what challenges are available today")
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Moment.self, Badge.self, DailyChallenge.self)
        let context = ModelContext(container)
        let challengeManager = ChallengeManager(modelContext: context)
        
        let todaysChallenge = challengeManager.getTodaysChallenge()
        
        var response = "Today's challenges:\n\n"
        
        // Challenge 1
        response += todaysChallenge.challenge1Completed ? "✅ " : "⭕️ "
        response += todaysChallenge.challenge1
        
        response += "\n\n"
        
        // Challenge 2
        response += todaysChallenge.challenge2Completed ? "✅ " : "⭕️ "
        response += todaysChallenge.challenge2
        
        let completedCount = (todaysChallenge.challenge1Completed ? 1 : 0) + (todaysChallenge.challenge2Completed ? 1 : 0)
        
        if completedCount == 2 {
            response += "\n\nYou've completed both challenges today! 🎉"
        } else if completedCount == 1 {
            response += "\n\nYou've completed 1 out of 2 challenges! Keep going! 💪"
        } else {
            response += "\n\nGo out and complete these challenges today! 🌟"
        }
        
        return .result(dialog: .init(stringLiteral: response))
    }
}

// MARK: - App Shortcuts Provider
struct GratefulMomentsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddGratefulMomentIntent(),
            phrases: [
                "Add grateful moment in \(.applicationName)",
                "Log gratitude in \(.applicationName)",
                "Record gratitude in \(.applicationName)",
                "Add gratitude in \(.applicationName)"
            ],
            shortTitle: "Add Moment",
            systemImageName: "heart.text.square.fill"
        )
        
        AppShortcut(
            intent: CheckStreakIntent(),
            phrases: [
                "Check my streak in \(.applicationName)",
                "What's my streak in \(.applicationName)",
                "Show my streak in \(.applicationName)"
            ],
            shortTitle: "Check Streak",
            systemImageName: "flame.fill"
        )
        
        AppShortcut(
            intent: CheckTodaysChallengesIntent(),
            phrases: [
                "Show today's challenges in \(.applicationName)",
                "What are today's challenges in \(.applicationName)",
                "Check my challenges in \(.applicationName)"
            ],
            shortTitle: "Today's Challenges",
            systemImageName: "star.circle.fill"
        )
    }
}
