//
//  AchievementsView.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 11/23/25.
//

import SwiftUI
import SwiftData


struct AchievementsView: View {
    @Query(filter: #Predicate<Badge> { $0.timestamp != nil })
    private var unlockedBadges: [Badge]


    @Query(filter: #Predicate<Badge> { $0.timestamp == nil })
    private var lockedBadges: [Badge]


    @Query(sort: \Moment.timestamp)
    private var moments: [Moment]


    var body: some View {
        NavigationStack {
            ScrollView {
                contentStack
            }
            .navigationTitle("Achievements")
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }


    private var contentStack: some View {
        VStack(alignment: .leading) {
            StreakView(numberOfDays: StreakCalculator().calculateStreak(for: moments))
                .frame(maxWidth: .infinity)

            Spacer(minLength: 8)

            // Unlocked section (always visible)
            header("Your Badges")
            if sortedUnlockedBadges.isEmpty {
                Text("No unlocked badges yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sortedUnlockedBadges) { badge in
                            UnlockedBadgeView(badge: badge)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Locked section (always visible)
            header("Locked Badges")
            if sortedLockedBadges.isEmpty {
                Text("No locked badges found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    ForEach(sortedLockedBadges) { badge in
                        LockedBadgeView(badge: badge)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }

            if unlockedBadges.isEmpty && lockedBadges.isEmpty {
                ContentUnavailableView {
                    Label("No badges yet", systemImage: "seal")
                } description: {
                    Text("Badges will appear here once they are loaded. Make sure the app seeds badges and uses the correct data store.")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }

            #if DEBUG
            Text("Unlocked: \(unlockedBadges.count) • Locked: \(lockedBadges.count) • Moments: \(moments.count)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            #endif
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
    }


    func header(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.top, 8)
    }


    /// - precondition: `unlockedBadges` must have a timestamp
    private var sortedUnlockedBadges: [Badge] {
        unlockedBadges.sorted {
            ($0.timestamp!, $0.details.title) < ($1.timestamp!, $1.details.title)
        }
    }


    private var sortedLockedBadges: [Badge] {
        lockedBadges.sorted {
            $0.details.rawValue < $1.details.rawValue
        }
    }
}


#Preview {
    AchievementsView()
        .sampleDataContainer()
}

