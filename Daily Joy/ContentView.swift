//
//  ContentView.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/14/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var celebrationBadge: Badge?
    @State private var showCelebration = false
    
    @Query private var allMoments: [Moment]
    
    // Check if there are any memory lane moments
    var hasMemories: Bool {
        let calendar = Calendar.current
        let today = Date()
        let currentDay = calendar.component(.day, from: today)
        let currentMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: today)
        
        return allMoments.contains { moment in
            let momentDay = calendar.component(.day, from: moment.timestamp)
            let momentMonth = calendar.component(.month, from: moment.timestamp)
            let momentYear = calendar.component(.year, from: moment.timestamp)
            
            return momentDay == currentDay &&
                   momentMonth == currentMonth &&
                   momentYear < currentYear
        }
    }
    
    var body: some View {
        TabView {
            Tab("Moments", systemImage: "heart.text.square.fill") {
                MomentsView()
            }
            
            // Only show Memory Lane tab if there are memories
            if hasMemories {
                Tab("Memory Lane", systemImage: "clock.arrow.circlepath") {
                    MemoryLaneFullView()
                }
            }
            
            Tab("Achievements", systemImage: "medal.fill") {
                AchievementsView()
            }
        }
        .badgeCelebration(badge: celebrationBadge, isPresented: $showCelebration)
        .onReceive(NotificationCenter.default.publisher(for: .badgeUnlocked)) { notification in
            if let badge = notification.object as? Badge {
                celebrationBadge = badge
                showCelebration = true
            }
        }
    }
}

// MARK: - Full Memory Lane View (for dedicated tab)
struct MemoryLaneFullView: View {
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
            
            return momentDay == currentDay &&
                   momentMonth == currentMonth &&
                   momentYear < currentYear
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with icon and description
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("On This Day")
                            .font(.largeTitle.bold())
                        
                        Text("Revisit your grateful moments from past years on this very day.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Stats section - using StatBadge from SharedComponents
                    HStack(spacing: 20) {
                        StatBadge(
                            value: "\(memoryMoments.count)",
                            label: memoryMoments.count == 1 ? "Memory" : "Memories",
                            icon: "sparkles",
                            color: .purple
                        )
                        
                        if let oldest = memoryMoments.last {
                            let yearsAgo = Calendar.current.dateComponents([.year], from: oldest.timestamp, to: Date()).year ?? 0
                            StatBadge(
                                value: "\(yearsAgo)",
                                label: yearsAgo == 1 ? "Year Ago" : "Years Ago",
                                icon: "calendar",
                                color: .blue
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Memory cards
                    LazyVStack(spacing: 16) {
                        ForEach(memoryMoments) { moment in
                            MemoryCardFull(moment: moment)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Memory Lane")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Full Memory Card
struct MemoryCardFull: View {
    let moment: Moment
    
    var yearsAgo: Int {
        let calendar = Calendar.current
        let years = calendar.dateComponents([.year], from: moment.timestamp, to: Date())
        return years.year ?? 0
    }
    
    var body: some View {
        NavigationLink {
            if moment.isLocked {
                LockedEntryView(moment: moment)
            } else {
                MomentDetailView(moment: moment)
            }
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    // Years ago badge
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)
                        Text("\(yearsAgo) \(yearsAgo == 1 ? "year" : "years") ago")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    
                    // Lock badge for locked moments
                    if moment.isLocked {
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                            Text("Locked")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                    }
                }
                
                // Image or color preview with lock overlay
                ZStack {
                    if let imageData = moment.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 250)
                            .clipped()
                            .cornerRadius(16)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.gray)
                            )
                    }
                    
                    // Blur/tint overlay for locked moments
                    if moment.isLocked {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.fromHex("0000FF").opacity(0.85))
                            .frame(height: 250)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Locked Moment")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            Text("Tap to unlock")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Title - blur if locked
                    if moment.isLocked {
                        Text(moment.title)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                            .blur(radius: 5)
                    } else {
                        Text(moment.title)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                    }
                    
                    // Note - blur if locked
                    if !moment.note.isEmpty {
                        if moment.isLocked {
                            Text(moment.note)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                                .blur(radius: 5)
                        } else {
                            Text(moment.note)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                        }
                    }
                    
                    // Original date
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(moment.timestamp, style: .date)
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .purple.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .sampleDataContainer()
}

// MARK: - Color Extension for Hex
extension Color {
    static func fromHex(_ hex: String) -> Color {
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

        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
