//
//  ChallengeManager.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/9/25.
//

import Foundation
import SwiftData
import FoundationModels

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
        
        let text = "\(moment.title) \(moment.note)"
        
        // Check challenge 1
        if !todaysChallenge.challenge1Completed {
            Task {
                let isComplete = await checkChallengeCompletion(
                    text: text,
                    challenge: todaysChallenge.challenge1,
                    keywords: todaysChallenge.challenge1Keywords
                )
                
                if isComplete {
                    await MainActor.run {
                        todaysChallenge.challenge1Completed = true
                        try? modelContext.save()
                        
                        // Post notification for celebration
                        NotificationCenter.default.post(
                            name: .challengeCompleted,
                            object: todaysChallenge.challenge1
                        )
                    }
                }
            }
        }
        
        // Check challenge 2
        if !todaysChallenge.challenge2Completed {
            Task {
                let isComplete = await checkChallengeCompletion(
                    text: text,
                    challenge: todaysChallenge.challenge2,
                    keywords: todaysChallenge.challenge2Keywords
                )
                
                if isComplete {
                    await MainActor.run {
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
        }
    }
    
    // Try Apple's Foundation Models first, fall back to keyword matching
    private func checkChallengeCompletion(text: String, challenge: String, keywords: [String]) async -> Bool {
        // Try Foundation Models (iOS 26.0+ / future release)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            if model.isAvailable {
                if let result = await checkWithFoundationModels(text: text, challenge: challenge) {
                    return result
                }
            } else {
                print("Foundation Models not available: \(model.availability)")
            }
        }
        
        // Fallback to keyword matching (works on all iOS versions)
        print("Using keyword matching")
        return checkKeywords(in: text.lowercased(), keywords: keywords)
    }
    
    // Apple's Foundation Models - On-device LLM
    @available(iOS 26.0, *)
    private func checkWithFoundationModels(text: String, challenge: String) async -> Bool? {
        do {
            // Create a session with system instructions
            let session = LanguageModelSession(
                instructions: """
                You are a challenge completion detector. You will be given a challenge prompt and a user's note.
                Your only job is to determine if the user completed the challenge based on their note.
                Respond with ONLY "YES" if they completed it, or "NO" if they did not. No explanation needed.
                """
            )
            
            let promptText = """
            Challenge: \(challenge)
            User's moment: \(text)
            
            Did the user complete this challenge?
            """
            
            let prompt = Prompt(promptText)
            let response = try await session.respond(to: prompt)
            
            // Extract text from response
            let responseText = response.content.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            
            print("✅ Foundation Models response: \(responseText)")
            
            return responseText.contains("YES")
            
        } catch {
            print("❌ Foundation Models check failed: \(error)")
            return nil // Fall back to keywords
        }
    }
    
    // Simple keyword matching (fallback)
    private func checkKeywords(in text: String, keywords: [String]) -> Bool {
        // Check if any keyword appears in the text
        for keyword in keywords {
            if text.contains(keyword.lowercased()) {
                print("Keyword match found: \(keyword)")
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
