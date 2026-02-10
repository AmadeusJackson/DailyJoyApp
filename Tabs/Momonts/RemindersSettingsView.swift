import SwiftUI

struct RemindersSettingsView: View {
    @Environment(DataContainer.self) private var dataContainer: DataContainer?

    @State private var style: NotificationManager.ReminderStyle = .gentle
    @State private var secondChanceEnabled: Bool = false
    @State private var selectedDate: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Style") {
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

                Section("Actions") {
                    Button("Save & Apply") {
                        savePreferences()
                        Task { await dataContainer?.notificationManager.scheduleSmartNotifications() }
                    }
                }
            }
            .navigationTitle("Reminders")
            .onAppear { loadPreferences() }
        }
    }

    private func loadPreferences() {
        style = NotificationManager.ReminderPreferences.style
        secondChanceEnabled = NotificationManager.ReminderPreferences.secondChanceEnabled
        let t = NotificationManager.ReminderPreferences.secondChanceTime
        selectedDate = Calendar.current.date(bySettingHour: t.hour, minute: t.minute, second: 0, of: Date()) ?? Date()
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
