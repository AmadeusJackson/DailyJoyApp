//
//  DailyJoyWidget.swift
//  DailyJoyWidget
//
//  Created by Amadeus Jackson on 1/7/26.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

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
            // Ember background
            Color(hex: "#fe7d00")
            
            VStack(spacing: 8) {
                // Fire emoji with number cutout
                ZStack {
                    Text("🔥")
                        .font(.system(size: 80))
                }
                .mask {
                    ZStack {
                        Rectangle()
                            .fill(.black)
                        
                        Text("\(entry.streakDays)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .blendMode(.destinationOut)
                            .offset(y: 18)
                    }
                    .compositingGroup()
                }
                
                Text("Streak")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Medium Widget View (Streak + Quick Add)
struct MediumWidgetView: View {
    let entry: DailyJoyEntry
    
    var body: some View {
        ZStack {
            // Ember background
            Color(hex: "#fe7d00")
            
            HStack(spacing: 20) {
                // Streak Section with flame and cutout number
                VStack(spacing: 8) {
                    ZStack {
                        Text("🔥")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .blendMode(.normal)
                    }
                    .mask {
                        ZStack {
                            Rectangle()
                                .fill(.black)
                            
                            Text("\(entry.streakDays)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .blendMode(.destinationOut)
                                .offset(y: 18)
                                .foregroundStyle(.white)
                        }
                        .compositingGroup()
                    }
                    
                    Text("Streak")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
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
                .font(.system(size: displayText == "!" ? 28 : 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .blendMode(.destinationOut)
                .offset(y: displayText == "!" ? 12 : 9)
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
