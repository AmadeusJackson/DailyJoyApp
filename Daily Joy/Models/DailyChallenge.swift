//
//  DailyChallenge.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/9/25.
//

import Foundation
import SwiftData

@Model
class DailyChallenge {
    var date: Date
    var challenge1: String
    var challenge2: String
    var challenge1Completed: Bool
    var challenge2Completed: Bool
    var challenge1Keywords: [String]
    var challenge2Keywords: [String]
    
    init(date: Date, challenge1: String, challenge2: String, challenge1Keywords: [String], challenge2Keywords: [String]) {
        self.date = date
        self.challenge1 = challenge1
        self.challenge2 = challenge2
        self.challenge1Completed = false
        self.challenge2Completed = false
        self.challenge1Keywords = challenge1Keywords
        self.challenge2Keywords = challenge2Keywords
    }
}

// MARK: - Challenge Bank
struct ChallengeBank {
    struct Challenge {
        let prompt: String
        let keywords: [String]
    }
    
    static let allChallenges: [Challenge] = [
        // Connection Challenges
        Challenge(prompt: "Call or text someone you haven't spoken to in a while", keywords: ["call", "called", "text", "texted", "message", "messaged", "reach out", "reconnect", "catch up", "phone", "contact"]),
        Challenge(prompt: "Compliment a stranger today", keywords: ["compliment", "stranger", "kind words", "praise", "told someone", "nice thing"]),
        Challenge(prompt: "Tell someone why you appreciate them", keywords: ["appreciate", "grateful for", "thank", "thanked", "told", "expressed", "love"]),
        Challenge(prompt: "Reach out to an old friend", keywords: ["old friend", "friend", "reached out", "reconnect", "catch up", "contact"]),
        Challenge(prompt: "Do something kind for a neighbor", keywords: ["neighbor", "neighbour", "kind", "help", "helped", "favor", "assist"]),
        Challenge(prompt: "Write a thank you note or message", keywords: ["thank you", "thanks", "note", "message", "appreciation", "grateful"]),
        Challenge(prompt: "Start a conversation with someone new", keywords: ["new person", "stranger", "conversation", "met", "introduced", "talk"]),
        Challenge(prompt: "Give someone a genuine compliment", keywords: ["compliment", "praise", "told", "nice", "appreciate"]),
        Challenge(prompt: "Spend quality time with a loved one", keywords: ["time", "together", "family", "friend", "loved one", "quality"]),
        Challenge(prompt: "Share something that made you laugh with someone", keywords: ["shared", "laugh", "funny", "joke", "told", "showed"]),
        
        // Self-Care Challenges
        Challenge(prompt: "Take a 10-minute walk outside", keywords: ["walk", "outside", "stroll", "nature", "fresh air", "outdoors"]),
        Challenge(prompt: "Try a new recipe or food today", keywords: ["recipe", "food", "cook", "cooked", "new dish", "tried", "ate", "taste"]),
        Challenge(prompt: "Spend 5 minutes in silence or meditation", keywords: ["meditate", "meditation", "silence", "quiet", "peace", "breathe", "calm"]),
        Challenge(prompt: "Do something creative (draw, write, sing)", keywords: ["creative", "draw", "drew", "paint", "write", "wrote", "sing", "sang", "create"]),
        Challenge(prompt: "Watch the sunrise or sunset", keywords: ["sunrise", "sunset", "sun", "dawn", "dusk", "morning", "evening"]),
        Challenge(prompt: "Stretch or do yoga for 10 minutes", keywords: ["stretch", "yoga", "exercise", "movement", "body"]),
        Challenge(prompt: "Read for pleasure for 20 minutes", keywords: ["read", "book", "reading", "chapter", "story"]),
        Challenge(prompt: "Take a break from screens for an hour", keywords: ["break", "screens", "phone", "disconnect", "offline", "no phone"]),
        Challenge(prompt: "Cook yourself a healthy meal", keywords: ["cook", "cooked", "meal", "healthy", "prepare", "made"]),
        Challenge(prompt: "Get 8 hours of sleep tonight", keywords: ["sleep", "slept", "rest", "bed early", "bedtime", "hours"]),
        
        // Kindness Challenges
        Challenge(prompt: "Buy coffee or a treat for someone", keywords: ["bought", "coffee", "treat", "pay", "paid", "surprise"]),
        Challenge(prompt: "Leave a positive review for a local business", keywords: ["review", "positive", "local", "business", "rating", "feedback"]),
        Challenge(prompt: "Help someone with a task without being asked", keywords: ["help", "helped", "assist", "task", "support", "volunteer"]),
        Challenge(prompt: "Donate something you don't need", keywords: ["donate", "donated", "give", "gave away", "charity", "donation"]),
        Challenge(prompt: "Pick up litter in your neighborhood", keywords: ["litter", "trash", "clean", "pick up", "environment", "neighborhood"]),
        Challenge(prompt: "Hold the door open for multiple people", keywords: ["door", "held", "polite", "kind", "gesture"]),
        Challenge(prompt: "Tip generously today", keywords: ["tip", "tipped", "generous", "extra", "gratuity"]),
        Challenge(prompt: "Let someone go ahead of you in line", keywords: ["line", "ahead", "let", "kind", "queue", "wait"]),
        Challenge(prompt: "Smile at 10 people today", keywords: ["smile", "smiled", "people", "friendly", "greeting"]),
        Challenge(prompt: "Send an encouraging message to someone", keywords: ["encourage", "message", "support", "text", "uplift", "motivate"]),
        
        // Growth Challenges
        Challenge(prompt: "Learn something new today", keywords: ["learn", "learned", "new", "skill", "knowledge", "discover"]),
        Challenge(prompt: "Face a small fear today", keywords: ["fear", "afraid", "scared", "overcome", "brave", "courage"]),
        Challenge(prompt: "Try something outside your comfort zone", keywords: ["comfort zone", "new", "try", "tried", "challenge", "different"]),
        Challenge(prompt: "Ask for help with something", keywords: ["ask", "asked", "help", "support", "advice", "guidance"]),
        Challenge(prompt: "Teach someone something you know", keywords: ["teach", "taught", "show", "showed", "explain", "share knowledge"]),
        Challenge(prompt: "Start a new hobby or return to an old one", keywords: ["hobby", "start", "began", "activity", "interest"]),
        Challenge(prompt: "Write down a goal and take one step toward it", keywords: ["goal", "plan", "step", "progress", "achieve", "work toward"]),
        Challenge(prompt: "Listen to a podcast or watch a documentary", keywords: ["podcast", "documentary", "learn", "watch", "listen", "education"]),
        Challenge(prompt: "Practice a skill you want to improve", keywords: ["practice", "skill", "improve", "better", "work on"]),
        Challenge(prompt: "Reflect on a mistake and what you learned", keywords: ["mistake", "learn", "reflect", "growth", "lesson"]),
        
        // Mindfulness Challenges
        Challenge(prompt: "Take 3 deep breaths before responding to stress", keywords: ["breathe", "breath", "calm", "stress", "relax", "pause"]),
        Challenge(prompt: "Notice 5 things you can see, 4 you can hear, 3 you can touch", keywords: ["notice", "observe", "senses", "aware", "mindful", "present"]),
        Challenge(prompt: "Eat one meal without distractions", keywords: ["eat", "meal", "mindful", "present", "focus", "no phone"]),
        Challenge(prompt: "Put your phone away for an hour", keywords: ["phone away", "disconnect", "no phone", "offline", "break"]),
        Challenge(prompt: "Write down 3 things you're grateful for", keywords: ["grateful", "gratitude", "thankful", "appreciate", "blessing"]),
        Challenge(prompt: "Spend time in nature", keywords: ["nature", "outside", "outdoors", "park", "trees", "natural"]),
        Challenge(prompt: "Practice saying 'no' to something today", keywords: ["no", "decline", "boundary", "prioritize", "refuse"]),
        Challenge(prompt: "Express a difficult emotion honestly", keywords: ["emotion", "feel", "feeling", "express", "honest", "vulnerable"]),
        Challenge(prompt: "Do nothing for 10 minutes", keywords: ["nothing", "rest", "pause", "sit", "still", "quiet"]),
        Challenge(prompt: "Notice something beautiful you usually overlook", keywords: ["beautiful", "notice", "appreciate", "beauty", "observe", "see"]),
    ]
    
    static func getTodaysChallenges(for date: Date) -> (Challenge, Challenge) {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        // Use day of year as seed for randomization to get consistent challenges per day
        var generator = SeededRandomNumberGenerator(seed: UInt64(dayOfYear))
        
        let shuffled = allChallenges.shuffled(using: &generator)
        return (shuffled[0], shuffled[1])
    }
}

// MARK: - Seeded Random Number Generator
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &+ 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
