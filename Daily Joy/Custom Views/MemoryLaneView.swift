//
//  MemoryLaneView.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/7/25.
//

import SwiftUI
import SwiftData

// MARK: - Memory Lane View
struct MemoryLaneView: View {
    @Query private var allMoments: [Moment]
    
    var memoryMoments: [Moment] {
        let calendar = Calendar.current
        let today = Date()
        let currentDay = calendar.component(.day, from: today)
        let currentMonth = calendar.component(.month, from: today)
        
        return allMoments.filter { moment in
            let momentDay = calendar.component(.day, from: moment.timestamp)
            let momentMonth = calendar.component(.month, from: moment.timestamp)
            let momentYear = calendar.component(.year, from: moment.timestamp)
            let currentYear = calendar.component(.year, from: today)
            
            // Same day and month, but different year
            return momentDay == currentDay &&
                   momentMonth == currentMonth &&
                   momentYear < currentYear
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        if !memoryMoments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .foregroundStyle(.purple)
                    Text("On This Day")
                        .font(.title3.bold())
                    Spacer()
                }
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(memoryMoments) { moment in
                            MemoryCard(moment: moment)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal)
        }
    }
}

// MARK: - Memory Card
struct MemoryCard: View {
    let moment: Moment
    
    var yearsAgo: Int {
        let calendar = Calendar.current
        let years = calendar.dateComponents([.year], from: moment.timestamp, to: Date())
        return years.year ?? 0
    }
    
    var body: some View {
        NavigationLink {
            MomentDetailView(moment: moment)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Image or color preview
                if let imageData = moment.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 280, height: 180)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 280, height: 180)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundStyle(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Years ago badge
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text("\(yearsAgo) \(yearsAgo == 1 ? "year" : "years") ago")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.purple.opacity(0.1))
                    )
                    
                    // Title
                    Text(moment.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    
                    // Note preview
                    if !moment.note.isEmpty {
                        Text(moment.note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Original date
                    Text(moment.timestamp, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
            .frame(width: 280)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Memory Lane Statistics View (Optional Bonus)
struct MemoryLaneStatsView: View {
    @Query private var allMoments: [Moment]
    
    var totalMemories: Int {
        allMoments.count
    }
    
    var oldestMoment: Moment? {
        allMoments.min(by: { $0.timestamp < $1.timestamp })
    }
    
    var daysTracking: Int {
        guard let oldest = oldestMoment else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: oldest.timestamp, to: Date())
        return days.day ?? 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Your Journey")
                .font(.title2.bold())
            
            HStack(spacing: 30) {
                StatCard(
                    value: "\(totalMemories)",
                    label: "Moments",
                    icon: "heart.fill",
                    color: .pink
                )
                
                StatCard(
                    value: "\(daysTracking)",
                    label: "Days",
                    icon: "calendar",
                    color: .blue
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
}

// StatCard is now in SharedComponents.swift - no need to redefine here

// MARK: - View Extension for Easy Integration
extension View {
    func memoryLane() -> some View {
        VStack(spacing: 0) {
            MemoryLaneView()
            self
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ScrollView {
            VStack {
                MemoryLaneView()
                MemoryLaneStatsView()
            }
        }
    }
    .sampleDataContainer()
}
