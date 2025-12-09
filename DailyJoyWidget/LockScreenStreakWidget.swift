//
//  LockScreenStreakWidget.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 11/28/25.
//

import WidgetKit
import SwiftUI

// MARK: - Custom Solid Flame Shape (Based on SF Symbol)
struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Bottom center start
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.95))
        
        // Bottom left curve
        path.addCurve(
            to: CGPoint(x: width * 0.25, y: height * 0.75),
            control1: CGPoint(x: width * 0.35, y: height * 0.95),
            control2: CGPoint(x: width * 0.22, y: height * 0.85)
        )
        
        // Left side middle
        path.addCurve(
            to: CGPoint(x: width * 0.2, y: height * 0.5),
            control1: CGPoint(x: width * 0.15, y: height * 0.68),
            control2: CGPoint(x: width * 0.15, y: height * 0.58)
        )
        
        // Left side upper
        path.addCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.25),
            control1: CGPoint(x: width * 0.2, y: height * 0.38),
            control2: CGPoint(x: width * 0.25, y: height * 0.3)
        )
        
        // Left side to tip
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.05),
            control1: CGPoint(x: width * 0.38, y: height * 0.15),
            control2: CGPoint(x: width * 0.43, y: height * 0.08)
        )
        
        // Tip to right side upper
        path.addCurve(
            to: CGPoint(x: width * 0.65, y: height * 0.25),
            control1: CGPoint(x: width * 0.57, y: height * 0.08),
            control2: CGPoint(x: width * 0.62, y: height * 0.15)
        )
        
        // Right side middle
        path.addCurve(
            to: CGPoint(x: width * 0.8, y: height * 0.5),
            control1: CGPoint(x: width * 0.75, y: height * 0.3),
            control2: CGPoint(x: width * 0.85, y: height * 0.38)
        )
        
        // Right side lower
        path.addCurve(
            to: CGPoint(x: width * 0.75, y: height * 0.75),
            control1: CGPoint(x: width * 0.85, y: height * 0.58),
            control2: CGPoint(x: width * 0.85, y: height * 0.68)
        )
        
        // Bottom right curve back to start
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.95),
            control1: CGPoint(x: width * 0.78, y: height * 0.85),
            control2: CGPoint(x: width * 0.65, y: height * 0.95)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Lock Screen Streak Entry
struct LockScreenStreakEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
}

// MARK: - Lock Screen Streak Provider
struct LockScreenStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenStreakEntry {
        LockScreenStreakEntry(date: Date(), streakCount: 7)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LockScreenStreakEntry) -> Void) {
        let entry = LockScreenStreakEntry(date: Date(), streakCount: getStreakCount())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenStreakEntry>) -> Void) {
        let currentDate = Date()
        let entry = LockScreenStreakEntry(date: currentDate, streakCount: getStreakCount())
        
        // Update at midnight
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
    
    private func getStreakCount() -> Int {
        guard let sharedDefaults = UserDefaults(suiteName: "group.dailyjoy.shared") else {
            return 0
        }
        return sharedDefaults.integer(forKey: "streakCount")
    }
}

// MARK: - Lock Screen Widget View
struct LockScreenStreakWidgetView: View {
    let entry: LockScreenStreakEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }
    
    // Circular lock screen widget
    private var circularView: some View {
        ZStack {
            Text("🔥")
                .font(.system(size: 44))
        }
        .mask {
            ZStack {
                Rectangle()
                    .fill(.black)
                
                Text("\(entry.streakCount)")
                    .font(.system(size: 18, weight: .black))
                    .blendMode(.destinationOut)
                    .offset(y: 9)
            }
            .compositingGroup()
        }
    }
    
    // Rectangular lock screen widget
    private var rectangularView: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.streakCount) Day")
                    .font(.system(size: 16, weight: .bold))
                Text("Streak")
                    .font(.system(size: 12))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // Inline lock screen widget (above time)
    private var inlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
            Text("\(entry.streakCount) day streak")
        }
    }
}

// MARK: - Lock Screen Widget Configuration
struct LockScreenStreakWidget: Widget {
    let kind: String = "LockScreenStreakWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenStreakProvider()) { entry in
            if #available(iOS 17.0, *) {
                LockScreenStreakWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        // Empty background for lock screen widgets
                    }
            } else {
                LockScreenStreakWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Streak")
        .description("Your current gratitude streak.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Preview
#Preview(as: .accessoryCircular) {
    LockScreenStreakWidget()
} timeline: {
    LockScreenStreakEntry(date: .now, streakCount: 7)
    LockScreenStreakEntry(date: .now, streakCount: 14)
    LockScreenStreakEntry(date: .now, streakCount: 30)
}
