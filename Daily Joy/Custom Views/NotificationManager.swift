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
    
    // Debug/testing support: accelerate time-based rules
    var debugAcceleratedTesting: Bool = false
    // When true, treat days as minutes to simulate inactivity windows quickly
    
    enum ReminderStyle: String, CaseIterable { case gentle, motivational, quiet }

    struct ReminderPreferences {
        static let styleKey = "reminder_style"
        static let secondChanceEnabledKey = "reminder_second_chance_enabled"
        static let secondChanceHourKey = "reminder_second_chance_hour"
        static let secondChanceMinuteKey = "reminder_second_chance_minute"

        static var style: ReminderStyle {
            get { ReminderStyle(rawValue: UserDefaults.standard.string(forKey: styleKey) ?? "gentle") ?? .gentle }
            set { UserDefaults.standard.set(newValue.rawValue, forKey: styleKey) }
        }
        static var secondChanceEnabled: Bool {
            get { UserDefaults.standard.bool(forKey: secondChanceEnabledKey) }
            set { UserDefaults.standard.set(newValue, forKey: secondChanceEnabledKey) }
        }
        static var secondChanceTime: (hour: Int, minute: Int) {
            get {
                let h = UserDefaults.standard.object(forKey: secondChanceHourKey) as? Int ?? 21
                let m = UserDefaults.standard.object(forKey: secondChanceMinuteKey) as? Int ?? 0
                return (h, m)
            }
            set {
                UserDefaults.standard.set(newValue.hour, forKey: secondChanceHourKey)
                UserDefaults.standard.set(newValue.minute, forKey: secondChanceMinuteKey)
            }
        }
    }
    
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
        let status = await checkPermissionStatus()
        guard status == .authorized else { return }

        // Clear all existing
        cancelAllNotifications()

        // Compute state needed for rules
        let calendar = Calendar.current
        let now = Date()
        let accelerated = debugAcceleratedTesting

        // Fetch all moments (or recent enough) to derive rules
        let descriptor = FetchDescriptor<Moment>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let moments: [Moment] = (try? modelContext.fetch(descriptor)) ?? []

        // Determine last moment date
        let lastMomentDate = moments.first?.timestamp

        // If no moments at all yet, use 4 PM daily as starter
        if lastMomentDate == nil {
            await scheduleDailyAt(hour: 16, minute: 0, identifier: "starter_4pm", body: bodyTextForStyle(defaultBody: "What made you smile today? ✨"))
            await scheduleSecondChanceIfEnabled()
            return
        }

        // Days since last moment
        let daysSinceLast: Int = {
            if accelerated {
                // In accelerated mode, compare minutes instead of days: 1 day == 1 minute
                let minutes = calendar.dateComponents([.minute], from: lastMomentDate!, to: now).minute ?? 0
                return minutes
            } else {
                return calendar.dateComponents([.day], from: calendar.startOfDay(for: lastMomentDate!), to: calendar.startOfDay(for: now)).day ?? 0
            }
        }()

        // Rule: After 7 days of inactivity -> 4pm on Mon/Wed/Fri only
        if daysSinceLast >= 7 {
            await scheduleMWFAt4pm(body: bodyTextForStyle(defaultBody: "A gentle nudge to add a moment ✨"))
            await scheduleSecondChanceIfEnabled()
            return
        }

        // Rule: After 5 days of inactivity -> back to 4pm daily
        if daysSinceLast >= 5 {
            await scheduleDailyAt(hour: 16, minute: 0, identifier: "fallback_4pm", body: bodyTextForStyle(defaultBody: "Take a moment to reflect 💛"))
            await scheduleSecondChanceIfEnabled()
            return
        }

        // Determine if we are within first 3 days of usage (track by first 3 distinct days with moments)
        let firstThreeDayCount: Int = {
            if accelerated {
                // Count distinct minutes bucket (simulating distinct days)
                let minuteBuckets = Set(moments.map { date in
                    let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date.timestamp)
                    // Use year/month/day/hour/minute as a unique bucket
                    return DateComponents(year: comps.year, month: comps.month, day: comps.day, hour: comps.hour, minute: comps.minute)
                })
                return min(3, minuteBuckets.count)
            } else {
                let distinctDays = Array(Set(moments.map { calendar.startOfDay(for: $0.timestamp) }))
                return min(3, distinctDays.count)
            }
        }()

        // If fewer than 3 distinct days with moments so far, schedule 4pm daily
        if firstThreeDayCount < 3 {
            await scheduleDailyAt(hour: 16, minute: 0, identifier: "onboarding_4pm", body: bodyTextForStyle(defaultBody: "What made you smile today? ✨"))
            await scheduleSecondChanceIfEnabled()
            return
        }

        // We have at least 3 distinct days. Compute average time-of-day for the first three days of activity.
        // Take the earliest three distinct days chronologically (first three days of usage).
        let firstThreeDays: [Date] = {
            if accelerated {
                // Use chronological unique minute buckets
                let buckets = Array(Set(moments.map { m in
                    calendar.dateComponents([.year, .month, .day, .hour, .minute], from: m.timestamp)
                }))
                .sorted { lhs, rhs in
                    let l = calendar.date(from: lhs) ?? .distantPast
                    let r = calendar.date(from: rhs) ?? .distantPast
                    return l < r
                }
                let first3 = buckets.prefix(3)
                return first3.compactMap { calendar.date(from: $0) }
            } else {
                let chronologicalDays = Array(Set(moments.map { calendar.startOfDay(for: $0.timestamp) })).sorted()
                return Array(chronologicalDays.prefix(3))
            }
        }()

        // Collect all moments that fall on those first three days
        let momentsInFirstThreeDays = moments.filter { m in
            let d = calendar.startOfDay(for: m.timestamp)
            return firstThreeDays.contains(d)
        }

        // Compute average seconds from midnight across those moments
        let secondsFromMidnight: [Int] = momentsInFirstThreeDays.map { m in
            let comps = calendar.dateComponents([.hour, .minute, .second], from: m.timestamp)
            let h = comps.hour ?? 0
            let mi = comps.minute ?? 0
            let s = comps.second ?? 0
            return h * 3600 + mi * 60 + s
        }

        // Fallback to 4pm if no samples (shouldn't happen if we had 3 days, but be safe)
        guard !secondsFromMidnight.isEmpty else {
            await scheduleDailyAt(hour: 16, minute: 0, identifier: "avg_fallback_4pm", body: bodyTextForStyle(defaultBody: "Ready to reflect on today?"))
            await scheduleSecondChanceIfEnabled()
            return
        }

        let avg = secondsFromMidnight.reduce(0, +) / secondsFromMidnight.count
        let avgHour = avg / 3600
        let avgMinute = (avg % 3600) / 60

        // Schedule exactly one repeating notification at the averaged time
        await scheduleDailyAt(hour: avgHour, minute: avgMinute, identifier: "smart_average_time", body: bodyTextForStyle(defaultBody: "Time for a moment of gratitude ✨"))
        await scheduleSecondChanceIfEnabled()
    }
    
    private func bodyTextForStyle(defaultBody: String) -> String {
        switch ReminderPreferences.style {
        case .gentle:
            return defaultBody
        case .motivational:
            return "Let’s capture a win today! ✨"
        case .quiet:
            return "A gentle nudge to add a moment."
        }
    }
    
    private func scheduleDailyAt(hour: Int, minute: Int, identifier: String, body: String) async {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        await scheduleNotification(identifier: identifier, title: "Daily Joy", body: body, dateComponents: comps)
    }

    private func scheduleMWFAt4pm(body: String) async {
        let weekdays = [2, 4, 6] // Monday(2), Wednesday(4), Friday(6)
        for (idx, wd) in weekdays.enumerated() {
            var comps = DateComponents()
            comps.weekday = wd
            comps.hour = 16
            comps.minute = 0
            await scheduleNotification(identifier: "mwf_4pm_\(idx)", title: "Daily Joy", body: body, dateComponents: comps)
        }
    }
    
    private func scheduleSecondChanceIfEnabled() async {
        guard ReminderPreferences.secondChanceEnabled else { return }
        let (h, m) = ReminderPreferences.secondChanceTime
        var comps = DateComponents()
        comps.hour = h
        comps.minute = m
        // Only show if no moment today; the trigger is repeating daily, but content remains same
        await scheduleNotification(identifier: "second_chance_daily", title: "Daily Joy", body: bodyTextForStyle(defaultBody: "Still time to capture a moment 🌙"), dateComponents: comps)
    }
    
   /* private func scheduleEndOfDayReminder() async {
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
    */
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

    func debug_fireIn(seconds: TimeInterval, body: String = "[DEBUG] Immediate test") async {
        let content = UNMutableNotificationContent()
        content.title = "Daily Joy"
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "debug_immediate_\(UUID().uuidString)", content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error scheduling immediate debug notification: \(error)")
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
        // No removal of second chance notifications needed since they repeat daily and UI check handles visibility
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
    
    // MARK: - Testing Helpers
    // Call these from a debug UI to simulate schedules immediately
    func debug_scheduleOnboarding4PM() async {
        cancelAllNotifications()
        await scheduleDailyAt(hour: 16, minute: 0, identifier: "debug_onboarding_4pm", body: "[DEBUG] Onboarding 4 PM")
    }

    func debug_scheduleAverage(at hour: Int, minute: Int) async {
        cancelAllNotifications()
        await scheduleDailyAt(hour: hour, minute: minute, identifier: "debug_avg_time", body: "[DEBUG] Average time")
    }

    func debug_scheduleFallback4PM() async {
        cancelAllNotifications()
        await scheduleDailyAt(hour: 16, minute: 0, identifier: "debug_fallback_4pm", body: "[DEBUG] Fallback 4 PM")
    }

    func debug_scheduleMWF4PM() async {
        cancelAllNotifications()
        await scheduleMWFAt4pm(body: "[DEBUG] MWF 4 PM")
    }
}
