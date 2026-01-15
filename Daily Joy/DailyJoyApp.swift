//
//  GratefulMomentsApp.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/14/25.
//
import SwiftUI
import PostHog   // ← this must ONLY exist in the app target

@main
struct DailyJoyApp: App {

    init() {
        let config = PostHogConfig(apiKey: "phc_RbVgJYRnnBEZSU7hUxYckaaQvNFZi65MjiW2O8K4KK4")
        config.host = "https://app.posthog.com"

        PostHogSDK.shared.setup(config)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// In AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    let config = PostHogConfig(apiKey: "YOUR_PROJECT_API_KEY")
    config.host = "https://app.posthog.com" // or your self-hosted URL
    PostHogSDK.shared.setup(config)
    
    return true
}

// Or in SwiftUI App
@main
struct YourApp: App {
    init() {
        let config = PostHogConfig(apiKey: "YOUR_PROJECT_API_KEY")
        config.host = "https://app.posthog.com"
        PostHogSDK.shared.setup(config)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
