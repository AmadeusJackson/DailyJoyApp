//
//  GratefulMomentsApp.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/14/25.
//

import SwiftUI
import SwiftData
import AppIntents

@main
struct GratefulMomentsApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var dataContainer = DataContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataContainer)
                .modelContainer(dataContainer.modelContainer)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Update app shortcuts when app becomes active
                GratefulMomentsShortcuts.updateAppShortcutParameters()
            }
        }
    }
}
