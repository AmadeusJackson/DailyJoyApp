//
//  BadgeManager.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 11/23/25.
//

import Foundation
import SwiftData
import UIKit

extension Notification.Name {
    static let badgeUnlocked = Notification.Name("badgeUnlocked")
}

class BadgeManager {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func unlockBadges(newMoment: Moment) throws {
        let context = modelContainer.mainContext
        let moments = try context.fetch(FetchDescriptor<Moment>())
        let lockedBadges = try context.fetch(FetchDescriptor<Badge>(predicate: #Predicate { $0.timestamp == nil }))

        var newlyUnlocked: [Badge] = []
        
        for badge in lockedBadges {
            switch badge.details {
            // Original badges
            case .firstEntry where moments.count >= 1:
                newlyUnlocked.append(badge)
                
            case .fiveStars where moments.count >= 5:
                newlyUnlocked.append(badge)
                
            case .shutterbug where moments.count(where: { $0.image != nil }) >= 3:
                newlyUnlocked.append(badge)
                
            case .expressive where moments.count(where: { $0.image != nil && !$0.note.isEmpty }) >= 5:
                newlyUnlocked.append(badge)
                
            case .perfectTen where moments.count >= 10 && lockedBadges.count == 1:
                newlyUnlocked.append(badge)
            
            // Streak-based badges
            case .fireStarter where checkStreak(moments: moments, days: 3):
                newlyUnlocked.append(badge)
                
            case .weekStreak where checkStreak(moments: moments, days: 7):
                newlyUnlocked.append(badge)
                
            case .marathon where checkStreak(moments: moments, days: 30):
                newlyUnlocked.append(badge)
            
            // Time-based badges
            case .earlyBird where checkTimeRange(moment: newMoment, startHour: 5, endHour: 8):
                newlyUnlocked.append(badge)
                
            case .nightOwl where checkTimeAfter(moment: newMoment, hour: 22):
                newlyUnlocked.append(badge)
                
            case .goldenHour where checkGoldenHour(moment: newMoment):
                newlyUnlocked.append(badge)
            
            // Photo-based badges
            case .photographer where moments.count(where: { $0.image != nil }) >= 20:
                newlyUnlocked.append(badge)
                
            case .photoAlbum where moments.count(where: { $0.image != nil }) >= 25:
                newlyUnlocked.append(badge)
            
            // Note-based badges
            case .journalist where moments.count(where: { !$0.note.isEmpty }) >= 10:
                newlyUnlocked.append(badge)
                
            case .storyteller where moments.count(where: { $0.note.count > 100 }) >= 5:
                newlyUnlocked.append(badge)
            
            // Color-based badges
            case .colorPalette where checkAllColorsUsed(moments: moments):
                newlyUnlocked.append(badge)
                
            case .minimalist where checkColorOnlyMoments(moments: moments, count: 5):
                newlyUnlocked.append(badge)
            
            // Milestone badges
            case .monthlyMilestone where checkMonthlyStreak(moments: moments):
                newlyUnlocked.append(badge)
                
            case .centuryClub where moments.count >= 100:
                newlyUnlocked.append(badge)
                
            default:
                continue
            }
        }

        for badge in newlyUnlocked {
            badge.moment = newMoment
            badge.timestamp = newMoment.timestamp
            
            // Post notification for celebration
            NotificationCenter.default.post(name: .badgeUnlocked, object: badge)
        }
    }

    func loadBadgesIfNeeded() throws {
        let context = modelContainer.mainContext
        var fetchDescriptor = FetchDescriptor<Badge>()
        fetchDescriptor.fetchLimit = 1
        let existingBadges = try context.fetch(fetchDescriptor)
        if existingBadges.isEmpty {
            for details in BadgeDetails.allCases {
                context.insert(Badge(details: details))
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func checkStreak(moments: [Moment], days: Int) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var currentDate = today
        var consecutiveDays = 0
        
        for _ in 0..<days {
            let hasMoment = moments.contains { moment in
                calendar.isDate(moment.timestamp, inSameDayAs: currentDate)
            }
            
            if hasMoment {
                consecutiveDays += 1
            } else {
                break
            }
            
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return consecutiveDays >= days
    }
    
    private func checkTimeRange(moment: Moment, startHour: Int, endHour: Int) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: moment.timestamp)
        return hour >= startHour && hour < endHour
    }
    
    private func checkTimeAfter(moment: Moment, hour: Int) -> Bool {
        let calendar = Calendar.current
        let momentHour = calendar.component(.hour, from: moment.timestamp)
        return momentHour >= hour
    }
    
    private func checkGoldenHour(moment: Moment) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: moment.timestamp)
        return (hour >= 6 && hour < 8) || (hour >= 18 && hour < 20)
    }
    
    private func checkAllColorsUsed(moments: [Moment]) -> Bool {
        // Get all color names from your assets
        let allColors = ["Ember", "Forest", "Lavender", "Ocean", "Pearl", "Rose", "Ruby", "Sapphire", "Sky"]
        var usedColors = Set<String>()
        
        for moment in moments {
            if let imageData = moment.imageData {
                // Check if it's a solid color image
                if let colorName = extractColorName(from: imageData) {
                    usedColors.insert(colorName)
                }
            }
        }
        
        return usedColors.count >= allColors.count
    }
    
    private func checkColorOnlyMoments(moments: [Moment], count: Int) -> Bool {
        let colorOnlyMoments = moments.filter { moment in
            guard let imageData = moment.imageData else { return false }
            // Check if it's a solid color (created by the color picker, not a photo)
            return isColorImage(imageData)
        }
        return colorOnlyMoments.count >= count
    }
    
    private func checkMonthlyStreak(moments: [Moment]) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        
        // Check if there's at least one moment for each day in the past 30 days
        for dayOffset in 0..<30 {
            guard let checkDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let hasMoment = moments.contains { moment in
                calendar.isDate(moment.timestamp, inSameDayAs: checkDate)
            }
            
            if !hasMoment {
                return false
            }
        }
        
        return true
    }
    
    // Helper to detect if image is a solid color
    private func isColorImage(_ imageData: Data) -> Bool {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else { return false }
        
        // Simple check: color images created by your app are 500x500
        return cgImage.width == 500 && cgImage.height == 500
    }
    
    // Helper to extract color name from solid color image (if you store it somehow)
    private func extractColorName(from imageData: Data) -> String? {
        // This is a placeholder - you'd need to implement based on how you store color info
        // One option: store color name in moment metadata
        // For now, just check if it's a color image
        return isColorImage(imageData) ? "Unknown" : nil
    }
}
