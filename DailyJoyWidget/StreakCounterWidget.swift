//
//  StreakCounterWIdget.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 1/8/26.
//

import WidgetKit
import SwiftUI

// MARK: - Streak Entry
struct StreakEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
}

// MARK: - Streak Timeline Provider
struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streakCount: 7)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let entry = StreakEntry(date: Date(), streakCount: getStreakCount())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let currentDate = Date()
        let entry = StreakEntry(date: currentDate, streakCount: getStreakCount())
        
        // Update at midnight
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
    
    private func getStreakCount() -> Int {
        // Load from shared UserDefaults (App Group)
        guard let sharedDefaults = UserDefaults(suiteName: "group.dailyjoy.shared") else {
            return 0
        }
        return sharedDefaults.integer(forKey: "streakCount")
    }
}

// MARK: - Streak Widget View
struct StreakWidgetView: View {
    let entry: StreakEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: widgetFamily == .systemSmall ? 40 : 50))
                    .foregroundColor(.white)
                
                Text("\(entry.streakCount)")
                    .font(.system(size: widgetFamily == .systemSmall ? 36 : 48, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Day Streak")
                    .font(.system(size: widgetFamily == .systemSmall ? 12 : 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
        }
    }
}

// MARK: - Streak Widget Configuration
struct StreakWidget: Widget {
    let kind: String = "StreakWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak Counter")
        .description("Track your daily streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry(date: .now, streakCount: 7)
    StreakEntry(date: .now, streakCount: 14)
    StreakEntry(date: .now, streakCount: 30)
}
