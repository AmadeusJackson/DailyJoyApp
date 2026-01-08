//
//  DailyJoyWidget.swift
//  DailyJoyWidget
//
//  Created by Amadeus Jackson on 1/7/26.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Entry
struct DailyJoyEntry: TimelineEntry {
    let date: Date
    let streakDays: Int
    let hasLoggedToday: Bool
}

// MARK: - Timeline Provider
struct DailyJoyProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyJoyEntry {
        DailyJoyEntry(date: Date(), streakDays: 7, hasLoggedToday: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DailyJoyEntry) -> Void) {
        let entry = DailyJoyEntry(date: Date(), streakDays: 7, hasLoggedToday: true)
        completion(entry)
    }
    
    @MainActor func getTimeline(in context: Context, completion: @escaping (Timeline<DailyJoyEntry>) -> Void) {
        let currentDate = Date()
        
        // Calculate streak from SwiftData
        let (streakDays, hasLoggedToday) = calculateStreak()
        
        // Create entry for current time
        let entry = DailyJoyEntry(
            date: currentDate,
            streakDays: streakDays,
            hasLoggedToday: hasLoggedToday
        )
        
        // Schedule next update at midnight
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!)
        
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
    
    @MainActor
    private func calculateStreak() -> (days: Int, loggedToday: Bool) {
        do {
            let modelContainer = try ModelContainer(for: Moment.self)
            let context = modelContainer.mainContext
            
            let descriptor = FetchDescriptor<Moment>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let moments = try context.fetch(descriptor)
            
            let calculator = StreakCalculator()
            let streak = calculator.calculateStreak(for: moments)
            let hasLogged = calculator.hasLoggedToday(moments: moments)
            
            return (streak, hasLogged)
        } catch {
            return (0, false)
        }
    }
}

// MARK: - Small Widget View (Streak Display)
struct SmallStreakWidgetView: View {
    let entry: DailyJoyEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.6), Color.red.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Text("🔥")
                    .font(.system(size: 40))
                
                Text("\(entry.streakDays)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("day streak")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

// MARK: - Medium Widget View (Streak + Quick Add)
struct MediumWidgetView: View {
    let entry: DailyJoyEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.6), Color.red.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 20) {
                // Streak Section
                VStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 44))
                    
                    Text("\(entry.streakDays)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("day streak")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Quick Add Section
                Link(destination: URL(string: "dailyjoy://addmoment")!) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                        
                        Text("Add Moment")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
    }
}

// MARK: - Lock Screen Widget View
struct LockScreenStreakWidgetView: View {
    let entry: DailyJoyEntry
    
    var displayText: String {
        if entry.hasLoggedToday {
            return "\(entry.streakDays)"
        } else {
            return "!"
        }
    }
    
    var body: some View {
        ZStack {
            // Fire emoji background
            Text("🔥")
                .font(.system(size: 56))
            
            // Streak number or exclamation (see-through effect via blending)
            Text(displayText)
                .font(.system(size: displayText == "!" ? 40 : 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }
}

// MARK: - Widget Configurations
struct DailyJoySmallWidget: Widget {
    let kind: String = "DailyJoySmallWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyJoyProvider()) { entry in
            SmallStreakWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Streak")
        .description("See your current streak at a glance")
        .supportedFamilies([.systemSmall])
    }
}

struct DailyJoyMediumWidget: Widget {
    let kind: String = "DailyJoyMediumWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyJoyProvider()) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak & Quick Add")
        .description("View your streak and quickly add a moment")
        .supportedFamilies([.systemMedium])
    }
}

struct DailyJoyLockScreenWidget: Widget {
    let kind: String = "DailyJoyLockScreenWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyJoyProvider()) { entry in
            LockScreenStreakWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Streak Reminder")
        .description("Your daily streak on your lock screen")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Widget Bundle
@main
struct DailyJoyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        DailyJoySmallWidget()
        DailyJoyMediumWidget()
        DailyJoyLockScreenWidget()
    }
}
