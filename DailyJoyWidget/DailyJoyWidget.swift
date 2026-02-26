//
//  DailyJoyWidget.swift
//  DailyJoyWidget
//
//  Created by Amadeus Jackson on 2/24/26.
//

import WidgetKit
import SwiftUI
import Foundation

private let widgetAppGroupIdentifier = "group.dailyjoy.shared"
private let emberColor = Color(red: 1.0, green: 0.42, blue: 0.21)
private let addMomentURL = URL(string: "dailyjoy://add-moment")
private let openChallengesURL = URL(string: "dailyjoy://challenges")

struct DailyJoyWidgetSnapshot: Codable {
    let lastUpdated: Date
    let streakCount: Int
    let latestMomentTitle: String
    let latestMomentNote: String
    let latestMomentDate: Date?
    let challenge1: String
    let challenge2: String
    let challenge1Completed: Bool
    let challenge2Completed: Bool
    let hasLoggedToday: Bool
}

struct DailyJoyWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: DailyJoyWidgetSnapshot
}

struct DailyJoyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyJoyWidgetEntry {
        DailyJoyWidgetEntry(date: Date(), snapshot: Self.placeholderSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyJoyWidgetEntry) -> Void) {
        completion(DailyJoyWidgetEntry(date: Date(), snapshot: loadSnapshot() ?? Self.placeholderSnapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyJoyWidgetEntry>) -> Void) {
        let snapshot = loadSnapshot() ?? Self.placeholderSnapshot
        let entry = DailyJoyWidgetEntry(date: Date(), snapshot: snapshot)

        let nextMidnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(60 * 60 * 24))
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    private func loadSnapshot() -> DailyJoyWidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: widgetAppGroupIdentifier),
              let data = defaults.data(forKey: "widgetSnapshot") else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(DailyJoyWidgetSnapshot.self, from: data)
    }

    static let placeholderSnapshot = DailyJoyWidgetSnapshot(
        lastUpdated: Date(),
        streakCount: 3,
        latestMomentTitle: "A quiet morning",
        latestMomentNote: "Grateful for a slow start and a warm drink.",
        latestMomentDate: Date(),
        challenge1: "Take a 10-minute walk outside",
        challenge2: "Write a thank you note",
        challenge1Completed: false,
        challenge2Completed: true,
        hasLoggedToday: true
    )
}

struct StreakSmallWidgetView: View {
    let entry: DailyJoyWidgetEntry

    var body: some View {
        ZStack(alignment: .center) {
            FlameBadge(number: entry.snapshot.streakCount, size: 90)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .offset(y: 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .containerBackground(emberColor, for: .widget)
    }
}

struct AddMomentSmallWidgetView: View {
    let entry: DailyJoyWidgetEntry

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.title)
                .foregroundStyle(.white)
            Text("Add Moment")
                .font(.headline)
                .foregroundStyle(.white)
            Text(entry.snapshot.hasLoggedToday ? "Logged today" : "Log today")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(emberColor, for: .widget)
        .widgetURL(addMomentURL)
    }
}

struct StreakAddSmallWidgetView: View {
    let entry: DailyJoyWidgetEntry

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                FlameBadge(number: entry.snapshot.streakCount, size: 52)
                Text("\(entry.snapshot.streakCount)-day")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)

            Text(entry.snapshot.latestMomentTitle)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text("Add Moment")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.2), in: Capsule())
                .foregroundStyle(.white)
        }
        .padding()
        .containerBackground(emberColor, for: .widget)
        .widgetURL(addMomentURL)
    }
}

struct DailyJoyLargeWidgetView: View {
    let entry: DailyJoyWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                FlameBadge(number: entry.snapshot.streakCount, size: 40)
                Text("\(entry.snapshot.streakCount)-day streak")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Link(destination: addMomentURL!) {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.snapshot.latestMomentTitle)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(entry.snapshot.latestMomentNote)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
            }

            Divider().overlay(.white.opacity(0.35))

            VStack(alignment: .leading, spacing: 6) {
                Text("Daily Challenges")
                    .font(.caption.bold())
                    .foregroundStyle(.white)

                challengeRow(text: entry.snapshot.challenge1, completed: entry.snapshot.challenge1Completed)
                challengeRow(text: entry.snapshot.challenge2, completed: entry.snapshot.challenge2Completed)

                Link(destination: openChallengesURL!) {
                    Text("View challenges")
                        .font(.caption2)
                        .underline()
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .padding()
        .containerBackground(emberColor, for: .widget)
    }

    private func challengeRow(text: String, completed: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
                .foregroundStyle(.white)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
    }
}

struct DailyJoyLockScreenWidgetView: View {
    let entry: DailyJoyWidgetEntry

    var body: some View {
        ZStack {
            Circle().fill(emberColor)
            FlameBadge(number: entry.snapshot.streakCount, size: 22)
        }
    }
}

struct FlameBadge: View {
    let number: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            Image("FlameSolid")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size * 2.15, height: size * 2.44)
                .foregroundStyle(.white)
            Text("\(number)")
                .font(.system(size: max(10, size * 0.4), weight: .bold))
                .foregroundStyle(.black)
                .offset(y: size * 0.33)
        }
        .accessibilityHidden(true)
    }
}

struct DailyJoyStreakSmallWidget: Widget {
    let kind: String = "DailyJoyStreakSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyJoyWidgetProvider()) { entry in
            StreakSmallWidgetView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Streak")
        .description("Your current streak.")
    }
}

struct DailyJoyAddSmallWidget: Widget {
    let kind: String = "DailyJoyAddSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyJoyWidgetProvider()) { entry in
            AddMomentSmallWidgetView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Add Moment")
        .description("Quickly add a grateful moment.")
    }
}

struct DailyJoyStreakAddSmallWidget: Widget {
    let kind: String = "DailyJoyStreakAddSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyJoyWidgetProvider()) { entry in
            StreakAddSmallWidgetView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Streak + Add")
        .description("Streak and quick add.")
    }
}

struct StreakAddMediumWidgetView: View {
    let entry: DailyJoyWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    FlameBadge(number: entry.snapshot.streakCount, size: 44)
                    Text("\(entry.snapshot.streakCount)-day streak")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Text(entry.snapshot.latestMomentTitle)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(entry.snapshot.latestMomentNote)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Link(destination: addMomentURL!) {
                VStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                    Text("Add")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
                .padding(10)
                .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .containerBackground(emberColor, for: .widget)
    }
}

struct DailyJoyStreakAddMediumWidget: Widget {
    let kind: String = "DailyJoyStreakAddMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyJoyWidgetProvider()) { entry in
            StreakAddMediumWidgetView(entry: entry)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Streak + Add")
        .description("Your streak and quick add.")
    }
}

struct DailyJoyLargeWidget: Widget {
    let kind: String = "DailyJoyLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyJoyWidgetProvider()) { entry in
            DailyJoyLargeWidgetView(entry: entry)
        }
        .supportedFamilies([.systemLarge])
        .configurationDisplayName("Daily Joy")
        .description("Streak, moments, and challenges.")
    }
}

struct DailyJoyLockWidget: Widget {
    let kind: String = "DailyJoyLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyJoyWidgetProvider()) { entry in
            DailyJoyLockScreenWidgetView(entry: entry)
        }
        .supportedFamilies([.accessoryCircular])
        .configurationDisplayName("Streak (Lock Screen)")
        .description("Your streak at a glance.")
    }
}

#Preview(as: .systemSmall) {
    DailyJoyStreakSmallWidget()
} timeline: {
    DailyJoyWidgetEntry(date: .now, snapshot: DailyJoyWidgetProvider.placeholderSnapshot)
}
