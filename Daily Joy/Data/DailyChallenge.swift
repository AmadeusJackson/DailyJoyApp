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
        Challenge(prompt: "Call or text someone you haven't spoken to in a while", keywords: ["call", "called", "calling", "text", "texted", "texting", "message", "messaged", "messaging", "reach out", "reached out", "reconnect", "reconnected", "catch up", "catching up", "phone", "phoned", "contact", "contacted", "old friend", "haven't talked", "long time", "been a while", "finally called", "finally texted"]),
        Challenge(prompt: "Compliment a stranger today", keywords: ["compliment", "complimented", "stranger", "random person", "someone I don't know", "kind words", "nice thing", "told them", "said something nice", "praised"]),
        Challenge(prompt: "Tell someone why you appreciate them", keywords: ["appreciate", "appreciated", "grateful for", "thank", "thanked", "told them", "told her", "told him", "expressed", "love", "let them know", "said how much", "means to me", "matter to me"]),
        Challenge(prompt: "Reach out to an old friend", keywords: ["old friend", "friend from", "childhood friend", "college friend", "school friend", "reached out", "reconnect", "reconnected", "catch up", "contact", "contacted", "called them", "texted them", "messaged them", "haven't talked", "long time"]),
        Challenge(prompt: "Do something kind for a neighbor", keywords: ["neighbor", "neighbour", "next door", "kind", "help", "helped", "favor", "favour", "assist", "assisted", "for my neighbor", "for the neighbor"]),
        Challenge(prompt: "Write a thank you note or message", keywords: ["thank you", "thanks", "thank-you", "note", "card", "message", "wrote", "sent", "appreciation", "grateful", "gratitude"]),
        Challenge(prompt: "Start a conversation with someone new", keywords: ["new person", "someone new", "stranger", "conversation", "met", "introduced", "talked to", "spoke with", "chatted with", "strike up", "started talking"]),
        Challenge(prompt: "Give someone a genuine compliment", keywords: ["compliment", "complimented", "praise", "praised", "told them", "nice", "appreciate", "said something"]),
        Challenge(prompt: "Spend quality time with a loved one", keywords: ["time with", "spent time", "quality time", "together", "family", "friend", "loved one", "partner", "spouse", "child", "parent", "hang out", "visited"]),
        Challenge(prompt: "Share something that made you laugh with someone", keywords: ["shared", "told", "showed", "laugh", "laughed", "funny", "hilarious", "joke", "made me laugh", "cracked up", "died laughing"]),
        
        // Self-Care Challenges
        Challenge(prompt: "Take a 10-minute walk outside", keywords: ["walk", "walked", "walking", "stroll", "strolled", "outside", "outdoors", "fresh air", "nature", "went for a walk", "took a walk"]),
        Challenge(prompt: "Try a new recipe or food today", keywords: ["recipe", "new recipe", "food", "new food", "cook", "cooked", "cooking", "made", "prepared", "tried", "taste", "tasted", "ate", "dish", "meal"]),
        Challenge(prompt: "Spend 5 minutes in silence or meditation", keywords: ["meditate", "meditated", "meditating", "meditation", "silence", "silent", "slience", "quiet", "quietly", "peace", "peaceful", "breathe", "breathing", "breath", "deep breath", "calm", "calmed", "calming", "mindful", "mindfulness", "sat still", "sit still", "sitting still", "sat quietly", "sat in silence", "just sat", "doing nothing"]),
        Challenge(prompt: "Do something creative (draw, write, sing)", keywords: ["creative", "create", "created", "draw", "drew", "drawing", "paint", "painted", "painting", "write", "wrote", "writing", "sing", "sang", "singing", "art", "sketch", "doodle"]),
        Challenge(prompt: "Watch the sunrise or sunset", keywords: ["sunrise", "sunset", "sun rise", "sun set", "dawn", "dusk", "morning", "evening", "watched the sun", "saw the sun"]),
        Challenge(prompt: "Stretch or do yoga for 10 minutes", keywords: ["stretch", "stretched", "stretching", "yoga", "exercise", "exercised", "movement", "body", "flexible"]),
        Challenge(prompt: "Read for pleasure for 20 minutes", keywords: ["read", "reading", "book", "novel", "chapter", "story", "pages"]),
        Challenge(prompt: "Take a break from screens for an hour", keywords: ["break from", "no phone", "no screens", "screen free", "phone away", "disconnect", "disconnected", "offline", "unplugged", "put phone down"]),
        Challenge(prompt: "Cook yourself a healthy meal", keywords: ["cook", "cooked", "cooking", "meal", "healthy", "nutritious", "prepare", "prepared", "made", "homemade"]),
        Challenge(prompt: "Get 8 hours of sleep tonight", keywords: ["sleep", "slept", "sleeping", "rest", "rested", "bed early", "early to bed", "8 hours", "full night", "good sleep"]),
        
        // Kindness Challenges
        Challenge(prompt: "Buy coffee or a treat for someone", keywords: ["bought", "buy", "coffee", "treat", "pay for", "paid for", "surprise", "got them", "purchased"]),
        Challenge(prompt: "Leave a positive review for a local business", keywords: ["review", "reviewed", "positive", "5 star", "rating", "rated", "feedback", "local", "business", "restaurant", "shop"]),
        Challenge(prompt: "Help someone with a task without being asked", keywords: ["help", "helped", "helping", "assist", "assisted", "task", "support", "supported", "volunteer", "volunteered", "without asking", "unasked"]),
        Challenge(prompt: "Donate something you don't need", keywords: ["donate", "donated", "donating", "give", "gave", "gave away", "charity", "donation", "goodwill"]),
        Challenge(prompt: "Pick up litter in your neighborhood", keywords: ["litter", "trash", "garbage", "clean", "cleaned", "pick up", "picked up", "environment", "neighborhood", "neighbourhood"]),
        Challenge(prompt: "Hold the door open for multiple people", keywords: ["door", "held", "hold", "open", "polite", "kind", "gesture", "courtesy"]),
        Challenge(prompt: "Tip generously today", keywords: ["tip", "tipped", "tipping", "generous", "generously", "extra", "gratuity", "left a tip", "big tip"]),
        Challenge(prompt: "Let someone go ahead of you in line", keywords: ["line", "queue", "ahead", "let them", "go first", "cut in front", "kind", "gesture"]),
        Challenge(prompt: "Smile at 10 people today", keywords: ["smile", "smiled", "smiling", "people", "friendly", "greeting", "greet", "everyone"]),
        Challenge(prompt: "Send an encouraging message to someone", keywords: ["encourage", "encouraged", "encouraging", "message", "messaged", "text", "texted", "support", "supportive", "uplift", "uplifting", "motivate", "motivated"]),
        
        // Growth Challenges
        Challenge(prompt: "Learn something new today", keywords: ["learn", "learned", "learning", "new", "skill", "knowledge", "discover", "discovered", "found out", "taught myself", "figured out", "understand", "understood"]),
        Challenge(prompt: "Face a small fear today", keywords: ["fear", "feared", "afraid", "scared", "scary", "overcome", "faced", "confronted", "brave", "bravery", "courage", "courageous", "nervous", "anxiety", "anxious", "terrified", "frightened"]),
        Challenge(prompt: "Try something outside your comfort zone", keywords: ["comfort zone", "outside comfort", "uncomfortable", "new", "try", "tried", "trying", "challenge", "challenged", "different", "never done", "first time", "pushing myself", "push myself", "stretched myself"]),
        Challenge(prompt: "Ask for help with something", keywords: ["ask", "asked", "asking", "help", "helped", "support", "advice", "guidance", "reached out", "admit", "admitted", "need help"]),
        Challenge(prompt: "Teach someone something you know", keywords: ["teach", "taught", "teaching", "show", "showed", "showing", "explain", "explained", "share", "shared", "knowledge", "help them learn"]),
        Challenge(prompt: "Start a new hobby or return to an old one", keywords: ["hobby", "hobbies", "start", "started", "starting", "began", "begin", "return", "returned", "back to", "activity", "interest", "passion"]),
        Challenge(prompt: "Write down a goal and take one step toward it", keywords: ["goal", "goals", "plan", "plans", "step", "progress", "progressed", "achieve", "work toward", "working toward", "move toward", "closer to"]),
        Challenge(prompt: "Listen to a podcast or watch a documentary", keywords: ["podcast", "documentary", "doc", "learn", "learned", "watch", "watched", "listen", "listened", "educational", "education"]),
        Challenge(prompt: "Practice a skill you want to improve", keywords: ["practice", "practiced", "practicing", "skill", "improve", "improving", "better", "work on", "working on", "training", "trained"]),
        Challenge(prompt: "Reflect on a mistake and what you learned", keywords: ["mistake", "error", "wrong", "messed up", "screwed up", "failed", "failure", "learn", "learned", "lesson", "reflect", "reflected", "realize", "realized", "understand", "understood", "growth", "should have", "shouldn't have", "wish I", "regret", "regretted", "my bad", "next time", "going forward", "from now on"]),
        
        // Mindfulness Challenges
        Challenge(prompt: "Take 3 deep breaths before responding to stress", keywords: ["breathe", "breath", "breathing", "deep breath", "calm", "calmed", "stress", "stressed", "relax", "relaxed", "pause", "paused"]),
        Challenge(prompt: "Notice 5 things you can see, 4 you can hear, 3 you can touch", keywords: ["notice", "noticed", "observe", "observed", "senses", "see", "hear", "touch", "aware", "awareness", "mindful", "mindfulness", "present", "grounding"]),
        Challenge(prompt: "Eat one meal without distractions", keywords: ["eat", "ate", "eating", "meal", "lunch", "dinner", "breakfast", "mindful", "present", "focus", "focused", "no phone", "no tv", "no distraction"]),
        Challenge(prompt: "Put your phone away for an hour", keywords: ["phone away", "put phone", "no phone", "without phone", "disconnect", "disconnected", "offline", "break from phone", "phone free", "unplugged"]),
        Challenge(prompt: "Write down 3 things you're grateful for", keywords: ["grateful", "gratitude", "thankful", "appreciate", "appreciated", "blessing", "blessings", "three things", "3 things", "wrote down", "list"]),
        Challenge(prompt: "Spend time in nature", keywords: ["nature", "natural", "outside", "outdoors", "outdoor", "park", "trees", "forest", "woods", "trail", "hike", "hiking"]),
        Challenge(prompt: "Practice saying 'no' to something today", keywords: ["no", "said no", "decline", "declined", "boundary", "boundaries", "prioritize", "priority", "refuse", "refused", "turn down", "turned down"]),
        Challenge(prompt: "Express a difficult emotion honestly", keywords: ["emotion", "emotional", "feel", "feeling", "felt", "express", "expressed", "honest", "honestly", "vulnerable", "vulnerability", "share", "shared", "open", "opened up"]),
        Challenge(prompt: "Do nothing for 10 minutes", keywords: ["nothing", "do nothing", "rest", "rested", "pause", "paused", "sit", "sat", "still", "stillness", "quiet", "silence", "just be"]),
        Challenge(prompt: "Notice something beautiful you usually overlook", keywords: ["beautiful", "beauty", "notice", "noticed", "appreciate", "appreciated", "observe", "observed", "see", "saw", "overlook", "overlooked", "miss", "missed", "usually", "normally", "details"]),
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
