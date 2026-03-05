import Foundation
import AVFoundation
import SwiftUI

// MARK: - Interaction Sound Settings Key
// A simple settings bridge using AppStorage. Views can bind to this key.
struct InteractionSoundSettingsKey {
    static let appStorageKey = "interactionSoundsEnabled"
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
        #if DEBUG
        print("[SoundFeedback] Requested playAddMomentSound — reduceMotion=\(reduceMotion), enabled=\(enabled), file=\(fileName).\(fileExtension)")
        #endif

        guard enabled, !reduceMotion else {
            #if DEBUG
            if !enabled { print("[SoundFeedback] Skipped: interaction sounds disabled by user setting.") }
            if reduceMotion { print("[SoundFeedback] Skipped: Reduce Motion is enabled.") }
            #endif
            return
        }

        // Look for a bundled asset. If not found, silently do nothing.
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            #if DEBUG
            print("[SoundFeedback] Asset not found in bundle: \(fileName).\(fileExtension)")
            #endif
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
            #if DEBUG
            print("[SoundFeedback] Playing sound: \(fileName).\(fileExtension)")
            #endif
            player?.play()
        } catch {
            #if DEBUG
            print("[SoundFeedback] Playback error: \(error)")
            #endif
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

