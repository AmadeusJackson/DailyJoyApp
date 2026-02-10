import SwiftUI

struct RemindersSettingsView: View {
    @Environment(DataContainer.self) private var dataContainer: DataContainer?

    @State private var style: NotificationManager.ReminderStyle = .gentle
    @State private var secondChanceEnabled: Bool = false
    @State private var hour: Int = 21
    @State private var minute: Int = 0

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
                        HStack {
                            Stepper("Hour: \(hour)", value: $hour, in: 0...23)
                            Stepper("Minute: \(minute)", value: $minute, in: 0...59)
                        }
                        Text("Fires daily at \(String(format: "%02d:%02d", hour, minute)) if you haven't added a moment yet.")
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
        hour = t.hour
        minute = t.minute
    }

    private func savePreferences() {
        NotificationManager.ReminderPreferences.style = style
        NotificationManager.ReminderPreferences.secondChanceEnabled = secondChanceEnabled
        NotificationManager.ReminderPreferences.secondChanceTime = (hour, minute)
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
