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
    @State private var shouldShowAddMoment = false
    
    var dataContainer = DataContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView(shouldShowAddMoment: $shouldShowAddMoment)
                .environment(dataContainer)
                .modelContainer(dataContainer.modelContainer)
                .task {  // ✅ Check notification permission on launch
                    _ = await dataContainer.notificationManager.checkPermissionStatus()
                }
                .onOpenURL { url in
                    // ✅ Handle widget deep links
                    if url.scheme == "dailyjoy" && url.host == "addmoment" {
                        shouldShowAddMoment = true
                    }
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Update app shortcuts when app becomes active
                GratefulMomentsShortcuts.updateAppShortcutParameters()
                
                // ✅ Check notification permission when app becomes active
                Task {
                    _ = await dataContainer.notificationManager.checkPermissionStatus()
                }
            }
        }
    }
}
