import SwiftUI

struct RemindersSettingsView: View {
    @Environment(DataContainer.self) private var dataContainer: DataContainer?

    @State private var style: NotificationManager.ReminderStyle = .gentle
    @State private var secondChanceEnabled: Bool = false
    @State private var selectedDate: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var iCloudSyncEnabled: Bool = DataContainer.isICloudSyncEnabled
    @State private var showDeleteAllConfirmation = false
    @State private var showRestartNotice = false

    var body: some View {
        NavigationStack {
            Form {
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

                Section("iCloud Sync") {
                    Toggle("Sync with iCloud", isOn: $iCloudSyncEnabled)
                        .onChange(of: iCloudSyncEnabled) { _, newValue in
                            DataContainer.isICloudSyncEnabled = newValue
                            showRestartNotice = true
                        }

                    Text("No account is required. If enabled, data syncs through the user's iCloud account.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if showRestartNotice {
                        Text("Restart the app to apply this change.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Actions") {
                    Button("Save & Apply") {
                        savePreferences()
                        Task { await dataContainer?.notificationManager.scheduleSmartNotifications() }
                    }
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
        }
    }

    private func loadPreferences() {
        style = NotificationManager.ReminderPreferences.style
        secondChanceEnabled = NotificationManager.ReminderPreferences.secondChanceEnabled
        let t = NotificationManager.ReminderPreferences.secondChanceTime
        selectedDate = Calendar.current.date(bySettingHour: t.hour, minute: t.minute, second: 0, of: Date()) ?? Date()
        iCloudSyncEnabled = DataContainer.isICloudSyncEnabled
        showRestartNotice = false
    }

    private func savePreferences() {
        NotificationManager.ReminderPreferences.style = style
        NotificationManager.ReminderPreferences.secondChanceEnabled = secondChanceEnabled
        let comps = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
        NotificationManager.ReminderPreferences.secondChanceTime = (comps.hour ?? 21, comps.minute ?? 0)
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

#Preview {
    RemindersSettingsView()
        .sampleDataContainer()
}
