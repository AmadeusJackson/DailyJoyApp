//
//  DataContainer.swift
//  GratefulMoments
//
//  Created by Amadeus Jackson on 11/14/25.
//

import SwiftData
import SwiftUI
import WidgetKit
import Foundation

// MARK: - DataContainer
// Coordinates app-wide persistence using SwiftData, optional iCloud sync, and App Group communication for widgets.
// Also manages badge loading/unlocking, notifications, import/export, and widget snapshot updates.

private let appGroupIdentifier = "group.com.amadeusjackson.dailyjoy"
private let widgetAppGroupIdentifier = "group.dailyjoy.shared"
private let iCloudContainerIdentifier = "iCloud.com.amadeusjackson.dailyjoy"
// Set to true after enabling iCloud capability in a paid Apple Developer Program team.
private let iCloudCapabilityAvailableDefault = false
private let iCloudSyncEnabledKey = "icloud_sync_enabled"
private let iCloudCapabilityAvailableKey = "icloud_capability_available"

/// Widget kind identifiers used to target specific timeline reloads.
struct DailyJoyWidgetKinds {
    static let streakSmall = "DailyJoyStreakSmallWidget"
    static let addSmall = "DailyJoyAddSmallWidget"
    static let streakAddMedium = "DailyJoyStreakAddMediumWidget"
    static let large = "DailyJoyLargeWidget"
    static let lock = "DailyJoyLockWidget"
}

/// Central application data coordinator.
/// - Manages the SwiftData `ModelContainer` and main `ModelContext`.
/// - Configures storage (in-memory, iCloud, or local) based on runtime flags.
/// - Orchestrates badge loading/unlocking, notifications, and widget updates.
@Observable
@MainActor
class DataContainer {
    /// Backing SwiftData container for all models.
    let modelContainer: ModelContainer
    /// Handles badge definitions and unlock logic.
    var badgeManager: BadgeManager
    /// Schedules and cancels local notifications.
    var notificationManager: NotificationManager

    /// Convenience accessor for the main model context.
    var context: ModelContext {
        modelContainer.mainContext
    }

    /// Lazily creates a `ChallengeManager` bound to the main context.
    var challengeManager: ChallengeManager {
        ChallengeManager(modelContext: context)
    }

    /// Initializes the data stack.
    /// - Parameter includeSampleMoments: When true, uses an in-memory store and seeds sample data for previews and testing.
    init(includeSampleMoments: Bool = false) {
        if !Self.isICloudCapabilityAvailable {
            Self.isICloudSyncEnabled = false
        }
        let schema = Schema([
            Moment.self,
            Badge.self,
            DailyChallenge.self,
            Draft.self
        ])

        do {
            if includeSampleMoments {
                let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                #if DEBUG
                print("Using in-memory sample store (includeSampleMoments == true)")
                #endif
            } else if Self.isICloudSyncEnabled && Self.isICloudCapabilityAvailable {
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    cloudKitDatabase: .private(iCloudContainerIdentifier)
                )
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                #if DEBUG
                print("Using iCloud CloudKit store (iCloud sync enabled)")
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
            updateWidgetSnapshot()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    /// Inserts sample `Moment` data and unlocks any resulting badges.
    private func loadSampleMoments() throws {
        for moment in Moment.sampleData {
            context.insert(moment)
            try badgeManager.unlockBadges(newMoment: moment)
        }
    }

    /// Inserts and persists a moment, unlocking badges and refreshing widget timelines.
    func saveMoment(_ moment: Moment) throws {
        context.insert(moment)
        try badgeManager.unlockBadges(newMoment: moment)
        try context.save()
        updateWidgetSnapshot()
    }

    /// Deletes a moment, persists changes, and refreshes widget timelines.
    func deleteMoment(_ moment: Moment) throws {
        context.delete(moment)
        try context.save()
        updateWidgetSnapshot()
    }

    /// Reloads timelines for all known Daily Joy widget kinds.
    func refreshWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.streakSmall)
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.addSmall)
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.streakAddMedium)
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.large)
        WidgetCenter.shared.reloadTimelines(ofKind: DailyJoyWidgetKinds.lock)
    }

    /// Exports all data (moments, badges, challenges) as JSON and CSV files.
    /// - Returns: URLs to the generated files in the temporary directory.
    func exportAllDataFiles() throws -> [URL] {
        let exportPayload = try buildExportPayload(includeBadges: true, includeChallenges: true)
        let jsonURL = try writeJSONExport(payload: exportPayload)
        let csvURL = try writeCSVExport(payload: exportPayload)
        return [jsonURL, csvURL]
    }

    /// Exports only `Moment` data as JSON and CSV files.
    func exportMomentsOnlyFiles() throws -> [URL] {
        let exportPayload = try buildExportPayload(includeBadges: false, includeChallenges: false)
        let jsonURL = try writeJSONExport(payload: exportPayload)
        let csvURL = try writeCSVExport(payload: exportPayload)
        return [jsonURL, csvURL]
    }

    /// Encodes the minimal state required by widgets to render timelines.
    private struct WidgetSnapshot: Codable {
        let lastUpdated: Date
        let streakCount: Int
        let latestMomentTitle: String
        let latestMomentNote: String
        let latestMomentDate: Date?
        let challenge1: String
        let challenge2: String
        let challenge1Completed: Bool
        let challenge2Completed: Bool
        let hasLoggedToday: Bool
    }

    /// Encodes the full export payload used for backup/restore.
    private struct ExportPayload: Codable {
        let exportedAt: Date
        let moments: [MomentExport]
        let badges: [BadgeExport]
        let challenges: [ChallengeExport]
    }

    /// Serializable representation of a `Moment` for export.
    private struct MomentExport: Codable {
        let title: String
        let note: String
        let timestamp: Date
        let isLocked: Bool
        let imageDataBase64: String?
    }

    /// Serializable representation of a `Badge` for export.
    private struct BadgeExport: Codable {
        let detailsRawValue: Int
        let title: String
        let unlockedAt: Date?
        let linkedMomentTitle: String?
    }

    /// Serializable representation of a `DailyChallenge` for export.
    private struct ChallengeExport: Codable {
        let date: Date
        let challenge1: String
        let challenge2: String
        let challenge1Completed: Bool
        let challenge2Completed: Bool
    }

    /// Builds an `ExportPayload` by fetching current data from the model context.
    private func buildExportPayload(includeBadges: Bool, includeChallenges: Bool) throws -> ExportPayload {
        let moments = try context.fetch(FetchDescriptor<Moment>(sortBy: [SortDescriptor(\.timestamp)]))
        let badges: [Badge] = includeBadges ? (try context.fetch(FetchDescriptor<Badge>())) : []
        let challenges: [DailyChallenge] = includeChallenges ? (try context.fetch(FetchDescriptor<DailyChallenge>(sortBy: [SortDescriptor(\.date)]))) : []

        let momentExports = moments.map { moment in
            MomentExport(
                title: moment.title,
                note: moment.note,
                timestamp: moment.timestamp,
                isLocked: moment.isLocked,
                imageDataBase64: moment.imageData?.base64EncodedString()
            )
        }

        let badgeExports = badges.map { badge in
            BadgeExport(
                detailsRawValue: badge.details.rawValue,
                title: badge.details.title,
                unlockedAt: badge.timestamp,
                linkedMomentTitle: badge.moment?.title
            )
        }

        let challengeExports = challenges.map { challenge in
            ChallengeExport(
                date: challenge.date,
                challenge1: challenge.challenge1,
                challenge2: challenge.challenge2,
                challenge1Completed: challenge.challenge1Completed,
                challenge2Completed: challenge.challenge2Completed
            )
        }

        return ExportPayload(
            exportedAt: Date(),
            moments: momentExports,
            badges: badgeExports,
            challenges: challengeExports
        )
    }

    /// Writes the export payload as a JSON file and returns its URL.
    private func writeJSONExport(payload: ExportPayload) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(exportFileName(extension: "json"))
        try data.write(to: url, options: [.atomic])
        return url
    }

    /// Writes the export payload as a CSV file and returns its URL.
    private func writeCSVExport(payload: ExportPayload) throws -> URL {
        var lines: [String] = []
        lines.append("# Moments")
        lines.append("title,note,timestamp,isLocked,hasImage")
        for moment in payload.moments {
            let row = [
                csvEscape(moment.title),
                csvEscape(moment.note),
                csvEscape(Self.csvDateFormatter.string(from: moment.timestamp)),
                moment.isLocked ? "true" : "false",
                moment.imageDataBase64 == nil ? "false" : "true"
            ].joined(separator: ",")
            lines.append(row)
        }

        lines.append("")
        lines.append("# Badges")
        lines.append("detailsRawValue,title,unlockedAt,linkedMomentTitle")
        for badge in payload.badges {
            let row = [
                String(badge.detailsRawValue),
                csvEscape(badge.title),
                csvEscape(badge.unlockedAt.map { Self.csvDateFormatter.string(from: $0) } ?? ""),
                csvEscape(badge.linkedMomentTitle ?? "")
            ].joined(separator: ",")
            lines.append(row)
        }

        lines.append("")
        lines.append("# Challenges")
        lines.append("date,challenge1,challenge2,challenge1Completed,challenge2Completed")
        for challenge in payload.challenges {
            let row = [
                csvEscape(Self.csvDateFormatter.string(from: challenge.date)),
                csvEscape(challenge.challenge1),
                csvEscape(challenge.challenge2),
                challenge.challenge1Completed ? "true" : "false",
                challenge.challenge2Completed ? "true" : "false"
            ].joined(separator: ",")
            lines.append(row)
        }

        let csv = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(exportFileName(extension: "csv"))
        guard let data = csv.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url, options: [.atomic])
        return url
    }

    /// Generates a timestamped file name for an export with the given extension.
    private func exportFileName(extension ext: String) -> String {
        "DailyJoyExport_\(Self.fileDateFormatter.string(from: Date())).\(ext)"
    }

    /// Escapes values for safe inclusion in CSV output.
    private func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    /// Date formatter used for CSV export rows.
    private static let csvDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()

    /// Date formatter used in generated export file names.
    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()

    /// Aggregates current app state and writes a compact snapshot for widgets, then reloads timelines.
    func updateWidgetSnapshot() {
        do {
            let moments = try context.fetch(FetchDescriptor<Moment>(sortBy: [SortDescriptor(\.timestamp)]))
            let streak = StreakCalculator().calculateStreak(for: moments)
            let hasLoggedToday = StreakCalculator().hasLoggedToday(moments: moments)
            let latestMoment = moments.last
            let challenge = ChallengeManager(modelContext: context).getTodaysChallenge()

            let snapshot = WidgetSnapshot(
                lastUpdated: Date(),
                streakCount: streak,
                latestMomentTitle: latestMoment?.title ?? "No moments yet",
                latestMomentNote: latestMoment?.note ?? "Add a grateful moment today.",
                latestMomentDate: latestMoment?.timestamp,
                challenge1: challenge.challenge1,
                challenge2: challenge.challenge2,
                challenge1Completed: challenge.challenge1Completed,
                challenge2Completed: challenge.challenge2Completed,
                hasLoggedToday: hasLoggedToday
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            if let widgetDefaults = UserDefaults(suiteName: widgetAppGroupIdentifier) {
                widgetDefaults.set(data, forKey: "widgetSnapshot")
            }
            refreshWidgets()
        } catch {
            #if DEBUG
            print("Failed to update widget snapshot: \(error)")
            #endif
        }
    }

    /// Imports a full data export from disk, merging with existing records when possible.
    func importAllData(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(ExportPayload.self, from: data)

        for momentExport in payload.moments {
            let moment = Moment(
                title: momentExport.title,
                note: momentExport.note,
                imageData: momentExport.imageDataBase64.flatMap { Data(base64Encoded: $0) },
                timestamp: momentExport.timestamp,
                isLocked: momentExport.isLocked
            )
            context.insert(moment)
        }

        try badgeManager.loadBadgesIfNeeded()
        let existingBadges = try context.fetch(FetchDescriptor<Badge>())
        let badgeByRawValue = Dictionary(grouping: existingBadges, by: { $0.details.rawValue })
        let moments = try context.fetch(FetchDescriptor<Moment>())

        for badgeExport in payload.badges {
            let matchingBadge = badgeByRawValue[badgeExport.detailsRawValue]?.first
            if let badge = matchingBadge {
                badge.timestamp = badgeExport.unlockedAt
                if let title = badgeExport.linkedMomentTitle {
                    badge.moment = moments.first(where: { $0.title == title })
                }
            } else if let details = BadgeDetails(rawValue: badgeExport.detailsRawValue) {
                let badge = Badge(details: details)
                badge.timestamp = badgeExport.unlockedAt
                if let title = badgeExport.linkedMomentTitle {
                    badge.moment = moments.first(where: { $0.title == title })
                }
                context.insert(badge)
            }
        }

        let existingChallenges = try context.fetch(FetchDescriptor<DailyChallenge>())
        let calendar = Calendar.current
        let challengeByDay = Dictionary(grouping: existingChallenges, by: { calendar.startOfDay(for: $0.date) })

        for challengeExport in payload.challenges {
            let dayKey = calendar.startOfDay(for: challengeExport.date)
            if let existing = challengeByDay[dayKey]?.first {
                existing.challenge1 = challengeExport.challenge1
                existing.challenge2 = challengeExport.challenge2
                existing.challenge1Completed = challengeExport.challenge1Completed
                existing.challenge2Completed = challengeExport.challenge2Completed
            } else {
                let challenge = DailyChallenge(
                    date: challengeExport.date,
                    challenge1: challengeExport.challenge1,
                    challenge2: challengeExport.challenge2,
                    challenge1Keywords: [],
                    challenge2Keywords: []
                )
                challenge.challenge1Completed = challengeExport.challenge1Completed
                challenge.challenge2Completed = challengeExport.challenge2Completed
                context.insert(challenge)
            }
        }

        try context.save()
        updateWidgetSnapshot()
    }

    /// Stores whether iCloud sync is enabled (user preference persisted in `UserDefaults`).
    static var isICloudSyncEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: iCloudSyncEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: iCloudSyncEnabledKey)
        }
    }

    /// Tracks whether the iCloud capability is available for this build (useful for QA and diagnostics).
    static var isICloudCapabilityAvailable: Bool {
        get {
            if UserDefaults.standard.object(forKey: iCloudCapabilityAvailableKey) == nil {
                UserDefaults.standard.set(iCloudCapabilityAvailableDefault, forKey: iCloudCapabilityAvailableKey)
            }
            return UserDefaults.standard.bool(forKey: iCloudCapabilityAvailableKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: iCloudCapabilityAvailableKey)
        }
    }

    /// Irreversibly deletes all persisted data, clears app group state, cancels notifications, and refreshes widgets.
    @MainActor
    func deleteAllData() async {
        let context = modelContainer.mainContext
        do {
            let moments = try context.fetch(FetchDescriptor<Moment>())
            let badges = try context.fetch(FetchDescriptor<Badge>())
            let challenges = try context.fetch(FetchDescriptor<DailyChallenge>())
            let drafts = try context.fetch(FetchDescriptor<Draft>())

            moments.forEach { context.delete($0) }
            badges.forEach { context.delete($0) }
            challenges.forEach { context.delete($0) }
            drafts.forEach { context.delete($0) }

            try context.save()
        } catch {
            #if DEBUG
            print("Failed to delete all data: \(error)")
            #endif
        }

        notificationManager.cancelAllNotifications()
        clearAppGroupData()
        updateWidgetSnapshot()
    }

    /// Removes any values persisted to the shared App Group `UserDefaults` used by widgets and extensions.
    private func clearAppGroupData() {
        if let defaults = UserDefaults(suiteName: appGroupIdentifier) {
            defaults.removeObject(forKey: "savedNotes")
            defaults.removeObject(forKey: "widgetNoteData")
            defaults.synchronize()
        }
        if let widgetDefaults = UserDefaults(suiteName: widgetAppGroupIdentifier) {
            widgetDefaults.removeObject(forKey: "widgetSnapshot")
            widgetDefaults.removeObject(forKey: "streakCount")
            widgetDefaults.synchronize()
        }
    }
}

private let sampleContainer = DataContainer(includeSampleMoments: true)  

/// Injects a sample `DataContainer` and its `ModelContainer` into the environment for previews.
extension View {
    func sampleDataContainer() -> some View {
        self
            .environment(sampleContainer)
            .modelContainer(sampleContainer.modelContainer)
    }
}
