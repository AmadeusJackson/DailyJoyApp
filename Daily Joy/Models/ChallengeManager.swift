//
//  ChallengeManager.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/9/25.
//

import Foundation
import SwiftData

@MainActor
class ChallengeManager {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Get or create today's challenges
    func getTodaysChallenge() -> DailyChallenge {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if we already have challenges for today
        let descriptor = FetchDescriptor<DailyChallenge>(
            predicate: #Predicate { challenge in
                challenge.date >= today
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if let existingChallenge = try? modelContext.fetch(descriptor).first,
           calendar.isDate(existingChallenge.date, inSameDayAs: today) {
            return existingChallenge
        }
        
        // Create new challenges for today
        let (challenge1, challenge2) = ChallengeBank.getTodaysChallenges(for: today)
        
        let newChallenge = DailyChallenge(
            date: today,
            challenge1: challenge1.prompt,
            challenge2: challenge2.prompt,
            challenge1Keywords: challenge1.keywords,
            challenge2Keywords: challenge2.keywords
        )
        
        modelContext.insert(newChallenge)
        try? modelContext.save()
        
        return newChallenge
    }
    
    // Check if a moment completes any challenges
    func checkChallengeCompletion(for moment: Moment) {
        let todaysChallenge = getTodaysChallenge()
        
        // Only check if there are incomplete challenges
        guard !todaysChallenge.challenge1Completed || !todaysChallenge.challenge2Completed else {
            return
        }
        
        let text = "\(moment.title) \(moment.note)".lowercased()
        
        // Check challenge 1
        if !todaysChallenge.challenge1Completed {
            if checkKeywords(in: text, keywords: todaysChallenge.challenge1Keywords) {
                todaysChallenge.challenge1Completed = true
                try? modelContext.save()
                
                // Post notification for celebration
                NotificationCenter.default.post(
                    name: .challengeCompleted,
                    object: todaysChallenge.challenge1
                )
            }
        }
        
        // Check challenge 2
        if !todaysChallenge.challenge2Completed {
            if checkKeywords(in: text, keywords: todaysChallenge.challenge2Keywords) {
                todaysChallenge.challenge2Completed = true
                try? modelContext.save()
                
                // Post notification for celebration
                NotificationCenter.default.post(
                    name: .challengeCompleted,
                    object: todaysChallenge.challenge2
                )
            }
        }
    }
    
    // Simple keyword matching (fallback for devices without Apple Intelligence)
    private func checkKeywords(in text: String, keywords: [String]) -> Bool {
        // Check if any keyword appears in the text
        for keyword in keywords {
            if text.contains(keyword.lowercased()) {
                return true
            }
        }
        return false
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let challengeCompleted = Notification.Name("challengeCompleted")
}
