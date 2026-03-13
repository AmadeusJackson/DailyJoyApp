import Foundation
import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private var player: AVAudioPlayer?

    // Configure to respect the mute switch and mix with other audio
    func configureAudioSessionIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        // Only attempt configuration if not already active
        if session.isOtherAudioPlaying { /* still OK to set category with mix */ }
        do {
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            // Optional: log error
        }
    }

    /// Plays the add-moment sound only if the user has enabled interaction sounds.
    /// Default file name and extension match the provided asset: PartyPopperSound.mp3
    func playAddMomentSoundIfEnabled(fileName: String = "PartyPopperSound", fileExtension: String = "mp3") {
        let enabled = UserDefaults.standard.bool(forKey: InteractionSoundSettingsKey.appStorageKey)
        guard enabled else { return }
        playSound(named: fileName, ext: fileExtension)
    }

    private func playSound(named name: String, ext: String) {
        configureAudioSessionIfNeeded()
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Optional: log error
        }
    }
}
