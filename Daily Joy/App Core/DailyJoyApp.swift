//
//  GratefulMomentsApp.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/14/25.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct DailyJoyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let dataContainer = DataContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataContainer)
                .modelContainer(dataContainer.modelContainer)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
