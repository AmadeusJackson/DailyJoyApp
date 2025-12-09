//
//  GratefulMomentsApp.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/14/25.
//

import SwiftUI
import SwiftData

@main
struct GratefulMomentsApp: App {
    @State private var showCreateMoment = false
    let dataContainer = DataContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(dataContainer.modelContainer)
                .environment(dataContainer)
                .onOpenURL { url in
                    // Handle deep link from widget
                    if url.scheme == "dailyjoy", url.host == "addMoment" {
                        showCreateMoment = true
                    }
                }
                .sheet(isPresented: $showCreateMoment) {
                    MomentEntryView()
                        .modelContainer(dataContainer.modelContainer)
                        .environment(dataContainer)
                }
        }
    }
}
