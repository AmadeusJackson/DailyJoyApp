import SwiftUI
import UniformTypeIdentifiers

struct RemindersSettingsView: View {
    @Environment(DataContainer.self) private var dataContainer: DataContainer?
    @Environment(\.dismiss) private var dismiss

    @State private var style: NotificationManager.ReminderStyle = .gentle
    @State private var secondChanceEnabled: Bool = false
    @State private var selectedDate: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showDeleteAllConfirmation = false
    @State private var exportFiles: [URL] = []
    @State private var showExportSheet = false
    @State private var exportErrorMessage: String?
    @State private var showImportPicker = false
    @State private var importSuccessMessage: String?
    @State private var showDiscardChangesAlert = false
    @State private var showSavedNotice = false
    @State private var interactionSoundsEnabled: Bool = UserDefaults.standard.bool(forKey: InteractionSoundSettingsKey.appStorageKey)
    @State private var showBackupRestoreDialog = false

    private var hasUnsavedChanges: Bool {
        let persistedStyle = NotificationManager.ReminderPreferences.style
        let persistedSecondChanceEnabled = NotificationManager.ReminderPreferences.secondChanceEnabled
        let t = NotificationManager.ReminderPreferences.secondChanceTime
        let persistedDate = Calendar.current.date(bySettingHour: t.hour, minute: t.minute, second: 0, of: Date()) ?? Date()
        let persistedInteractionSounds = UserDefaults.standard.bool(forKey: InteractionSoundSettingsKey.appStorageKey)
        let currentComps = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
        let persistedComps = Calendar.current.dateComponents([.hour, .minute], from: persistedDate)
        let timeChanged = currentComps.hour != persistedComps.hour || currentComps.minute != persistedComps.minute
        return style != persistedStyle ||
               secondChanceEnabled != persistedSecondChanceEnabled ||
               timeChanged ||
               interactionSoundsEnabled != persistedInteractionSounds
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Manage reminders, backups, and privacy for your journal.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("Audio") {
                    Toggle("Interaction Sounds", isOn: $interactionSoundsEnabled)
                    .accessibilityHint("Play subtle sounds for actions like adding a moment.")

                    Text("Interaction sounds respect the mute switch and will mix with other audio, like music or podcasts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Reminders") {
                    Picker("Reminder Style", selection: $style) {
                        ForEach(NotificationManager.ReminderStyle.allCases, id: \.self) { s in
                            Text(label(for: s)).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(previewText(for: style))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Second Chance Reminder") {
                    Toggle("Enable", isOn: $secondChanceEnabled)
                    if secondChanceEnabled {
                        DatePicker(
                            "Time",
                            selection: Binding(get: { selectedDate }, set: { selectedDate = $0 }),
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        Text("Fires daily at the selected time if you haven't added a moment yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Backup & Restore") {
                    Button("Backup & Restore") {
                        showBackupRestoreDialog = true
                    }
                }

                Section("Support & About") {
                    if let supportEmailURL {
                        Link("Contact Support", destination: supportEmailURL)
                    }
                    Text("Version \(appVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Danger Zone") {
                    Button("Delete All Data", role: .destructive) {
                        showDeleteAllConfirmation = true
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear { loadPreferences() }
            .confirmationDialog("Delete all data?", isPresented: $showDeleteAllConfirmation) {
                Button("Delete All Data", role: .destructive) {
                    Task { await dataContainer?.deleteAllData() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all moments, badges, challenges, and drafts. If iCloud sync is enabled, it will also delete from iCloud.")
            }
            .alert("Export Failed", isPresented: Binding(get: { exportErrorMessage != nil }, set: { _ in exportErrorMessage = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportErrorMessage ?? "")
            }
            .alert("Import Complete", isPresented: Binding(get: { importSuccessMessage != nil }, set: { _ in importSuccessMessage = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importSuccessMessage ?? "")
            }
            .alert("Discard changes?", isPresented: $showDiscardChangesAlert) {
                Button("Discard Changes", role: .destructive) {
                    loadPreferences()
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Do you want to discard them?")
            }
            .alert("Settings saved", isPresented: $showSavedNotice) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your changes have been applied.")
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(items: exportFiles)
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .confirmationDialog("Backup & Restore", isPresented: $showBackupRestoreDialog) {
                Button("Backup (Export)") { exportData() }
                Button("Restore (Import)") { showImportPicker = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose an action. Backups are exported as JSON.")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showDiscardChangesAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .accessibilityLabel("Cancel and discard changes")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePreferences()
                        Task { await dataContainer?.notificationManager.scheduleSmartNotifications() }
                        showSavedNotice = true
                    }
                    .accessibilityLabel("Save settings")
                    .disabled(!hasUnsavedChanges)
                    .tint(hasUnsavedChanges ? Color("Ember") : .gray)
                }
            }
        }
    }

    private func loadPreferences() {
        style = NotificationManager.ReminderPreferences.style
        secondChanceEnabled = NotificationManager.ReminderPreferences.secondChanceEnabled
        let t = NotificationManager.ReminderPreferences.secondChanceTime
        selectedDate = Calendar.current.date(bySettingHour: t.hour, minute: t.minute, second: 0, of: Date()) ?? Date()
        exportFiles = []
        showExportSheet = false
        exportErrorMessage = nil
        showImportPicker = false
        importSuccessMessage = nil
        interactionSoundsEnabled = UserDefaults.standard.bool(forKey: InteractionSoundSettingsKey.appStorageKey)
    }

    private func savePreferences() {
        NotificationManager.ReminderPreferences.style = style
        NotificationManager.ReminderPreferences.secondChanceEnabled = secondChanceEnabled
        let comps = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
        NotificationManager.ReminderPreferences.secondChanceTime = (comps.hour ?? 21, comps.minute ?? 0)
        UserDefaults.standard.set(interactionSoundsEnabled, forKey: InteractionSoundSettingsKey.appStorageKey)
    }

    private func exportData() {
        guard let dataContainer else {
            exportErrorMessage = "Data store is not available."
            return
        }
        do {
            exportFiles = try dataContainer.exportAllDataFiles()
            showExportSheet = true
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func exportMomentsOnly() {
        guard let dataContainer else {
            exportErrorMessage = "Data store is not available."
            return
        }
        do {
            exportFiles = try dataContainer.exportMomentsOnlyFiles()
            showExportSheet = true
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        guard let dataContainer else {
            exportErrorMessage = "Data store is not available."
            return
        }
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            try dataContainer.importAllData(from: url)
            importSuccessMessage = "Import finished. Your data is now available."
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private var supportEmailURL: URL? {
        URL(string: "mailto:nottherealmozart@gmail.com")
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func label(for style: NotificationManager.ReminderStyle) -> String {
        switch style {
        case .gentle: return "Gentle"
        case .motivational: return "Motivational"
        case .quiet: return "Quiet"
        }
    }

    private func previewText(for style: NotificationManager.ReminderStyle) -> String {
        switch style {
        case .gentle: return "What made you smile today? ✨"
        case .motivational: return "Let’s capture a win today! ✨"
        case .quiet: return "A gentle nudge to add a moment."
        }
    }
}
