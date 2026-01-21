//
//  GratefulMomentsApp.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/14/25.
//
import SwiftUI
import SwiftData

@main
struct DailyJoyApp: App {
    private let dataContainer = DataContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataContainer)
                .modelContainer(dataContainer.modelContainer)
        }
    }
}

