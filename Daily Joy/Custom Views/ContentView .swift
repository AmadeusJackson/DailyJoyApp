//
//  ContentView.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/14/25.
//

import SwiftUI
import SwiftData

/// Root tab-based interface for Daily Joy.
/// Hosts Moments, Challenges, conditional Memory Lane, and Achievements tabs.
/// Handles deep links from widgets to open Add Moment or Challenges.
@available(iOS 17.0, *)
struct ContentView: View {

    /// Bound to widget deep link state to present the Add Moment flow when needed.
    @Binding var shouldShowAddMoment: Bool
    
    // ✅ Explicit initializer with default value
    init(shouldShowAddMoment: Binding<Bool> = .constant(false)) {
        self._shouldShowAddMoment = shouldShowAddMoment
    }

    /// The most recently unlocked badge to show in a celebration overlay.
    @State private var celebrationBadge: Badge?
    /// Controls presentation of the badge celebration overlay.
    @State private var showCelebration = false
    /// The identifier or title of a completed challenge to celebrate.
    @State private var completedChallenge: String?
    /// Controls presentation of the challenge celebration overlay.
    @State private var showChallengeCelebration = false
    /// Currently selected tab index.
    @State private var selectedTab = 0  // ✅ Track selected tab

    /// All persisted moments, used to determine whether Memory Lane should be shown.
    @Query private var allMoments: [Moment]

    /// Returns true if there are moments from the same day/month in prior years.
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

    // Main tab layout and celebrations wiring.
    var body: some View {
        TabView(selection: $selectedTab) {

            MomentsView(shouldShowAddMoment: $shouldShowAddMoment)
                .tabItem {
                    Label("Moments", systemImage: "heart.text.square.fill")
                }
                .tag(0)

            DailyChallengesView()
                .tabItem {
                    Label("Challenges", systemImage: "star.circle.fill")
                }
                .tag(1)

            if hasMemories {
                MemoryLaneFullView()
                    .tabItem {
                        Label("Memory Lane", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(2)
            }

            AchievementsView()
                .tabItem {
                    Label("Achievements", systemImage: "medal.fill")
                }
                .tag(hasMemories ? 3 : 2)
        }
        .badgeCelebration(
            badge: celebrationBadge,
            isPresented: $showCelebration
        )
        .challengeCelebration(
            challenge: completedChallenge,
            isPresented: $showChallengeCelebration
        )
        /// Listen for badge unlock notifications to trigger celebration UI.
        .onReceive(NotificationCenter.default.publisher(for: .badgeUnlocked)) {
            notification in
            if let badge = notification.object as? Badge {
                celebrationBadge = badge
                showCelebration = true
            }
        }
        /// Listen for challenge completion notifications to trigger celebration UI.
        .onReceive(NotificationCenter.default.publisher(for: .challengeCompleted)) {
            notification in
            if let challenge = notification.object as? String {
                completedChallenge = challenge
                showChallengeCelebration = true
            }
        }
        /// Respond to deep link state and switch to the Moments tab to present the add flow.
        .onChange(of: shouldShowAddMoment) { oldValue, newValue in
            if newValue {
                selectedTab = 0  // Switch to Moments tab
                // The binding will trigger MomentsView to show add sheet
            }
        }
        /// Handle custom URL scheme from widgets (e.g., dailyjoy://add-moment, dailyjoy://challenges).
        .onOpenURL { url in
            handleWidgetURL(url)
        }
    }

    /// Parses and routes widget URLs to the appropriate tab or action.
    private func handleWidgetURL(_ url: URL) {
        guard url.scheme == "dailyjoy" else { return }
        switch url.host {
        case "add-moment":
            shouldShowAddMoment = true
        case "challenges":
            selectedTab = 1
        default:
            break
        }
    }
}

// MARK: - Memory Lane Full View

/// Dedicated screen listing prior-year moments that occurred on today's date.
@available(iOS 17.0, *)
struct MemoryLaneFullView: View {

    init() {}

    @Query private var allMoments: [Moment]

    /// Filters and sorts moments to "On This Day" entries from previous years.
    var memoryMoments: [Moment] {
        let calendar = Calendar.current
        let today = Date()

        let currentDay = calendar.component(.day, from: today)
        let currentMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: today)

        return allMoments
            .filter { moment in
                let day = calendar.component(.day, from: moment.timestamp)
                let month = calendar.component(.month, from: moment.timestamp)
                let year = calendar.component(.year, from: moment.timestamp)

                return day == currentDay &&
                       month == currentMonth &&
                       year < currentYear
            }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

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

                        Text("Revisit your grateful moments from past years.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                    Divider()

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

// MARK: - Memory Card

/// Card-style navigation row for a single memory, respecting locked state.
struct MemoryCardFull: View {

    let moment: Moment

    /// Number of years between the moment timestamp and now.
    var yearsAgo: Int {
        Calendar.current
            .dateComponents([.year], from: moment.timestamp, to: Date())
            .year ?? 0
    }

    var body: some View {
        // Navigate to detail or locked view depending on moment state.
        NavigationLink {
            moment.isLocked
                ? AnyView(LockedEntryView(moment: moment))
                : AnyView(MomentDetailView(moment: moment))
        } label: {
            VStack(alignment: .leading, spacing: 12) {

                Text("\(yearsAgo) \(yearsAgo == 1 ? "Year" : "Years") Ago")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(6)
                    .background(
                        Capsule().fill(Color.blue)
                    )

                Text(moment.title)
                    .font(.title3.bold())
                    .blur(radius: moment.isLocked ? 5 : 0)

                if !moment.note.isEmpty {
                    Text(moment.note)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                        .blur(radius: moment.isLocked ? 5 : 0)
                }

                Text(moment.timestamp, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 5)
            )
        }
        .buttonStyle(.plain)
    }
}
