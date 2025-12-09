//
//  DailyJoyWidget.swift
//  DailyJoyWidget
//
//  Created by Amadeus Jackson on 11/28/25.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Moment Data Model
struct WidgetMomentData: Codable {
    let title: String
    let note: String
    let imageData: Data?
    let timestamp: Date
}

// MARK: - Moment Entry
struct MomentEntry: TimelineEntry {
    let date: Date
    let momentData: WidgetMomentData?
}

// MARK: - Moment Timeline Provider
struct MomentProvider: TimelineProvider {
    func placeholder(in context: Context) -> MomentEntry {
        MomentEntry(
            date: Date(),
            momentData: WidgetMomentData(
                title: "🎉 Great Day",
                note: "Had an amazing time with friends",
                imageData: nil,
                timestamp: Date()
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MomentEntry) -> Void) {
        let entry = MomentEntry(date: Date(), momentData: loadLatestMoment())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MomentEntry>) -> Void) {
        let currentDate = Date()
        let entry = MomentEntry(date: currentDate, momentData: loadLatestMoment())
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadLatestMoment() -> WidgetMomentData? {
        // Load from shared UserDefaults (App Group)
        guard let sharedDefaults = UserDefaults(suiteName: "group.dailyjoy.shared"),
              let data = sharedDefaults.data(forKey: "latestMoment"),
              let momentData = try? JSONDecoder().decode(WidgetMomentData.self, from: data) else {
            return nil
        }
        return momentData
    }
}

// MARK: - Moment Widget View
struct MomentWidgetView: View {
    let entry: MomentEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        if let momentData = entry.momentData {
            ZStack {
                Color(UIColor.systemBackground)
                
                if widgetFamily == .systemSmall {
                    smallWidgetContent(momentData: momentData)
                } else {
                    mediumWidgetContent(momentData: momentData)
                }
            }
            .widgetURL(URL(string: "dailyjoy://addMoment"))
        } else {
            emptyStateView
                .widgetURL(URL(string: "dailyjoy://addMoment"))
        }
    }
    
    @ViewBuilder
    private func smallWidgetContent(momentData: WidgetMomentData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageData = momentData.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 80)
                    .clipped()
                    .cornerRadius(8)
            }
            
            Text(momentData.title)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(2)
            
            if !momentData.note.isEmpty {
                Text(momentData.note)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.pink)
                Text(momentData.timestamp, style: .relative)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func mediumWidgetContent(momentData: WidgetMomentData) -> some View {
        HStack(spacing: 12) {
            if let imageData = momentData.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.pink)
                    .frame(width: 100, height: 100)
                    .background(Color.pink.opacity(0.1))
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(momentData.title)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(2)
                
                if !momentData.note.isEmpty {
                    Text(momentData.note)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.pink)
                    Text(momentData.timestamp, style: .relative)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Add Moment")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Text("Tap to add your first grateful moment")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Moment Widget Configuration
struct MomentWidget: Widget {
    let kind: String = "MomentWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MomentProvider()) { entry in
            MomentWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Latest Moment")
        .description("Display your most recent grateful moment. Tap to add new.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemMedium) {
    MomentWidget()
} timeline: {
    MomentEntry(
        date: .now,
        momentData: WidgetMomentData(
            title: "🎉 Great Day",
            note: "Had an amazing time with friends today!",
            imageData: nil,
            timestamp: Date()
        )
    )
}
