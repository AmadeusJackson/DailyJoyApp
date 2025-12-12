//
//  DataContainer.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/14/25.
//

import SwiftData
import SwiftUI


@Observable
@MainActor
class DataContainer {
    let modelContainer: ModelContainer
    var badgeManager: BadgeManager


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
            DailyChallenge.self
        ])


        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: includeSampleMoments)


        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            badgeManager = BadgeManager(modelContainer: modelContainer)


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
}


private let sampleContainer = DataContainer(includeSampleMoments: true)


extension View {
    func sampleDataContainer() -> some View {
        self
            .environment(sampleContainer)
            .modelContainer(sampleContainer.modelContainer)
    }
}
