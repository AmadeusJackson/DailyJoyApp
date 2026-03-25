//
//  StreakCalculator.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 11/24/25.
//

import Foundation
import WidgetKit

/// Calculates streak-related metrics and persists a compact value for widgets.
struct StreakCalculator {
    let calendar = Calendar.current

    /// Computes the current streak length from a chronologically sorted list of moments and updates widgets.
    /// 
    /// Days are measured from the end of the day, rather than whatever time of day it is currently
    /// - precondition: `moments` must be sorted by timestamp, from earliest to latest
    func calculateStreak(for moments: [Moment]) -> Int {
        let startOfToday = calendar.startOfDay(for: .now)
        let endOfToday = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfToday)!

        // Ex. [0, 0, 1, 2, 4, 5]
        let daysAgoArray = moments
            .reversed()
            .map(\.timestamp)
            .map { calendar.dateComponents([.day], from: $0, to: endOfToday) }
            .compactMap { $0.day }

        var streak = 0
        for daysAgo in daysAgoArray {
            if daysAgo == streak {
                // Streak already here; don't increase the streak.
                // 5 posts in 1 day is a 1 streak. 5 posts in 2 days is a 2 streak.
                continue
            } else if daysAgo == streak + 1 {
                // A moment exists the day after the current streak, add to the streak
                streak += 1
            } else {
                // The streak breaks if jumping more than one day
                break
            }
        }

        // Streak is calculated above starting from yesterday.
        // Not yet saving a moment today shouldn't break the streak.
        // If a moment has been saved today, include it in the streak.
        if daysAgoArray.first == 0 {
            streak += 1
        }

        // Save streak to shared storage for widget
        saveStreakForWidget(streak)

        return streak
    }

    /// Returns true if at least one moment exists with a timestamp on the current day.
    func hasLoggedToday(moments: [Moment]) -> Bool {
        let startOfToday = calendar.startOfDay(for: .now)
        let endOfToday = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfToday)!

        return moments.contains {
            calendar.dateComponents([.day], from: $0.timestamp, to: endOfToday).day == 0
        }
    }

    /// Persists the streak in shared `UserDefaults` and reloads widget timelines.
    private func saveStreakForWidget(_ streak: Int) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.dailyjoy.shared") else {
            return
        }
        sharedDefaults.set(streak, forKey: "streakCount")
        WidgetCenter.shared.reloadAllTimelines()
    }
}

