//
//  DataContainer.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/14/25.
//

import SwiftData
import SwiftUI
import WidgetKit

private let appGroupIdentifier = "group.com.amadeusjackson.dailyjoy"

// Local copy of widget kind strings so app can reload specific timelines
struct DailyJoyWidgetKinds {
    static let small = "DailyJoySmallWidget"
    static let medium = "DailyJoyMediumWidget"
    static let lock = "DailyJoyLockScreenWidget"
}

@Observable
@MainActor
class DataContainer {
    let modelContainer: ModelContainer
    var badgeManager: BadgeManager
    var notificationManager: NotificationManager

    var context: ModelContext {
        modelContainer.mainContext
    }
    
    var challengeManager: ChallengeManager {
        ChallengeManager(modelContext: context)
    }

    init(includeSampleMoments: Bool = false) {
        let schema = Schema([
            Moment.self,
            Badge.self,
            DailyChallenge.self,
            Draft.self
        ])

        do {
            // Use shared App Group store so the app and widgets see the same data
            if includeSampleMoments {
                let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                #if DEBUG
                print("Using in-memory sample store (includeSampleMoments == true)")
                #endif
            } else {
                // Diagnostic: use default app container (no App Group) to validate persistence across relaunches
                let modelConfiguration = ModelConfiguration(schema: schema)
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                #if DEBUG
                print("Using default app container store (diagnostic mode)")
                #endif
            }
            badgeManager = BadgeManager(modelContainer: modelContainer)
            notificationManager = NotificationManager(modelContext: modelContainer.mainContext)

            try badgeManager.loadBadgesIfNeeded()

            if includeSampleMoments {
                try loadSampleMoments()
            }
            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private func loadSampleMoments() throws {
        for moment in Moment.sampleData {
            context.insert(moment)
            try badgeManager.unlockBadges(newMoment: moment)
        }
    }
    
    // ✅ NEW: Function to save and refresh widgets
    func saveMoment(_ moment: Moment) throws {
        context.insert(moment)
        try badgeManager.unlockBadges(newMoment: moment)
        try context.save()
        
        // Reload widgets immediately after saving a moment
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.small)
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.medium)
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.lock)
    }
    
    // ✅ NEW: Function to delete and refresh widgets
    func deleteMoment(_ moment: Moment) throws {
        context.delete(moment)
        try context.save()
        
        // Reload widgets after deletion
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.small)
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.medium)
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.lock)
    }
    
    // ✅ NEW: Call this after any context save that affects moments
    func refreshWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.small)
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.medium)
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.lock)
    }
}

private let sampleContainer = DataContainer(includeSampleMoments: true)  

extension View {
    func sampleDataContainer() -> some View {
        self
            .environment(sampleContainer)
            .modelContainer(sampleContainer.modelContainer)
    }
}

