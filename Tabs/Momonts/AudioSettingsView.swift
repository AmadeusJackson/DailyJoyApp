import SwiftUI

struct AudioSettingsView: View {
    @AppStorage(InteractionSoundSettingsKey.appStorageKey) private var playInteractionSounds: Bool = true

    var body: some View {
        Form {
            Section(header: Text("Audio")) {
                Toggle("Interaction Sounds", isOn: $playInteractionSounds)
                    .accessibilityHint("Play subtle sounds for actions like adding a moment.")
            }
            Section(footer: Text("Interaction sounds respect the mute switch and will mix with other audio, like music or podcasts.")) {
                EmptyView()
            }
        }
        .navigationTitle("Sound")
    }
}

#Preview {
    NavigationStack { AudioSettingsView() }
}
