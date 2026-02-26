//
//  ContentView.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/14/25.
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct ContentView: View {

    // ✅ Add binding for widget deep link
    @Binding var shouldShowAddMoment: Bool
    
    // ✅ Explicit initializer with default value
    init(shouldShowAddMoment: Binding<Bool> = .constant(false)) {
        self._shouldShowAddMoment = shouldShowAddMoment
    }

    @State private var celebrationBadge: Badge?
    @State private var showCelebration = false
    @State private var completedChallenge: String?
    @State private var showChallengeCelebration = false
    @State private var selectedTab = 0  // ✅ Track selected tab

    @Query private var allMoments: [Moment]

    // MARK: - Memory Lane Check
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

    // MARK: - UI
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
        .onReceive(NotificationCenter.default.publisher(for: .badgeUnlocked)) {
            notification in
            if let badge = notification.object as? Badge {
                celebrationBadge = badge
                showCelebration = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .challengeCompleted)) {
            notification in
            if let challenge = notification.object as? String {
                completedChallenge = challenge
                showChallengeCelebration = true
            }
        }
        // ✅ Handle widget deep link
        .onChange(of: shouldShowAddMoment) { oldValue, newValue in
            if newValue {
                selectedTab = 0  // Switch to Moments tab
                // The binding will trigger MomentsView to show add sheet
            }
        }
        .onOpenURL { url in
            handleWidgetURL(url)
        }
    }

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
@available(iOS 17.0, *)
struct MemoryLaneFullView: View {

    init() {}

    @Query private var allMoments: [Moment]

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
struct MemoryCardFull: View {

    let moment: Moment

    var yearsAgo: Int {
        Calendar.current
            .dateComponents([.year], from: moment.timestamp, to: Date())
            .year ?? 0
    }

    var body: some View {
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
