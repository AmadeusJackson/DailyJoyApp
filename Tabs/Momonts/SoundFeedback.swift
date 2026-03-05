import Foundation
import AVFoundation
import SwiftUI

// MARK: - Interaction Sound Settings Key
// A simple settings bridge using AppStorage. Views can bind to this key.
struct InteractionSoundSettingsKey {
    static let appStorageKey = "interactionSoundsEnabled"
}

// MARK: - Environment support for interaction sounds
private struct InteractionSoundsEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    /// Whether the app should play interaction sounds.
    /// Backed by @AppStorage in views, but this provides a convenient read for helpers.
    var interactionSoundsEnabled: Bool {
        get { self[InteractionSoundsEnabledKey.self] }
        set { self[InteractionSoundsEnabledKey.self] = newValue }
    }
}

extension View {
    /// Inject an interaction sound enabled flag into the environment.
    func interactionSoundsEnabled(_ enabled: Bool) -> some View {
        environment(\.interactionSoundsEnabled, enabled)
    }
}

// MARK: - Sound & Haptic Feedback
final class SoundFeedback {
    static let shared = SoundFeedback()

    private var player: AVAudioPlayer?

    /// Play the add-moment sound if allowed by settings and system state.
    /// - Parameters:
    ///   - reduceMotion: If true, skip sound (callers can still trigger haptics separately).
    ///   - enabled: In-app toggle for interaction sounds.
    ///   - fileName: The bundled audio resource name without extension.
    ///   - fileExtension: The bundled audio file extension (default: "caf").
    func playAddMomentSound(reduceMotion: Bool, enabled: Bool, fileName: String = "addMoment", fileExtension: String = "caf") {
        guard enabled, !reduceMotion else { return }

        // Look for a bundled asset. If not found, silently do nothing.
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            return
        }

        do {
            // .ambient respects the mute switch and mixes with other audio (e.g., Music/Podcasts).
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true, options: [.notifyOthersOnDeactivation])

            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.7
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Intentionally ignore playback errors to avoid impacting UX.
        }
    }
}

// MARK: - Haptic helpers
enum HapticFeedback {
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
