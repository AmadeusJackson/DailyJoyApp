//
//  NotificationManager.swift
//  Daily Joy
//
//  Created by Amadeus Jackson on 12/28/25.
//

import Foundation
import UserNotifications
import SwiftData

@Observable
class NotificationManager {
    private let modelContext: ModelContext
    
    // Track if we have permission (based on system permission)
    var hasPermission: Bool = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Permission Request
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            
            if granted {
                hasPermission = true
                await scheduleSmartNotifications()
            }
            
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        hasPermission = settings.authorizationStatus == .authorized
        return settings.authorizationStatus
    }
    
    // MARK: - Smart Scheduling
    
    func scheduleSmartNotifications() async {
        // Check if we have permission first
        let status = await checkPermissionStatus()
        guard status == .authorized else { return }
        
        // Cancel existing notifications
        cancelAllNotifications()
        
        // Get user's typical logging times
        let typicalTimes = await analyzeLoggingPatterns()
        
        // Schedule notifications based on patterns
        if !typicalTimes.isEmpty {
            await schedulePatternBasedNotifications(times: typicalTimes)
        } else {
            // No pattern yet, use default gentle reminder
            await scheduleDefaultNotification()
        }
        
        // Always schedule end-of-day reminder
        await scheduleEndOfDayReminder()
    }
    
    private func analyzeLoggingPatterns() async -> [DateComponents] {
        // Fetch recent moments to find patterns
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate { moment in
                moment.timestamp >= thirtyDaysAgo
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        
        guard let moments = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        // Need at least 5 moments to establish a pattern
        guard moments.count >= 5 else {
            return []
        }
        
        // Group moments by hour to find most common logging times
        var hourCounts: [Int: Int] = [:]
        
        for moment in moments {
            let hour = calendar.component(.hour, from: moment.timestamp)
            hourCounts[hour, default: 0] += 1
        }
        
        // Find top 2 most common hours (must have at least 3 occurrences to count)
        let topHours = hourCounts
            .filter { $0.value >= 3 }
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { $0.key }
        
        // Convert to DateComponents
        return topHours.map { hour in
            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            return components
        }
    }
    
    private func schedulePatternBasedNotifications(times: [DateComponents]) async {
        let messages = [
            "Time for a moment of gratitude ✨",
            "What made you smile today?",
            "Capture a joyful moment 💛",
            "What are you grateful for right now?",
            "Ready to reflect on today?",
            "Time to capture some joy ☀️"
        ]
        
        for (index, time) in times.enumerated() {
            let message = messages.randomElement() ?? "Time to log a moment"
            
            await scheduleNotification(
                identifier: "pattern_\(index)",
                title: "Daily Joy",
                body: message,
                dateComponents: time
            )
        }
    }
    
    private func scheduleDefaultNotification() async {
        // Default to mid-afternoon if no pattern exists
        var components = DateComponents()
        components.hour = 15
        components.minute = 0
        
        await scheduleNotification(
            identifier: "default_reminder",
            title: "Daily Joy",
            body: "What made you smile today? ✨",
            dateComponents: components
        )
    }
    
    private func scheduleEndOfDayReminder() async {
        var components = DateComponents()
        components.hour = 21  // 9 PM
        components.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Joy"
        content.body = "Still time to capture a moment from today 🌙"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "end_of_day_reminder", content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error scheduling end-of-day reminder: \(error)")
        }
    }
    
    private func scheduleNotification(identifier: String, title: String, body: String, dateComponents: DateComponents) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
    
    // MARK: - Notification Management
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Update Schedule (call after new moment is saved)
    
    func updateScheduleAfterNewMoment() async {
        // Only reschedule if we have permission
        guard hasPermission else { return }
        
        // Reschedule based on updated patterns
        await scheduleSmartNotifications()
    }
    
    // MARK: - Check if should show end-of-day reminder
    
    func shouldShowEndOfDayReminder() async -> Bool {
        // Check if user has logged any moments today
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate { moment in
                moment.timestamp >= startOfDay
            }
        )
        
        let todayMoments = (try? modelContext.fetch(descriptor)) ?? []
        return todayMoments.isEmpty
    }
}
