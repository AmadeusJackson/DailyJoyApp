//
//  HeatmapCalender.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/7/25.
//

import SwiftUI
import SwiftData

// MARK: - Heatmap Calendar View (Current Month Only)
struct HeatmapCalendarView: View {
    @Query(sort: \Moment.timestamp) private var allMoments: [Moment]
    @State private var selectedDate: Date?
    @State private var currentMonth = Date()
    @Environment(\.dismiss) private var dismiss
    
    let calendar = Calendar.current
    
    // Get all days in the selected month
    var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = monthInterval.start
        
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    // Organize days into weeks for grid display
    var weeks: [[Date?]] {
        var result: [[Date?]] = []
        var week: [Date?] = []
        
        // Add empty cells for days before the month starts
        if let firstDay = daysInMonth.first {
            let weekday = calendar.component(.weekday, from: firstDay)
            for _ in 1..<weekday {
                week.append(nil)
            }
        }
        
        // Add all days in the month
        for day in daysInMonth {
            week.append(day)
            
            let weekday = calendar.component(.weekday, from: day)
            if weekday == 7 { // Saturday
                result.append(week)
                week = []
            }
        }
        
        // Add remaining week if not empty
        if !week.isEmpty {
            while week.count < 7 {
                week.append(nil)
            }
            result.append(week)
        }
        
        return result
    }
    
    // Count moments per day
    func momentsCount(for date: Date) -> Int {
        allMoments.filter { moment in
            calendar.isDate(moment.timestamp, inSameDayAs: date)
        }.count
    }
    
    // GitHub-style color intensity
    func colorIntensity(for count: Int) -> Color {
        switch count {
        case 0:
            return Color(.systemGray5)
        case 1:
            return Color.green.opacity(0.3)
        case 2:
            return Color.green.opacity(0.5)
        case 3:
            return Color.green.opacity(0.7)
        case 4:
            return Color.green.opacity(0.85)
        default: // 5+
            return Color.green
        }
    }
    
    var totalMomentsThisMonth: Int {
        let monthInterval = calendar.dateInterval(of: .month, for: currentMonth)!
        return allMoments.filter { moment in
            monthInterval.contains(moment.timestamp)
        }.count
    }
    
    var currentStreak: Int {
        StreakCalculator().calculateStreak(for: Array(allMoments))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Month navigation
                    monthNavigator
                    
                    // Stats cards
                    statsSection
                    
                    // Legend
                    legendSection
                    
                    // Heatmap
                    heatmapSection
                    
                    // Selected date detail
                    if let selectedDate = selectedDate {
                        selectedDateDetail(for: selectedDate)
                    }
                }
                .padding()
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var monthNavigator: some View {
        HStack {
            Button {
                currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            
            Spacer()
            
            Text(currentMonth, format: .dateTime.month(.wide).year())
                .font(.title2.bold())
            
            Spacer()
            
            Button {
                if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth),
                   nextMonth <= Date() {
                    currentMonth = nextMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .disabled(calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            VStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(.pink)
                
                Text("\(totalMomentsThisMonth)")
                    .font(.title.bold())
                
                Text("This Month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pink.opacity(0.1))
            )
            
            VStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                Text("\(currentStreak)")
                    .font(.title.bold())
                
                Text("Day Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
            )
        }
    }
    
    private var legendSection: some View {
        HStack(spacing: 8) {
            Text("Less")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            ForEach(0..<6) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorIntensity(for: index))
                    .frame(width: 15, height: 15)
            }
            
            Text("More")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day labels (S M T W T F S)
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)
            
            // Calendar grid
            VStack(spacing: 8) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 8) {
                        ForEach(Array(week.enumerated()), id: \.offset) { dayIndex, date in
                            if let date = date {
                                let count = momentsCount(for: date)
                                let dayNumber = calendar.component(.day, from: date)
                                
                                VStack(spacing: 2) {
                                    Text("\(dayNumber)")
                                        .font(.caption2)
                                        .foregroundStyle(count > 0 ? .white : .secondary)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(colorIntensity(for: count))
                                        .frame(height: 8)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(calendar.isDateInToday(date) ? Color.blue.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(
                                            selectedDate == date ? Color.blue : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedDate = date
                                    }
                                }
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8)
        )
    }
    
    private func selectedDateDetail(for date: Date) -> some View {
        let moments = allMoments.filter { moment in
            calendar.isDate(moment.timestamp, inSameDayAs: date)
        }
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(date, style: .date)
                        .font(.headline)
                    
                    Text("\(moments.count) \(moments.count == 1 ? "moment" : "moments")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        selectedDate = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
            }
            
            if !moments.isEmpty {
                Divider()
                
                VStack(spacing: 12) {
                    ForEach(moments) { moment in
                        NavigationLink {
                            MomentDetailView(moment: moment)
                        } label: {
                            HStack(spacing: 12) {
                                // Thumbnail
                                if let imageData = moment.imageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "heart.fill")
                                                .foregroundStyle(.gray)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(moment.title)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    
                                    if !moment.note.isEmpty {
                                        Text(moment.note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    
                                    Text(moment.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.1))
        )
    }
}

// MARK: - Preview
#Preview {
    HeatmapCalendarView()
        .sampleDataContainer()
}
