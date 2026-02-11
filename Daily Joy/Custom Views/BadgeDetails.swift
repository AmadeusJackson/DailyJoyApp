//
//  BadgeDetails.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 11/20/25.
//

import Foundation
import SwiftUI

enum BadgeDetails: Int, Codable, CaseIterable {
    case firstEntry
    case fiveStars
    case shutterbug
    case expressive
    case perfectTen
    
    // New badges
    case weekStreak
    case marathon
    case earlyBird
    case nightOwl
    case photographer
    case journalist
    case fireStarter
    case colorPalette
    case monthlyMilestone
    case minimalist
    case photoAlbum
    case storyteller
    case centuryClub
    case goldenHour

    var requirements: String {
        switch self {
        case .firstEntry:
            return "Log a moment to start your journey."
        case .fiveStars:
            return "Record five moments."
        case .shutterbug:
            return "Add three entries with photos."
        case .expressive:
            return "Add five moments with a photo and text."
        case .perfectTen:
            return "Record at least 10 moments, collecting all the other badges along the way."
            
        // New badges
        case .weekStreak:
            return "Save at least 1 moment on 7 consecutive days."
        case .marathon:
            return "Unlock after a 30-day streak."
        case .earlyBird:
            return "Save a moment between 5:00–8:00 AM."
        case .nightOwl:
            return "Save a moment after 10:00 PM."
        case .photographer:
            return "Save 20 moments with images."
        case .journalist:
            return "Save 10 moments with a non-empty note."
        case .fireStarter:
            return "Reach a 3-day streak."
        case .colorPalette:
            return "Use all 9 color options at least once."
        case .monthlyMilestone:
            return "Save at least 1 moment every day for a full month."
        case .minimalist:
            return "Save 5 moments with just a color (no photo)."
        case .photoAlbum:
            return "Save 25 moments with photos."
        case .storyteller:
            return "Save 5 moments with notes longer than 100 characters."
        case .centuryClub:
            return "Save 100 total moments."
        case .goldenHour:
            return "Save a moment during golden hour (6-8 AM or 6-8 PM)."
        }
    }
    
    var title: String {
        switch self {
        case .firstEntry:
            return "Start the Journey"
        case .fiveStars:
            return "5 Stars"
        case .shutterbug:
            return "Shutterbug"
        case .expressive:
            return "Expressive"
        case .perfectTen:
            return "Perfect 10"
            
        // New badges
        case .weekStreak:
            return "Week Streak"
        case .marathon:
            return "Marathon"
        case .earlyBird:
            return "Early Bird"
        case .nightOwl:
            return "Night Owl"
        case .photographer:
            return "Photographer"
        case .journalist:
            return "Journalist"
        case .fireStarter:
            return "Fire Starter"
        case .colorPalette:
            return "Color Palette"
        case .monthlyMilestone:
            return "Monthly Milestone"
        case .minimalist:
            return "Minimalist"
        case .photoAlbum:
            return "Photo Album"
        case .storyteller:
            return "Storyteller"
        case .centuryClub:
            return "Century Club"
        case .goldenHour:
            return "Golden Hour"
        }
    }
    
    var image: ImageResource {
        switch self {
        case .firstEntry:
            return .firstEntryUnlocked
        case .fiveStars:
            return .fiveStarsUnlocked
        case .shutterbug:
            return .shutterbugUnlocked
        case .expressive:
            return .expressiveUnlocked
        case .perfectTen:
            return .perfectTenUnlocked
            
        // New badges - You'll need to add these images to your Assets
        case .weekStreak:
            return .weekStreakUnlocked
        case .marathon:
            return .marathonUnlocked
        case .earlyBird:
            return .earlyBirdUnlocked
        case .nightOwl:
            return .nightOwlUnlocked
        case .photographer:
            return .photographerUnlocked
        case .journalist:
            return .journalistUnlocked
        case .fireStarter:
            return .fireStarterUnlocked
        case .colorPalette:
            return .colorPaletteUnlocked
        case .monthlyMilestone:
            return .monthlyMilestoneUnlocked
        case .minimalist:
            return .minimalistUnlocked
        case .photoAlbum:
            return .photoAlbumUnlocked
        case .storyteller:
            return .storytellerUnlocked
        case .centuryClub:
            return .centuryClubUnlocked
        case .goldenHour:
            return .goldenHourUnlocked
        }
    }

    var lockedImage: ImageResource {
        switch self {
        case .firstEntry:
            return .firstEntryLocked
        case .fiveStars:
            return .fiveStarsLocked
        case .shutterbug:
            return .shutterbugLocked
        case .expressive:
            return .expressiveLocked
        case .perfectTen:
            return .perfectTenLocked
            
        // New badges - You'll need to add these images to your Assets
        case .weekStreak:
            return .weekStreakLocked
        case .marathon:
            return .marathonLocked
        case .earlyBird:
            return .earlyBirdLocked
        case .nightOwl:
            return .nightOwlLocked
        case .photographer:
            return .photographerLocked
        case .journalist:
            return .journalistLocked
        case .fireStarter:
            return .fireStarterLocked
        case .colorPalette:
            return .colorPaletteLocked
        case .monthlyMilestone:
            return .monthlyMilestoneLocked
        case .minimalist:
            return .minimalistLocked
        case .photoAlbum:
            return .photoAlbumLocked
        case .storyteller:
            return .storytellerLocked
        case .centuryClub:
            return .centuryClubLocked
        case .goldenHour:
            return .goldenHourLocked
        }
    }

    var color: Color {
        switch self {
        case .firstEntry:
            return .ember
        case .fiveStars:
            return .ruby
        case .shutterbug:
            return .sapphire
        case .expressive:
            return .ocean
        case .perfectTen:
            return .ember
            
        // New badges - Suggested colors
        case .weekStreak:
            return .ember
        case .marathon:
            return .ruby
        case .earlyBird:
            return Color("Sky")
        case .nightOwl:
            return Color("Sapphire")
        case .photographer:
            return Color("Ocean")
        case .journalist:
            return Color("Forest")
        case .fireStarter:
            return .ember
        case .colorPalette:
            return Color("Rose")
        case .monthlyMilestone:
            return Color("Lavender")
        case .minimalist:
            return Color("Pearl")
        case .photoAlbum:
            return .sapphire
        case .storyteller:
            return Color("Forest")
        case .centuryClub:
            return Color("Ruby")
        case .goldenHour:
            return .ember
        }
    }
    
    var congratulatoryMessage: String {
        switch self {
        case .firstEntry:
            return "Every journey begins with a single step. Congratulations — you're on your way!"
        case .fiveStars:
            return "You're building momentum! The more you focus on regular practice, the better you get at choosing to keep up your intentioned habits."
        case .shutterbug:
            return "Photos connect us to our past, and looking at them can take us right back to the grateful feeling we had when we snapped them."
        case .expressive:
            return "Look at you, giving yourself all the ways to savor your happy memories!"
        case .perfectTen:
            return "You're getting the hang of your new habit! Keep it up and see how far it can take you."
            
        // New badges
        case .weekStreak:
            return "A full week of gratitude! You're building a powerful habit that will transform your mindset."
        case .marathon:
            return "30 days of gratitude! You've proven that consistency creates change. Keep this amazing momentum going!"
        case .earlyBird:
            return "Starting your day with gratitude sets a positive tone for everything that follows. Well done!"
        case .nightOwl:
            return "Ending your day by reflecting on grateful moments helps you sleep with peace and contentment."
        case .photographer:
            return "Your photo collection is growing! Each image captures a moment of joy you can revisit anytime."
        case .journalist:
            return "Your words bring your memories to life. Keep writing and watch your gratitude journal flourish!"
        case .fireStarter:
            return "Three days in a row! You're building the foundation of a life-changing habit. Keep the fire burning!"
        case .colorPalette:
            return "You've explored the full spectrum of joy! Each color represents a different shade of happiness in your life."
        case .monthlyMilestone:
            return "A full month of daily gratitude! You've made this practice a true part of your daily routine."
        case .minimalist:
            return "Sometimes less is more. The beauty in simplicity shows that gratitude doesn't need to be complicated."
        case .photoAlbum:
            return "Your visual gratitude album is flourishing! These images are treasures you'll cherish for years to come."
        case .storyteller:
            return "Your thoughtful reflections show deep appreciation for life's moments. Your stories matter!"
        case .centuryClub:
            return "100 moments of gratitude! You've created a treasure trove of joy and positive memories. Incredible!"
        case .goldenHour:
            return "You caught the golden hour — that magical time when light is perfect and moments feel extraordinary!"
        }
    }
}
